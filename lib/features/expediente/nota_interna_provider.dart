import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/nota_interna.dart';
import 'nota_interna_repository.dart';

final notaInternaRepositoryProvider =
    Provider((ref) => NotaInternaRepository());

final notasInternasProvider =
    AsyncNotifierProviderFamily<NotasInternasNotifier, List<NotaInterna>, String>(
  NotasInternasNotifier.new,
);

class NotasInternasNotifier
    extends FamilyAsyncNotifier<List<NotaInterna>, String> {
  @override
  Future<List<NotaInterna>> build(String notaClinicaId) async {
    return ref
        .read(notaInternaRepositoryProvider)
        .obtenerPorNota(notaClinicaId);
  }

  Future<void> agregar({
    required String pacienteId,
    required String contenido,
    required String autor,
  }) async {
    await ref.read(notaInternaRepositoryProvider).crear(
          pacienteId: pacienteId,
          notaClinicaId: arg,
          contenido: contenido,
          autor: autor,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminar(String id) async {
    await ref.read(notaInternaRepositoryProvider).eliminar(id);
    ref.invalidateSelf();
    await future;
  }
}

