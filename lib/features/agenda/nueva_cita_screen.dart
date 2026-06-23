import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cita.dart';
import '../../core/models/nota_clinica.dart';
import '../../core/models/paciente.dart';
import '../../core/models/usuario.dart';
import '../../core/database/database_helper.dart';
import '../agenda/agenda_provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/widgets/whatsapp_buttons.dart';

class NuevaCitaScreen extends ConsumerStatefulWidget {
  const NuevaCitaScreen({super.key});

  @override
  ConsumerState<NuevaCitaScreen> createState() => _NuevaCitaScreenState();
}

class _NuevaCitaScreenState extends ConsumerState<NuevaCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notas = TextEditingController();

  Especialidad _especialidad = Especialidad.fisioterapia;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  int _duracion = 60;
  Paciente? _pacienteSeleccionado;
  List<Paciente> _pacientes = [];
  List<Usuario> _terapeutas = [];
  Usuario? _terapeutaSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
    _cargarTerapeutas();
  }

  Future<void> _cargarPacientes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('pacientes', orderBy: 'apellido_paterno ASC');
    setState(() {
      _pacientes = maps.map((m) => Paciente.fromMap(m)).toList();
    });
  }

  Future<void> _cargarTerapeutas() async {
    final usuarios =
        await ref.read(usuarioRepositoryProvider).obtenerTodos();
    setState(() {
      _terapeutas = usuarios.where((u) => u.activo).toList();
    });
  }

  String _formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pacienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un paciente')),
      );
      return;
    }
    if (_terapeutaSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un terapeuta')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final cita = await ref.read(citaRepositoryProvider).crear(
            pacienteId: _pacienteSeleccionado!.id,
            especialidad: _especialidad,
            fecha: _formatFecha(_fecha),
            hora: _formatHora(_hora),
            duracionMinutos: _duracion,
            terapeuta: _terapeutaSeleccionado!.nombre,
            notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
          );

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _DialogoCitaGuardada(
            cita: cita,
            paciente: _pacienteSeleccionado!,
          ),
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
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva cita')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _seccion('Paciente'),
            DropdownButtonFormField<Paciente>(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Selecciona un paciente'),
              value: _pacienteSeleccionado,
              items: _pacientes
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.nombreCompleto),
                      ))
                  .toList(),
              onChanged: (p) => setState(() => _pacienteSeleccionado = p),
            ),
            const SizedBox(height: 20),
            _seccion('Especialidad'),
            DropdownButtonFormField<Especialidad>(
              value: _especialidad,
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
            _seccion('Fecha y hora'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text('${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _fecha,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 1)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _fecha = d);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_formatHora(_hora)),
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: _hora,
                      );
                      if (t != null) setState(() => _hora = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _seccion('Duración: $_duracion minutos'),
            Slider(
              value: _duracion.toDouble(),
              min: 30,
              max: 120,
              divisions: 6,
              label: '$_duracion min',
              onChanged: (v) => setState(() => _duracion = v.round()),
            ),
            const SizedBox(height: 12),
            _seccion('Terapeuta'),
            DropdownButtonFormField<Usuario>(
              value: _terapeutaSeleccionado,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Selecciona un terapeuta',
              ),
              items: _terapeutas
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text('${u.nombre} (${u.rol.etiqueta})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _terapeutaSeleccionado = v),
              validator: (v) =>
                  v == null ? 'Selecciona un terapeuta' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notas,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Guardar cita'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(titulo,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary)),
      );
}

class _DialogoCitaGuardada extends StatelessWidget {
  final Cita cita;
  final Paciente paciente;

  const _DialogoCitaGuardada({
    required this.cita,
    required this.paciente,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.teal),
          SizedBox(width: 8),
          Text('Cita agendada'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cita registrada para ${paciente.nombreCompleto}'),
          const SizedBox(height: 4),
          Text('${cita.fecha} a las ${cita.hora}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          const Text('¿Deseas notificar al paciente por WhatsApp?',
              style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: BotonWhatsAppCitaNueva(
              cita: cita,
              paciente: paciente,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}