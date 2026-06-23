import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/models/ejercicio.dart';
import '../../core/models/paciente.dart';
import '../../core/services/ejercicio_service.dart';
import '../../core/services/pdf_service.dart';
import '../auth/auth_provider.dart';

class GeneradorRutinasScreen extends ConsumerStatefulWidget {
  final Paciente paciente;
  const GeneradorRutinasScreen({super.key, required this.paciente});

  @override
  ConsumerState<GeneradorRutinasScreen> createState() =>
      _GeneradorRutinasScreenState();
}

class _GeneradorRutinasScreenState
    extends ConsumerState<GeneradorRutinasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filtros
  String? _filtroCategoria;
  String? _filtroMusculo;
  String? _filtroNivel;
  String? _filtroImpacto;
  String? _filtroObjetivo;
  final _busqueda = TextEditingController();

  // Listas
  List<Ejercicio> _ejerciciosFiltrados = [];
  List<String> _categorias = [];
  List<String> _musculos = [];
  List<String> _niveles = [];
  List<String> _impactos = [];
  List<String> _objetivos = [];

  // Rutina
  final List<EjercicioEnRutina> _rutina = [];
  final _observacionesGenerales = TextEditingController();
  bool _generando = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busqueda.dispose();
    _observacionesGenerales.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final categorias = await EjercicioService.getCategorias();
    final musculos = await EjercicioService.getMusculos();
    final niveles = await EjercicioService.getNiveles();
    final impactos = await EjercicioService.getImpactos();
    final objetivos = await EjercicioService.getObjetivos();
    setState(() {
      _categorias = categorias;
      _musculos = musculos;
      _niveles = niveles;
      _impactos = impactos;
      _objetivos = objetivos;
      _cargando = false;
    });
    await _aplicarFiltros();
  }

  Future<void> _aplicarFiltros() async {
    final resultado = await EjercicioService.filtrar(
      categoria: _filtroCategoria,
      musculoPrincipal: _filtroMusculo,
      nivel: _filtroNivel,
      impacto: _filtroImpacto,
      objetivo: _filtroObjetivo,
      busqueda: _busqueda.text,
    );
    setState(() => _ejerciciosFiltrados = resultado);
  }

  void _agregarARoutina(Ejercicio ejercicio) {
    final yaEsta =
        _rutina.any((e) => e.ejercicio.id == ejercicio.id);
    if (yaEsta) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ejercicio.name} ya está en la rutina'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
    setState(() {
      _rutina.add(EjercicioEnRutina(
        ejercicio: ejercicio,
        series: 3,
        repeticiones: 12,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${ejercicio.name} agregado'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.teal,
      ),
    );
    _tabController.animateTo(1);
  }

  Future<void> _generarPdf() async {
    if (_rutina.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ejercicio a la rutina'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _generando = true);
    try {
      final authState = ref.read(authProvider).valueOrNull;
      final terapeuta = authState?.usuario?.nombre ?? 'Terapeuta';

      final pdfPath = await PdfService.generarRutina(
        paciente: widget.paciente,
        ejercicios: _rutina,
        terapeuta: terapeuta,
        observacionesGenerales:
            _observacionesGenerales.text.trim().isEmpty
                ? null
                : _observacionesGenerales.text.trim(),
      );

      if (mounted) _mostrarOpciones(pdfPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  void _mostrarOpciones(String pdfPath) {
    final nombre =
        'Rutina_${widget.paciente.apellidoPaterno}.pdf';
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.fitness_center, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(nombre,
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.teal),
              title: const Text('Compartir'),
              subtitle: const Text('WhatsApp, Email, Drive...'),
              onTap: () async {
                Navigator.pop(context);
                await Share.shareXFiles(
                  [XFile(pdfPath, mimeType: 'application/pdf')],
                  subject: nombre,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined,
                  color: Colors.indigo),
              title: const Text('Imprimir'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(
                  onLayout: (_) async =>
                      await File(pdfPath).readAsBytes(),
                  name: nombre,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rutina · ${widget.paciente.nombre}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.search),
              text: 'Ejercicios (${_ejerciciosFiltrados.length})',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _rutina.isNotEmpty,
                label: Text('${_rutina.length}'),
                child: const Icon(Icons.fitness_center),
              ),
              text: 'Rutina',
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _tabEjercicios(),
                _tabRutina(),
              ],
            ),
    );
  }

  Widget _tabEjercicios() {
    return Column(
      children: [
        Container(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _busqueda,
                decoration: InputDecoration(
                  hintText: 'Buscar ejercicio...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _busqueda.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _busqueda.clear();
                            _aplicarFiltros();
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surface,
                ),
                onChanged: (_) => _aplicarFiltros(),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chipFiltro('Categoría', _filtroCategoria,
                        _categorias, (v) {
                      setState(() {
                        _filtroCategoria = v;
                        _filtroMusculo = null;
                      });
                      _cargarMusculosPorCategoria();
                      _aplicarFiltros();
                    }),
                    const SizedBox(width: 8),
                    _chipFiltro('Músculo', _filtroMusculo,
                        _musculos, (v) {
                      setState(() => _filtroMusculo = v);
                      _aplicarFiltros();
                    }),
                    const SizedBox(width: 8),
                    _chipFiltro(
                        'Nivel', _filtroNivel, _niveles, (v) {
                      setState(() => _filtroNivel = v);
                      _aplicarFiltros();
                    }),
                    const SizedBox(width: 8),
                    _chipFiltro('Impacto', _filtroImpacto,
                        _impactos, (v) {
                      setState(() => _filtroImpacto = v);
                      _aplicarFiltros();
                    }),
                    const SizedBox(width: 8),
                    _chipFiltro('Objetivo', _filtroObjetivo,
                        _objetivos, (v) {
                      setState(() => _filtroObjetivo = v);
                      _aplicarFiltros();
                    }),
                    if (_hayFiltrosActivos()) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Limpiar'),
                        avatar:
                            const Icon(Icons.clear, size: 16),
                        onPressed: _limpiarFiltros,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _ejerciciosFiltrados.isEmpty
              ? const Center(
                  child:
                      Text('Sin ejercicios con estos filtros'),
                )
              : ListView.builder(
                  itemCount: _ejerciciosFiltrados.length,
                  itemBuilder: (context, i) {
                    final e = _ejerciciosFiltrados[i];
                    final enRutina = _rutina
                        .any((r) => r.ejercicio.id == e.id);
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            _colorCategoria(e.category)
                                .withValues(alpha: 0.2),
                        child: Text(
                          e.category[0],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _colorCategoria(e.category),
                          ),
                        ),
                      ),
                      title: Text(e.name,
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${e.mainMuscle} · ${e.level} · ${e.objective}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: enRutina
                          ? const Icon(Icons.check_circle,
                              color: Colors.teal, size: 20)
                          : IconButton(
                              icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20),
                              color: Colors.teal,
                              onPressed: () =>
                                  _agregarARoutina(e),
                            ),
                      onTap: enRutina
                          ? null
                          : () => _agregarARoutina(e),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _tabRutina() {
    if (_rutina.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center,
                size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Rutina vacía',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Ir a buscar ejercicios'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _rutina.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _rutina.removeAt(oldIndex);
                _rutina.insert(newIndex, item);
              });
            },
            itemBuilder: (context, i) {
              final e = _rutina[i];
              return _tarjetaEjercicioRutina(e, i);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
            border: Border(
                top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _observacionesGenerales,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText:
                      'Indicaciones generales (opcional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _generando ? null : _generarPdf,
                  icon: _generando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(
                      'Generar PDF (${_rutina.length} ejercicios)'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaEjercicioRutina(
      EjercicioEnRutina e, int index) {
    return Card(
      key: ValueKey(e.ejercicio.id),
      margin: const EdgeInsets.symmetric(
          vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor:
              _colorCategoria(e.ejercicio.category)
                  .withValues(alpha: 0.2),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _colorCategoria(e.ejercicio.category),
            ),
          ),
        ),
        title: Text(e.ejercicio.name,
            style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '${e.ejercicio.mainMuscle} · ${e.resumen}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: () =>
                  setState(() => _rutina.removeAt(index)),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Tipo:',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'reps',
                            label: Text('Series/Reps')),
                        ButtonSegment(
                            value: 'tiempo',
                            label: Text('Tiempo')),
                      ],
                      selected: {
                        e.tiempoSegundos != null
                            ? 'tiempo'
                            : 'reps'
                      },
                      onSelectionChanged: (v) {
                        setState(() {
                          if (v.first == 'tiempo') {
                            e.repeticiones = null;
                            e.tiempoSegundos = 30;
                            e.series = 3;
                          } else {
                            e.tiempoSegundos = null;
                            e.series = 3;
                            e.repeticiones = 12;
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (e.tiempoSegundos != null)
                  Row(children: [
                    Expanded(
                        child: _campoNumerico(
                            'Series',
                            e.series ?? 3,
                            (v) =>
                                setState(() => e.series = v))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campoNumerico(
                            'Tiempo (seg)',
                            e.tiempoSegundos ?? 30,
                            (v) => setState(
                                () => e.tiempoSegundos = v))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campoNumerico(
                            'Descanso (seg)',
                            e.descansoSegundos ?? 60,
                            (v) => setState(
                                () => e.descansoSegundos = v))),
                  ])
                else
                  Row(children: [
                    Expanded(
                        child: _campoNumerico(
                            'Series',
                            e.series ?? 3,
                            (v) =>
                                setState(() => e.series = v))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campoNumerico(
                            'Reps',
                            e.repeticiones ?? 12,
                            (v) => setState(
                                () => e.repeticiones = v))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _campoNumerico(
                            'Descanso (seg)',
                            e.descansoSegundos ?? 60,
                            (v) => setState(
                                () => e.descansoSegundos = v))),
                  ]),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: e.notas,
                  decoration: const InputDecoration(
                    labelText: 'Notas / instrucciones',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => e.notas =
                      v.trim().isEmpty ? null : v.trim(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoNumerico(
      String label, int valor, ValueChanged<int> onChanged) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed:
              valor > 1 ? () => onChanged(valor - 1) : null,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '$valor',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, size: 16),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(valor + 1),
        ),
      ],
    );
  }

  Widget _chipFiltro(
    String label,
    String? valorActual,
    List<String> opciones,
    ValueChanged<String?> onChanged,
  ) {
    return FilterChip(
      label: Text(
        valorActual ?? label,
        style: const TextStyle(fontSize: 12),
      ),
      selected: valorActual != null,
      onSelected: (_) => _mostrarDialogoFiltro(
          label, opciones, valorActual, onChanged),
    );
  }

  void _mostrarDialogoFiltro(
    String titulo,
    List<String> opciones,
    String? valorActual,
    ValueChanged<String?> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          const Divider(height: 1),
          if (valorActual != null)
            ListTile(
              leading: const Icon(Icons.clear, color: Colors.red),
              title: const Text('Quitar filtro'),
              onTap: () {
                Navigator.pop(context);
                onChanged(null);
              },
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: opciones.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(opciones[i]),
                trailing: opciones[i] == valorActual
                    ? const Icon(Icons.check, color: Colors.teal)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onChanged(opciones[i]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarMusculosPorCategoria() async {
    final musculos = await EjercicioService.getMusculos(
        categoria: _filtroCategoria);
    setState(() => _musculos = musculos);
  }

  bool _hayFiltrosActivos() =>
      _filtroCategoria != null ||
      _filtroMusculo != null ||
      _filtroNivel != null ||
      _filtroImpacto != null ||
      _filtroObjetivo != null ||
      _busqueda.text.isNotEmpty;

  void _limpiarFiltros() {
    setState(() {
      _filtroCategoria = null;
      _filtroMusculo = null;
      _filtroNivel = null;
      _filtroImpacto = null;
      _filtroObjetivo = null;
      _busqueda.clear();
    });
    _aplicarFiltros();
  }

  Color _colorCategoria(String categoria) {
    switch (categoria) {
      case 'Core':
        return Colors.teal;
      case 'Tren superior':
        return Colors.indigo;
      case 'Tren inferior':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

