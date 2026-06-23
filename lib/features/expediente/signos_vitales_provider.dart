import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/signos_vitales.dart';
import 'signos_vitales_repository.dart';

final signosVitalesRepositoryProvider =
    Provider((ref) => SignosVitalesRepository());

final signosVitalesProvider =
    AsyncNotifierProviderFamily<SignosVitalesNotifier, List<SignosVitales>, String>(
  SignosVitalesNotifier.new,
);

class SignosVitalesNotifier
    extends FamilyAsyncNotifier<List<SignosVitales>, String> {
  @override
  Future<List<SignosVitales>> build(String pacienteId) async {
    return ref
        .read(signosVitalesRepositoryProvider)
        .obtenerPorPaciente(pacienteId);
  }

  Future<void> agregar(SignosVitales signos) async {
    await ref.read(signosVitalesRepositoryProvider).crear(signos);
    ref.invalidateSelf();
    await future;
  }
}

