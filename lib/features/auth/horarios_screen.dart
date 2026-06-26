import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/horario_atencion.dart';
import '../../core/services/horario_service.dart';
import '../../core/services/configuracion_service.dart';
import '../../core/database/database_helper.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<HorarioAtencion> _horarios = [];
  List<BloqueoHorario> _bloqueos = [];
  int _terapeutasSimultaneos = 1;
  int _duracionCita = 60;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final horarios = await HorarioService.obtenerHorarios();
    final bloqueos = await HorarioService.obtenerBloqueos();
    final terapeutas = await ConfiguracionService.getTerapeutasSimultaneos();
    final duracion = await ConfiguracionService.getDuracionCita();
    List<HorarioAtencion> lista = horarios;
    if (lista.isEmpty) {
      lista = List.generate(7, (i) {
        final dia = i + 1;
        return HorarioAtencion(
          diaSemana: dia,
          activo: dia <= 6,
          horaInicio: '09:00',
          horaFin: dia == 6 ? '14:00' : '18:00',
        );
      });
    }
    setState(() {
      _horarios = lista;
      _bloqueos = bloqueos;
      _terapeutasSimultaneos = terapeutas;
      _duracionCita = duracion;
      _cargando = false;
    });
  }

  Future<void> _guardarHorarios() async {
    setState(() => _guardando = true);
    await HorarioService.guardarTodos(_horarios);
    await ConfiguracionService.setTerapeutasSimultaneos(_terapeutasSimultaneos);
    await ConfiguracionService.setDuracionCita(_duracionCita);
    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horarios guardados')));
    }
  }

  void _actualizarHorario(int i, HorarioAtencion nuevo) =>
      setState(() => _horarios[i] = nuevo);

  Future<void> _seleccionarHora(int i, bool esInicio) async {
    final h = _horarios[i];
    final p = (esInicio ? h.horaInicio : h.horaFin).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final str = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _actualizarHorario(i, esInicio ? h.copyWith(horaInicio: str) : h.copyWith(horaFin: str));
  }

  Future<void> _agregarBloqueo() async {
    final resultado = await showDialog<BloqueoHorario>(
      context: context,
      builder: (_) => const _DialogoBloqueo(),
    );
    if (resultado != null) {
      await HorarioService.agregarBloqueo(resultado);
      await _cargar();
    }
  }

  Future<void> _eliminarBloqueo(BloqueoHorario b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar bloqueo'),
        content: Text('¿Eliminar el bloqueo del ${b.rangoFechaTexto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await HorarioService.eliminarBloqueo(b.id);
      await _cargar();
    }
  }

  Future<void> _enviarDisponibilidad() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (fecha == null || !mounted) return;

    // Cargar terapeutas activos
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('usuarios', where: 'activo = ?', whereArgs: [1]);
    final terapeutas = rows.map((r) => r['nombre'] as String).toList();

    if (!mounted) return;

    // Preguntar preferencia de terapeuta
    String? terapeutaSeleccionado = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoSeleccionTerapeuta(terapeutas: terapeutas),
    );

    // null = canceló el diálogo, '' = sin preferencia
    if (terapeutaSeleccionado == null || !mounted) return;

    final nombre = await ConfiguracionService.getNombreConsultorio();
    final mensaje = await HorarioService.generarMensajeDisponibilidad(
      fecha: fecha,
      duracionMinutos: _duracionCita,
      nombreConsultorio: nombre,
      terapeutaNombre: terapeutaSeleccionado.isEmpty ? null : terapeutaSeleccionado,
      terapeutasSimultaneos: _terapeutasSimultaneos,
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => _DialogoMensajeWhatsApp(mensaje: mensaje),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horarios y disponibilidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Color(0xFF25D366)),
            tooltip: 'Enviar disponibilidad por WhatsApp',
            onPressed: _enviarDisponibilidad,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Horarios'),
            Tab(icon: Icon(Icons.block_outlined), text: 'Bloqueos'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _TabHorarios(
                  horarios: _horarios,
                  terapeutasSimultaneos: _terapeutasSimultaneos,
                  duracionCita: _duracionCita,
                  onTerapeutasChanged: (v) => setState(() => _terapeutasSimultaneos = v),
                  onDuracionChanged: (v) => setState(() => _duracionCita = v),
                  onToggleDia: (i, val) => _actualizarHorario(i, _horarios[i].copyWith(activo: val)),
                  onSeleccionarHora: _seleccionarHora,
                  onGuardar: _guardando ? null : _guardarHorarios,
                  guardando: _guardando,
                ),
                _TabBloqueos(
                  bloqueos: _bloqueos,
                  onAgregar: _agregarBloqueo,
                  onEliminar: _eliminarBloqueo,
                ),
              ],
            ),
    );
  }
}

