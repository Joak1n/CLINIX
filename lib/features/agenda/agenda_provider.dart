import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cita.dart';
import 'cita_repository.dart';
import '../../core/providers/realtime_provider.dart';

final citaRepositoryProvider = Provider((ref) => CitaRepository());

// Fecha seleccionada en la agenda
final fechaSeleccionadaProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final citasDelDiaProvider =
    AsyncNotifierProviderFamily<CitasNotifier, List<Cita>, String>(
  CitasNotifier.new,
);

class CitasNotifier extends FamilyAsyncNotifier<List<Cita>, String> {
  @override
  Future<List<Cita>> build(String fecha) async {
    ref.watch(realtimeVersionProvider);
    return ref.read(citaRepositoryProvider).obtenerPorFecha(fecha);
  }

  Future<void> actualizarEstado(String citaId, EstadoCita estado) async {
    await ref.read(citaRepositoryProvider).actualizarEstado(citaId, estado);
    ref.invalidateSelf();
    await future;
  }
  Future<void> actualizar(Cita cita) async {
    await ref.read(citaRepositoryProvider).actualizar(cita);
    ref.invalidateSelf();
    await future;
  }
  Future<void> eliminar(String citaId) async {
    await ref.read(citaRepositoryProvider).eliminar(citaId);
    ref.invalidateSelf();
    await future;
  }
}

