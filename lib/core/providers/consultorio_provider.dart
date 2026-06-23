import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/configuracion_service.dart';

class ConsultorioState {
  final String nombre;
  final String? logoPath;

  const ConsultorioState({
    required this.nombre,
    this.logoPath,
  });

  ConsultorioState copyWith({String? nombre, String? logoPath,
      bool limpiarLogo = false}) {
    return ConsultorioState(
      nombre: nombre ?? this.nombre,
      logoPath: limpiarLogo ? null : (logoPath ?? this.logoPath),
    );
  }
}

final consultorioProvider =
    AsyncNotifierProvider<ConsultorioNotifier, ConsultorioState>(
  ConsultorioNotifier.new,
);

class ConsultorioNotifier extends AsyncNotifier<ConsultorioState> {
  @override
  Future<ConsultorioState> build() async {
    final nombre = await ConfiguracionService.getNombreConsultorio();
    final logoPath = await ConfiguracionService.getLogoPath();
    return ConsultorioState(nombre: nombre, logoPath: logoPath);
  }

  Future<void> actualizarNombre(String nombre) async {
    await ConfiguracionService.setNombreConsultorio(nombre);
    final current = state.valueOrNull;
    state = AsyncData(
        (current ?? const ConsultorioState(nombre: '')).copyWith(nombre: nombre));
  }

  Future<void> actualizarLogo(String path) async {
    final logoPath = await ConfiguracionService.guardarLogo(path);
    final current = state.valueOrNull;
    state = AsyncData(
        (current ?? const ConsultorioState(nombre: '')).copyWith(logoPath: logoPath));
  }

  Future<void> eliminarLogo() async {
    await ConfiguracionService.eliminarLogo();
    final current = state.valueOrNull;
    state = AsyncData(
        (current ?? const ConsultorioState(nombre: '')).copyWith(limpiarLogo: true));
  }
}

