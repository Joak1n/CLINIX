import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/historia_clinica.dart';
import '../../core/models/paciente.dart';
import 'historia_clinica_provider.dart';
import 'historia_clinica_repository.dart';

class HistoriaClinicaScreen extends ConsumerStatefulWidget {
  final Paciente paciente;
  const HistoriaClinicaScreen({super.key, required this.paciente});

  @override
  ConsumerState<HistoriaClinicaScreen> createState() =>
      _HistoriaClinicaScreenState();
}

class _HistoriaClinicaScreenState
    extends ConsumerState<HistoriaClinicaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;
  bool _cargado = false;
  late HistoriaClinica _historia;

  // Antecedentes heredofamiliares
  bool _hfDiabetes = false;
  bool _hfHipertension = false;
  bool _hfCancer = false;
  bool _hfCardiopatia = false;
  bool _hfObesidad = false;
  final _hfOtros = TextEditingController();

  // Antecedentes patológicos
  bool _apDiabetes = false;
  bool _apHipertension = false;
  bool _apCardiopatia = false;
  bool _apAsma = false;
  bool _apCancer = false;
  bool _apFracturas = false;
  bool _apTransfusiones = false;
  final _apCirugias = TextEditingController();
  final _apTraumatismos = TextEditingController();
  final _apHospitalizaciones = TextEditingController();
  final _apOtros = TextEditingController();

  // Antecedentes no patológicos
  final _anpTabaquismo = TextEditingController();
  final _anpAlcoholismo = TextEditingController();
  final _anpDrogas = TextEditingController();
  final _anpActividadFisica = TextEditingController();
  final _anpOcupacion = TextEditingController();

  // Gineco-obstétricos
  final _goMenarca = TextEditingController();
  final _goFur = TextEditingController();
  final _goGestas = TextEditingController();
  final _goPartos = TextEditingController();
  final _goCesareas = TextEditingController();
  final _goAbortos = TextEditingController();
  final _goAnticonceptivos = TextEditingController();

  // Padecimiento y medicamentos
  final _padecimiento = TextEditingController();
  final _medicamentos = TextEditingController();

  // Escalas clínicas
  int? _escalaEva;
  int? _escalaDaniels;
  int? _escalaGlasgow;
  int? _escalaNorton;

  @override
  void dispose() {
    for (final c in [
      _hfOtros, _apCirugias, _apTraumatismos, _apHospitalizaciones,
      _apOtros, _anpTabaquismo, _anpAlcoholismo, _anpDrogas,
      _anpActividadFisica, _anpOcupacion,
      _goMenarca, _goFur, _goGestas, _goPartos, _goCesareas,
      _goAbortos, _goAnticonceptivos, _padecimiento, _medicamentos,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cargarDatos(HistoriaClinica? h) {
    if (_cargado) return;
    _cargado = true;
    if (h == null) {
      _historia = ref
          .read(historiaClinicaRepositoryProvider)
          .nueva(widget.paciente.id);
      return;
    }
    _historia = h;
    setState(() {
      _hfDiabetes = h.hfDiabetes;
      _hfHipertension = h.hfHipertension;
      _hfCancer = h.hfCancer;
      _hfCardiopatia = h.hfCardiopatia;
      _hfObesidad = h.hfObesidad;
      _hfOtros.text = h.hfOtros ?? '';
      _apDiabetes = h.apDiabetes;
      _apHipertension = h.apHipertension;
      _apCardiopatia = h.apCardiopatia;
      _apAsma = h.apAsma;
      _apCancer = h.apCancer;
      _apFracturas = h.apFracturas;
      _apTransfusiones = h.apTransfusiones;
      _apCirugias.text = h.apCirugias ?? '';
      _apTraumatismos.text = h.apTraumatismos ?? '';
      _apHospitalizaciones.text = h.apHospitalizaciones ?? '';
      _apOtros.text = h.apOtros ?? '';
      _anpTabaquismo.text = h.anpTabaquismo ?? '';
      _anpAlcoholismo.text = h.anpAlcoholismo ?? '';
      _anpDrogas.text = h.anpDrogas ?? '';
      _anpActividadFisica.text = h.anpActividadFisica ?? '';
      _anpOcupacion.text = h.anpOcupacion ?? '';
      _goMenarca.text = h.goMenarca ?? '';
      _goFur.text = h.goFur ?? '';
      _goGestas.text = h.goGestas?.toString() ?? '';
      _goPartos.text = h.goPartos?.toString() ?? '';
      _goCesareas.text = h.goCesareas?.toString() ?? '';
      _goAbortos.text = h.goAbortos?.toString() ?? '';
      _goAnticonceptivos.text = h.goAnticonceptivos ?? '';
      _padecimiento.text = h.padecimientoActual ?? '';
      _medicamentos.text = h.medicamentosActuales ?? '';
      _escalaEva = h.escalaEva;
      _escalaDaniels = h.escalaDaniels;
      _escalaGlasgow = h.escalaGlasgow;
      _escalaNorton = h.escalaNorton;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final ahora = DateTime.now().toIso8601String();
      final actualizada = HistoriaClinica(
        id: _historia.id,
        pacienteId: widget.paciente.id,
        hfDiabetes: _hfDiabetes,
        hfHipertension: _hfHipertension,
        hfCancer: _hfCancer,
        hfCardiopatia: _hfCardiopatia,
        hfObesidad: _hfObesidad,
        hfOtros: _hfOtros.text.trim().isEmpty ? null : _hfOtros.text.trim(),
        apDiabetes: _apDiabetes,
        apHipertension: _apHipertension,
        apCardiopatia: _apCardiopatia,
        apAsma: _apAsma,
        apCancer: _apCancer,
        apFracturas: _apFracturas,
        apTransfusiones: _apTransfusiones,
        apCirugias: _apCirugias.text.trim().isEmpty ? null : _apCirugias.text.trim(),
        apTraumatismos: _apTraumatismos.text.trim().isEmpty ? null : _apTraumatismos.text.trim(),
        apHospitalizaciones: _apHospitalizaciones.text.trim().isEmpty ? null : _apHospitalizaciones.text.trim(),
        apOtros: _apOtros.text.trim().isEmpty ? null : _apOtros.text.trim(),
        anpTabaquismo: _anpTabaquismo.text.trim().isEmpty ? null : _anpTabaquismo.text.trim(),
        anpAlcoholismo: _anpAlcoholismo.text.trim().isEmpty ? null : _anpAlcoholismo.text.trim(),
        anpDrogas: _anpDrogas.text.trim().isEmpty ? null : _anpDrogas.text.trim(),
        anpActividadFisica: _anpActividadFisica.text.trim().isEmpty ? null : _anpActividadFisica.text.trim(),
        anpOcupacion: _anpOcupacion.text.trim().isEmpty ? null : _anpOcupacion.text.trim(),
        goMenarca: _goMenarca.text.trim().isEmpty ? null : _goMenarca.text.trim(),
        goFur: _goFur.text.trim().isEmpty ? null : _goFur.text.trim(),
        goGestas: int.tryParse(_goGestas.text.trim()),
        goPartos: int.tryParse(_goPartos.text.trim()),
        goCesareas: int.tryParse(_goCesareas.text.trim()),
        goAbortos: int.tryParse(_goAbortos.text.trim()),
        goAnticonceptivos: _goAnticonceptivos.text.trim().isEmpty ? null : _goAnticonceptivos.text.trim(),
        padecimientoActual: _padecimiento.text.trim().isEmpty ? null : _padecimiento.text.trim(),
        medicamentosActuales: _medicamentos.text.trim().isEmpty ? null : _medicamentos.text.trim(),
        escalaEva: _escalaEva,
        escalaDaniels: _escalaDaniels,
        escalaGlasgow: _escalaGlasgow,
        escalaNorton: _escalaNorton,
        createdAt: _historia.createdAt,
        updatedAt: ahora,
      );

      await ref
          .read(historiaClinicaProvider(widget.paciente.id).notifier)
          .guardar(actualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historia clínica guardada')),
        );
        Navigator.pop(context);
      }
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
    final historiaAsync =
        ref.watch(historiaClinicaProvider(widget.paciente.id));

    return historiaAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (historia) {
        _cargarDatos(historia);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historia clínica'),
            actions: [
              TextButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Padecimiento actual
                _seccion('Padecimiento actual y motivo de consulta'),
                _campo(_padecimiento,
                    'Descripción del padecimiento actual',
                    maxLineas: 4),
                const SizedBox(height: 12),
                _campo(_medicamentos, 'Medicamentos actuales',
                    maxLineas: 3),
                const SizedBox(height: 24),

                // Antecedentes heredofamiliares
                _seccion('Antecedentes heredofamiliares'),
                _checkboxes([
                  ('Diabetes', _hfDiabetes,
                      (v) => setState(() => _hfDiabetes = v!)),
                  ('Hipertensión', _hfHipertension,
                      (v) => setState(() => _hfHipertension = v!)),
                  ('Cáncer', _hfCancer,
                      (v) => setState(() => _hfCancer = v!)),
                  ('Cardiopatía', _hfCardiopatia,
                      (v) => setState(() => _hfCardiopatia = v!)),
                  ('Obesidad', _hfObesidad,
                      (v) => setState(() => _hfObesidad = v!)),
                ]),
                _campo(_hfOtros, 'Otros antecedentes familiares'),
                const SizedBox(height: 24),

                // Antecedentes patológicos
                _seccion('Antecedentes patológicos personales'),
                _checkboxes([
                  ('Diabetes', _apDiabetes,
                      (v) => setState(() => _apDiabetes = v!)),
                  ('Hipertensión', _apHipertension,
                      (v) => setState(() => _apHipertension = v!)),
                  ('Cardiopatía', _apCardiopatia,
                      (v) => setState(() => _apCardiopatia = v!)),
                  ('Asma', _apAsma,
                      (v) => setState(() => _apAsma = v!)),
                  ('Cáncer', _apCancer,
                      (v) => setState(() => _apCancer = v!)),
                  ('Fracturas', _apFracturas,
                      (v) => setState(() => _apFracturas = v!)),
                  ('Transfusiones', _apTransfusiones,
                      (v) => setState(() => _apTransfusiones = v!)),
                ]),
                const SizedBox(height: 8),
                _campo(_apCirugias, 'Cirugías previas'),
                const SizedBox(height: 12),
                _campo(_apTraumatismos, 'Traumatismos'),
                const SizedBox(height: 12),
                _campo(_apHospitalizaciones,
                    'Hospitalizaciones previas'),
                const SizedBox(height: 12),
                _campo(_apOtros,
                    'Otros antecedentes patológicos'),
                const SizedBox(height: 24),

                // Antecedentes no patológicos
                _seccion('Antecedentes no patológicos'),
                _campo(_anpOcupacion, 'Ocupación'),
                const SizedBox(height: 12),
                _campo(_anpTabaquismo,
                    'Tabaquismo (cantidad/frecuencia)'),
                const SizedBox(height: 12),
                _campo(_anpAlcoholismo,
                    'Alcoholismo (cantidad/frecuencia)'),
                const SizedBox(height: 12),
                _campo(_anpDrogas, 'Otras drogas'),
                const SizedBox(height: 12),
                _campo(_anpActividadFisica, 'Actividad física'),
                const SizedBox(height: 24),

                // Gineco-obstétricos
                if (widget.paciente.sexo == 'Femenino') ...[
                  _seccion('Antecedentes gineco-obstétricos'),
                  Row(children: [
                    Expanded(child: _campo(_goMenarca, 'Menarca')),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(_goFur, 'FUR')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _campo(_goGestas, 'Gestas',
                            tipo: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campo(_goPartos, 'Partos',
                            tipo: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campo(_goCesareas, 'Cesáreas',
                            tipo: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campo(_goAbortos, 'Abortos',
                            tipo: TextInputType.number)),
                  ]),
                  const SizedBox(height: 12),
                  _campo(_goAnticonceptivos,
                      'Método anticonceptivo'),
                  const SizedBox(height: 24),
                ],

                // Escalas clínicas
                _seccion('Escalas clínicas (opcionales)'),
                const SizedBox(height: 8),
                _filaEscala(
                  titulo: 'Escala de EVA',
                  descripcion: 'Valoración del dolor (0-10)',
                  valor: _escalaEva,
                  min: 0,
                  max: 10,
                  onChanged: (v) =>
                      setState(() => _escalaEva = v),
                ),
                const SizedBox(height: 12),
                _filaEscala(
                  titulo: 'Escala de Daniels',
                  descripcion: 'Fuerza muscular (0-5)',
                  valor: _escalaDaniels,
                  min: 0,
                  max: 5,
                  onChanged: (v) =>
                      setState(() => _escalaDaniels = v),
                ),
                const SizedBox(height: 12),
                _filaEscala(
                  titulo: 'Escala de Glasgow',
                  descripcion: 'Nivel de conciencia (3-15)',
                  valor: _escalaGlasgow,
                  min: 3,
                  max: 15,
                  onChanged: (v) =>
                      setState(() => _escalaGlasgow = v),
                ),
                const SizedBox(height: 12),
                _filaEscala(
                  titulo: 'Escala de Norton',
                  descripcion:
                      'Riesgo de úlceras por presión (5-20)',
                  valor: _escalaNorton,
                  min: 5,
                  max: 20,
                  onChanged: (v) =>
                      setState(() => _escalaNorton = v),
                ),
                const SizedBox(height: 32),

                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar historia clínica'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).colorScheme.primary)),
            const Divider(),
          ],
        ),
      );

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    int maxLineas = 1,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLineas,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLineas > 1,
      ),
    );
  }

  Widget _checkboxes(
      List<(String, bool, void Function(bool?))> items) {
    return Wrap(
      children: items
          .map((item) => SizedBox(
                width: 160,
                child: CheckboxListTile(
                  title: Text(item.$1,
                      style: const TextStyle(fontSize: 13)),
                  value: item.$2,
                  onChanged: item.$3,
                  dense: true,
                  controlAffinity:
                      ListTileControlAffinity.leading,
                ),
              ))
          .toList(),
    );
  }

  Widget _filaEscala({
    required String titulo,
    required String descripcion,
    required int? valor,
    required int min,
    required int max,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                  Text(descripcion,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  if (valor != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$valor',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    )
                  else
                    Text('No registrado',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500)),
                  const SizedBox(width: 8),
                  if (valor != null)
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onChanged(null),
                      tooltip: 'Limpiar',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              showValueIndicator:
                  ShowValueIndicator.onDrag,
            ),
            child: Slider(
              value: (valor ?? min).toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: '${valor ?? min}',
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text('$min',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              Text('$max',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

