import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/paciente.dart';
import '../../core/models/signos_vitales.dart';
import 'signos_vitales_provider.dart';
import 'signos_vitales_repository.dart';

class SignosVitalesScreen extends ConsumerWidget {
  final Paciente paciente;
  const SignosVitalesScreen({super.key, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signosAsync = ref.watch(signosVitalesProvider(paciente.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Signos vitales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref),
        icon: const Icon(Icons.monitor_heart),
        label: const Text('Registrar'),
      ),
      body: signosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Sin registros de signos vitales',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _TarjetaSignos(signos: lista[i]),
          );
        },
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FormularioSignos(paciente: paciente),
    ).then((_) => ref.invalidate(signosVitalesProvider(paciente.id)));
  }
}

class _TarjetaSignos extends StatelessWidget {
  final SignosVitales signos;
  const _TarjetaSignos({required this.signos});

  Widget _dato(String label, String? valor, String unidad) {
    if (valor == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Text('$valor $unidad',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_heart_outlined,
                    size: 18, color: Colors.teal),
                const SizedBox(width: 6),
                Text(signos.fechaFormateada,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
            const Divider(height: 16),
            _dato('Tensión arterial', signos.tensionArterial != '—' ? signos.tensionArterial : null, ''),
            _dato('Frec. cardiaca', signos.frecuenciaCardiaca?.toString(), 'lpm'),
            _dato('Frec. respiratoria', signos.frecuenciaRespiratoria?.toString(), 'rpm'),
            _dato('Temperatura', signos.temperatura?.toString(), '°C'),
            _dato('Peso', signos.peso?.toString(), 'kg'),
            _dato('Talla', signos.talla?.toString(), 'cm'),
            _dato('IMC', signos.imc?.toString(), 'kg/m²'),
            _dato('Sat. O₂', signos.saturacionOxigeno?.toString(), '%'),
            _dato('Glucosa', signos.glucosa?.toString(), 'mg/dL'),
            if (signos.notas != null) ...[
              const SizedBox(height: 6),
              Text(signos.notas!,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormularioSignos extends ConsumerStatefulWidget {
  final Paciente paciente;
  const _FormularioSignos({required this.paciente});

  @override
  ConsumerState<_FormularioSignos> createState() => _FormularioSignosState();
}

class _FormularioSignosState extends ConsumerState<_FormularioSignos> {
  final _sistolica = TextEditingController();
  final _diastolica = TextEditingController();
  final _fc = TextEditingController();
  final _fr = TextEditingController();
  final _temp = TextEditingController();
  final _peso = TextEditingController();
  final _talla = TextEditingController();
  final _sat = TextEditingController();
  final _glucosa = TextEditingController();
  final _notas = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [
      _sistolica, _diastolica, _fc, _fr, _temp,
      _peso, _talla, _sat, _glucosa, _notas
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final repo = ref.read(signosVitalesRepositoryProvider);
      final signos = repo.nuevo(
        pacienteId: widget.paciente.id,
        tensionSistolica: int.tryParse(_sistolica.text.trim()),
        tensionDiastolica: int.tryParse(_diastolica.text.trim()),
        frecuenciaCardiaca: int.tryParse(_fc.text.trim()),
        frecuenciaRespiratoria: int.tryParse(_fr.text.trim()),
        temperatura: double.tryParse(_temp.text.trim()),
        peso: double.tryParse(_peso.text.trim()),
        talla: double.tryParse(_talla.text.trim()),
        saturacionOxigeno: int.tryParse(_sat.text.trim()),
        glucosa: int.tryParse(_glucosa.text.trim()),
        notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
      );
      await ref
          .read(signosVitalesProvider(widget.paciente.id).notifier)
          .agregar(signos);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Registrar signos vitales',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Tensión arterial
            Row(children: [
              Expanded(child: _campo(_sistolica, 'T.A. sistólica', 'mmHg')),
              const SizedBox(width: 12),
              Expanded(child: _campo(_diastolica, 'T.A. diastólica', 'mmHg')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campo(_fc, 'Frec. cardiaca', 'lpm')),
              const SizedBox(width: 12),
              Expanded(child: _campo(_fr, 'Frec. respiratoria', 'rpm')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campo(_temp, 'Temperatura', '°C')),
              const SizedBox(width: 12),
              Expanded(child: _campo(_sat, 'Sat. O₂', '%')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _campo(_peso, 'Peso', 'kg')),
              const SizedBox(width: 12),
              Expanded(child: _campo(_talla, 'Talla', 'cm')),
            ]),
            const SizedBox(height: 12),
            _campo(_glucosa, 'Glucosa', 'mg/dL'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notas,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar signos vitales'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController ctrl, String label, String unidad) {
    return TextFormField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unidad,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

