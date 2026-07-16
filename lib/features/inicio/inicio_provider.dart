import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/cita.dart';

class InicioData {
  final List<Cita> citasHoy;
  final int totalMes;
  final int completadasMes;
  final int canceladasMes;
  final int noShowMes;
  final int pacientesNuevosMes;

  const InicioData({
    required this.citasHoy,
    required this.totalMes,
    required this.completadasMes,
    required this.canceladasMes,
    required this.noShowMes,
    required this.pacientesNuevosMes,
  });

  double get tasaAsistencia => totalMes == 0
      ? 0
      : (completadasMes / totalMes * 100);
}

final inicioProvider = FutureProvider<InicioData>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final hoy = DateTime.now();
  final fechaHoy =
      '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  final inicioMes =
      '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-01';

  // Citas de hoy con nombre de paciente
  final citasMaps = await db.rawQuery('''
    SELECT c.*,
      CASE
        WHEN c.paciente_id IS NOT NULL
        THEN p.nombre || ' ' || p.apellido_paterno
        ELSE c.nombre_temporal
      END AS nombre_paciente
    FROM citas c
    LEFT JOIN pacientes p ON c.paciente_id = p.id
    WHERE c.fecha = ?
    ORDER BY c.hora ASC
  ''', [fechaHoy]);

  final citasHoy = citasMaps.map((m) => Cita.fromMap(m)).toList();

  // Stats del mes
  final statsMes = await db.rawQuery('''
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN estado = 'completada' THEN 1 ELSE 0 END) as completadas,
      SUM(CASE WHEN estado = 'cancelada' THEN 1 ELSE 0 END) as canceladas,
      SUM(CASE WHEN estado = 'no_show' THEN 1 ELSE 0 END) as no_show
    FROM citas
    WHERE fecha >= ?
  ''', [inicioMes]);

  final s = statsMes.first;

  // Pacientes nuevos este mes
  final nuevos = await db.rawQuery('''
    SELECT COUNT(*) as count FROM pacientes
    WHERE created_at >= ?
  ''', [inicioMes]);

  return InicioData(
    citasHoy: citasHoy,
    totalMes: (s['total'] as int?) ?? 0,
    completadasMes: (s['completadas'] as int?) ?? 0,
    canceladasMes: (s['canceladas'] as int?) ?? 0,
    noShowMes: (s['no_show'] as int?) ?? 0,
    pacientesNuevosMes:
        (nuevos.first['count'] as int?) ?? 0,
  );
});