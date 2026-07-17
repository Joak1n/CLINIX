import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/usuario.dart';
import 'auth_provider.dart';

final _usuariosProvider = FutureProvider((ref) async {
  return ref.read(usuarioRepositoryProvider).obtenerTodos();
});

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(_usuariosProvider);
    final usuarioActual =
        ref.watch(authProvider).valueOrNull?.usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioNuevo(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
      ),
      body: usuariosAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (usuarios) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final u = usuarios[i];
            final esYoMismo =
                u.id == usuarioActual?.id;
            final esAdminPrincipal =
                u.email == 'admin@mediconfort.com';

            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    // ── Avatar ────────────────────────
                    CircleAvatar(
                      backgroundColor: _colorRol(u.rol),
                      child: Text(
                        u.nombre[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ── Info (expandido) ──────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fila 1: nombre + chip "Tú"
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  u.nombre,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 14),
                                  overflow:
                                      TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (esYoMismo) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets
                                      .symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal
                                        .withValues(
                                            alpha: 0.15),
                                    borderRadius:
                                        BorderRadius
                                            .circular(4),
                                  ),
                                  child: const Text('Tú',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.teal)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          // Fila 2: email · rol
                          Text(
                            '${u.email} · ${u.rol.etiqueta}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          // Fila 3: switch + acciones
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: u.activo,
                                    onChanged: esYoMismo
                                        ? null
                                        : (v) async {
                                            await ref
                                                .read(
                                                    usuarioRepositoryProvider)
                                                .actualizarEstado(
                                                    u.id, v);
                                            ref.invalidate(
                                                _usuariosProvider);
                                          },
                                  ),
                                  Text(
                                    u.activo
                                        ? 'Activo'
                                        : 'Inactivo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: u.activo
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.key_outlined,
                                        size: 18),
                                    visualDensity:
                                        VisualDensity
                                            .compact,
                                    tooltip:
                                        'Cambiar contraseña',
                                    onPressed: () =>
                                        _mostrarCambioPassword(
                                            context, ref, u),
                                  ),
                                  if (!esYoMismo)
                                    IconButton(
                                      icon: const Icon(
                                          Icons
                                              .delete_outline,
                                          size: 18,
                                          color:
                                              Colors.red),
                                      visualDensity:
                                          VisualDensity
                                              .compact,
                                      tooltip:
                                          'Eliminar usuario',
                                      onPressed: () =>
                                          _confirmarEliminar(
                                              context,
                                              ref,
                                              u),
                                    ),
                                ],
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
          },
        ),
      ),
    );
  }

  Color _colorRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.admin:
        return Colors.teal;
      case RolUsuario.terapeuta:
        return Colors.indigo;
      case RolUsuario.recepcionista:
        return Colors.orange;
    }
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Estás seguro de eliminar a ${usuario.nombre}?\n\n'
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
          .read(usuarioRepositoryProvider)
          .eliminar(usuario.id);
      ref.invalidate(_usuariosProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${usuario.nombre} eliminado')),
        );
      }
    }
  }

  void _mostrarFormularioNuevo(
      BuildContext context, WidgetRef ref) {
    final nombre = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    RolUsuario rol = RolUsuario.terapeuta;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nuevo usuario'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombre,
                    decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    keyboardType:
                        TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.length < 6)
                            ? 'Mínimo 6 caracteres'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RolUsuario>(
                    initialValue: rol,
                    decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder()),
                    items: RolUsuario.values
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.etiqueta),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => rol = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }
                try {
                  await ref
                      .read(usuarioRepositoryProvider)
                      .crear(
                        nombre: nombre.text,
                        email: email.text,
                        password: password.text,
                        rol: rol,
                      );
                  ref.invalidate(_usuariosProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Error: el correo ya existe')),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarCambioPassword(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Cambiar contraseña\n${usuario.nombre}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder()),
            validator: (v) =>
                (v == null || v.length < 6)
                    ? 'Mínimo 6 caracteres'
                    : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              await ref
                  .read(usuarioRepositoryProvider)
                  .cambiarPassword(
                      usuario.id, ctrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Contraseña actualizada')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

