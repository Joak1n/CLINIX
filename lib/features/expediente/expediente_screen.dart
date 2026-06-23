import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/paciente.dart';
import '../../core/models/nota_clinica.dart';
import '../../core/models/historia_clinica.dart';
import '../../core/models/signos_vitales.dart';
import '../../core/services/pdf_service.dart';
import '../pacientes/editar_paciente_screen.dart';
import 'historia_clinica_screen.dart';
import 'signos_vitales_screen.dart';
import 'nota_provider.dart';
import 'nueva_nota_screen.dart';
import 'package:printing/printing.dart';
import '../../core/services/pdf_service.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/historia_clinica.dart';
import '../../core/models/signos_vitales.dart';
import '../auth/auth_provider.dart';
import 'notas_internas_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'comprobante_screen.dart';
import '../rutinas/generador_rutinas_screen.dart';
import 'adjuntos_screen.dart';
import '../../core/models/adjunto.dart';

class ExpedienteScreen extends ConsumerWidget {
  final Paciente paciente;
  const ExpedienteScreen({super.key, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notasAsync = ref.watch(notasProvider(paciente.id));

      return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paciente.nombreCompleto,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Expediente clínico',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [

          IconButton(    // Botón para generar comprobante
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Generar comprobante',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ComprobanteScreen(paciente: paciente),
              ),
            ),
          ),

