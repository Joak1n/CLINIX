import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/adjunto.dart';
import 'adjunto_repository.dart';

final adjuntoRepositoryProvider =
    Provider((ref) => AdjuntoRepository());

final adjuntosProvider =
    AsyncNotifierProviderFamily<AdjuntosNotifier,
        List<Adjunto>, String>(
  AdjuntosNotifier.new,
);

class AdjuntosNotifier
    extends FamilyAsyncNotifier<List<Adjunto>, String> {
  @override
  Future<List<Adjunto>> build(String pacienteId) async {
    return ref
        .read(adjuntoRepositoryProvider)
        .obtenerPorPaciente(pacienteId);
  }

  Future<void> subir({
    required String rutaArchivo,
    required String nombre,
    required String tipo,
    required int tamano,
    String? descripcion,
  }) async {
    await ref.read(adjuntoRepositoryProvider).subir(
          pacienteId: arg,
          rutaArchivo: rutaArchivo,
          nombre: nombre,
          tipo: tipo,
          tamano: tamano,
          descripcion: descripcion,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminar(Adjunto adjunto) async {
    await ref
        .read(adjuntoRepositoryProvider)
        .eliminar(adjunto);
    ref.invalidateSelf();
    await future;
  }
}

