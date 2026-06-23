import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paciente_provider.dart';

class NuevoPacienteScreen extends ConsumerStatefulWidget {
  const NuevoPacienteScreen({super.key});

  @override
  ConsumerState<NuevoPacienteScreen> createState() =>
      _NuevoPacienteScreenState();
}

class _NuevoPacienteScreenState extends ConsumerState<NuevoPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellidoPaterno = TextEditingController();
  final _apellidoMaterno = TextEditingController();
  final _curp = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _alergias = TextEditingController();

  bool _esMenor = false;
  final _responsableNombre = TextEditingController();
  final _responsableParentesco = TextEditingController();
  final _responsableTelefono = TextEditingController();
  final _responsableCurp = TextEditingController();
  bool _consentimientoTutor = false;

  String _sexo = 'Masculino';
  DateTime? _fechaNacimiento;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _apellidoPaterno.dispose();
    _apellidoMaterno.dispose();
    _curp.dispose();
    _telefono.dispose();
    _email.dispose();
    _alergias.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Fecha de nacimiento',
    );
    if (fecha != null) setState(() => _fechaNacimiento = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento')),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await ref.read(pacientesProvider.notifier).agregar(
            nombre: _nombre.text.trim(),
            apellidoPaterno: _apellidoPaterno.text.trim(),
            apellidoMaterno: _apellidoMaterno.text.trim().isEmpty
                ? null
                : _apellidoMaterno.text.trim(),
            fechaNacimiento:
                '${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}',
            sexo: _sexo,
            curp: _curp.text.trim().isEmpty ? null : _curp.text.trim(),
            telefono:
                _telefono.text.trim().isEmpty ? null : _telefono.text.trim(),
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            alergias:
                _alergias.text.trim().isEmpty ? null : _alergias.text.trim(),
          );

      if (mounted) Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Nuevo paciente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Datos obligatorios NOM-004
            _seccion('Datos de identificación'),
            _campo(_nombre, 'Nombre(s)', obligatorio: true),
            const SizedBox(height: 12),
            _campo(_apellidoPaterno, 'Apellido paterno', obligatorio: true),
            const SizedBox(height: 12),
            _campo(_apellidoMaterno, 'Apellido materno'),
            const SizedBox(height: 12),

            // Fecha de nacimiento
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de nacimiento *'),
              subtitle: Text(
                _fechaNacimiento == null
                    ? 'Toca para seleccionar'
                    : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _seleccionarFecha,
            ),
            // Aparece automáticamente si es menor de edad
            if (_esMenor) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.child_care,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Paciente menor de edad — NOM-004',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Se requieren datos del responsable legal y consentimiento informado firmado.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700),
                    ),
                    const SizedBox(height: 12),
                    _seccion('Datos del responsable legal'),
                    _campo(_responsableNombre,
                        'Nombre completo del responsable',
                        obligatorio: true),
                    const SizedBox(height: 12),
                    _campo(_responsableParentesco,
                        'Parentesco (padre, madre, tutor)',
                        obligatorio: true),
                    const SizedBox(height: 12),
                    _campo(_responsableTelefono,
                        'Teléfono del responsable',
                        tipo: TextInputType.phone),
                    const SizedBox(height: 12),
                    _campo(_responsableCurp,
                        'CURP del responsable'),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: _consentimientoTutor,
                      onChanged: (v) =>
                          setState(() => _consentimientoTutor = v!),
                      title: const Text(
                        'Consentimiento informado firmado por el responsable legal',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Art. 10 NOM-004-SSA3-2012',
                        style: TextStyle(fontSize: 11),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // Sexo
            const Text('Sexo *'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Masculino', label: Text('Masculino')),
                ButtonSegment(value: 'Femenino', label: Text('Femenino')),
                ButtonSegment(value: 'Otro', label: Text('Otro')),
              ],
              selected: {_sexo},
              onSelectionChanged: (v) => setState(() => _sexo = v.first),
            ),
            const SizedBox(height: 20),

            _seccion('Datos de contacto'),
            _campo(_telefono, 'Teléfono',
                tipo: TextInputType.phone),
            const SizedBox(height: 12),
            _campo(_email, 'Correo electrónico',
                tipo: TextInputType.emailAddress),
            const SizedBox(height: 20),

            _seccion('Datos clínicos'),
            _campo(_curp, 'CURP'),
            const SizedBox(height: 12),
            _campo(_alergias, 'Alergias conocidas',
                maxLineas: 3),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar paciente'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String etiqueta, {
    bool obligatorio = false,
    TextInputType tipo = TextInputType.text,
    int maxLineas = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      maxLines: maxLineas,
      decoration: InputDecoration(
        labelText: obligatorio ? '$etiqueta *' : etiqueta,
        border: const OutlineInputBorder(),
      ),
      validator: obligatorio
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(...);
    if (fecha != null) {
      setState(() {
        _fechaNacimiento = fecha;
        // Detectar automáticamente si es menor
        final hoy = DateTime.now();
        int edad = hoy.year - fecha.year;
        if (hoy.month < fecha.month ||
            (hoy.month == fecha.month && hoy.day < fecha.day)) edad--;
        _esMenor = edad < 18;
      });
    }
  }
}