          IconButton(    // Botón para ver signos vitales
            icon: const Icon(Icons.monitor_heart_outlined),
            tooltip: 'Signos vitales',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SignosVitalesScreen(paciente: paciente),
              ),
            ),
          ),
          IconButton(    // Botón para ver historia clínica
            icon: const Icon(Icons.history_edu_outlined),
            tooltip: 'Historia clínica',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoriaClinicaScreen(paciente: paciente),
              ),
            ),
          ),
          IconButton(    // Botón para exportar a PDF
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar a PDF',
            onPressed: () => _exportarPdf(context, paciente),
          ),
          IconButton(    // Nuevo botón para generar rutina
            icon: const Icon(Icons.fitness_center_outlined),
            tooltip: 'Generar rutina',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GeneradorRutinasScreen(
                    paciente: paciente),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Estudios adjuntos',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdjuntosScreen(paciente: paciente),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NuevaNotaScreen(paciente: paciente),
          ),
        ).then((_) => ref.invalidate(notasProvider(paciente.id))),
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
      body: Column(
        children: [
          // Resumen del paciente
          _ResumenPaciente(paciente: paciente),
          const Divider(height: 1),
          // Historial de notas
          Expanded(
            child: notasAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (notas) {
                if (notas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Sin notas clínicas',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 6),
                        Text('Agrega la primera nota de evolución',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _TarjetaNota(nota: notas[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenPaciente extends StatelessWidget {
  final Paciente paciente;
  const _ResumenPaciente({required this.paciente});

  int get _edad {
    final hoy = DateTime.now();
    final fn = DateTime.parse(paciente.fechaNacimiento);
    int edad = hoy.year - fn.year;
    if (hoy.month < fn.month ||
        (hoy.month == fn.month && hoy.day < fn.day)) {
      edad--;
    }
    return edad;
  }

  @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                paciente.nombre[0].toUpperCase(),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(paciente.nombreCompleto,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    '$_edad años · ${paciente.sexo}'
                    '${paciente.curp != null ? ' · ${paciente.curp}' : ''}',
                    style:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  if (paciente.telefono != null)
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(paciente.telefono!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  if (paciente.alergias != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '⚠ ${paciente.alergias}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.red.shade700),
                      ),
                    ),
                  if (paciente.esMenorDeEdad) ...[    //alerta visual si el paciente es menor
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.child_care,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Menor de edad · ${paciente.responsableNombre ?? 'Sin responsable registrado'}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700),
                          ),
                          if (!paciente.consentimientoTutor) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '⚠ Sin consentimiento',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Botón editar contacto
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Editar datos del paciente',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditarPacienteScreen(paciente: paciente),
                ),
              ),
            ),
          ],
        ),
      );
    }
  
}

class _TarjetaNota extends ConsumerWidget {
  final NotaClinica nota;
  const _TarjetaNota({required this.nota});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).valueOrNull;
    final autorActual = authState?.usuario?.nombre ?? 'Terapeuta';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(nota.especialidad.nombre,
                      style: const TextStyle(fontSize: 12)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(nota.fechaFormateada,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            if (nota.subjetivo != null) ...[
              _filaSoap('S', 'Subjetivo', nota.subjetivo!),
              const SizedBox(height: 6),
            ],
            if (nota.objetivo != null) ...[
              _filaSoap('O', 'Objetivo', nota.objetivo!),
              const SizedBox(height: 6),
            ],
            if (nota.evaluacion != null) ...[
              _filaSoap('A', 'Evaluación', nota.evaluacion!),
              const SizedBox(height: 6),
            ],
            if (nota.plan != null) ...[
              _filaSoap('P', 'Plan', nota.plan!),
              const SizedBox(height: 6),
            ],
            const Divider(height: 16),
            Text(
              'Terapeuta: ${nota.terapeuta}',
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            NotasInternasWidget(
              notaClinicaId: nota.id,
              pacienteId: nota.pacienteId,
              autorActual: autorActual,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaSoap(String letra, String titulo, String contenido) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(letra,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Text(contenido,
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _exportarPdf(
    BuildContext context, Paciente paciente) async {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generando PDF...'),
            ],
          ),
        ),
      );

      try {
        final db = await DatabaseHelper.instance.database;

        // Cargar notas
        final notasMaps = await db.query(
          'notas_clinicas',
          where: 'paciente_id = ?',
          whereArgs: [paciente.id],
          orderBy: 'created_at DESC',
        );
        final notas =
            notasMaps.map((m) => NotaClinica.fromMap(m)).toList();

        // Cargar historia clínica
        final historiaMaps = await db.query(
          'historia_clinica',
          where: 'paciente_id = ?',
          whereArgs: [paciente.id],
          limit: 1,
        );
        final historia = historiaMaps.isNotEmpty
            ? HistoriaClinica.fromMap(historiaMaps.first)
            : null;

        // Cargar signos vitales
        final signosMaps = await db.query(
          'signos_vitales',
          where: 'paciente_id = ?',
          whereArgs: [paciente.id],
          orderBy: 'created_at DESC',
          limit: 5,
        );
        final signos =
            signosMaps.map((m) => SignosVitales.fromMap(m)).toList();

        // Cargar adjuntos
        final adjuntosMaps = await db.query(
          'adjuntos',
          where: 'paciente_id = ?',
          whereArgs: [paciente.id],
          orderBy: 'created_at DESC',
        );
        final adjuntos =
            adjuntosMaps.map((m) => Adjunto.fromMap(m)).toList();

        // Generar PDF
        final pdfPath = await PdfService.generarExpediente(
          paciente: paciente,
          notas: notas,
          historia: historia,
          signosVitales: signos,
          adjuntos: adjuntos,
        );

        if (context.mounted) {
          Navigator.pop(context); // cerrar loading

          final pdfBytes = await File(pdfPath).readAsBytes();
          final nombreArchivo =
              'Expediente_${paciente.apellidoPaterno}_${paciente.nombre}.pdf';

          showModalBottomSheet(
            context: context,
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nombreArchivo,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.share,
                        color: Colors.teal),
                    title: const Text('Compartir'),
                    subtitle: const Text(
                        'WhatsApp, Email, Drive, etc.'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Share.shareXFiles(
                        [
                          XFile(pdfPath,
                              mimeType: 'application/pdf')
                        ],
                        subject: nombreArchivo,
                        text:
                            'Expediente clínico de ${paciente.nombreCompleto}',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                        Icons.print_outlined,
                        color: Colors.indigo),
                    title: const Text('Previsualizar e imprimir'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                        name: nombreArchivo,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al generar PDF: $e')),
          );
        }
      }
    }

