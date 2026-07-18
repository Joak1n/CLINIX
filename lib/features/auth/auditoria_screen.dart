import 'package:flutter/material.dart';
import '../../core/models/registro_auditoria.dart';
import '../../core/services/auditoria_service.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  late Future<List<RegistroAuditoria>> _future;
  String? _filtroEntidad;

  @override
  void initState() {
    super.initState();
    _future = AuditoriaService.obtenerRegistros();
  }

  void _recargar() {
    setState(() {
      _future = AuditoriaService.obtenerRegistros(entidad: _filtroEntidad);
    });
  }

  Color _colorAccion(String accion) {
    switch (accion) {
      case 'crear':
        return Colors.green;
      case 'eliminar':
        return Colors.red;
      case 'cambiar_estado':
        return Colors.orange;
      default:
        return Colors.indigo;
    }
  }

  String _formatearFecha(String iso) {
    try {
      final d = DateTime.parse(iso);
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final hora = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '${d.day} ${meses[d.month - 1]} · $hora:$min';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoría'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('Todo', null),
                  const SizedBox(width: 8),
                  _chipFiltro('Citas', 'cita'),
                  const SizedBox(width: 8),
                  _chipFiltro('Pacientes', 'paciente'),
                  const SizedBox(width: 8),
                  _chipFiltro('Usuarios', 'usuario'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<RegistroAuditoria>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final registros = snapshot.data!;
          if (registros.isEmpty) {
            return const Center(
              child: Text('Sin actividad registrada',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: registros.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final r = registros[i];
                final color = _colorAccion(r.accion);
                return Card(
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(r.iconoAccion,
                          style: const TextStyle(fontSize: 15)),
                    ),
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: r.usuarioNombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' ${r.etiquetaAccion} ${r.etiquetaEntidad}'),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: Text(
                      [
                        _formatearFecha(r.fecha),
                        if (r.detalle != null && r.detalle!.isNotEmpty) r.detalle!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _chipFiltro(String label, String? entidad) {
    final seleccionado = _filtroEntidad == entidad;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) {
        setState(() => _filtroEntidad = entidad);
        _recargar();
      },
    );
  }
}
