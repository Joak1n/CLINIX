import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/nota_clinica.dart';
import '../../core/services/supabase_service.dart';

class NotaRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<NotaClinica>> obtenerPorPaciente(String pacienteId) async {
    final db = await _db.database;
    final maps = await db.query(
      'notas_clinicas',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => NotaClinica.fromMap(m)).toList();
  }

  Future<NotaClinica> crear({
    required String pacienteId,
    required Especialidad especialidad,
    String? subjetivo,
    String? objetivo,
    String? evaluacion,
    String? plan,
    required String terapeuta,
  }) async {
    final nota = NotaClinica(
      id: _uuid.v4(),
      pacienteId: pacienteId,
      especialidad: especialidad,
      subjetivo: subjetivo,
      objetivo: objetivo,
      evaluacion: evaluacion,
      plan: plan,
      terapeuta: terapeuta,
      createdAt: DateTime.now().toIso8601String(),
    );

    final db = await _db.database;
    await db.insert('notas_clinicas', nota.toMap());
    _subirNota(nota);
    return nota;
  }

  void _subirNota(NotaClinica n) async {
    try {
      await SupabaseService.client.from('notas_clinicas').upsert({
        'id': n.id,
        'paciente_id': n.pacienteId,
        'especialidad': n.especialidad.valor,
        'subjetivo': n.subjetivo,
        'objetivo': n.objetivo,
        'evaluacion': n.evaluacion,
        'plan': n.plan,
        'terapeuta': n.terapeuta,
      });
    } catch (_) {}
  }
}

