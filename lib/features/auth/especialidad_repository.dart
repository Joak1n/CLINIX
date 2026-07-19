import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/especialidad_personalizada.dart';
import '../../core/services/supabase_service.dart';

class EspecialidadRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<EspecialidadPersonalizada>> obtenerTodas(
      {bool soloActivas = false}) async {
    final db = await _db.database;
    final maps = await db.query(
      'especialidades',
      where: soloActivas ? 'activa = 1' : null,
      orderBy: 'orden ASC',
    );
    return maps.map((m) => EspecialidadPersonalizada.fromMap(m)).toList();
  }

  Future<void> crear(String nombre) async {
    final db = await _db.database;
    final maxOrden = await db.rawQuery(
        'SELECT MAX(orden) as max FROM especialidades');
    final orden = (maxOrden.first['max'] as int? ?? -1) + 1;
    final registro = {
      'id': _uuid.v4(),
      'nombre': nombre.trim(),
      'activa': 1,
      'orden': orden,
    };
    await db.insert('especialidades', registro);
    _subir(registro);
  }

  Future<void> actualizarEstado(String id, bool activa) async {
    final db = await _db.database;
    await db.update('especialidades', {'activa': activa ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('especialidades')
          .update({'activa': activa}).eq('id', id);
    } catch (_) {}
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete('especialidades', where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('especialidades')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  Future<void> renombrar(String id, String nuevoNombre) async {
    final db = await _db.database;
    await db.update('especialidades', {'nombre': nuevoNombre.trim()},
        where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('especialidades')
          .update({'nombre': nuevoNombre.trim()}).eq('id', id);
    } catch (_) {}
  }

  void _subir(Map<String, dynamic> registro) async {
    try {
      await SupabaseService.client.from('especialidades').upsert(registro);
    } catch (_) {}
  }

  static Future<void> subirTodo() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('especialidades');
    for (final m in maps) {
      try {
        await SupabaseService.client.from('especialidades').upsert(m);
      } catch (_) {}
    }
  }

  static Future<void> bajarTodo() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final rows = await SupabaseService.client.from('especialidades').select();
      for (final r in rows) {
        await db.insert('especialidades', r,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
  }
}