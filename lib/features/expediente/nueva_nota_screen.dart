import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/paciente.dart';
import '../../core/models/nota_clinica.dart';
import 'nota_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/models/usuario.dart';

class NuevaNotaScreen extends ConsumerStatefulWidget {
  final Paciente paciente;
  const NuevaNotaScreen({super.key, required this.paciente});

  @override
  ConsumerState<NuevaNotaScreen> createState() => _NuevaNotaScreenState();
}

class _NuevaNotaScreenState extends ConsumerState<NuevaNotaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjetivo = TextEditingController();
  final _objetivo = TextEditingController();
  final _evaluacion = TextEditingController();
  final _plan = TextEditingController();
  final _terapeuta = TextEditingController();

  Especialidad _especialidad = Especialidad.fisioterapia;
  bool _guardando = false;

  @override
  void dispose() {
    _subjetivo.dispose();
    _objetivo.dispose();
    _evaluacion.dispose();
    _plan.dispose();
    _terapeuta.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await ref.read(notasProvider(widget.paciente.id).notifier).agregar(
            especialidad: _especialidad,
            subjetivo: _subjetivo.text.trim().isEmpty
                ? null
                : _subjetivo.text.trim(),
            objetivo: _objetivo.text.trim().isEmpty
                ? null
                : _objetivo.text.trim(),
            evaluacion: _evaluacion.text.trim().isEmpty
                ? null
                : _evaluacion.text.trim(),
            plan: _plan.text.trim().isEmpty ? null : _plan.text.trim(),
            terapeuta: _terapeuta.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nueva nota · ${widget.paciente.nombre}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Especialidad
            const Text('Especialidad',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<Especialidad>(
              initialValue: _especialidad,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: Especialidad.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.nombre),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _especialidad = v!),
            ),
            const SizedBox(height: 20),

            // SOAP
            _campoSoap('S — Subjetivo', _subjetivo,
                'Lo que el paciente reporta: dolor, síntomas, molestias'),
            const SizedBox(height: 14),
            _campoSoap('O — Objetivo', _objetivo,
                'Hallazgos clínicos observables: rangos, pruebas, mediciones'),
            const SizedBox(height: 14),
            _campoSoap('A — Evaluación / Diagnóstico', _evaluacion,
                'Interpretación clínica de los datos subjetivos y objetivos'),
            const SizedBox(height: 14),
            _campoSoap('P — Plan', _plan,
                'Tratamiento, indicaciones, próxima cita'),
            const SizedBox(height: 20),

            // Terapeuta
            TextFormField(
              controller: _terapeuta,
              decoration: const InputDecoration(
                labelText: 'Nombre del terapeuta *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar nota'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _campoSoap(
      String etiqueta, TextEditingController ctrl, String hint) {
    return TextFormField(
      controller: ctrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}

