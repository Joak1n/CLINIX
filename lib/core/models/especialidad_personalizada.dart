class EspecialidadPersonalizada {
  final String id;
  final String nombre;
  final bool activa;
  final int orden;

  EspecialidadPersonalizada({
    required this.id,
    required this.nombre,
    required this.activa,
    required this.orden,
  });

  factory EspecialidadPersonalizada.fromMap(Map<String, dynamic> m) {
    return EspecialidadPersonalizada(
      id: m['id'],
      nombre: m['nombre'],
      activa: m['activa'] == 1,
      orden: m['orden'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'activa': activa ? 1 : 0,
        'orden': orden,
      };
}