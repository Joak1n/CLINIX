class Ejercicio {
  final String id;
  final String name;
  final String category;
  final String mainMuscle;
  final List<String> secondaryMuscles;
  final String level;
  final String impact;
  final String objective;

  Ejercicio({
    required this.id,
    required this.name,
    required this.category,
    required this.mainMuscle,
    required this.secondaryMuscles,
    required this.level,
    required this.impact,
    required this.objective,
  });

  factory Ejercicio.fromJson(Map<String, dynamic> j) {
    return Ejercicio(
      id: j['id'],
      name: j['name'],
      category: j['category'],
      mainMuscle: j['mainMuscle'],
      secondaryMuscles:
          List<String>.from(j['secondaryMuscles'] ?? []),
      level: j['level'],
      impact: j['impact'],
      objective: j['objective'],
    );
  }
}

class EjercicioEnRutina {
  final Ejercicio ejercicio;
  // Series y reps O tiempo
  int? series;
  int? repeticiones;
  int? tiempoSegundos;
  int? descansoSegundos;
  String? notas;

  EjercicioEnRutina({
    required this.ejercicio,
    this.series,
    this.repeticiones,
    this.tiempoSegundos,
    this.descansoSegundos,
    this.notas,
  });

  String get resumen {
    if (tiempoSegundos != null) {
      final min = tiempoSegundos! ~/ 60;
      final seg = tiempoSegundos! % 60;
      final tiempoStr = min > 0
          ? '${min}min ${seg > 0 ? '${seg}seg' : ''}'
          : '${seg}seg';
      return series != null
          ? '${series}x $tiempoStr'
          : tiempoStr;
    }
    if (series != null && repeticiones != null) {
      return '${series}x$repeticiones reps';
    }
    return '—';
  }
}

