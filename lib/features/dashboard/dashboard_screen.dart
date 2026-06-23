import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardProvider);
    final periodo = ref.watch(periodoDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          SegmentedButton<PeriodoDashboard>(
            segments: const [
              ButtonSegment(
                  value: PeriodoDashboard.semana,
                  label: Text('7d')),
              ButtonSegment(
                  value: PeriodoDashboard.mes,
                  label: Text('Mes')),
              ButtonSegment(
                  value: PeriodoDashboard.trimestre,
                  label: Text('3M')),
            ],
            selected: {periodo},
            onSelectionChanged: (v) => ref
                .read(periodoDashboardProvider.notifier)
                .state = v.first,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (data) => _buildDashboard(context, data),
      ),
    );
  }

  Widget _buildDashboard(
      BuildContext context, Map<String, dynamic> data) {
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cards de resumen ─────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                titulo: 'Total pacientes',
                valor: '${data['totalPacientes']}',
                icono: Icons.people,
                color: Colors.teal,
              ),
              _StatCard(
                titulo: 'Pacientes nuevos',
                valor: '${data['pacientesNuevos']}',
                icono: Icons.person_add,
                color: Colors.indigo,
              ),
              _StatCard(
                titulo: 'Total citas',
                valor: '${data['totalCitas']}',
                icono: Icons.calendar_month,
                color: Colors.orange,
              ),
              _StatCard(
                titulo: 'Tasa asistencia',
                valor: '${data['tasaAsistencia']}%',
                icono: Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Resumen de estados de citas ───────────────
          _SeccionTitulo(
              titulo: 'Estado de citas',
              icono: Icons.donut_large),
          const SizedBox(height: 12),
          _ResumenEstados(
            completadas: data['citasCompletadas'],
            canceladas: data['citasCanceladas'],
            noShow: data['citasNoShow'],
            total: data['totalCitas'],
          ),
          const SizedBox(height: 20),

          // ── Gráfica de citas por semana ───────────────
          if ((data['porSemana'] as List).isNotEmpty) ...[
            _SeccionTitulo(
                titulo: 'Citas por semana',
                icono: Icons.bar_chart),
            const SizedBox(height: 12),
            _GraficaBarras(
                semanas: data['porSemana'] as List),
            const SizedBox(height: 20),
          ],

          // ── Citas por especialidad ────────────────────
          if ((data['porEspecialidad'] as List)
              .isNotEmpty) ...[
            _SeccionTitulo(
                titulo: 'Por especialidad',
                icono: Icons.medical_services_outlined),
            const SizedBox(height: 12),
            _ListaRanking(
              items: data['porEspecialidad'] as List,
              labelKey: 'especialidad',
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
          ],

          // ── Citas por terapeuta ───────────────────────
          if ((data['porTerapeuta'] as List)
              .isNotEmpty) ...[
            _SeccionTitulo(
                titulo: 'Por terapeuta',
                icono: Icons.person_outline),
            const SizedBox(height: 12),
            _ListaRanking(
              items: data['porTerapeuta'] as List,
              labelKey: 'terapeuta',
              color: Colors.indigo,
            ),
            const SizedBox(height: 20),
          ],

          // ── Citas por día de semana ───────────────────
          if ((data['porDiaSemana'] as List)
              .isNotEmpty) ...[
            _SeccionTitulo(
                titulo: 'Día más ocupado',
                icono: Icons.today),
            const SizedBox(height: 12),
            _GraficaDiaSemana(
                dias: data['porDiaSemana'] as List),
            const SizedBox(height: 20),
          ],

          // ── Notas clínicas ────────────────────────────
          _StatCard(
            titulo: 'Notas clínicas registradas',
            valor: '${data['totalNotas']}',
            icono: Icons.description_outlined,
            color: Colors.purple,
            ancho: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final IconData icono;
  const _SeccionTitulo(
      {required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono,
            size: 18,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(titulo,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).colorScheme.primary,
            )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final bool ancho;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.ancho = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(valor,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenEstados extends StatelessWidget {
  final int completadas;
  final int canceladas;
  final int noShow;
  final int total;

  const _ResumenEstados({
    required this.completadas,
    required this.canceladas,
    required this.noShow,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _EstadoItem(
                label: 'Completadas',
                valor: completadas,
                color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(
            child: _EstadoItem(
                label: 'Canceladas',
                valor: canceladas,
                color: Colors.red)),
        const SizedBox(width: 8),
        Expanded(
            child: _EstadoItem(
                label: 'No show',
                valor: noShow,
                color: Colors.orange)),
      ],
    );
  }
}

class _EstadoItem extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;

  const _EstadoItem({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('$valor',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _GraficaBarras extends StatelessWidget {
  final List semanas;
  const _GraficaBarras({required this.semanas});

  @override
  Widget build(BuildContext context) {
    final maxY = semanas
            .map((s) => (s['count'] as int).toDouble())
            .fold(0.0, (a, b) => a > b ? a : b) +
        2;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i >= semanas.length)
                    return const SizedBox.shrink();
                  return Text(
                    semanas[i]['label'],
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles:
                    SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles:
                    SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Colors.grey,
              strokeWidth: 0.3,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: semanas
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['count'] as int)
                            .toDouble(),
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        width: 16,
                        borderRadius:
                            const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _GraficaDiaSemana extends StatelessWidget {
  final List dias;
  const _GraficaDiaSemana({required this.dias});

  static const _nombres = [
    'Dom', 'Lun', 'Mar', 'Mié',
    'Jue', 'Vie', 'Sáb'
  ];

  @override
  Widget build(BuildContext context) {
    final datos = List.filled(7, 0);
    for (final d in dias) {
      final dia = int.tryParse(d['dia'] ?? '0') ?? 0;
      if (dia < 7) datos[dia] = d['count'] as int;
    }

    final maxY =
        datos.fold(0, (a, b) => a > b ? a : b).toDouble() +
            1;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  _nombres[v.toInt()],
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles:
                    SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles:
                    SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Colors.grey,
              strokeWidth: 0.3,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: datos
              .asMap()
              .entries
              .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: e.value ==
                                datos.fold(0,
                                    (a, b) => a > b ? a : b)
                            ? Colors.teal
                            : Colors.teal.withOpacity(0.4),
                        width: 20,
                        borderRadius:
                            const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _ListaRanking extends StatelessWidget {
  final List items;
  final String labelKey;
  final Color color;

  const _ListaRanking({
    required this.items,
    required this.labelKey,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty
        ? 1
        : (items.first['count'] as int);

    return Column(
      children: items.take(5).map((item) {
        final label = item[labelKey] as String;
        final count = item['count'] as int;
        final porcentaje =
            maxCount > 0 ? count / maxCount : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje,
                    backgroundColor:
                        color.withOpacity(0.1),
                    valueColor:
                        AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

