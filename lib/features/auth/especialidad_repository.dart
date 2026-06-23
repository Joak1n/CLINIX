import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/especialidad_personalizada.dart';

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
    await db.insert('especialidades', {
      'id': _uuid.v4(),
      'nombre': nombre.trim(),
      'activa': 1,
      'orden': orden,
    });
  }

  Future<void> actualizarEstado(String id, bool activa) async {
    final db = await _db.database;
    await db.update('especialidades', {'activa': activa ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete('especialidades', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renombrar(String id, String nuevoNombre) async {
    final db = await _db.database;
    await db.update('especialidades', {'nombre': nuevoNombre.trim()},
        where: 'id = ?', whereArgs: [id]);
  }
}