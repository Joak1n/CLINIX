import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/paciente.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/auditoria_service.dart';

class PacienteRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Paciente>> obtenerTodos({String orderBy = 'apellido_paterno ASC'}) async {
    final db = await _db.database;
    final maps = await db.query(
      'pacientes',
      orderBy: orderBy,
    );
    return maps.map((m) => Paciente.fromMap(m)).toList();
  }

  Future<void> guardar(Paciente paciente) async {
  final db = await _db.database;
  await db.insert('pacientes', paciente.toMap());

  // Subir a Supabase en background
  _subirPaciente(paciente);
}

void _subirPaciente(Paciente p) async {
  try {
    await SupabaseService.client.from('pacientes').upsert({
      'id': p.id,
      'nombre': p.nombre,
      'apellido_paterno': p.apellidoPaterno,
      'apellido_materno': p.apellidoMaterno,
      'fecha_nacimiento': p.fechaNacimiento,
      'sexo': p.sexo,
      'curp': p.curp,
      'telefono': p.telefono,
      'email': p.email,
      'alergias': p.alergias,
    });
  } catch (_) {
    // Falla silenciosamente, se sincronizará después
  }
}
  Future<Paciente> crear({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String fechaNacimiento,
    required String sexo,
    String? curp,
    String? telefono,
    String? email,
    String? alergias,
  }) async {
    final ahora = DateTime.now().toIso8601String();
    final paciente = Paciente(
      id: _uuid.v4(),
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
      fechaNacimiento: fechaNacimiento,
      sexo: sexo,
      curp: curp,
      telefono: telefono,
      email: email,
      alergias: alergias,
      createdAt: ahora,
      updatedAt: ahora,
    );
    await guardar(paciente);
    AuditoriaService.registrar(
      accion: 'crear',
      entidad: 'paciente',
      entidadId: paciente.id,
      detalle: paciente.nombreCompleto,
    );
    return paciente;
  }

    Future<Paciente?> obtenerPorId(String id) async {
    final db = await _db.database;
    final maps = await db.query(
      'pacientes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Paciente.fromMap(maps.first);
  }

  Future<void> actualizar(Paciente paciente) async {
    final db = await _db.database;
    final ahora = DateTime.now().toIso8601String();
    await db.update(
      'pacientes',
      {...paciente.toMap(), 'updated_at': ahora},
      where: 'id = ?',
      whereArgs: [paciente.id],
    );
    _subirPaciente(paciente);
    AuditoriaService.registrar(
      accion: 'actualizar',
      entidad: 'paciente',
      entidadId: paciente.id,
      detalle: paciente.nombreCompleto,
    );
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete('notas_clinicas',
        where: 'paciente_id = ?', whereArgs: [id]);
    await db.delete('citas',
        where: 'paciente_id = ?', whereArgs: [id]);
    await db.delete('pacientes',
        where: 'id = ?', whereArgs: [id]);

    // Eliminar en Supabase
    try {
      await SupabaseService.client
          .from('pacientes')
          .delete()
          .eq('id', id);
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'eliminar',
      entidad: 'paciente',
      entidadId: id,
    );
  }
  Future<List<Paciente>> buscar(String query) async {
    final db = await _db.database;
    final q = '%${query.trim()}%';
    final maps = await db.query(
      'pacientes',
      where: '''
        nombre LIKE ? OR
        apellido_paterno LIKE ? OR
        apellido_materno LIKE ? OR
        curp LIKE ? OR
        telefono LIKE ?
      ''',
      whereArgs: [q, q, q, q, q],
      orderBy: 'apellido_paterno ASC',
    );
    return maps.map((m) => Paciente.fromMap(m)).toList();
  }
}

