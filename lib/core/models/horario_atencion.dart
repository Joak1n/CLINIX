class HorarioAtencion {
  final int diaSemana; // 1=Lunes … 7=Domingo
  final bool activo;
  final String horaInicio;
  final String horaFin;

  const HorarioAtencion({
    required this.diaSemana,
    required this.activo,
    required this.horaInicio,
    required this.horaFin,
  });

  String get nombreDia {
    const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[diaSemana];
  }

  String get nombreDiaCorto {
    const dias = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[diaSemana];
  }

  List<String> slots(int duracionMinutos) {
    if (!activo) return [];
    final result = <String>[];
    var actual = _toMin(horaInicio);
    final fin = _toMin(horaFin);
    while (actual + duracionMinutos <= fin) {
      result.add(_fromMin(actual));
      actual += duracionMinutos;
    }
    return result;
  }

  static int _toMin(String h) {
    final p = h.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static String _fromMin(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  factory HorarioAtencion.fromMap(Map<String, dynamic> m) => HorarioAtencion(
        diaSemana: m['dia_semana'],
        activo: (m['activo'] as int) == 1,
        horaInicio: m['hora_inicio'],
        horaFin: m['hora_fin'],
      );

  Map<String, dynamic> toMap() => {
        'dia_semana': diaSemana,
        'activo': activo ? 1 : 0,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
      };

  HorarioAtencion copyWith({bool? activo, String? horaInicio, String? horaFin}) =>
      HorarioAtencion(
        diaSemana: diaSemana,
        activo: activo ?? this.activo,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
      );
}

class BloqueoHorario {
  final String id;
  final String fechaInicio;
  final String fechaFin;
  final String? horaInicio;
  final String? horaFin;
  final bool esDiaCompleto;
  final String? motivo;
  final String createdAt;

  const BloqueoHorario({
    required this.id,
    required this.fechaInicio,
    required this.fechaFin,
    this.horaInicio,
    this.horaFin,
    required this.esDiaCompleto,
    this.motivo,
    required this.createdAt,
  });

  bool abarcaFecha(String fecha) =>
      fecha.compareTo(fechaInicio) >= 0 && fecha.compareTo(fechaFin) <= 0;

  bool bloqueaSlot(String fecha, String slot) {
    if (!abarcaFecha(fecha)) return false;
    if (esDiaCompleto || horaInicio == null || horaFin == null) return true;
    return slot.compareTo(horaInicio!) >= 0 && slot.compareTo(horaFin!) < 0;
  }

  String get rangoFechaTexto {
    if (fechaInicio == fechaFin) return _fmt(fechaInicio);
    return '${_fmt(fechaInicio)} – ${_fmt(fechaFin)}';
  }

  String get rangoHoraTexto => esDiaCompleto ? 'Día completo' : '$horaInicio – $horaFin';

  static String _fmt(String iso) {
    final p = iso.split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  factory BloqueoHorario.fromMap(Map<String, dynamic> m) => BloqueoHorario(
        id: m['id'],
        fechaInicio: m['fecha_inicio'],
        fechaFin: m['fecha_fin'],
        horaInicio: m['hora_inicio'],
        horaFin: m['hora_fin'],
        esDiaCompleto: (m['es_dia_completo'] as int) == 1,
        motivo: m['motivo'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'es_dia_completo': esDiaCompleto ? 1 : 0,
        'motivo': motivo,
        'created_at': createdAt,
      };
}