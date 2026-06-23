import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/adjunto.dart';
import '../../core/services/supabase_service.dart';

class AdjuntoRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Adjunto>> obtenerPorPaciente(
      String pacienteId) async {
    final db = await _db.database;
    final maps = await db.query(
      'adjuntos',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Adjunto.fromMap(m)).toList();
  }

  Future<Adjunto> subir({
    required String pacienteId,
    required String rutaArchivo,
    required String nombre,
    required String tipo,
    required int tamano,
    String? descripcion,
  }) async {
    final id = _uuid.v4();
    final ahora = DateTime.now().toIso8601String();

    // Copiar a directorio local de la app
    final dir = await getApplicationDocumentsDirectory();
    final carpeta =
        Directory('${dir.path}/adjuntos/$pacienteId');
    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }
    final extension = nombre.contains('.')
        ? '.${nombre.split('.').last}'
        : '';
    final rutaLocal = '${carpeta.path}/$id$extension';
    await File(rutaArchivo).copy(rutaLocal);

    // Subir a Supabase Storage
    String? url;
    String? storagePath;
    try {
      storagePath = 'adjuntos/$pacienteId/$id$extension';
      final bytes = await File(rutaLocal).readAsBytes();
      await SupabaseService.client.storage
          .from('adjuntos')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: tipo,
            ),
          );
      url = SupabaseService.client.storage
          .from('adjuntos')
          .getPublicUrl(storagePath);
    } catch (_) {}

    final adjunto = Adjunto(
      id: id,
      pacienteId: pacienteId,
      nombre: nombre,
      tipo: tipo,
      tamano: tamano,
      rutaLocal: rutaLocal,
      url: url,
      storagePath: storagePath,
      descripcion: descripcion,
      createdAt: ahora,
    );

    final db = await _db.database;
    await db.insert('adjuntos', adjunto.toMap());

    // Guardar en Supabase
    try {
      await SupabaseService.client
          .from('adjuntos')
          .upsert({
        'id': id,
        'paciente_id': pacienteId,
        'nombre': nombre,
        'tipo': tipo,
        'tamano': tamano,
        'url': url,
        'storage_path': storagePath,
        'descripcion': descripcion,
      });
    } catch (_) {}

    return adjunto;
  }

  Future<void> eliminar(Adjunto adjunto) async {
    // Eliminar archivo local
    if (adjunto.rutaLocal != null) {
      final file = File(adjunto.rutaLocal!);
      if (await file.exists()) await file.delete();
    }

    // Eliminar de Supabase Storage
    if (adjunto.storagePath != null) {
      try {
        await SupabaseService.client.storage
            .from('adjuntos')
            .remove([adjunto.storagePath!]);
      } catch (_) {}
    }

    // Eliminar registro
    final db = await _db.database;
    await db.delete('adjuntos',
        where: 'id = ?', whereArgs: [adjunto.id]);

    try {
      await SupabaseService.client
          .from('adjuntos')
          .delete()
          .eq('id', adjunto.id);
    } catch (_) {}
  }

  // Descargar adjunto desde Supabase si no existe local
  Future<String?> obtenerRutaLocal(
      Adjunto adjunto) async {
    if (adjunto.rutaLocal != null &&
        await File(adjunto.rutaLocal!).exists()) {
      return adjunto.rutaLocal;
    }

    if (adjunto.url != null) {
      try {
        final dir =
            await getApplicationDocumentsDirectory();
        final carpeta = Directory(
            '${dir.path}/adjuntos/${adjunto.pacienteId}');
        if (!await carpeta.exists()) {
          await carpeta.create(recursive: true);
        }
        final extension = adjunto.nombre.contains('.')
            ? '.${adjunto.nombre.split('.').last}'
            : '';
        final rutaLocal =
            '${carpeta.path}/${adjunto.id}$extension';
        final bytes = await SupabaseService.client.storage
            .from('adjuntos')
            .download(adjunto.storagePath!);
        await File(rutaLocal).writeAsBytes(bytes);
        return rutaLocal;
      } catch (_) {}
    }
    return null;
  }
}

