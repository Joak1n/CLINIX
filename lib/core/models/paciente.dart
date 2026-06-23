class Paciente {
  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String? apellidoMaterno;
  final String fechaNacimiento;
  final String sexo;
  final String? curp;
  final String? telefono;
  final String? email;
  final String? alergias;
  final String createdAt;
  final String updatedAt;
  final bool esMenor;
  final String? responsableNombre;
  final String? responsableParentesco;
  final String? responsableTelefono;
  final String? responsableCurp;
  final bool consentimientoTutor;

  Paciente({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    this.apellidoMaterno,
    required this.fechaNacimiento,
    required this.sexo,
    this.curp,
    this.telefono,
    this.email,
    this.alergias,
    required this.createdAt,
    required this.updatedAt,
    this.esMenor = false,
    this.responsableNombre,
    this.responsableParentesco,
    this.responsableTelefono,
    this.responsableCurp,
    this.consentimientoTutor = false,
  });

  // Convierte un Map (de SQLite) a Paciente
  factory Paciente.fromMap(Map<String, dynamic> map) {
    return Paciente(
      id: map['id'],
      nombre: map['nombre'],
      apellidoPaterno: map['apellido_paterno'],
      apellidoMaterno: map['apellido_materno'],
      fechaNacimiento: map['fecha_nacimiento'],
      sexo: map['sexo'],
      curp: map['curp'],
      telefono: map['telefono'],
      email: map['email'],
      alergias: map['alergias'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      esMenor: map['es_menor'] == 1,
      responsableNombre: map['responsable_nombre'],
      responsableParentesco: map['responsable_parentesco'],
      responsableTelefono: map['responsable_telefono'],
      responsableCurp: map['responsable_curp'],
      consentimientoTutor: map['consentimiento_tutor'] == 1,
    );
  }

  // Convierte un Paciente a Map (para guardar en SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido_paterno': apellidoPaterno,
      'apellido_materno': apellidoMaterno,
      'fecha_nacimiento': fechaNacimiento,
      'sexo': sexo,
      'curp': curp,
      'telefono': telefono,
      'email': email,
      'alergias': alergias,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'es_menor': esMenor ? 1 : 0,
      'responsable_nombre': responsableNombre,
      'responsable_parentesco': responsableParentesco,
      'responsable_telefono': responsableTelefono,
      'responsable_curp': responsableCurp,
      'consentimiento_tutor': consentimientoTutor ? 1 : 0,
    };
  }

  bool get esMenorDeEdad {    //getter para saber si es menor automáticamente por fecha de nacimiento
    try {
      final fn = DateTime.parse(fechaNacimiento);
      final hoy = DateTime.now();
      int edad = hoy.year - fn.year;
      if (hoy.month < fn.month ||
          (hoy.month == fn.month && hoy.day < fn.day)) edad--;
      return edad < 18;
    } catch (_) {
      return false;
    }
  }

  // Nombre completo para mostrar en listas
  String get nombreCompleto =>
      '$nombre $apellidoPaterno${apellidoMaterno != null ? ' $apellidoMaterno' : ''}';
}