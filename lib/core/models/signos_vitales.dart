class SignosVitales {
  final String id;
  final String pacienteId;
  final String fecha;
  final int? tensionSistolica;
  final int? tensionDiastolica;
  final int? frecuenciaCardiaca;
  final int? frecuenciaRespiratoria;
  final double? temperatura;
  final double? peso;
  final double? talla;
  final double? imc;
  final int? saturacionOxigeno;
  final int? glucosa;
  final String? notas;
  final String createdAt;

  SignosVitales({
    required this.id,
    required this.pacienteId,
    required this.fecha,
    this.tensionSistolica,
    this.tensionDiastolica,
    this.frecuenciaCardiaca,
    this.frecuenciaRespiratoria,
    this.temperatura,
    this.peso,
    this.talla,
    this.imc,
    this.saturacionOxigeno,
    this.glucosa,
    this.notas,
    required this.createdAt,
  });

  factory SignosVitales.fromMap(Map<String, dynamic> m) {
    return SignosVitales(
      id: m['id'],
      pacienteId: m['paciente_id'],
      fecha: m['fecha'],
      tensionSistolica: m['tension_sistolica'],
      tensionDiastolica: m['tension_diastolica'],
      frecuenciaCardiaca: m['frecuencia_cardiaca'],
      frecuenciaRespiratoria: m['frecuencia_respiratoria'],
      temperatura: m['temperatura'],
      peso: m['peso'],
      talla: m['talla'],
      imc: m['imc'],
      saturacionOxigeno: m['saturacion_oxigeno'],
      glucosa: m['glucosa'],
      notas: m['notas'],
      createdAt: m['created_at'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'paciente_id': pacienteId,
        'fecha': fecha,
        'tension_sistolica': tensionSistolica,
        'tension_diastolica': tensionDiastolica,
        'frecuencia_cardiaca': frecuenciaCardiaca,
        'frecuencia_respiratoria': frecuenciaRespiratoria,
        'temperatura': temperatura,
        'peso': peso,
        'talla': talla,
        'imc': imc,
        'saturacion_oxigeno': saturacionOxigeno,
        'glucosa': glucosa,
        'notas': notas,
        'created_at': createdAt,
      };

  // Texto resumen para mostrar en listas
  String get tensionArterial =>
      (tensionSistolica != null && tensionDiastolica != null)
          ? '$tensionSistolica/$tensionDiastolica mmHg'
          : '—';

  String get fechaFormateada {
    final dt = DateTime.parse(createdAt).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

