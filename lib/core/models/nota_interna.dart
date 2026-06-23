class NotaInterna {
  final String id;
  final String pacienteId;
  final String? notaClinicaId;
  final String contenido;
  final String autor;
  final String createdAt;

  NotaInterna({
    required this.id,
    required this.pacienteId,
    this.notaClinicaId,
    required this.contenido,
    required this.autor,
    required this.createdAt,
  });

  factory NotaInterna.fromMap(Map<String, dynamic> m) {
    return NotaInterna(
      id: m['id'],
      pacienteId: m['paciente_id'],
      notaClinicaId: m['nota_clinica_id'],
      contenido: m['contenido'],
      autor: m['autor'],
      createdAt: m['created_at'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'paciente_id': pacienteId,
        'nota_clinica_id': notaClinicaId,
        'contenido': contenido,
        'autor': autor,
        'created_at': createdAt,
      };

  String get fechaFormateada {
    final dt = DateTime.parse(createdAt).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

