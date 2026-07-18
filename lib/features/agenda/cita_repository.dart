import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/cita.dart';
import '../../core/models/nota_clinica.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/auditoria_service.dart';

class CitaRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<Cita>> obtenerPorFecha(String fecha) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT c.*, 
             CASE 
               WHEN c.paciente_id IS NOT NULL 
               THEN p.nombre || ' ' || p.apellido_paterno 
               ELSE c.nombre_temporal 
             END AS nombre_paciente
      FROM citas c
      LEFT JOIN pacientes p ON c.paciente_id = p.id
      WHERE c.fecha = ?
      ORDER BY c.hora ASC
    ''', [fecha]);
    return maps.map((m) => Cita.fromMap(m)).toList();
  }

  Future<List<Cita>> obtenerPorPaciente(String pacienteId) async {
    final db = await _db.database;
    final maps = await db.query(
      'citas',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'fecha DESC, hora DESC',
    );
    return maps.map((m) => Cita.fromMap(m)).toList();
  }

  Future<Cita> crear({
    String? pacienteId,
    String? nombreTemporal,
    String? telefonoTemporal,
    required Especialidad especialidad,
    required String fecha,
    required String hora,
    required int duracionMinutos,
    required String terapeuta,
    String? notas,
  }) async {
    final cita = Cita(
      id: _uuid.v4(),
      pacienteId: pacienteId,
      nombreTemporal: nombreTemporal,
      telefonoTemporal: telefonoTemporal,
      especialidad: especialidad,
      fecha: fecha,
      hora: hora,
      duracionMinutos: duracionMinutos,
      terapeuta: terapeuta,
      estado: EstadoCita.confirmada,
      notas: notas,
      createdAt: DateTime.now().toIso8601String(),
    );
    final db = await _db.database;
    await db.insert('citas', cita.toMap());
    _subirCita(cita);
    AuditoriaService.registrar(
      accion: 'crear',
      entidad: 'cita',
      entidadId: cita.id,
      detalle:
          'Cita ${cita.fecha} ${cita.hora} · ${cita.especialidad.valor} · ${cita.terapeuta}',
    );
    return cita;
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete('citas', where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('citas')
          .delete()
          .eq('id', id);
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'eliminar',
      entidad: 'cita',
      entidadId: id,
    );
  }

  Future<void> actualizarEstado(String id, EstadoCita estado) async {
    final db = await _db.database;
    await db.update(
      'citas',
      {'estado': estado.valor},
      where: 'id = ?',
      whereArgs: [id],
    );
    try {
      await SupabaseService.client
          .from('citas')
          .update({'estado': estado.valor}).eq('id', id);
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'cambiar_estado',
      entidad: 'cita',
      entidadId: id,
      detalle: 'Nuevo estado: ${estado.etiqueta}',
    );
  }
  Future<void> actualizar(Cita cita) async {
    final db = await _db.database;
    await db.update(
      'citas',
      cita.toMap(),
      where: 'id = ?',
      whereArgs: [cita.id],
    );
    _subirCita(cita);
    AuditoriaService.registrar(
      accion: 'actualizar',
      entidad: 'cita',
      entidadId: cita.id,
      detalle:
          'Cita ${cita.fecha} ${cita.hora} · ${cita.especialidad.valor} · ${cita.terapeuta} · ${cita.estado.etiqueta}',
    );
  }
  void _subirCita(Cita c) async {
  try {
    await SupabaseService.client.from('citas').upsert({
      'id': c.id,
      'paciente_id': c.pacienteId,
      'especialidad': c.especialidad.valor,
      'fecha': c.fecha,
      'hora': c.hora,
      'duracion_minutos': c.duracionMinutos,
      'terapeuta': c.terapeuta,
      'estado': c.estado.valor,
      'notas': c.notas,
    });
  } catch (_) {}
}
}