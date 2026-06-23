class Adjunto {
  final String id;
  final String pacienteId;
  final String nombre;
  final String tipo;
  final int? tamano;
  final String? rutaLocal;
  final String? url;
  final String? storagePath;
  final String? descripcion;
  final String createdAt;

  Adjunto({
    required this.id,
    required this.pacienteId,
    required this.nombre,
    required this.tipo,
    this.tamano,
    this.rutaLocal,
    this.url,
    this.storagePath,
    this.descripcion,
    required this.createdAt,
  });

  factory Adjunto.fromMap(Map<String, dynamic> m) {
    return Adjunto(
      id: m['id'],
      pacienteId: m['paciente_id'],
      nombre: m['nombre'],
      tipo: m['tipo'],
      tamano: m['tamano'],
      rutaLocal: m['ruta_local'],
      url: m['url'],
      storagePath: m['storage_path'],
      descripcion: m['descripcion'],
      createdAt: m['created_at'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'paciente_id': pacienteId,
        'nombre': nombre,
        'tipo': tipo,
        'tamano': tamano,
        'ruta_local': rutaLocal,
        'url': url,
        'storage_path': storagePath,
        'descripcion': descripcion,
        'created_at': createdAt,
      };

  bool get esImagen =>
      tipo.startsWith('image/') ||
      nombre.toLowerCase().endsWith('.jpg') ||
      nombre.toLowerCase().endsWith('.jpeg') ||
      nombre.toLowerCase().endsWith('.png');

  bool get esPdf =>
      tipo == 'application/pdf' ||
      nombre.toLowerCase().endsWith('.pdf');

  String get tamanoFormateado {
    if (tamano == null) return '';
    if (tamano! < 1024) return '${tamano}B';
    if (tamano! < 1024 * 1024) {
      return '${(tamano! / 1024).toStringAsFixed(1)}KB';
    }
    return '${(tamano! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fechaFormateada {
    final dt = DateTime.parse(createdAt).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