// ── Tab Horarios ─────────────────────────────────────────────────────────────

class _TabHorarios extends StatelessWidget {
  final List<HorarioAtencion> horarios;
  final int terapeutasSimultaneos;
  final int duracionCita;
  final ValueChanged<int> onTerapeutasChanged;
  final ValueChanged<int> onDuracionChanged;
  final void Function(int, bool) onToggleDia;
  final void Function(int, bool) onSeleccionarHora;
  final VoidCallback? onGuardar;
  final bool guardando;

  const _TabHorarios({
    required this.horarios,
    required this.terapeutasSimultaneos,
    required this.duracionCita,
    required this.onTerapeutasChanged,
    required this.onDuracionChanged,
    required this.onToggleDia,
    required this.onSeleccionarHora,
    required this.onGuardar,
    required this.guardando,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuración general',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.people_outline, size: 20, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Terapeutas simultáneos')),
                  _Contador(
                    valor: terapeutasSimultaneos,
                    min: 1,
                    max: 10,
                    onChanged: onTerapeutasChanged,
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.timer_outlined, size: 20, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Duración por cita')),
                  DropdownButton<int>(
                    value: duracionCita,
                    underline: const SizedBox(),
                    items: [30, 45, 60, 90, 120]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                        .toList(),
                    onChanged: (v) => onDuracionChanged(v ?? duracionCita),
                  ),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Horario por día',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ...List.generate(horarios.length, (i) {
          final h = horarios[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                SizedBox(
                  width: 48,
                  child: Text(h.nombreDiaCorto,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: h.activo ? Colors.teal : Colors.grey)),
                ),
                Switch(value: h.activo, onChanged: (v) => onToggleDia(i, v)),
                const Spacer(),
                if (h.activo) ...[
                  _BotonHora(hora: h.horaInicio, onTap: () => onSeleccionarHora(i, true)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('–', style: TextStyle(color: Colors.grey)),
                  ),
                  _BotonHora(hora: h.horaFin, onTap: () => onSeleccionarHora(i, false)),
                ] else
                  const Text('Cerrado', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onGuardar,
          icon: guardando
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: const Text('Guardar horarios'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BotonHora extends StatelessWidget {
  final String hora;
  final VoidCallback onTap;
  const _BotonHora({required this.hora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(hora,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  final int valor;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Contador({
    required this.valor, required this.min,
    required this.max, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: valor > min ? () => onChanged(valor - 1) : null,
          visualDensity: VisualDensity.compact,
        ),
        Text('$valor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: valor < max ? () => onChanged(valor + 1) : null,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Tab Bloqueos ─────────────────────────────────────────────────────────────

class _TabBloqueos extends StatelessWidget {
  final List<BloqueoHorario> bloqueos;
  final VoidCallback onAgregar;
  final void Function(BloqueoHorario) onEliminar;

  const _TabBloqueos({
    required this.bloqueos, required this.onAgregar, required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final isoHoy = '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    final futuros = bloqueos.where((b) => b.fechaFin.compareTo(isoHoy) >= 0).toList();
    final pasados = bloqueos.where((b) => b.fechaFin.compareTo(isoHoy) < 0).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: onAgregar,
          icon: const Icon(Icons.add),
          label: const Text('Agregar bloqueo'),
        ),
        const SizedBox(height: 20),
        if (futuros.isEmpty && pasados.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Column(children: [
                Icon(Icons.event_available_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('Sin bloqueos registrados', style: TextStyle(color: Colors.grey)),
              ]),
            ),
          ),
        if (futuros.isNotEmpty) ...[
          const Text('Próximos bloqueos',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          ...futuros.map((b) => _TarjetaBloqueo(bloqueo: b, onEliminar: () => onEliminar(b), pasado: false)),
        ],
        if (pasados.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Bloqueos anteriores',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          ...pasados.map((b) => _TarjetaBloqueo(bloqueo: b, onEliminar: () => onEliminar(b), pasado: true)),
        ],
      ],
    );
  }
}

class _TarjetaBloqueo extends StatelessWidget {
  final BloqueoHorario bloqueo;
  final VoidCallback onEliminar;
  final bool pasado;

  const _TarjetaBloqueo({required this.bloqueo, required this.onEliminar, required this.pasado});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: pasado ? Theme.of(context).colorScheme.surfaceContainerLowest : null,
      child: ListTile(
        leading: Icon(
          bloqueo.esDiaCompleto ? Icons.calendar_month_outlined : Icons.access_time_outlined,
          color: pasado ? Colors.grey : Colors.orange,
        ),
        title: Text(bloqueo.rangoFechaTexto,
            style: TextStyle(fontWeight: FontWeight.w600, color: pasado ? Colors.grey : null)),
        subtitle: Text(bloqueo.rangoHoraTexto),
        trailing: pasado
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onEliminar,
              ),
      ),
    );
  }
}

// ── Diálogo bloqueo ──────────────────────────────────────────────────────────

class _DialogoBloqueo extends StatefulWidget {
  const _DialogoBloqueo();

  @override
  State<_DialogoBloqueo> createState() => _DialogoBloqueoState();
}

class _DialogoBloqueoState extends State<_DialogoBloqueo> {
  bool _diaCompleto = true;
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();
  String _horaInicio = '12:00';
  String _horaFin = '14:00';
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _pickFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = picked;
        if (_fechaFin.isBefore(picked)) _fechaFin = picked;
      } else {
        _fechaFin = picked;
      }
    });
  }

  Future<void> _pickHora(bool esInicio) async {
    final p = (esInicio ? _horaInicio : _horaFin).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    final str = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => esInicio ? _horaInicio = str : _horaFin = str);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar bloqueo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Día(s) completo(s)'),
                    icon: Icon(Icons.calendar_month_outlined)),
                ButtonSegment(value: false, label: Text('Horario parcial'),
                    icon: Icon(Icons.access_time_outlined)),
              ],
              selected: {_diaCompleto},
              onSelectionChanged: (s) => setState(() => _diaCompleto = s.first),
            ),
            const SizedBox(height: 16),
            const Text('Fecha inicio', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _pickFecha(true),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_fmt(_fechaInicio)),
            ),
            const SizedBox(height: 12),
            const Text('Fecha fin', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _pickFecha(false),
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_fmt(_fechaFin)),
            ),
            if (!_diaCompleto) ...[
              const SizedBox(height: 16),
              const Text('Hora inicio', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _pickHora(true),
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(_horaInicio),
              ),
              const SizedBox(height: 12),
              const Text('Hora fin', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _pickHora(false),
                icon: const Icon(Icons.access_time, size: 18),
                label: Text(_horaFin),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional, interno)',
                border: OutlineInputBorder(),
                hintText: 'Ej. Junta, Vacaciones...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, BloqueoHorario(
              id: const Uuid().v4(),
              fechaInicio: _iso(_fechaInicio),
              fechaFin: _iso(_fechaFin),
              horaInicio: _diaCompleto ? null : _horaInicio,
              horaFin: _diaCompleto ? null : _horaFin,
              esDiaCompleto: _diaCompleto,
              motivo: _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim(),
              createdAt: DateTime.now().toIso8601String(),
            ));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

