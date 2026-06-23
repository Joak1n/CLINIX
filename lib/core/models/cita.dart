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
  final String? pacienteId;       // null si es paciente temporal
  final String? nombreTemporal;   // nombre cuando no está registrado
  final String? telefonoTemporal; // teléfono cuando no está registrado
  final Especialidad especialidad;
  final String fecha;
  final String hora;
  final int duracionMinutos;
  final String terapeuta;
  final EstadoCita estado;
  final String? notas;
  final String createdAt;

  // Campo calculado para mostrar nombre en listas
  final String? nombrePaciente;

  bool get esPacienteTemporal => pacienteId == null;

  String get nombreMostrado =>
      nombrePaciente ?? nombreTemporal ?? 'Paciente sin nombre';

  Cita({
    required this.id,
    this.pacienteId,
    this.nombreTemporal,
    this.telefonoTemporal,
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
      nombreTemporal: map['nombre_temporal'],
      telefonoTemporal: map['telefono_temporal'],
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
      'nombre_temporal': nombreTemporal,
      'telefono_temporal': telefonoTemporal,
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
    String? nombreTemporal,
    String? telefonoTemporal,
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
      nombreTemporal: nombreTemporal ?? this.nombreTemporal,
      telefonoTemporal: telefonoTemporal ?? this.telefonoTemporal,
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