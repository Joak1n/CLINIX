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
        final tienelogo = consultorio.logoPath != null;
        final colorTexto = color ??
            Theme.of(context).colorScheme.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo o ícono por defecto
            if (tienelogo)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(consultorio.logoPath!),
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              )
            else
              Icon(
                Icons.local_hospital_rounded,
                size: logoSize,
                color: colorTexto,
              ),

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
}

/// Solo el logo (para AppBar)
class LogoConsultorio extends ConsumerWidget {
  final double size;

  const LogoConsultorio({super.key, this.size = 32});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultorioAsync = ref.watch(consultorioProvider);

    return consultorioAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (consultorio) {
        if (consultorio.logoPath == null) {
          return Icon(Icons.local_hospital_rounded,
              size: size,
              color: Theme.of(context).colorScheme.primary);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(consultorio.logoPath!),
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

