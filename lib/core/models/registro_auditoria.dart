class RegistroAuditoria {
  final String id;
  final String fecha; // ISO 8601
  final String? usuarioId;
  final String usuarioNombre;
  final String accion; // crear | actualizar | eliminar | cambiar_estado | login
  final String entidad; // cita | paciente | usuario
  final String? entidadId;
  final String? detalle;

  const RegistroAuditoria({
    required this.id,
    required this.fecha,
    this.usuarioId,
    required this.usuarioNombre,
    required this.accion,
    required this.entidad,
    this.entidadId,
    this.detalle,
  });

  String get iconoAccion {
    switch (accion) {
      case 'crear':
        return '➕';
      case 'actualizar':
        return '✏️';
      case 'eliminar':
        return '🗑️';
      case 'cambiar_estado':
        return '🔄';
      default:
        return '•';
    }
  }

  String get etiquetaAccion {
    switch (accion) {
      case 'crear':
        return 'Creó';
      case 'actualizar':
        return 'Modificó';
      case 'eliminar':
        return 'Eliminó';
      case 'cambiar_estado':
        return 'Cambió estado de';
      default:
        return accion;
    }
  }

  String get etiquetaEntidad {
    switch (entidad) {
      case 'cita':
        return 'una cita';
      case 'paciente':
        return 'un paciente';
      case 'usuario':
        return 'un usuario';
      default:
        return entidad;
    }
  }

  factory RegistroAuditoria.fromMap(Map<String, dynamic> m) => RegistroAuditoria(
        id: m['id'],
        fecha: m['fecha'],
        usuarioId: m['usuario_id'],
        usuarioNombre: m['usuario_nombre'] ?? 'Desconocido',
        accion: m['accion'],
        entidad: m['entidad'],
        entidadId: m['entidad_id'],
        detalle: m['detalle'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha,
        'usuario_id': usuarioId,
        'usuario_nombre': usuarioNombre,
        'accion': accion,
        'entidad': entidad,
        'entidad_id': entidadId,
        'detalle': detalle,
      };
}