// ── Diálogo selección de terapeuta ──────────────────────────────────────────

class _DialogoSeleccionTerapeuta extends StatelessWidget {
  final List<String> terapeutas;
  const _DialogoSeleccionTerapeuta({required this.terapeutas});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Terapeuta preferido?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Opción sin preferencia
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.people_outline, size: 18),
            ),
            title: const Text('Sin preferencia'),
            subtitle: const Text('Muestra horarios con al menos un lugar libre'),
            onTap: () => Navigator.pop(context, ''),
          ),
          const Divider(),
          // Un tile por terapeuta
          ...terapeutas.map((nombre) => ListTile(
                leading: CircleAvatar(
                  child: Text(nombre[0].toUpperCase(),
                      style: const TextStyle(fontSize: 13)),
                ),
                title: Text(nombre),
                onTap: () => Navigator.pop(context, nombre),
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ── Diálogo mensaje WhatsApp ─────────────────────────────────────────────────

class _DialogoMensajeWhatsApp extends StatelessWidget {
  final String mensaje;
  const _DialogoMensajeWhatsApp({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.message, color: Color(0xFF25D366)),
        SizedBox(width: 8),
        Text('Disponibilidad'),
      ]),
      content: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDCF8C6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            mensaje,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          icon: const Icon(Icons.copy),
          label: const Text('Copiar'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: mensaje));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mensaje copiado al portapapeles')),
            );
          },
        ),
      ],
    );
  }
}