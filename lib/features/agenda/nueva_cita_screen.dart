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
  final _nombreTemporal = TextEditingController();
  final _telefonoTemporal = TextEditingController();
  final _busqueda = TextEditingController();

  Especialidad _especialidad = Especialidad.fisioterapia;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  int _duracion = 60;

  // Selección de paciente
  bool _esPacienteTemporal = false;
  Paciente? _pacienteSeleccionado;
  List<Paciente> _pacientes = [];
  List<Paciente> _pacientesFiltrados = [];

  List<Usuario> _terapeutas = [];
  Usuario? _terapeutaSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarPacientes();
    _cargarTerapeutas();
    _busqueda.addListener(_filtrarPacientes);
  }

  @override
  void dispose() {
    _notas.dispose();
    _nombreTemporal.dispose();
    _telefonoTemporal.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargarPacientes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('pacientes', orderBy: 'apellido_paterno ASC');
    setState(() {
      _pacientes = maps.map((m) => Paciente.fromMap(m)).toList();
      _pacientesFiltrados = _pacientes;
    });
  }

  Future<void> _cargarTerapeutas() async {
    final usuarios = await ref.read(usuarioRepositoryProvider).obtenerTodos();
    setState(() {
      _terapeutas = usuarios.where((u) => u.activo).toList();
    });
  }

  void _filtrarPacientes() {
    final q = _busqueda.text.toLowerCase();
    setState(() {
      _pacientesFiltrados = _pacientes.where((p) {
        return p.nombreCompleto.toLowerCase().contains(q) ||
            (p.telefono ?? '').contains(q);
      }).toList();
    });
  }

  String _formatFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar selección de paciente
    if (!_esPacienteTemporal && _pacienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un paciente o usa "Sin registrar"')),
      );
      return;
    }
    if (_esPacienteTemporal && _nombreTemporal.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre del paciente')),
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
            pacienteId: _esPacienteTemporal ? null : _pacienteSeleccionado!.id,
            nombreTemporal: _esPacienteTemporal ? _nombreTemporal.text.trim() : null,
            telefonoTemporal: _esPacienteTemporal && _telefonoTemporal.text.trim().isNotEmpty
                ? _telefonoTemporal.text.trim()
                : null,
            especialidad: _especialidad,
            fecha: _formatFecha(_fecha),
            hora: _formatHora(_hora),
            duracionMinutos: _duracion,
            terapeuta: _terapeutaSeleccionado!.nombre,
            notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
          );

      if (mounted) {
        if (_esPacienteTemporal &&
            _telefonoTemporal.text.trim().isNotEmpty) {
          // Ofrecer WhatsApp para paciente temporal
          await _dialogoWhatsAppTemporal(cita);
        } else if (!_esPacienteTemporal) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _DialogoCitaGuardada(
              cita: cita,
              paciente: _pacienteSeleccionado!,
            ),
          );
        } else {
          // Temporal sin teléfono — solo confirmar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cita guardada correctamente')),
            );
          }
        }
        if (mounted) Navigator.pop(context);
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

  Future<void> _dialogoWhatsAppTemporal(Cita cita) async {
    final partes = cita.fecha.split('-');
    final fechaFmt = '${partes[2]}/${partes[1]}/${partes[0]}';
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.teal),
          SizedBox(width: 8),
          Text('Cita agendada'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cita registrada para ${cita.nombreTemporal}'),
            const SizedBox(height: 4),
            Text('$fechaFmt a las ${cita.hora}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('¿Notificar al paciente por WhatsApp?',
                style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, cerrar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.message),
            label: const Text('Notificar'),
            onPressed: () async {
              Navigator.pop(context);
              // El widget BotonWhatsAppCitaNueva necesita Paciente,
              // aquí enviamos directo con los datos temporales
              final mensaje =
                  'Hola ${cita.nombreTemporal}!\n\n'
                  'Tu cita ha sido registrada:\n\n'
                  '*Fecha:* $fechaFmt\n'
                  '*Hora:* ${cita.hora}\n'
                  '*Servicio:* ${cita.especialidad.nombre}\n\n'
                  'Te esperamos!';
              final uri = Uri.parse(
                  'https://wa.me/${cita.telefonoTemporal}?text=${Uri.encodeComponent(mensaje)}');
              // ignore: deprecated_member_use
              // Usar url_launcher si está disponible
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Abriendo WhatsApp para ${cita.nombreTemporal}')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _abrirBuscadorPaciente() async {
    _busqueda.clear();
    _filtrarPacientes();
    final resultado = await showModalBottomSheet<Paciente>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.95,
            builder: (_, ctrl) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seleccionar paciente',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _busqueda,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o teléfono...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (_) {
                          _filtrarPacientes();
                          setModal(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _pacientesFiltrados.isEmpty
                      ? const Center(
                          child: Text('No se encontraron pacientes',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          controller: ctrl,
                          itemCount: _pacientesFiltrados.length,
                          itemBuilder: (_, i) {
                            final p = _pacientesFiltrados[i];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(p.nombre[0].toUpperCase()),
                              ),
                              title: Text(p.nombreCompleto),
                              subtitle: p.telefono != null
                                  ? Text(p.telefono!)
                                  : null,
                              onTap: () => Navigator.pop(ctx, p),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        _pacienteSeleccionado = resultado;
        _esPacienteTemporal = false;
      });
    }
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
            // ── SECCIÓN PACIENTE ──
            _seccion('Paciente'),
            // Toggle registrado / temporal
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Paciente registrado'),
                    selected: !_esPacienteTemporal,
                    onSelected: (_) =>
                        setState(() => _esPacienteTemporal = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Sin registrar'),
                    selected: _esPacienteTemporal,
                    onSelected: (_) =>
                        setState(() => _esPacienteTemporal = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!_esPacienteTemporal) ...[
              // Selector de paciente registrado
              InkWell(
                onTap: _abrirBuscadorPaciente,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Toca para buscar paciente',
                    suffixIcon: _pacienteSeleccionado != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setState(() => _pacienteSeleccionado = null),
                          )
                        : const Icon(Icons.search),
                  ),
                  child: _pacienteSeleccionado != null
                      ? Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              child: Text(
                                  _pacienteSeleccionado!.nombre[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_pacienteSeleccionado!.nombreCompleto,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  if (_pacienteSeleccionado!.telefono != null)
                                    Text(_pacienteSeleccionado!.telefono!,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : const Text('Buscar paciente...',
                          style: TextStyle(color: Colors.grey)),
                ),
              ),
            ] else ...[
              // Campos para paciente temporal
              TextFormField(
                controller: _nombreTemporal,
                decoration: const InputDecoration(
                  labelText: 'Nombre del paciente *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => _esPacienteTemporal &&
                        (v == null || v.trim().isEmpty)
                    ? 'Campo requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoTemporal,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'Con código de país ej. 521...',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Puedes registrar al paciente después desde el expediente.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],

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
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
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
              validator: (v) => v == null ? 'Selecciona un terapeuta' : null,
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