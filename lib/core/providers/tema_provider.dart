import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/configuracion_service.dart';

class TemaState {
  final Color colorPrimario;
  final Color colorSecundario;
  final Color colorFondo;

  const TemaState({
    required this.colorPrimario,
    required this.colorSecundario,
    required this.colorFondo,
  });

  // Colores por defecto
  static const inicial = TemaState(
    colorPrimario: Color(0xFF1D9E75),
    colorSecundario: Color(0xFF0D6E56),
    colorFondo: Color(0xFFF5F5F5),
  );
}

final temaProvider =
    AsyncNotifierProvider<TemaNotifier, TemaState>(
  TemaNotifier.new,
);

class TemaNotifier extends AsyncNotifier<TemaState> {
  @override
  Future<TemaState> build() async {
    final primario =
        await ConfiguracionService.getColorPrimario();
    final secundario =
        await ConfiguracionService.getColorSecundario();
    final fondo =
        await ConfiguracionService.getColorFondo();
    return TemaState(
      colorPrimario: Color(primario),
      colorSecundario: Color(secundario),
      colorFondo: Color(fondo),
    );
  }

  Future<void> actualizarPrimario(Color color) async {
    await ConfiguracionService.setColorPrimario(
        color.value);
    ref.invalidateSelf();
    await future;
  }

  Future<void> actualizarSecundario(Color color) async {
    await ConfiguracionService.setColorSecundario(
        color.value);
    ref.invalidateSelf();
    await future;
  }

  Future<void> actualizarFondo(Color color) async {
    await ConfiguracionService.setColorFondo(
        color.value);
    ref.invalidateSelf();
    await future;
  }

  Future<void> restaurarDefecto() async {
    await ConfiguracionService.setColorPrimario(
        0xFF1D9E75);
    await ConfiguracionService.setColorSecundario(
        0xFF0D6E56);
    await ConfiguracionService.setColorFondo(
        0xFFF5F5F5);
    ref.invalidateSelf();
    await future;
  }
}

