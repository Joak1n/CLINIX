import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/signos_vitales.dart';
import '../../core/services/supabase_service.dart';

class SignosVitalesRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<SignosVitales>> obtenerPorPaciente(String pacienteId) async {
    final db = await _db.database;
    final maps = await db.query(
      'signos_vitales',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SignosVitales.fromMap(m)).toList();
  }

  Future<SignosVitales> crear(SignosVitales signos) async {
    final db = await _db.database;
    await db.insert('signos_vitales', signos.toMap());
    _subirSignos(signos);
    return signos;
  }

  void _subirSignos(SignosVitales s) async {
    try {
      await SupabaseService.client.from('signos_vitales').upsert({
        'id': s.id,
        'paciente_id': s.pacienteId,
        'fecha': s.fecha,
        'tension_sistolica': s.tensionSistolica,
        'tension_diastolica': s.tensionDiastolica,
        'frecuencia_cardiaca': s.frecuenciaCardiaca,
        'frecuencia_respiratoria': s.frecuenciaRespiratoria,
        'temperatura': s.temperatura,
        'peso': s.peso,
        'talla': s.talla,
        'imc': s.imc,
        'saturacion_oxigeno': s.saturacionOxigeno,
        'glucosa': s.glucosa,
        'notas': s.notas,
      });
    } catch (_) {}
  }

  SignosVitales nuevo({
    required String pacienteId,
    int? tensionSistolica,
    int? tensionDiastolica,
    int? frecuenciaCardiaca,
    int? frecuenciaRespiratoria,
    double? temperatura,
    double? peso,
    double? talla,
    int? saturacionOxigeno,
    int? glucosa,
    String? notas,
  }) {
    final ahora = DateTime.now();
    double? imc;
    if (peso != null && talla != null && talla > 0) {
      final tallaM = talla / 100;
      imc = double.parse((peso / (tallaM * tallaM)).toStringAsFixed(1));
    }
    return SignosVitales(
      id: _uuid.v4(),
      pacienteId: pacienteId,
      fecha: ahora.toIso8601String().substring(0, 10),
      tensionSistolica: tensionSistolica,
      tensionDiastolica: tensionDiastolica,
      frecuenciaCardiaca: frecuenciaCardiaca,
      frecuenciaRespiratoria: frecuenciaRespiratoria,
      temperatura: temperatura,
      peso: peso,
      talla: talla,
      imc: imc,
      saturacionOxigeno: saturacionOxigeno,
      glucosa: glucosa,
      notas: notas,
      createdAt: ahora.toIso8601String(),
    );
  }
}

