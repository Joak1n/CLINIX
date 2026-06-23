enum Especialidad {
  fisioterapia,
  quiropractica,
  spa,
  asesoriaDeportiva,
}

extension EspecialidadExt on Especialidad {
  String get nombre {
    switch (this) {
      case Especialidad.fisioterapia:
        return 'Fisioterapia';
      case Especialidad.quiropractica:
        return 'Quiropráctica';
      case Especialidad.spa:
        return 'Spa';
      case Especialidad.asesoriaDeportiva:
        return 'Asesoría deportiva';
    }
  }

  String get valor {
    switch (this) {
      case Especialidad.fisioterapia:
        return 'fisioterapia';
      case Especialidad.quiropractica:
        return 'quiropractica';
      case Especialidad.spa:
        return 'spa';
      case Especialidad.asesoriaDeportiva:
        return 'asesoria_deportiva';
    }
  }

  static Especialidad fromValor(String valor) {
    return Especialidad.values.firstWhere(
      (e) => e.valor == valor,
      orElse: () => Especialidad.fisioterapia,
    );
  }
}

class NotaClinica {
  final String id;
  final String pacienteId;
  final Especialidad especialidad;
  final String? subjetivo;
  final String? objetivo;
  final String? evaluacion;
  final String? plan;
  final String terapeuta;
  final String createdAt;

  NotaClinica({
    required this.id,
    required this.pacienteId,
    required this.especialidad,
    this.subjetivo,
    this.objetivo,
    this.evaluacion,
    this.plan,
    required this.terapeuta,
    required this.createdAt,
  });

  factory NotaClinica.fromMap(Map<String, dynamic> map) {
    return NotaClinica(
      id: map['id'],
      pacienteId: map['paciente_id'],
      especialidad: EspecialidadExt.fromValor(map['especialidad']),
      subjetivo: map['subjetivo'],
      objetivo: map['objetivo'],
      evaluacion: map['evaluacion'],
      plan: map['plan'],
      terapeuta: map['terapeuta'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'especialidad': especialidad.valor,
      'subjetivo': subjetivo,
      'objetivo': objetivo,
      'evaluacion': evaluacion,
      'plan': plan,
      'terapeuta': terapeuta,
      'created_at': createdAt,
    };
  }

  // Fecha formateada para mostrar en UI
    String get fechaFormateada {
    final dt = DateTime.parse(createdAt).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

