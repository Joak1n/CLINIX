import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/especialidad_personalizada.dart';
import 'especialidad_repository.dart';

final especialidadRepositoryProvider =
    Provider((ref) => EspecialidadRepository());

final especialidadesProvider =
    AsyncNotifierProvider<EspecialidadesNotifier, List<EspecialidadPersonalizada>>(
  EspecialidadesNotifier.new,
);

class EspecialidadesNotifier
    extends AsyncNotifier<List<EspecialidadPersonalizada>> {
  @override
  Future<List<EspecialidadPersonalizada>> build() async {
    return ref.read(especialidadRepositoryProvider).obtenerTodas();
  }

  Future<void> agregar(String nombre) async {
    await ref.read(especialidadRepositoryProvider).crear(nombre);
    ref.invalidateSelf();
    await future;
  }

  Future<void> cambiarEstado(String id, bool activa) async {
    await ref.read(especialidadRepositoryProvider).actualizarEstado(id, activa);
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminar(String id) async {
    await ref.read(especialidadRepositoryProvider).eliminar(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> renombrar(String id, String nombre) async {
    await ref.read(especialidadRepositoryProvider).renombrar(id, nombre);
    ref.invalidateSelf();
    await future;
  }
}

// Solo las activas, para usar en dropdowns
final especialidadesActivasProvider =
    FutureProvider<List<EspecialidadPersonalizada>>((ref) async {
  ref.watch(especialidadesProvider); // refrescar cuando cambien
  return ref.read(especialidadRepositoryProvider).obtenerTodas(soloActivas: true);
});