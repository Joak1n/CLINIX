import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/paciente.dart';
import '../../core/models/bitacora_sesion.dart';
import '../../core/services/bitacora_sync_service.dart';
import '../../core/services/supabase_service.dart';
import '../auth/auth_provider.dart';

// ── Provider ────────────────────────────────────────────────────────────────

final bitacoraProvider = FutureProvider.family<List<BitacoraSesion>, String>(
  (ref, pacienteId) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'bitacora_sesiones',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'numero_sesion DESC',
    );
    return maps.map((m) => BitacoraSesion.fromMap(m)).toList();
  },
);

// ── Pantalla principal ───────────────────────────────────────────────────────

class BitacoraProgresoScreen extends ConsumerWidget {
  final Paciente paciente;
  const BitacoraProgresoScreen({super.key, required this.paciente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesionesAsync = ref.watch(bitacoraProvider(paciente.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paciente.nombreCompleto,
                style: const TextStyle(fontSize: 16)),
            const Text('Bitácora de progreso',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final sesiones = sesionesAsync.valueOrNull ?? [];
          final siguiente = sesiones.isEmpty
              ? 1
              : (sesiones.map((s) => s.numeroSesion).reduce(
                      (a, b) => a > b ? a : b) +
                  1);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _NuevaSesionScreen(
                paciente: paciente,
                numeroSesion: siguiente,
                sesionesPrescritas:
                    sesiones.isEmpty ? null : sesiones.first.sesionesPrescitas,
              ),
            ),
          );
          ref.invalidate(bitacoraProvider(paciente.id));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva sesión'),
      ),
      body: sesionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sesiones) {
          if (sesiones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.track_changes_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Sin sesiones registradas',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Registra la primera sesión de este paciente',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          // Calcular estadísticas
          final totalSesiones = sesiones.length;
          final prescitas = sesiones.first.sesionesPrescitas;
          final evasRegistradas =
              sesiones.where((s) => s.dolorEva != null).toList();
          final promedioEva = evasRegistradas.isEmpty
              ? null
              : evasRegistradas
                      .map((s) => s.dolorEva!)
                      .reduce((a, b) => a + b) /
                  evasRegistradas.length;

          return Column(
            children: [
              // ── Panel de resumen ──
              _PanelResumen(
                totalSesiones: totalSesiones,
                sesionesPrescritas: prescitas,
                promedioEva: promedioEva,
                evaInicial: evasRegistradas.isEmpty
                    ? null
                    : sesiones.last.dolorEva,
                evaActual: evasRegistradas.isEmpty
                    ? null
                    : sesiones.first.dolorEva,
              ),
              const Divider(height: 1),
              // ── Lista de sesiones ──
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sesiones.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TarjetaSesion(
                    sesion: sesiones[i],
                    onEditar: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _EditarSesionScreen(
                            sesion: sesiones[i],
                          ),
                        ),
                      );
                      ref.invalidate(
                          bitacoraProvider(paciente.id));
                    },
                    onEliminar: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar sesión'),
                          content: Text(
                              '¿Eliminar la sesión ${sesiones[i].numeroSesion}?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final db =
                            await DatabaseHelper.instance.database;
                        await db.delete('bitacora_sesiones',
                            where: 'id = ?',
                            whereArgs: [sesiones[i].id]);
                        BitacoraSyncService.eliminarRegistro(sesiones[i].id);
                        ref.invalidate(
                            bitacoraProvider(paciente.id));
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Panel de resumen ─────────────────────────────────────────────────────────

class _PanelResumen extends StatelessWidget {
  final int totalSesiones;
  final int? sesionesPrescritas;
  final double? promedioEva;
  final int? evaInicial;
  final int? evaActual;

  const _PanelResumen({
    required this.totalSesiones,
    this.sesionesPrescritas,
    this.promedioEva,
    this.evaInicial,
    this.evaActual,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = sesionesPrescritas != null && sesionesPrescritas! > 0
        ? (totalSesiones / sesionesPrescritas!).clamp(0.0, 1.0)
        : null;
    final mejora = evaInicial != null && evaActual != null
        ? evaInicial! - evaActual!
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de progreso de sesiones
          Row(
            children: [
              const Icon(Icons.event_repeat_outlined,
                  size: 16, color: Colors.teal),
              const SizedBox(width: 6),
              Text(
                sesionesPrescritas != null
                    ? 'Sesión $totalSesiones de $sesionesPrescritas prescritas'
                    : '$totalSesiones sesiones registradas',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (progreso != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: progreso >= 1.0 ? Colors.green : Colors.teal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progreso * 100).toInt()}% completado',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
          if (mejora != null || promedioEva != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (mejora != null)
                  _Stat(
                    label: 'Mejora EVA',
                    valor: mejora > 0
                        ? '-$mejora pts'
                        : mejora < 0
                            ? '+${-mejora} pts'
                            : 'Sin cambio',
                    color: mejora > 0
                        ? Colors.green
                        : mejora < 0
                            ? Colors.red
                            : Colors.grey,
                  ),
                if (mejora != null && promedioEva != null)
                  const SizedBox(width: 24),
                if (promedioEva != null)
                  _Stat(
                    label: 'EVA promedio',
                    valor: promedioEva!.toStringAsFixed(1),
                    color: Colors.teal,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _Stat(
      {required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(valor,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ── Tarjeta de sesión ────────────────────────────────────────────────────────

class _TarjetaSesion extends StatelessWidget {
  final BitacoraSesion sesion;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _TarjetaSesion({
    required this.sesion,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final partes = sesion.fecha.split('-');
    final fechaFmt =
        partes.length == 3 ? '${partes[2]}/${partes[1]}/${partes[0]}' : sesion.fecha;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: número sesión + fecha + menú
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sesión ${sesion.numeroSesion}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(fechaFmt,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (v) {
                    if (v == 'editar') onEditar();
                    if (v == 'eliminar') onEliminar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'editar', child: Text('Editar')),
                    const PopupMenuItem(
                        value: 'eliminar',
                        child: Text('Eliminar',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // EVA
            if (sesion.dolorEva != null) ...[
              Row(
                children: [
                  const Text('Dolor EVA: ',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: sesion.evaColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sesion.evaTexto,
                      style: TextStyle(
                          fontSize: 12,
                          color: sesion.evaColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Campos de texto
            if (sesion.tratamientoRealizado != null)
              _Campo('Tratamiento', sesion.tratamientoRealizado!),
            if (sesion.respuestaTratamiento != null)
              _Campo('Respuesta', sesion.respuestaTratamiento!),
            if (sesion.ejerciciosRealizados != null)
              _Campo('Ejercicios', sesion.ejerciciosRealizados!),
            if (sesion.observaciones != null)
              _Campo('Observaciones', sesion.observaciones!),

            const SizedBox(height: 6),
            Text('Terapeuta: ${sesion.terapeuta}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  const _Campo(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$etiqueta: ',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(valor,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Formulario nueva sesión ──────────────────────────────────────────────────

class _NuevaSesionScreen extends ConsumerStatefulWidget {
  final Paciente paciente;
  final int numeroSesion;
  final int? sesionesPrescritas;

  const _NuevaSesionScreen({
    required this.paciente,
    required this.numeroSesion,
    this.sesionesPrescritas,
  });

  @override
  ConsumerState<_NuevaSesionScreen> createState() =>
      _NuevaSesionScreenState();
}

class _NuevaSesionScreenState extends ConsumerState<_NuevaSesionScreen> {
  final _tratamiento = TextEditingController();
  final _respuesta = TextEditingController();
  final _ejercicios = TextEditingController();
  final _observaciones = TextEditingController();
  final _sesionCtrl = TextEditingController();
  final _prescritasCtrl = TextEditingController();

  DateTime _fecha = DateTime.now();
  int _eva = 0;
  bool _registrarEva = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _sesionCtrl.text = widget.numeroSesion.toString();
    if (widget.sesionesPrescritas != null) {
      _prescritasCtrl.text = widget.sesionesPrescritas.toString();
    }
  }

  @override
  void dispose() {
    _tratamiento.dispose();
    _respuesta.dispose();
    _ejercicios.dispose();
    _observaciones.dispose();
    _sesionCtrl.dispose();
    _prescritasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final authState = ref.read(authProvider).valueOrNull;
      final terapeuta = authState?.usuario?.nombre ?? 'Terapeuta';
      final fecha =
          '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';

      final sesion = BitacoraSesion(
        id: const Uuid().v4(),
        pacienteId: widget.paciente.id,
        fecha: fecha,
        numeroSesion: int.tryParse(_sesionCtrl.text) ?? widget.numeroSesion,
        sesionesPrescitas: int.tryParse(_prescritasCtrl.text),
        terapeuta: terapeuta,
        dolorEva: _registrarEva ? _eva : null,
        tratamientoRealizado: _tratamiento.text.trim().isEmpty
            ? null
            : _tratamiento.text.trim(),
        respuestaTratamiento: _respuesta.text.trim().isEmpty
            ? null
            : _respuesta.text.trim(),
        ejerciciosRealizados: _ejercicios.text.trim().isEmpty
            ? null
            : _ejercicios.text.trim(),
        observaciones: _observaciones.text.trim().isEmpty
            ? null
            : _observaciones.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );

      final db = await DatabaseHelper.instance.database;
      await db.insert('bitacora_sesiones', sesion.toMap());
      BitacoraSyncService.subirRegistro(sesion.toMap());

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
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva sesión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Número sesión y prescritas
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sesionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'N° sesión',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _prescritasCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sesiones prescritas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment_outlined),
                    hintText: 'ej. 20',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fecha
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
                '${_fecha.day}/${_fecha.month}/${_fecha.year}'),
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _fecha,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _fecha = d);
            },
          ),
          const SizedBox(height: 20),

          // EVA
          Row(
            children: [
              const Text('Escala EVA de dolor',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(
                value: _registrarEva,
                onChanged: (v) =>
                    setState(() => _registrarEva = v),
              ),
            ],
          ),
          if (_registrarEva) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('0', style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: _eva.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$_eva',
                    onChanged: (v) =>
                        setState(() => _eva = v.round()),
                  ),
                ),
                const Text('10',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: BitacoraSesion(
                    id: '',
                    pacienteId: '',
                    fecha: '',
                    numeroSesion: 1,
                    terapeuta: '',
                    dolorEva: _eva,
                    createdAt: '',
                  ).evaColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  BitacoraSesion(
                    id: '',
                    pacienteId: '',
                    fecha: '',
                    numeroSesion: 1,
                    terapeuta: '',
                    dolorEva: _eva,
                    createdAt: '',
                  ).evaTexto,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: BitacoraSesion(
                      id: '',
                      pacienteId: '',
                      fecha: '',
                      numeroSesion: 1,
                      terapeuta: '',
                      dolorEva: _eva,
                      createdAt: '',
                    ).evaColor,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Campos clínicos
          _campo('Tratamiento realizado', _tratamiento,
              'Técnicas, modalidades aplicadas...', 3),
          const SizedBox(height: 12),
          _campo('Respuesta al tratamiento', _respuesta,
              'Reacción del paciente, cambios observados...', 2),
          const SizedBox(height: 12),
          _campo('Ejercicios realizados', _ejercicios,
              'Ejercicios indicados y repeticiones...', 2),
          const SizedBox(height: 12),
          _campo('Observaciones', _observaciones,
              'Notas adicionales...', 2),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Guardar sesión'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      String hint, int lines) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: lines > 1,
      ),
    );
  }
}

// ── Editar sesión existente ──────────────────────────────────────────────────

class _EditarSesionScreen extends StatefulWidget {
  final BitacoraSesion sesion;
  const _EditarSesionScreen({required this.sesion});

  @override
  State<_EditarSesionScreen> createState() => _EditarSesionScreenState();
}

class _EditarSesionScreenState extends State<_EditarSesionScreen> {
  late final TextEditingController _tratamiento;
  late final TextEditingController _respuesta;
  late final TextEditingController _ejercicios;
  late final TextEditingController _observaciones;
  late final TextEditingController _prescritasCtrl;
  late int _eva;
  late bool _registrarEva;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tratamiento = TextEditingController(
        text: widget.sesion.tratamientoRealizado ?? '');
    _respuesta = TextEditingController(
        text: widget.sesion.respuestaTratamiento ?? '');
    _ejercicios = TextEditingController(
        text: widget.sesion.ejerciciosRealizados ?? '');
    _observaciones = TextEditingController(
        text: widget.sesion.observaciones ?? '');
    _prescritasCtrl = TextEditingController(
        text: widget.sesion.sesionesPrescitas?.toString() ?? '');
    _eva = widget.sesion.dolorEva ?? 0;
    _registrarEva = widget.sesion.dolorEva != null;
  }

  @override
  void dispose() {
    _tratamiento.dispose();
    _respuesta.dispose();
    _ejercicios.dispose();
    _observaciones.dispose();
    _prescritasCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final cambios = {
        'sesiones_prescritas':
            int.tryParse(_prescritasCtrl.text),
        'dolor_eva': _registrarEva ? _eva : null,
        'tratamiento_realizado':
            _tratamiento.text.trim().isEmpty
                ? null
                : _tratamiento.text.trim(),
        'respuesta_tratamiento':
            _respuesta.text.trim().isEmpty
                ? null
                : _respuesta.text.trim(),
        'ejercicios_realizados':
            _ejercicios.text.trim().isEmpty
                ? null
                : _ejercicios.text.trim(),
        'observaciones': _observaciones.text.trim().isEmpty
            ? null
            : _observaciones.text.trim(),
      };
      await db.update(
        'bitacora_sesiones',
        cambios,
        where: 'id = ?',
        whereArgs: [widget.sesion.id],
      );
      try {
        await SupabaseService.client
            .from('bitacora_sesiones')
            .update(cambios)
            .eq('id', widget.sesion.id);
      } catch (_) {}
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
    return Scaffold(
      appBar: AppBar(
          title: Text('Sesión ${widget.sesion.numeroSesion}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _prescritasCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sesiones prescritas',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.assignment_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Escala EVA',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              Switch(
                value: _registrarEva,
                onChanged: (v) =>
                    setState(() => _registrarEva = v),
              ),
            ],
          ),
          if (_registrarEva) ...[
            Row(
              children: [
                const Text('0',
                    style: TextStyle(color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: _eva.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$_eva',
                    onChanged: (v) =>
                        setState(() => _eva = v.round()),
                  ),
                ),
                const Text('10',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _campo('Tratamiento realizado', _tratamiento, 3),
          const SizedBox(height: 12),
          _campo('Respuesta al tratamiento', _respuesta, 2),
          const SizedBox(height: 12),
          _campo('Ejercicios realizados', _ejercicios, 2),
          const SizedBox(height: 12),
          _campo('Observaciones', _observaciones, 2),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Guardar cambios'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _campo(
      String label, TextEditingController ctrl, int lines) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        alignLabelWithHint: lines > 1,
      ),
    );
  }
}