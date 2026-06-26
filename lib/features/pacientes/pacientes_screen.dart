import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paciente_provider.dart';
import 'nuevo_paciente_screen.dart';
import 'editar_paciente_screen.dart';
import '../expediente/expediente_screen.dart';

class PacientesScreen extends ConsumerStatefulWidget {
  const PacientesScreen({super.key});

  @override
  ConsumerState<PacientesScreen> createState() =>
      _PacientesScreenState();
}

class _PacientesScreenState
    extends ConsumerState<PacientesScreen> {
  final _searchController = TextEditingController();
  bool _buscando = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmarEliminar(
      BuildContext context, String id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar paciente'),
        content: Text(
          '¿Estás seguro de eliminar a $nombre?\n\n'
          'Se eliminarán también todas sus notas clínicas y citas. '
          'Esta acción no se puede deshacer.',
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

    if (confirmar == true) {
      await ref
          .read(pacientesProvider.notifier)
          .eliminar(id);
      ref.invalidate(pacientesFiltradosProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nombre eliminado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pacientesAsync =
        ref.watch(pacientesFiltradosProvider);
    final query = ref.watch(busquedaProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buscando
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar paciente...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => ref
                    .read(busquedaProvider.notifier)
                    .state = v,
              )
            : const Text('Pacientes'),
        actions: [
          // Botón buscar
          IconButton(
            icon: Icon(
                _buscando ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _buscando = !_buscando);
              if (!_buscando) {
                _searchController.clear();
                ref.read(busquedaProvider.notifier).state =
                    '';
              }
            },
          ),
          // Ordenamiento (solo cuando no está buscando)
          if (!_buscando)
            Consumer(
              builder: (context, ref, _) {
                final orden =
                    ref.watch(ordenPacientesProvider);
                return PopupMenuButton<OrdenPacientes>(
                  tooltip: 'Ordenar',
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(orden.icono, size: 20),
                      const SizedBox(width: 4),
                      Text(orden.etiquetaCorta,
                          style: const TextStyle(fontSize: 12)),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                  onSelected: (nuevoOrden) {
                    ref.read(ordenPacientesProvider.notifier).state = nuevoOrden;
                    ref.invalidate(pacientesFiltradosProvider);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      enabled: false,
                      height: 28,
                      child: Text('Por apellido',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    ...[OrdenPacientes.apellidoAsc, OrdenPacientes.apellidoDesc].map((o) =>
                      PopupMenuItem(
                        value: o,
                        child: Row(children: [
                          Icon(o.icono, size: 18),
                          const SizedBox(width: 8),
                          Text(o.etiqueta),
                          if (o == orden) ...[const Spacer(), const Icon(Icons.check, size: 16, color: Colors.teal)],
                        ]),
                      )),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      height: 28,
                      child: Text('Por nombre',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    ...[OrdenPacientes.nombreAsc, OrdenPacientes.nombreDesc].map((o) =>
                      PopupMenuItem(
                        value: o,
                        child: Row(children: [
                          Icon(o.icono, size: 18),
                          const SizedBox(width: 8),
                          Text(o.etiqueta),
                          if (o == orden) ...[const Spacer(), const Icon(Icons.check, size: 16, color: Colors.teal)],
                        ]),
                      )),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: OrdenPacientes.recientes,
                      child: Row(children: [
                        Icon(OrdenPacientes.recientes.icono, size: 18),
                        const SizedBox(width: 8),
                        Text(OrdenPacientes.recientes.etiqueta),
                        if (OrdenPacientes.recientes == orden) ...[const Spacer(), const Icon(Icons.check, size: 16, color: Colors.teal)],
                      ]),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const NuevoPacienteScreen()),
        ).then((_) {
          ref.invalidate(pacientesProvider);
          ref.invalidate(pacientesFiltradosProvider);
        }),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo paciente'),
      ),
      body: Column(
        children: [
          // Chip de búsqueda activa
          if (query.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Resultados para "$query"',
                      style: const TextStyle(
                          fontSize: 13),
                    ),
                  ),
                  pacientesAsync.when(
                    data: (p) => Text(
                      '${p.length} encontrado${p.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey),
                    ),
                    loading: () =>
                        const SizedBox.shrink(),
                    error: (_, _) =>
                        const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

          // Lista de pacientes
          Expanded(
            child: pacientesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (pacientes) {
                if (pacientes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          query.isNotEmpty
                              ? Icons.search_off
                              : Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isNotEmpty
                              ? 'Sin resultados para "$query"'
                              : 'Sin pacientes registrados',
                          style: const TextStyle(
                              color: Colors.grey),
                        ),
                        if (query.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(busquedaProvider
                                      .notifier)
                                  .state = '';
                              setState(
                                  () => _buscando = false);
                            },
                            child: const Text(
                                'Limpiar búsqueda'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pacientes.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = pacientes[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            p.nombre[0].toUpperCase(),
                            style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold),
                          ),
                        ),
                        title: _buscando &&
                                query.isNotEmpty
                            ? _textoResaltado(
                                p.nombreCompleto, query)
                            : Text(p.nombreCompleto),
                        subtitle: Text(
                            'Nacimiento: ${p.fechaNacimiento}'
                            '${p.telefono != null ? ' · ${p.telefono}' : ''}'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(
                              Icons.more_vert),
                          onSelected: (accion) async {
                            if (accion == 'editar') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditarPacienteScreen(
                                          paciente: p),
                                ),
                              );
                              ref.invalidate(
                                  pacientesProvider);
                              ref.invalidate(
                                  pacientesFiltradosProvider);
                            } else if (accion ==
                                'eliminar') {
                              await _confirmarEliminar(
                                  context,
                                  p.id,
                                  p.nombreCompleto);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'editar',
                              child: ListTile(
                                leading: Icon(
                                    Icons.edit_outlined),
                                title: Text('Editar'),
                                contentPadding:
                                    EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'eliminar',
                              child: ListTile(
                                leading: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red),
                                title: Text('Eliminar',
                                    style: TextStyle(
                                        color:
                                            Colors.red)),
                                contentPadding:
                                    EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ExpedienteScreen(
                                    paciente: p),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Resalta el texto buscado en el resultado
  Widget _textoResaltado(String texto, String query) {
    final lowerTexto = texto.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerTexto.indexOf(lowerQuery);

    if (index == -1) return Text(texto);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: texto.substring(0, index)),
          TextSpan(
            text: texto.substring(
                index, index + query.length),
            style: TextStyle(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
              text: texto.substring(
                  index + query.length)),
        ],
      ),
    );
  }
}