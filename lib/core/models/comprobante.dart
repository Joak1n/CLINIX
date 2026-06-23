class Comprobante {
  final String pacienteNombre;
  final String pacienteFechaNacimiento;
  final String? pacienteTelefono;
  final String fecha;
  final String hora;
  final String especialidad;
  final String terapeuta;
  final String? motivoConsulta;
  final String? diagnostico;
  final String? indicaciones;
  final String? proximaCita;
  final String? observaciones;

  Comprobante({
    required this.pacienteNombre,
    required this.pacienteFechaNacimiento,
    this.pacienteTelefono,
    required this.fecha,
    required this.hora,
    required this.especialidad,
    required this.terapeuta,
    this.motivoConsulta,
    this.diagnostico,
    this.indicaciones,
    this.proximaCita,
    this.observaciones,
  });
}

