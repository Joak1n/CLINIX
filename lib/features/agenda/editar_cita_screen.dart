import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cita.dart';
import '../../core/models/nota_clinica.dart';
import '../../core/models/paciente.dart';
import '../../core/models/usuario.dart';
import '../../core/database/database_helper.dart';
import '../auth/auth_provider.dart';
import 'agenda_provider.dart';
import '../../core/services/whatsapp_service.dart';

class EditarCitaScreen extends ConsumerStatefulWidget {
  final Cita cita;
  const EditarCitaScreen({super.key, required this.cita});

  @override
  ConsumerState<EditarCitaScreen> createState() => _EditarCitaScreenState();
}

class _EditarCitaScreenState extends ConsumerState<EditarCitaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notas;

  late Especialidad _especialidad;
  late DateTime _fecha;
  late TimeOfDay _hora;
  late int _duracion;
  late EstadoCita _estado;
  Paciente? _pacienteSeleccionado;
  List<Paciente> _pacientes = [];
  List<Usuario> _terapeutas = [];
  Usuario? _terapeutaSeleccionado;
  bool _guardando = false;
  bool _esPacienteTemporal = false;
  final _nombreTemporal = TextEditingController();
  final _telefonoTemporal = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notas = TextEditingController(text: widget.cita.notas ?? '');
    _especialidad = widget.cita.especialidad;
    _estado = widget.cita.estado;
    _duracion = widget.cita.duracionMinutos;

    final partesFecha = widget.cita.fecha.split('-');
    _fecha = DateTime(
      int.parse(partesFecha[0]),
      int.parse(partesFecha[1]),
      int.parse(partesFecha[2]),
    );

    final partesHora = widget.cita.hora.split(':');
    _hora = TimeOfDay(
      hour: int.parse(partesHora[0]),
      minute: int.parse(partesHora[1]),
    );

    _cargarPacientes();
    _cargarTerapeutas();
  }

  Future<void> _cargarPacientes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('pacientes', orderBy: 'apellido_paterno ASC');
    final lista = maps.map((m) => Paciente.fromMap(m)).toList();
    setState(() {
      _pacientes = lista;
      try {
        _pacienteSeleccionado = lista.firstWhere(
          (p) => p.id == widget.cita.pacienteId,
        );
      } catch (_) {
        _pacienteSeleccionado = lista.isNotEmpty ? lista.first : null;
      }
    });
  }

  Future<void> _cargarTerapeutas() async {
    final usuarios =
        await ref.read(usuarioRepositoryProvider).obtenerTodos();
    final activos = usuarios.where((u) => u.activo).toList();
    setState(() {
      _terapeutas = activos;
      try {
        _terapeutaSeleccionado = activos.firstWhere(
          (u) => u.nombre == widget.cita.terapeuta,
        );
      } catch (_) {
        _terapeutaSeleccionado =
            activos.isNotEmpty ? activos.first : null;
      }
    });
  }

  String _formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_esPacienteTemporal && _pacienteSeleccionado == null) {
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
      // Para paciente temporal usar un ID placeholder
      final pacienteId = _esPacienteTemporal
          ? 'temporal'
          : _pacienteSeleccionado!.id;
      final nombrePaciente = _esPacienteTemporal
          ? _nombreTemporal.text.trim()
          : _pacienteSeleccionado!.nombreCompleto;

      final cita = await ref.read(citaRepositoryProvider).crear(
            pacienteId: pacienteId,
            especialidad: _especialidad,
            fecha: _formatFecha(_fecha),
            hora: _formatHora(_hora),
            duracionMinutos: _duracion,
            terapeuta: _terapeutaSeleccionado!.nombre,
            notas: _notas.text.trim().isEmpty
                ? null
                : _notas.text.trim(),
          );

      if (mounted) {
        // Si tiene teléfono temporal, ofrecer notificar
        if (_esPacienteTemporal &&
            _telefonoTemporal.text.trim().isNotEmpty) {
          await _notificarPacienteTemporal(
              cita, nombrePaciente,
              _telefonoTemporal.text.trim());
        } else if (!_esPacienteTemporal) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _DialogoCitaGuardada(
              cita: cita,
              paciente: _pacienteSeleccionado!,
            ),
          );
        }
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

  Future<void> _notificarPacienteTemporal(
      Cita cita, String nombre, String telefono) async {
    final partesFecha = cita.fecha.split('-');
    final fechaFormateada =
        '${partesFecha[2]}/${partesFecha[1]}/${partesFecha[0]}';
    final mensaje = await WhatsAppService.mensajeCitaNueva(
      nombrePaciente: nombre,
      fecha: fechaFormateada,
      hora: cita.hora,
      especialidad: cita.especialidad.nombre,
      terapeuta: cita.terapeuta,
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal),
            SizedBox(width: 8),
            Text('Cita agendada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cita registrada para $nombre'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF25D366),
                  side: const BorderSide(
                      color: Color(0xFF25D366)),
                ),
                icon: const Icon(Icons.message),
                label: const Text('Notificar por WhatsApp'),
                onPressed: () async {
                  Navigator.pop(context);
                  await WhatsAppService.enviarMensaje(
                    telefono: telefono,
                    mensaje: mensaje,
                  );
                },
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
      ),
    );
  }

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
    _nombreTemporal.dispose();
    _telefonoTemporal.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar cita'),
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
      body: _pacientes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _seccion('Paciente'),    
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Registrado'),
                          selected: !_esPacienteTemporal,
                          onSelected: (_) =>
                              setState(() => _esPacienteTemporal = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Nuevo / Sin registro'),
                          selected: _esPacienteTemporal,
                          onSelected: (_) =>
                              setState(() => _esPacienteTemporal = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_esPacienteTemporal)
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
                      onChanged: (p) =>
                          setState(() => _pacienteSeleccionado = p),
                    )
                  else ...[
                    TextFormField(
                      controller: _nombreTemporal,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del paciente *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          _esPacienteTemporal && (v == null || v.trim().isEmpty)
                              ? 'Campo requerido'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoTemporal,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'WhatsApp (con código de país)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: '5212345678901',
                        helperText: 'Para enviar notificación de cita',
                      ),
                    ),
                  ],

                  _seccion('Especialidad'),
                  DropdownButtonFormField<Especialidad>(
                    initialValue: _especialidad,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: Especialidad.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.nombre),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _especialidad = v!),
                  ),
                  const SizedBox(height: 20),

                  _seccion('Estado de la cita'),
                  DropdownButtonFormField<EstadoCita>(
                    initialValue: _estado,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: EstadoCita.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.etiqueta),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _estado = v!),
                  ),
                  const SizedBox(height: 20),

                  _seccion('Fecha y hora'),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                              '${_fecha.day}/${_fecha.month}/${_fecha.year}'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _fecha,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
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
                    initialValue: _terapeutaSeleccionado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _terapeutas
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child:
                                  Text('${u.nombre} (${u.rol.etiqueta})'),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _terapeutaSeleccionado = v),
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
        padding: const EdgeInsets.only(bottom: 8),
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