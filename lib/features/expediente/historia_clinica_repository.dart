import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/historia_clinica.dart';
import '../../core/services/supabase_service.dart';

class HistoriaClinicaRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<HistoriaClinica?> obtenerPorPaciente(String pacienteId) async {
    final db = await _db.database;
    final maps = await db.query(
      'historia_clinica',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HistoriaClinica.fromMap(maps.first);
  }

  Future<HistoriaClinica> guardar(HistoriaClinica historia) async {
    final db = await _db.database;
    final existente = await obtenerPorPaciente(historia.pacienteId);
    if (existente == null) {
      await db.insert('historia_clinica', historia.toMap());
    } else {
      await db.update(
        'historia_clinica',
        historia.toMap(),
        where: 'paciente_id = ?',
        whereArgs: [historia.pacienteId],
      );
    }
    _subirHistoria(historia);
    return historia;
  }

  void _subirHistoria(HistoriaClinica h) async {
    try {
      await SupabaseService.client.from('historia_clinica').upsert({
        'id': h.id,
        'paciente_id': h.pacienteId,
        'hf_diabetes': h.hfDiabetes,
        'hf_hipertension': h.hfHipertension,
        'hf_cancer': h.hfCancer,
        'hf_cardiopatia': h.hfCardiopatia,
        'hf_obesidad': h.hfObesidad,
        'hf_otros': h.hfOtros,
        'ap_diabetes': h.apDiabetes,
        'ap_hipertension': h.apHipertension,
        'ap_cardiopatia': h.apCardiopatia,
        'ap_asma': h.apAsma,
        'ap_cancer': h.apCancer,
        'ap_fracturas': h.apFracturas,
        'ap_transfusiones': h.apTransfusiones,
        'ap_cirugias': h.apCirugias,
        'ap_traumatismos': h.apTraumatismos,
        'ap_hospitalizaciones': h.apHospitalizaciones,
        'ap_otros': h.apOtros,
        'anp_tabaquismo': h.anpTabaquismo,
        'anp_alcoholismo': h.anpAlcoholismo,
        'anp_drogas': h.anpDrogas,
        'anp_actividad_fisica': h.anpActividadFisica,
        'anp_ocupacion': h.anpOcupacion,
        'go_menarca': h.goMenarca,
        'go_fur': h.goFur,
        'go_gestas': h.goGestas,
        'go_partos': h.goPartos,
        'go_cesareas': h.goCesareas,
        'go_abortos': h.goAbortos,
        'go_anticonceptivos': h.goAnticonceptivos,
        'padecimiento_actual': h.padecimientoActual,
        'medicamentos_actuales': h.medicamentosActuales,
        'escala_eva': h.escalaEva,
        'escala_daniels': h.escalaDaniels,
        'escala_glasgow': h.escalaGlasgow,
        'escala_norton': h.escalaNorton,
      });
    } catch (_) {}
  }

  HistoriaClinica nueva(String pacienteId) {
    final ahora = DateTime.now().toIso8601String();
    return HistoriaClinica(
      id: _uuid.v4(),
      pacienteId: pacienteId,
      createdAt: ahora,
      updatedAt: ahora,
    );
  }
}

