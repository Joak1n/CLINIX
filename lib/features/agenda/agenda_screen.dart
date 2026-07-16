import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/cita.dart';
import 'agenda_provider.dart';
import 'nueva_cita_screen.dart';
import '../../core/models/nota_clinica.dart';
import 'editar_cita_screen.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/paciente.dart';
import '../../shared/widgets/whatsapp_buttons.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/services/configuracion_service.dart';

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  String _formatearFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _etiquetaDia(DateTime d) {
    final hoy = DateTime.now();
    if (d.year == hoy.year && d.month == hoy.month && d.day == hoy.day) {
      return 'Hoy';
    }
    final manana = hoy.add(const Duration(days: 1));
    if (d.year == manana.year &&
        d.month == manana.month &&
        d.day == manana.day) {
      return 'Mañana';
    }
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dias[d.weekday - 1]} ${d.day} ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fechaSeleccionada = ref.watch(fechaSeleccionadaProvider);
    final fechaStr = _formatearFecha(fechaSeleccionada);
    final citasAsync = ref.watch(citasDelDiaProvider(fechaStr));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Recordatorios del día',
            onPressed: () => _mostrarRecordatorios(context, ref, fechaStr),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NuevaCitaScreen()),
        ).then((_) => ref.invalidate(citasDelDiaProvider(fechaStr))),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
      ),
      body: Column(
        children: [
          FutureBuilder<List<String>>(
            future: _pacientesCumpleanios(),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final nombres = snapshot.data!;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade400,
                      Colors.orange.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🎂',
                        style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Cumpleaños hoy!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            nombres.join(', '),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message,
                          color: Colors.white),
                      tooltip: 'Felicitar por WhatsApp',
                      onPressed: () =>
                          _felicitarPorWhatsApp(
                              context, nombres),
                    ),
                  ],
                ),
              );
            },
          ),
          // Selector de días (scroll horizontal)
          _SelectorDias(
            seleccionado: fechaSeleccionada,
            etiqueta: _etiquetaDia,
            onSeleccionar: (d) =>
                ref.read(fechaSeleccionadaProvider.notifier).state = d,
          ),
          const Divider(height: 1),
          // Lista de citas
          Expanded(
            child: citasAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (citas) {
                if (citas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available,
                            size: 56, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Sin citas para ${_etiquetaDia(fechaSeleccionada)}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: citas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TarjetaCita(
                    cita: citas[i],
                    onCambiarEstado: (estado) => ref
                        .read(citasDelDiaProvider(fechaStr).notifier)
                        .actualizarEstado(citas[i].id, estado),
                    onEliminar: () => ref
                        .read(citasDelDiaProvider(fechaStr).notifier)
                        .eliminar(citas[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Future<List<String>> _pacientesCumpleanios() async {
    final db = await DatabaseHelper.instance.database;
    final hoy = DateTime.now();
    final mes = hoy.month.toString().padLeft(2, '0');
    final dia = hoy.day.toString().padLeft(2, '0'  );
    final maps = await db.rawQuery(
      "SELECT nombre, apellido_paterno FROM pacientes "
      "WHERE strftime('%m-%d', fecha_nacimiento) = ?",
      ['$mes-$dia'],
    );
    return maps
        .map((m) => '${m['nombre']} ${m['apellido_paterno']}')
        .toList();
  }
}

class _SelectorDias extends StatelessWidget {
  final DateTime seleccionado;
  final String Function(DateTime) etiqueta;
  final ValueChanged<DateTime> onSeleccionar;

  const _SelectorDias({
    required this.seleccionado,
    required this.etiqueta,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = List.generate(14, (i) => hoy.add(Duration(days: i - 3)));

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: dias.length,
        itemBuilder: (context, i) {
          final d = dias[i];
          final activo = d.year == seleccionado.year &&
              d.month == seleccionado.month &&
              d.day == seleccionado.day;
          return GestureDetector(
            onTap: () => onSeleccionar(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: activo
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activo
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                etiqueta(d),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      activo ? FontWeight.w600 : FontWeight.normal,
                  color: activo ? Colors.white : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaCita extends StatelessWidget {
  final Cita cita;
  final ValueChanged<EstadoCita> onCambiarEstado;
  final VoidCallback onEliminar;

  const _TarjetaCita({
    required this.cita,
    required this.onCambiarEstado,
    required this.onEliminar,
  });

  Color _colorEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.confirmada:   return Colors.teal;
      case EstadoCita.completada:   return Colors.green;
      case EstadoCita.cancelada:    return Colors.red;
      case EstadoCita.noShow:       return Colors.orange;
    }
  }

  @override
    Widget build(BuildContext context) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Hora ──────────────────────────────────────────
              SizedBox(
                width: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cita.hora,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${cita.duracionMinutos}m',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              // ── Barra de color ─────────────────────────────────
              Container(
                width: 3,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _colorEstado(cita.estado),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Info (expandido) ───────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fila 1: nombre + chip estado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cita.nombreMostrado,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _ChipEstado(
                          estado: cita.estado,
                          color: _colorEstado(cita.estado),
                          onChanged: (nuevoEstado) async {
                            onCambiarEstado(nuevoEstado);
                            if (nuevoEstado == EstadoCita.cancelada &&
                                context.mounted) {
                              _ofrecerNotificarCancelacion(context);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Fila 2: especialidad · terapeuta
                    Text(
                      '${cita.especialidad.nombre} · ${cita.terapeuta}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // Fila 3: botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar cita',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditarCitaScreen(cita: cita),
                            ),
                          ).then((actualizado) {
                            if (actualizado == true) onCambiarEstado(cita.estado);
                          }),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          tooltip: 'Eliminar cita',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Eliminar cita'),
                                content: Text(
                                  '¿Eliminar la cita de ${cita.nombreMostrado} '
                                  'del ${cita.fecha} a las ${cita.hora}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmar == true) onEliminar();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

  Future<void> _ofrecerNotificarCancelacion(BuildContext context) async {
    if (cita.pacienteId == null) return; // paciente temporal, sin expediente
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('pacientes',
        where: 'id = ?', whereArgs: [cita.pacienteId], limit: 1);
    if (maps.isEmpty || !context.mounted) return;
    final paciente = Paciente.fromMap(maps.first);
    if (paciente.telefono == null || paciente.telefono!.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cita cancelada'),
        content: Text(
            '¿Deseas notificar a ${paciente.nombre} '
            'sobre la cancelación por WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366)),
            icon: const Icon(Icons.message),
            label: const Text('Notificar'),
            onPressed: () async {
              Navigator.pop(context);
              final partes = cita.fecha.split('-');
              final fechaFmt =
                  '${partes[2]}/${partes[1]}/${partes[0]}';
              final mensaje = await WhatsAppService.mensajeCancelacion(
                nombrePaciente: paciente.nombre,
                fecha: fechaFmt,
                hora: cita.hora,
              );
              await WhatsAppService.enviarMensaje(
                telefono: paciente.telefono!,
                mensaje: mensaje,
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _felicitarPorWhatsApp(
    BuildContext context, List<String> nombres) async {
  final db = await DatabaseHelper.instance.database;
  final hoy = DateTime.now();
  final mes = hoy.month.toString().padLeft(2, '0');
  final dia = hoy.day.toString().padLeft(2, '0');

  final maps = await db.rawQuery(
    "SELECT nombre, apellido_paterno, telefono "
    "FROM pacientes "
    "WHERE strftime('%m-%d', fecha_nacimiento) = ? "
    "AND telefono IS NOT NULL",
    ['$mes-$dia'],
  );

  if (maps.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Los pacientes no tienen teléfono registrado')),
      );
    }
    return;
  }

  final nombreConsultorio =
      await ConfiguracionService.getNombreConsultorio();

  for (final p in maps) {
    final nombre =
        '${p['nombre']} ${p['apellido_paterno']}';
    final telefono = p['telefono'] as String;
    final mensaje =
        '¡Feliz cumpleaños $nombre!\n\n'
        'Todo el equipo de *$nombreConsultorio* '
        'te desea un maravilloso día lleno de salud y alegría.\n\n'
        '¡Que los cumplas muy feliz!';

    await WhatsAppService.enviarMensaje(
      telefono: telefono,
      mensaje: mensaje,
    );
  }
}

Future<void> _mostrarRecordatorios(
    BuildContext context, WidgetRef ref, String fechaStr) async {
  final citas = ref.read(citasDelDiaProvider(fechaStr)).valueOrNull ?? [];

  if (citas.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay citas para hoy')),
    );
    return;
  }

  // Cargar pacientes de las citas del día (solo citas con paciente registrado)
  final db = await DatabaseHelper.instance.database;
  final citasConPaciente = citas.where((c) => c.pacienteId != null).toList();
  final ids = citasConPaciente.map((c) => "'${c.pacienteId}'").join(',');
  final Map<String, Paciente> pacientes = {};
  if (ids.isNotEmpty) {
    final maps = await db.rawQuery(
        'SELECT * FROM pacientes WHERE id IN ($ids)');
    pacientes.addAll({
      for (final m in maps) m['id'] as String: Paciente.fromMap(m)
    });
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.message, color: Color(0xFF25D366)),
                const SizedBox(width: 8),
                Text(
                  'Recordatorios — ${citas.length} citas',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.all(12),
              itemCount: citas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final cita = citas[i];
                // Paciente temporal: mostrar con datos del campo nombreTemporal
                if (cita.esPacienteTemporal) {
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline, size: 18),
                    ),
                    title: Text(cita.nombreTemporal ?? 'Paciente sin nombre'),
                    subtitle: Text(
                        '${cita.hora} · ${cita.especialidad.nombre} · Sin registrar'),
                  );
                }
                final paciente = pacientes[cita.pacienteId];
                if (paciente == null) return const SizedBox.shrink();
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8),
                  leading: CircleAvatar(
                    child: Text(paciente.nombre[0].toUpperCase()),
                  ),
                  title: Text(paciente.nombreCompleto),
                  subtitle: Text(
                      '${cita.hora} · ${cita.especialidad.nombre}'),
                  trailing: BotonWhatsAppRecordatorio(
                    cita: cita,
                    paciente: paciente,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
// ── Chip de estado con popup ─────────────────────────────────────────────────

class _ChipEstado extends StatelessWidget {
  final EstadoCita estado;
  final Color color;
  final ValueChanged<EstadoCita> onChanged;

  const _ChipEstado({
    required this.estado,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EstadoCita>(
      tooltip: 'Cambiar estado',
      onSelected: onChanged,
      itemBuilder: (_) => EstadoCita.values
          .map((e) => PopupMenuItem(
                value: e,
                child: Text(e.etiqueta),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          estado.etiqueta,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}