import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../../core/models/adjunto.dart';
import '../../core/models/paciente.dart';
import 'adjunto_provider.dart';
import 'adjunto_repository.dart';

class AdjuntosScreen extends ConsumerWidget {
  final Paciente paciente;
  const AdjuntosScreen({super.key, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjuntosAsync =
        ref.watch(adjuntosProvider(paciente.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Estudios · ${paciente.nombre}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _seleccionarArchivo(context, ref),
        icon: const Icon(Icons.attach_file),
        label: const Text('Adjuntar estudio'),
      ),
      body: adjuntosAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (adjuntos) {
          if (adjuntos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined,
                      size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Sin estudios adjuntos',
                      style:
                          TextStyle(color: Colors.grey)),
                  SizedBox(height: 6),
                  Text(
                    'Adjunta RX, US, TAC u otros archivos',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: adjuntos.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _TarjetaAdjunto(
              adjunto: adjuntos[i],
              paciente: paciente,
              onEliminar: () async {
                await ref
                    .read(adjuntosProvider(paciente.id)
                        .notifier)
                    .eliminar(adjuntos[i]);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _seleccionarArchivo(
      BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    // Mostrar diálogo para descripción
    final descripcion = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Descripción del estudio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w500),
              ),
              Text(
                '${(file.size / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  labelText:
                      'Tipo de estudio (ej: RX Columna, US Rodilla)',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Subir'),
            ),
          ],
        );
      },
    );

    if (descripcion == null) return;

    // Mostrar loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Subiendo archivo...'),
            ],
          ),
        ),
      );
    }

    try {
      await ref
          .read(adjuntosProvider(paciente.id).notifier)
          .subir(
            rutaArchivo: file.path!,
            nombre: file.name,
            tipo: file.extension != null
                ? 'application/${file.extension}'
                : 'application/octet-stream',
            tamano: file.size,
            descripcion: descripcion.isEmpty
                ? null
                : descripcion,
          );

      if (context.mounted) {
        Navigator.pop(context); // cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Archivo subido correctamente'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _TarjetaAdjunto extends ConsumerWidget {
  final Adjunto adjunto;
  final Paciente paciente;
  final VoidCallback onEliminar;

  const _TarjetaAdjunto({
    required this.adjunto,
    required this.paciente,
    required this.onEliminar,
  });

  IconData _icono() {
    if (adjunto.esImagen) return Icons.image_outlined;
    if (adjunto.esPdf) {
      return Icons.picture_as_pdf_outlined;
    }
    return Icons.attach_file;
  }

  Color _color() {
    if (adjunto.esImagen) return Colors.teal;
    if (adjunto.esPdf) return Colors.red;
    return Colors.indigo;
  }

  Future<void> _abrir(
      BuildContext context, WidgetRef ref) async {
    final repo = ref.read(adjuntoRepositoryProvider);
    final ruta = await repo.obtenerRutaLocal(adjunto);

    if (ruta == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se pudo abrir el archivo')),
        );
      }
      return;
    }

    await OpenFile.open(ruta);
  }

  Future<void> _confirmarEliminar(
      BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar adjunto'),
        content: Text(
            '¿Eliminar "${adjunto.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) onEliminar();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _color().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: adjunto.esImagen &&
                  adjunto.rutaLocal != null &&
                  File(adjunto.rutaLocal!).existsSync()
              ? ClipRRect(
                  borderRadius:
                      BorderRadius.circular(8),
                  child: Image.file(
                    File(adjunto.rutaLocal!),
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(_icono(), color: _color()),
        ),
        title: Text(
          adjunto.descripcion ?? adjunto.nombre,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14),
        ),
        subtitle: Text(
          '${adjunto.nombre} · ${adjunto.tamanoFormateado} · ${adjunto.fechaFormateada}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  size: 20),
              tooltip: 'Abrir',
              onPressed: () => _abrir(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.red),
              tooltip: 'Eliminar',
              onPressed: () =>
                  _confirmarEliminar(context),
            ),
          ],
        ),
        onTap: () => _abrir(context, ref),
      ),
    );
  }
}

