import 'nota_clinica.dart';

enum EstadoCita { confirmada, cancelada, noShow, completada }

extension EstadoCitaExt on EstadoCita {
  String get valor {
    switch (this) {
      case EstadoCita.confirmada:   return 'confirmada';
      case EstadoCita.cancelada:    return 'cancelada';
      case EstadoCita.noShow:       return 'no_show';
      case EstadoCita.completada:   return 'completada';
    }
  }

  String get etiqueta {
    switch (this) {
      case EstadoCita.confirmada:   return 'Confirmada';
      case EstadoCita.cancelada:    return 'Cancelada';
      case EstadoCita.noShow:       return 'No show';
      case EstadoCita.completada:   return 'Completada';
    }
  }

  static EstadoCita fromValor(String v) {
    return EstadoCita.values.firstWhere(
      (e) => e.valor == v,
      orElse: () => EstadoCita.confirmada,
    );
  }
}

class Cita {
  final String id;
  final String pacienteId;
  final Especialidad especialidad;
  final String fecha;       // 'yyyy-MM-dd'
  final String hora;        // 'HH:mm'
  final int duracionMinutos;
  final String terapeuta;
  final EstadoCita estado;
  final String? notas;
  final String createdAt;

  // Campo opcional para mostrar nombre del paciente en listas
  final String? nombrePaciente;

  Cita({
    required this.id,
    required this.pacienteId,
    required this.especialidad,
    required this.fecha,
    required this.hora,
    required this.duracionMinutos,
    required this.terapeuta,
    required this.estado,
    this.notas,
    required this.createdAt,
    this.nombrePaciente,
  });

  factory Cita.fromMap(Map<String, dynamic> map) {
    return Cita(
      id: map['id'],
      pacienteId: map['paciente_id'],
      especialidad: EspecialidadExt.fromValor(map['especialidad']),
      fecha: map['fecha'],
      hora: map['hora'],
      duracionMinutos: map['duracion_minutos'],
      terapeuta: map['terapeuta'],
      estado: EstadoCitaExt.fromValor(map['estado']),
      notas: map['notas'],
      createdAt: map['created_at'],
      nombrePaciente: map['nombre_paciente'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paciente_id': pacienteId,
      'especialidad': especialidad.valor,
      'fecha': fecha,
      'hora': hora,
      'duracion_minutos': duracionMinutos,
      'terapeuta': terapeuta,
      'estado': estado.valor,
      'notas': notas,
      'created_at': createdAt,
    };
  }

  Cita copyWith({
    EstadoCita? estado,
    String? pacienteId,
    Especialidad? especialidad,
    String? fecha,
    String? hora,
    int? duracionMinutos,
    String? terapeuta,
    String? notas,
    String? nombrePaciente,
  }) {
    return Cita(
      id: id,
      pacienteId: pacienteId ?? this.pacienteId,
      especialidad: especialidad ?? this.especialidad,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      duracionMinutos: duracionMinutos ?? this.duracionMinutos,
      terapeuta: terapeuta ?? this.terapeuta,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      createdAt: createdAt,
      nombrePaciente: nombrePaciente ?? this.nombrePaciente,
    );
  }
}

