enum RolUsuario { admin, terapeuta, recepcionista }

extension RolUsuarioExt on RolUsuario {
  String get valor {
    switch (this) {
      case RolUsuario.admin:         return 'admin';
      case RolUsuario.terapeuta:     return 'terapeuta';
      case RolUsuario.recepcionista: return 'recepcionista';
    }
  }

  String get etiqueta {
    switch (this) {
      case RolUsuario.admin:         return 'Administrador';
      case RolUsuario.terapeuta:     return 'Terapeuta';
      case RolUsuario.recepcionista: return 'Recepcionista';
    }
  }

  static RolUsuario fromValor(String v) {
    return RolUsuario.values.firstWhere(
      (r) => r.valor == v,
      orElse: () => RolUsuario.recepcionista,
    );
  }

  // Permisos por rol
  bool get puedeVerExpedientes =>
      this == RolUsuario.admin || this == RolUsuario.terapeuta;

  bool get puedeEditarPacientes =>
      this == RolUsuario.admin || this == RolUsuario.terapeuta;

  bool get puedeEliminarPacientes => this == RolUsuario.admin;

  bool get puedeGestionarUsuarios => this == RolUsuario.admin;

  bool get puedeVerAgenda => true;

  bool get puedeCrearCitas => true;
}

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String passwordHash;
  final RolUsuario rol;
  final bool activo;
  final String createdAt;
  final String updatedAt;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.passwordHash,
    required this.rol,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Usuario.fromMap(Map<String, dynamic> m) {
    return Usuario(
      id: m['id'],
      nombre: m['nombre'],
      email: m['email'],
      passwordHash: m['password_hash'],
      rol: RolUsuarioExt.fromValor(m['rol']),
      activo: m['activo'] == 1,
      createdAt: m['created_at'],
      updatedAt: m['updated_at'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'email': email,
        'password_hash': passwordHash,
        'rol': rol.valor,
        'activo': activo ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

