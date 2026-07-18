import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/paciente.dart';
import '../../core/models/consentimiento_informado.dart';
import '../../core/services/consentimiento_service.dart';
import '../../core/services/pdf_service.dart';
import '../../shared/widgets/signature_pad.dart';

Uint8List _base64ToBytes(String s) => base64Decode(s);
String _bytesToBase64(Uint8List b) => base64Encode(b);

class ConsentimientoScreen extends StatefulWidget {
  final Paciente paciente;
  const ConsentimientoScreen({super.key, required this.paciente});

  @override
  State<ConsentimientoScreen> createState() => _ConsentimientoScreenState();
}

class _ConsentimientoScreenState extends State<ConsentimientoScreen> {
  final _signatureKey = GlobalKey<SignaturePadState>();
  ConsentimientoInformado? _existente;
  bool _cargando = true;
  bool _guardando = false;
  bool _reFirmar = false;

  @override
  void initState() {
    super.initState();
    _cargarExistente();
  }

  Future<void> _cargarExistente() async {
    final c =
        await ConsentimientoService.obtenerMasReciente(widget.paciente.id);
    if (mounted) {
      setState(() {
        _existente = c;
        _cargando = false;
      });
    }
  }

  String _formatearFecha(String iso) {
    try {
      final d = DateTime.parse(iso);
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final hora = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '${d.day} ${meses[d.month - 1]} ${d.year} · $hora:$min';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _firmarYGuardar() async {
    final firmaBytes = await _signatureKey.currentState?.exportarPng();
    if (firmaBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor firma antes de continuar')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final firmaBase64 = _bytesToBase64(firmaBytes);
      await ConsentimientoService.guardar(
        pacienteId: widget.paciente.id,
        firmaBase64: firmaBase64,
      );

      final pdfPath = await PdfService.generarConsentimiento(
        paciente: widget.paciente,
        firmaPng: firmaBytes,
        fechaFirma: DateTime.now(),
      );

      if (!mounted) return;
      await _cargarExistente();
      setState(() => _reFirmar = false);

      final compartir = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Consentimiento guardado'),
          ]),
          content: const Text(
              'El consentimiento se firmó y guardó correctamente. '
              '¿Quieres compartir o enviar el PDF ahora?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Compartir PDF'),
            ),
          ],
        ),
      );

      if (compartir == true) {
        await Share.shareXFiles(
          [XFile(pdfPath, mimeType: 'application/pdf')],
          subject:
              'Consentimiento informado - ${widget.paciente.nombreCompleto}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consentimiento informado')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : (_existente != null && !_reFirmar)
              ? _vistaFirmado()
              : _vistaFirmar(),
    );
  }

  Widget _vistaFirmado() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.verified_outlined, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Consentimiento firmado',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Firmado el ${_formatearFecha(_existente!.fechaFirma)}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.memory(
              _base64ToBytes(_existente!.firmaBase64),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generar y compartir PDF'),
            onPressed: _guardando
                ? null
                : () async {
                    setState(() => _guardando = true);
                    try {
                      final pdfPath =
                          await PdfService.generarConsentimiento(
                        paciente: widget.paciente,
                        firmaPng: _base64ToBytes(_existente!.firmaBase64),
                        fechaFirma: DateTime.parse(_existente!.fechaFirma),
                      );
                      if (!mounted) return;
                      await Share.shareXFiles(
                        [XFile(pdfPath, mimeType: 'application/pdf')],
                        subject:
                            'Consentimiento informado - ${widget.paciente.nombreCompleto}',
                      );
                    } finally {
                      if (mounted) setState(() => _guardando = false);
                    }
                  },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Volver a firmar'),
            onPressed: () => setState(() => _reFirmar = true),
          ),
        ],
      ),
    );
  }

  Widget _vistaFirmar() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paciente: ${widget.paciente.nombreCompleto}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    textoConsentimientoInformado,
                    style: const TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Firma aquí:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SignaturePad(key: _signatureKey),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        _signatureKey.currentState?.limpiar(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Limpiar firma'),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardando ? null : _firmarYGuardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Firmar y guardar'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
