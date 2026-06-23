import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/nota_interna.dart';
import '../../core/services/supabase_service.dart';

class NotaInternaRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<NotaInterna>> obtenerPorNota(
      String notaClinicaId) async {
    final db = await _db.database;
    final maps = await db.query(
      'notas_internas',
      where: 'nota_clinica_id = ?',
      whereArgs: [notaClinicaId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => NotaInterna.fromMap(m)).toList();
  }

  Future<NotaInterna> crear({
    required String pacienteId,
    required String notaClinicaId,
    required String contenido,
    required String autor,
  }) async {
    final nota = NotaInterna(
      id: _uuid.v4(),
      pacienteId: pacienteId,
      notaClinicaId: notaClinicaId,
      contenido: contenido,
      autor: autor,
      createdAt: DateTime.now().toIso8601String(),
    );
    final db = await _db.database;
    await db.insert('notas_internas', nota.toMap());
    _subirNota(nota);
    return nota;
  }

  void _subirNota(NotaInterna n) async {
    try {
      await SupabaseService.client.from('notas_internas').upsert({
        'id': n.id,
        'paciente_id': n.pacienteId,
        'nota_clinica_id': n.notaClinicaId,
        'contenido': n.contenido,
        'autor': n.autor,
      });
    } catch (_) {}
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete('notas_internas',
        where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('notas_internas')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }
}

