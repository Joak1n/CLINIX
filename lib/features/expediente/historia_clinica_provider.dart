import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/historia_clinica.dart';
import 'historia_clinica_repository.dart';

final historiaClinicaRepositoryProvider =
    Provider((ref) => HistoriaClinicaRepository());

final historiaClinicaProvider =
    AsyncNotifierProviderFamily<HistoriaClinicaNotifier, HistoriaClinica?, String>(
  HistoriaClinicaNotifier.new,
);

class HistoriaClinicaNotifier
    extends FamilyAsyncNotifier<HistoriaClinica?, String> {
  @override
  Future<HistoriaClinica?> build(String pacienteId) async {
    return ref
        .read(historiaClinicaRepositoryProvider)
        .obtenerPorPaciente(pacienteId);
  }

  Future<void> guardar(HistoriaClinica historia) async {
    await ref
        .read(historiaClinicaRepositoryProvider)
        .guardar(historia);
    ref.invalidateSelf();
    await future;
  }
}

