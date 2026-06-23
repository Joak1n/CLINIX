import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/paciente.dart';
import 'paciente_provider.dart';

class EditarPacienteScreen extends ConsumerStatefulWidget {
  final Paciente paciente;
  const EditarPacienteScreen({super.key, required this.paciente});

  @override
  ConsumerState<EditarPacienteScreen> createState() =>
      _EditarPacienteScreenState();
}

class _EditarPacienteScreenState
    extends ConsumerState<EditarPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellidoPaterno;
  late final TextEditingController _apellidoMaterno;
  late final TextEditingController _curp;
  late final TextEditingController _telefono;
  late final TextEditingController _email;
  late final TextEditingController _alergias;

  late String _sexo;
  DateTime? _fechaNacimiento;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.paciente;
    _nombre = TextEditingController(text: p.nombre);
    _apellidoPaterno = TextEditingController(text: p.apellidoPaterno);
    _apellidoMaterno = TextEditingController(text: p.apellidoMaterno ?? '');
    _curp = TextEditingController(text: p.curp ?? '');
    _telefono = TextEditingController(text: p.telefono ?? '');
    _email = TextEditingController(text: p.email ?? '');
    _alergias = TextEditingController(text: p.alergias ?? '');
    _sexo = p.sexo;

    final partes = p.fechaNacimiento.split('-');
    _fechaNacimiento = DateTime(
      int.parse(partes[0]),
      int.parse(partes[1]),
      int.parse(partes[2]),
    );
  }

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
      initialDate: _fechaNacimiento ?? DateTime(1990),
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
      final actualizado = Paciente(
        id: widget.paciente.id,
        nombre: _nombre.text.trim(),
        apellidoPaterno: _apellidoPaterno.text.trim(),
        apellidoMaterno: _apellidoMaterno.text.trim().isEmpty
            ? null
            : _apellidoMaterno.text.trim(),
        fechaNacimiento:
            '${_fechaNacimiento!.year}-'
            '${_fechaNacimiento!.month.toString().padLeft(2, '0')}-'
            '${_fechaNacimiento!.day.toString().padLeft(2, '0')}',
        sexo: _sexo,
        curp: _curp.text.trim().isEmpty ? null : _curp.text.trim(),
        telefono: _telefono.text.trim().isEmpty
            ? null
            : _telefono.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        alergias: _alergias.text.trim().isEmpty
            ? null
            : _alergias.text.trim(),
        createdAt: widget.paciente.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await ref.read(pacientesProvider.notifier).actualizar(actualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paciente actualizado correctamente')),
        );
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar paciente'),
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
                    : '${_fechaNacimiento!.day}/'
                      '${_fechaNacimiento!.month}/'
                      '${_fechaNacimiento!.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _seleccionarFecha,
            ),
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
            _campo(_telefono, 'Teléfono', tipo: TextInputType.phone),
            const SizedBox(height: 12),
            _campo(_email, 'Correo electrónico',
                tipo: TextInputType.emailAddress),
            const SizedBox(height: 20),

            _seccion('Datos clínicos'),
            _campo(_curp, 'CURP'),
            const SizedBox(height: 12),
            _campo(_alergias, 'Alergias conocidas', maxLineas: 3),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
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
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
          : null,
    );
  }
}

