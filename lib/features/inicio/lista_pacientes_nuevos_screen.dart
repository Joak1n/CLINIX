import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/paciente.dart';
import '../expediente/expediente_screen.dart';

/// Muestra el listado de pacientes registrados en un rango de fechas
/// (por defecto, el mes en curso).
class ListaPacientesNuevosScreen extends StatefulWidget {
  final DateTime? desde;
  final DateTime? hasta;
  final String titulo;

  const ListaPacientesNuevosScreen({
    super.key,
    this.desde,
    this.hasta,
    this.titulo = 'Pacientes nuevos del mes',
  });

  @override
  State<ListaPacientesNuevosScreen> createState() =>
      _ListaPacientesNuevosScreenState();
}

class _ListaPacientesNuevosScreenState
    extends State<ListaPacientesNuevosScreen> {
  late Future<List<Paciente>> _futurePacientes;

  @override
  void initState() {
    super.initState();
    _futurePacientes = _cargar();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<Paciente>> _cargar() async {
    final db = await DatabaseHelper.instance.database;
    final hoy = DateTime.now();
    final desde = widget.desde ?? DateTime(hoy.year, hoy.month, 1);

    final where = StringBuffer('created_at >= ?');
    final args = <Object?>[_fmt(desde)];
    if (widget.hasta != null) {
      where.write(' AND created_at <= ?');
      args.add('${_fmt(widget.hasta!)}T23:59:59');
    }

    final maps = await db.query(
      'pacientes',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );

    return maps.map((m) => Paciente.fromMap(m)).toList();
  }

  void _recargar() => setState(() => _futurePacientes = _cargar());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: FutureBuilder<List<Paciente>>(
        future: _futurePacientes,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final pacientes = snapshot.data!;
          if (pacientes.isEmpty) {
            return const Center(
              child: Text('No hay pacientes para mostrar',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pacientes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = pacientes[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        p.nombre.isNotEmpty
                            ? p.nombre[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      '${p.nombre} ${p.apellidoPaterno}'
                      '${p.apellidoMaterno != null ? ' ${p.apellidoMaterno}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpedienteScreen(paciente: p),
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
