import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/nota_interna.dart';
import 'nota_interna_provider.dart';

class NotasInternasWidget extends ConsumerStatefulWidget {
  final String notaClinicaId;
  final String pacienteId;
  final String autorActual;

  const NotasInternasWidget({
    super.key,
    required this.notaClinicaId,
    required this.pacienteId,
    required this.autorActual,
  });

  @override
  ConsumerState<NotasInternasWidget> createState() =>
      _NotasInternasWidgetState();
}

class _NotasInternasWidgetState
    extends ConsumerState<NotasInternasWidget> {
  final _ctrl = TextEditingController();
  bool _expandido = false;
  bool _guardando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _guardando = true);
    try {
      await ref
          .read(notasInternasProvider(widget.notaClinicaId)
              .notifier)
          .agregar(
            pacienteId: widget.pacienteId,
            contenido: _ctrl.text.trim(),
            autor: widget.autorActual,
          );
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _confirmarEliminar(NotaInterna nota) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar nota'),
        content:
            const Text('¿Eliminar esta nota interna?'),
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
          .read(notasInternasProvider(widget.notaClinicaId)
              .notifier)
          .eliminar(nota.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notasAsync = ref.watch(
        notasInternasProvider(widget.notaClinicaId));
    final totalNotas =
        notasAsync.valueOrNull?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado colapsable
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () =>
                setState(() => _expandido = !_expandido),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Notas internas privadas',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800),
                  ),
                  const SizedBox(width: 6),
                  if (totalNotas > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalNotas',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    'No se incluyen en el PDF',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.amber.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expandido
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: Colors.amber.shade700,
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandido
          if (_expandido) ...[
            Divider(
                height: 1, color: Colors.amber.shade200),
            // Lista de notas existentes
            notasAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                    child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Error: $e'),
              ),
              data: (notas) {
                if (notas.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Sin notas internas aún.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade600,
                          fontStyle: FontStyle.italic),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  itemCount: notas.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: Colors.amber.shade100),
                  itemBuilder: (_, i) {
                    final nota = notas[i];
                    return Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_outlined,
                            size: 14,
                            color: Colors.amber.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(nota.contenido,
                                  style: const TextStyle(
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                '${nota.autor} · ${nota.fechaFormateada}',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors
                                        .amber.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 16,
                              color: Colors.amber.shade700),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(),
                          onPressed: () =>
                              _confirmarEliminar(nota),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            // Campo para nueva nota
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  10, 0, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      maxLines: null,
                      style:
                          const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Agregar nota interna...',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color:
                                Colors.amber.shade400),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color:
                                  Colors.amber.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color:
                                  Colors.amber.shade500),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color:
                                  Colors.amber.shade300),
                        ),
                      ),
                      onSubmitted: (_) => _agregar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor:
                          Colors.amber.shade600,
                      foregroundColor: Colors.white,
                    ),
                    icon: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Icon(Icons.send, size: 18),
                    onPressed: _guardando ? null : _agregar,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

