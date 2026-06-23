import '../database/database_helper.dart';

class EstadisticasService {
  static final _db = DatabaseHelper.instance;

  static Future<Map<String, dynamic>> obtenerResumen({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    final db = await _db.database;
    final inicioStr =
        inicio.toIso8601String().substring(0, 10);
    final finStr =
        fin.toIso8601String().substring(0, 10);

    final totalPacientes = (await db.rawQuery(
            'SELECT COUNT(*) as count FROM pacientes'))
        .first['count'] as int;

    final pacientesNuevos = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM pacientes "
      "WHERE DATE(created_at) BETWEEN ? AND ?",
      [inicioStr, finStr],
    )).first['count'] as int;

    final totalCitas = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ?",
      [inicioStr, finStr],
    )).first['count'] as int;

    final citasCompletadas = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ? AND estado = ?",
      [inicioStr, finStr, 'completada'],
    )).first['count'] as int;

    final citasCanceladas = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ? AND estado = ?",
      [inicioStr, finStr, 'cancelada'],
    )).first['count'] as int;

    final citasNoShow = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ? AND estado = ?",
      [inicioStr, finStr, 'no_show'],
    )).first['count'] as int;

    final tasaAsistencia = totalCitas > 0
        ? (citasCompletadas / totalCitas * 100).round()
        : 0;

    final porEspecialidad = await db.rawQuery(
      "SELECT especialidad, COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ? "
      "GROUP BY especialidad ORDER BY count DESC",
      [inicioStr, finStr],
    );

    final porTerapeuta = await db.rawQuery(
      "SELECT terapeuta, COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ? "
      "GROUP BY terapeuta ORDER BY count DESC LIMIT 5",
      [inicioStr, finStr],
    );

    final porDiaSemana = await db.rawQuery(
      "SELECT strftime('%w', fecha) as dia, "
      "COUNT(*) as count FROM citas "
      "WHERE fecha BETWEEN ? AND ? "
      "GROUP BY dia ORDER BY dia",
      [inicioStr, finStr],
    );

    final totalNotas = (await db.rawQuery(
      "SELECT COUNT(*) as count FROM notas_clinicas "
      "WHERE DATE(created_at) BETWEEN ? AND ?",
      [inicioStr, finStr],
    )).first['count'] as int;

    final porSemana =
        await _citasPorSemana(db, inicio, fin);

    return {
      'totalPacientes': totalPacientes,
      'pacientesNuevos': pacientesNuevos,
      'totalCitas': totalCitas,
      'citasCompletadas': citasCompletadas,
      'citasCanceladas': citasCanceladas,
      'citasNoShow': citasNoShow,
      'tasaAsistencia': tasaAsistencia,
      'porEspecialidad': porEspecialidad,
      'porTerapeuta': porTerapeuta,
      'porDiaSemana': porDiaSemana,
      'totalNotas': totalNotas,
      'porSemana': porSemana,
    };
  }

  static Future<List<Map<String, dynamic>>> _citasPorSemana(
    dynamic db,
    DateTime inicio,
    DateTime fin,
  ) async {
    final semanas = <Map<String, dynamic>>[];
    var semanaInicio = inicio;

    while (semanaInicio.isBefore(fin)) {
      final semanaFin =
          semanaInicio.add(const Duration(days: 6));
      final finReal =
          semanaFin.isAfter(fin) ? fin : semanaFin;

      final inicioStr =
          semanaInicio.toIso8601String().substring(0, 10);
      final finStr =
          finReal.toIso8601String().substring(0, 10);

      final count = (await db.rawQuery(
        "SELECT COUNT(*) as count FROM citas "
        "WHERE fecha BETWEEN ? AND ?",
        [inicioStr, finStr],
      )).first['count'] as int;

      semanas.add({
        'label':
            '${semanaInicio.day}/${semanaInicio.month}',
        'count': count,
      });

      semanaInicio =
          semanaInicio.add(const Duration(days: 7));
    }

    return semanas;
  }
}

