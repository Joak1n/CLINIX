import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/consultorio_provider.dart';

class ConsultorioHeader extends ConsumerWidget {
  final double logoSize;
  final double fontSize;
  final Color? color;
  final bool mostrarNombre;

  const ConsultorioHeader({
    super.key,
    this.logoSize = 40,
    this.fontSize = 20,
    this.color,
    this.mostrarNombre = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultorioAsync = ref.watch(consultorioProvider);

    return consultorioAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (consultorio) {
        final colorTexto = color ?? Theme.of(context).colorScheme.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo del consultorio o logo de Clinix como fallback
            if (consultorio.logoPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(consultorio.logoPath!),
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _logoClinic(logoSize),
                ),
              )
            else
              _logoClinic(logoSize),

            if (mostrarNombre) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  consultorio.nombre,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: colorTexto,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _logoClinic(double size) => Image.asset(
        'assets/icon/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
}

/// Solo el logo (para AppBar y onboarding)
class LogoConsultorio extends ConsumerWidget {
  final double size;

  const LogoConsultorio({super.key, this.size = 32});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultorioAsync = ref.watch(consultorioProvider);

    return consultorioAsync.when(
      loading: () => _logoClinic(),
      error: (_, __) => _logoClinic(),
      data: (consultorio) {
        if (consultorio.logoPath == null) return _logoClinic();
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(consultorio.logoPath!),
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _logoClinic(),
          ),
        );
      },
    );
  }

  Widget _logoClinic() => Image.asset(
        'assets/icon/icon.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
}