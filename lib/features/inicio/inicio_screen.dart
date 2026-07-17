import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'inicio_provider.dart';
import '../../core/models/cita.dart';
import '../../core/models/usuario.dart';
import '../../core/models/nota_clinica.dart';
import '../agenda/agenda_screen.dart';
import 'lista_citas_mes_screen.dart';
import 'lista_pacientes_nuevos_screen.dart';

class InicioScreen extends ConsumerWidget {
  final Usuario usuario;
  const InicioScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(inicioProvider);
    final hoy = DateTime.now();
    const dias = [
      '', 'lunes', 'martes', 'miércoles',
      'jueves', 'viernes', 'sábado', 'domingo'
    ];
    const meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final fechaTexto =
        '${dias[hoy.weekday].substring(0, 1).toUpperCase()}'
        '${dias[hoy.weekday].substring(1)} '
        '${hoy.day} de ${meses[hoy.month]}';

    return Scaffold(
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(inicioProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Saludo ──────────────────────────────────────────
              _Saludo(
                nombre: usuario.nombre,
                fechaTexto: fechaTexto,
              ),
              const SizedBox(height: 20),

              // ── Stats rápidas del mes ────────────────────────────
              _SeccionTitulo(
                titulo: 'Resumen del mes',
                icono: Icons.bar_chart_outlined,
              ),
              const SizedBox(height: 10),
              _StatsDelMes(data: data),
              const SizedBox(height: 24),

              // ── Citas de hoy ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SeccionTitulo(
                      titulo: 'Citas de hoy',
                      icono: Icons.today_outlined,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AgendaScreen(),
                        ),
                      );
                    },
                    child: const Text('Ver agenda'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.citasHoy.isEmpty)
                _SinCitas()
              else
                ...data.citasHoy.map((c) => _TarjetaCitaHoy(cita: c)),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Saludo ───────────────────────────────────────────────────────────────────

class _Saludo extends StatelessWidget {
  final String nombre;
  final String fechaTexto;
  const _Saludo({required this.nombre, required this.fechaTexto});

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final primerNombre = nombre.split(' ').first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_saludo, $primerNombre',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fechaTexto,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats del mes ─────────────────────────────────────────────────────────────

class _StatsDelMes extends StatelessWidget {
  final InicioData data;
  const _StatsDelMes({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Total citas',
                valor: '${data.totalMes}',
                color: Theme.of(context).colorScheme.primary,
                icono: Icons.calendar_month_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListaCitasMesScreen(
                      titulo: 'Total de citas del mes',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'Pacientes nuevos',
                valor: '${data.pacientesNuevosMes}',
                color: Colors.indigo,
                icono: Icons.person_add_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListaPacientesNuevosScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Completadas',
                valor: '${data.completadasMes}',
                color: Colors.green,
                icono: Icons.check_circle_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListaCitasMesScreen(
                      titulo: 'Citas completadas del mes',
                      estado: EstadoCita.completada,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'Canceladas',
                valor: '${data.canceladasMes}',
                color: Colors.red,
                icono: Icons.cancel_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListaCitasMesScreen(
                      titulo: 'Citas canceladas del mes',
                      estado: EstadoCita.cancelada,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'No show',
                valor: '${data.noShowMes}',
                color: Colors.orange,
                icono: Icons.person_off_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ListaCitasMesScreen(
                      titulo: 'Citas con no show del mes',
                      estado: EstadoCita.noShow,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (data.totalMes > 0) ...[
          const SizedBox(height: 12),
          _BarraAsistencia(
            porcentaje: data.tasaAsistencia / 100,
            texto:
                'Tasa de asistencia: ${data.tasaAsistencia.toStringAsFixed(0)}%',
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final IconData icono;
  final VoidCallback? onTap;
  const _StatChip({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icono, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(valor,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraAsistencia extends StatelessWidget {
  final double porcentaje;
  final String texto;
  const _BarraAsistencia(
      {required this.porcentaje, required this.texto});

  Color get _color {
    if (porcentaje >= 0.8) return Colors.green;
    if (porcentaje >= 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(texto,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: porcentaje.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            color: _color,
          ),
        ),
      ],
    );
  }
}

// ── Sección título ────────────────────────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  const _SeccionTitulo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono,
            size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(titulo,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            )),
      ],
    );
  }
}

// ── Sin citas ─────────────────────────────────────────────────────────────────

class _SinCitas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_available_outlined,
              size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('No hay citas programadas para hoy',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Tarjeta cita de hoy ───────────────────────────────────────────────────────

class _TarjetaCitaHoy extends StatelessWidget {
  final Cita cita;
  const _TarjetaCitaHoy({required this.cita});

  Color get _colorEstado {
    switch (cita.estado) {
      case EstadoCita.completada:  return Colors.green;
      case EstadoCita.cancelada:   return Colors.red;
      case EstadoCita.noShow:      return Colors.orange;
      case EstadoCita.confirmada:  return Colors.teal;
    }
  }

  IconData get _iconoEstado {
    switch (cita.estado) {
      case EstadoCita.completada:  return Icons.check_circle;
      case EstadoCita.cancelada:   return Icons.cancel;
      case EstadoCita.noShow:      return Icons.person_off;
      case EstadoCita.confirmada:  return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Hora
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(
                  vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: _colorEstado.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                cita.hora,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _colorEstado,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cita.nombreMostrado,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cita.especialidad.nombre} · ${cita.terapeuta}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Estado
            Icon(_iconoEstado, color: _colorEstado, size: 20),
          ],
        ),
      ),
    );
  }
}