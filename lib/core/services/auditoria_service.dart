import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/registro_auditoria.dart';
import 'sesion_actual.dart';
import 'supabase_service.dart';

/// Servicio de auditoría básica: registra quién hizo qué y cuándo sobre
/// las entidades principales (citas, pacientes, usuarios). Pensado para
/// dar trazabilidad mínima, no para cumplimiento normativo exhaustivo.
class AuditoriaService {
  static const _uuid = Uuid();

  static Future<void> _asegurarTabla() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS auditoria (
        id TEXT PRIMARY KEY,
        fecha TEXT NOT NULL,
        usuario_id TEXT,
        usuario_nombre TEXT NOT NULL,
        accion TEXT NOT NULL,
        entidad TEXT NOT NULL,
        entidad_id TEXT,
        detalle TEXT
      )
    ''');
  }

  /// Registra una acción de auditoría. No lanza excepciones: si algo falla
  /// (por ejemplo sin conexión), la operación principal no debe verse
  /// afectada por un fallo al auditar.
  static Future<void> registrar({
    required String accion,
    required String entidad,
    String? entidadId,
    String? detalle,
  }) async {
    try {
      await _asegurarTabla();
      final db = await DatabaseHelper.instance.database;
      final usuario = SesionActual.actual;
      final registro = RegistroAuditoria(
        id: _uuid.v4(),
        fecha: DateTime.now().toIso8601String(),
        usuarioId: usuario?.id,
        usuarioNombre: usuario?.nombre ?? 'Sistema',
        accion: accion,
        entidad: entidad,
        entidadId: entidadId,
        detalle: detalle,
      );
      await db.insert('auditoria', registro.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      _subir(registro);
    } catch (_) {
      // Nunca dejar que un fallo de auditoría rompa la operación principal.
    }
  }

  static void _subir(RegistroAuditoria r) async {
    try {
      await SupabaseService.client.from('auditoria').upsert(r.toMap());
    } catch (_) {
      // Se sincronizará después con "Sincronizar con la nube".
    }
  }

  static Future<List<RegistroAuditoria>> obtenerRegistros({
    int limite = 300,
    String? entidad,
  }) async {
    await _asegurarTabla();
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'auditoria',
      where: entidad != null ? 'entidad = ?' : null,
      whereArgs: entidad != null ? [entidad] : null,
      orderBy: 'fecha DESC',
      limit: limite,
    );
    return maps.map((m) => RegistroAuditoria.fromMap(m)).toList();
  }

  /// Sube todos los registros locales a Supabase (para reintentar los que
  /// hayan fallado por falta de conexión).
  static Future<void> subirTodo() async {
    await _asegurarTabla();
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('auditoria');
    for (final m in maps) {
      try {
        await SupabaseService.client.from('auditoria').upsert(m);
      } catch (_) {}
    }
  }

  /// Baja los registros de Supabase hacia el dispositivo local.
  static Future<void> bajarTodo() async {
    await _asegurarTabla();
    try {
      final rows = await SupabaseService.client.from('auditoria').select();
      final db = await DatabaseHelper.instance.database;
      for (final r in rows) {
        await db.insert(
          'auditoria',
          {
            'id': r['id'],
            'fecha': r['fecha'],
            'usuario_id': r['usuario_id'],
            'usuario_nombre': r['usuario_nombre'],
            'accion': r['accion'],
            'entidad': r['entidad'],
            'entidad_id': r['entidad_id'],
            'detalle': r['detalle'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }
}
