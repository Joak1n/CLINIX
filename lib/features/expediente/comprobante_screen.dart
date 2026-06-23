import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/models/paciente.dart';
import '../../core/models/comprobante.dart';
import '../../core/services/pdf_service.dart';
import '../auth/auth_provider.dart';

class ComprobanteScreen extends ConsumerStatefulWidget {
  final Paciente paciente;
  const ComprobanteScreen({super.key, required this.paciente});

  @override
  ConsumerState<ComprobanteScreen> createState() =>
      _ComprobanteScreenState();
}

class _ComprobanteScreenState
    extends ConsumerState<ComprobanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoConsulta = TextEditingController();
  final _diagnostico = TextEditingController();
  final _indicaciones = TextEditingController();
  final _proximaCita = TextEditingController();
  final _observaciones = TextEditingController();

  String _especialidad = 'Fisioterapia';
  bool _generando = false;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();

  final _especialidades = [
    'Fisioterapia',
    'Spa',
    'Asesoría deportiva',
  ];

  @override
  void dispose() {
    _motivoConsulta.dispose();
    _diagnostico.dispose();
    _indicaciones.dispose();
    _proximaCita.dispose();
    _observaciones.dispose();
    super.dispose();
  }

  String _formatFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  Future<void> _generar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _generando = true);

    try {
      final authState =
          ref.read(authProvider).valueOrNull;
      final terapeuta =
          authState?.usuario?.nombre ?? 'Terapeuta';

      final comprobante = Comprobante(
        pacienteNombre: widget.paciente.nombreCompleto,
        pacienteFechaNacimiento:
            widget.paciente.fechaNacimiento,
        pacienteTelefono: widget.paciente.telefono,
        fecha: _formatFecha(_fecha),
        hora: _formatHora(_hora),
        especialidad: _especialidad,
        terapeuta: terapeuta,
        motivoConsulta:
            _motivoConsulta.text.trim().isEmpty
                ? null
                : _motivoConsulta.text.trim(),
        diagnostico: _diagnostico.text.trim().isEmpty
            ? null
            : _diagnostico.text.trim(),
        indicaciones:
            _indicaciones.text.trim().isEmpty
                ? null
                : _indicaciones.text.trim(),
        proximaCita:
            _proximaCita.text.trim().isEmpty
                ? null
                : _proximaCita.text.trim(),
        observaciones:
            _observaciones.text.trim().isEmpty
                ? null
                : _observaciones.text.trim(),
      );

      final pdfPath =
          await PdfService.generarComprobante(
        comprobante: comprobante,
      );

      if (mounted) {
        _mostrarOpciones(pdfPath,
            widget.paciente.nombreCompleto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al generar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  void _mostrarOpciones(
      String pdfPath, String nombrePaciente) {
    final nombreArchivo =
        'Comprobante_$nombrePaciente.pdf';
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
                  const Icon(Icons.receipt_long,
                      color: Colors.teal),
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
                  'WhatsApp, Email, Drive...'),
              onTap: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [
                    XFile(pdfPath,
                        mimeType: 'application/pdf')
                  ],
                  subject: nombreArchivo,
                  text:
                      'Comprobante de consulta de $nombrePaciente',
                );
              },
            ),
            ListTile(
              leading: const Icon(
                  Icons.print_outlined,
                  color: Colors.indigo),
              title:
                  const Text('Previsualizar e imprimir'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(
                  onLayout: (_) async =>
                      await File(pdfPath).readAsBytes(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Comprobante · ${widget.paciente.nombre}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info del paciente
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      widget.paciente.nombre[0]
                          .toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.paciente.nombreCompleto,
                          style: const TextStyle(
                              fontWeight:
                                  FontWeight.w500),
                        ),
                        Text(
                          widget.paciente
                              .fechaNacimiento,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Especialidad
            _seccion('Datos de la consulta'),
            DropdownButtonFormField<String>(
              initialValue: _especialidad,
              decoration: const InputDecoration(
                labelText: 'Especialidad',
                border: OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.medical_services_outlined),
              ),
              items: _especialidades
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _especialidad = v!),
            ),
            const SizedBox(height: 12),

            // Fecha y hora
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                        Icons.calendar_today,
                        size: 18),
                    label: Text(_formatFecha(_fecha)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _fecha,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(
                            const Duration(days: 365)),
                      );
                      if (d != null) {
                        setState(() => _fecha = d);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time,
                        size: 18),
                    label: Text(_formatHora(_hora)),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _hora,
                      );
                      if (t != null) {
                        setState(() => _hora = t);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campos clínicos
            _seccion('Información clínica'),
            _campo(_motivoConsulta,
                'Motivo de consulta',
                maxLineas: 2),
            const SizedBox(height: 12),
            _campo(_diagnostico,
                'Diagnóstico / Impresión diagnóstica',
                maxLineas: 2),
            const SizedBox(height: 12),
            _campo(_indicaciones,
                'Indicaciones y tratamiento',
                maxLineas: 3),
            const SizedBox(height: 20),

            _seccion('Seguimiento'),
            _campo(_proximaCita, 'Próxima cita',
                icono: Icons.calendar_month_outlined),
            const SizedBox(height: 12),
            _campo(_observaciones, 'Observaciones',
                maxLineas: 2),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _generando ? null : _generar,
              icon: _generando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: const Text(
                  'Generar comprobante'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding:
            const EdgeInsets.only(bottom: 12),
        child: Text(
          titulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).colorScheme.primary,
          ),
        ),
      );

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    int maxLineas = 1,
    IconData? icono,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLineas,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icono != null ? Icon(icono) : null,
        alignLabelWithHint: maxLineas > 1,
      ),
    );
  }
}

