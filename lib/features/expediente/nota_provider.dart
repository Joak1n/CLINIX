import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/nota_clinica.dart';
import 'nota_repository.dart';
import '../../core/providers/realtime_provider.dart';

final notaRepositoryProvider = Provider((ref) => NotaRepository());

final notasProvider = AsyncNotifierProviderFamily<NotasNotifier,
    List<NotaClinica>, String>(
  NotasNotifier.new,
);

class NotasNotifier extends FamilyAsyncNotifier<List<NotaClinica>, String> {
  @override
  Future<List<NotaClinica>> build(String pacienteId) async {
    ref.watch(realtimeVersionProvider);
    return ref.read(notaRepositoryProvider).obtenerPorPaciente(pacienteId);
  }

  Future<void> agregar({
    required Especialidad especialidad,
    String? subjetivo,
    String? objetivo,
    String? evaluacion,
    String? plan,
    required String terapeuta,
  }) async {
    await ref.read(notaRepositoryProvider).crear(
          pacienteId: arg,
          especialidad: especialidad,
          subjetivo: subjetivo,
          objetivo: objetivo,
          evaluacion: evaluacion,
          plan: plan,
          terapeuta: terapeuta,
        );
    ref.invalidateSelf();
    await future;
  }
}

