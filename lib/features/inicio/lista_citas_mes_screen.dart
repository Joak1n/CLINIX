import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/cita.dart';
import '../agenda/editar_cita_screen.dart';

/// Muestra el listado de citas en un rango de fechas (por defecto, el mes
/// en curso), opcionalmente filtradas por estado (completadas, canceladas,
/// no show). Si [estado] es null, se muestran todas las citas del rango.
class ListaCitasMesScreen extends StatefulWidget {
  final String titulo;
  final EstadoCita? estado;
  final DateTime? desde;
  final DateTime? hasta;

  const ListaCitasMesScreen({
    super.key,
    required this.titulo,
    this.estado,
    this.desde,
    this.hasta,
  });

  @override
  State<ListaCitasMesScreen> createState() => _ListaCitasMesScreenState();
}

class _ListaCitasMesScreenState extends State<ListaCitasMesScreen> {
  late Future<List<Cita>> _futureCitas;

  @override
  void initState() {
    super.initState();
    _futureCitas = _cargar();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Cita>> _cargar() async {
    final db = await DatabaseHelper.instance.database;
    final hoy = DateTime.now();
    final desde = widget.desde ?? DateTime(hoy.year, hoy.month, 1);

    final where = StringBuffer('c.fecha >= ?');
    final args = <Object?>[_fmt(desde)];
    if (widget.hasta != null) {
      where.write(' AND c.fecha <= ?');
      args.add(_fmt(widget.hasta!));
    }
    if (widget.estado != null) {
      where.write(' AND c.estado = ?');
      args.add(widget.estado!.valor);
    }

    final maps = await db.rawQuery('''
      SELECT c.*,
        CASE
          WHEN c.paciente_id IS NOT NULL
          THEN p.nombre || ' ' || p.apellido_paterno
          ELSE c.nombre_temporal
        END AS nombre_paciente
      FROM citas c
      LEFT JOIN pacientes p ON c.paciente_id = p.id
      WHERE ${where.toString()}
      ORDER BY c.fecha DESC, c.hora DESC
    ''', args);

    return maps.map((m) => Cita.fromMap(m)).toList();
  }

  void _recargar() => setState(() => _futureCitas = _cargar());

  String _formatearFechaCorta(String fechaIso) {
    final partes = fechaIso.split('-');
    if (partes.length != 3) return fechaIso;
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    final mes = int.tryParse(partes[1]) ?? 1;
    return '${partes[2]} ${meses[mes - 1]}';
  }

  Color _colorEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.completada: return Colors.green;
      case EstadoCita.cancelada:  return Colors.red;
      case EstadoCita.noShow:     return Colors.orange;
      case EstadoCita.confirmada: return Colors.teal;
    }
  }

  IconData _iconoEstado(EstadoCita e) {
    switch (e) {
      case EstadoCita.completada: return Icons.check_circle;
      case EstadoCita.cancelada:  return Icons.cancel;
      case EstadoCita.noShow:     return Icons.person_off;
      case EstadoCita.confirmada: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: FutureBuilder<List<Cita>>(
        future: _futureCitas,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final citas = snapshot.data!;
          if (citas.isEmpty) {
            return const Center(
              child: Text('No hay citas para mostrar',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: citas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = citas[i];
                final color = _colorEstado(c.estado);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(_iconoEstado(c.estado), color: color),
                    ),
                    title: Text(c.nombreMostrado,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${_formatearFechaCorta(c.fecha)} · ${c.hora} · '
                      '${c.especialidad.nombre} · ${c.terapeuta}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarCitaScreen(cita: c),
                        ),
                      );
                      _recargar();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
