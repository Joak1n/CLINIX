class ConsentimientoInformado {
  final String id;
  final String pacienteId;
  final String fechaFirma; // ISO 8601
  final int version;
  final String firmaBase64; // PNG de la firma, codificado en base64
  final String createdAt;

  const ConsentimientoInformado({
    required this.id,
    required this.pacienteId,
    required this.fechaFirma,
    required this.version,
    required this.firmaBase64,
    required this.createdAt,
  });

  factory ConsentimientoInformado.fromMap(Map<String, dynamic> m) =>
      ConsentimientoInformado(
        id: m['id'],
        pacienteId: m['paciente_id'],
        fechaFirma: m['fecha_firma'],
        version: m['version'] ?? 1,
        firmaBase64: m['firma_base64'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'paciente_id': pacienteId,
        'fecha_firma': fechaFirma,
        'version': version,
        'firma_base64': firmaBase64,
        'created_at': createdAt,
      };
}
