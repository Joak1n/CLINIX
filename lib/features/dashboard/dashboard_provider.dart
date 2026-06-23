import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/estadisticas_service.dart';

enum PeriodoDashboard { semana, mes, trimestre }

final periodoDashboardProvider =
    StateProvider<PeriodoDashboard>(
        (ref) => PeriodoDashboard.mes);

final dashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final periodo = ref.watch(periodoDashboardProvider);
  final ahora = DateTime.now();

  DateTime inicio;
  switch (periodo) {
    case PeriodoDashboard.semana:
      inicio = ahora.subtract(const Duration(days: 7));
      break;
    case PeriodoDashboard.mes:
      inicio = DateTime(ahora.year, ahora.month, 1);
      break;
    case PeriodoDashboard.trimestre:
      inicio = DateTime(ahora.year, ahora.month - 2, 1);
      break;
  }

  return EstadisticasService.obtenerResumen(
    inicio: inicio,
    fin: ahora,
  );
});

