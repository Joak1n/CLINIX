import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/consultorio_provider.dart';
import '../../core/services/configuracion_service.dart';
import '../../shared/widgets/consultorio_header.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/providers/tema_provider.dart';
import 'especialidad_provider.dart';
import '../../core/models/especialidad_personalizada.dart';
import 'migracion_screen.dart';
import 'horarios_screen.dart';
import '../../core/services/backup_service.dart';
import 'package:share_plus/share_plus.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState
    extends ConsumerState<ConfiguracionScreen> {
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _codigoAcceso = TextEditingController();
  bool _guardando = false;
  bool _generandoBackup = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _exportarBackup() async {
    setState(() => _generandoBackup = true);
    try {
      final archivo = await BackupService.generar();
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(archivo.path, mimeType: 'application/json')],
        subject: 'Respaldo CLINIX',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el respaldo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoBackup = false);
    }
  }

  Future<void> _cargar() async {
    _nombre.text = await ConfiguracionService.getNombreConsultorio();
    _telefono.text =
        await ConfiguracionService.getTelefonoConsultorio();
    _direccion.text =
        await ConfiguracionService.getDireccionConsultorio() ?? '';
    _codigoAcceso.text =
        await ConfiguracionService.getCodigoAcceso();
    setState(() {});
  }

  

  Future<void> _guardar() async {
    if (_nombre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El nombre no puede estar vacío')),
      );
      return;
    }
    if (_codigoAcceso.text.trim().isNotEmpty) {
      await ConfiguracionService.setCodigoAcceso(
          _codigoAcceso.text.trim());
    }
    setState(() => _guardando = true);
    await ref
        .read(consultorioProvider.notifier)
        .actualizarNombre(_nombre.text.trim());
    await ConfiguracionService.setTelefonoConsultorio(
        _telefono.text.trim());
    await ConfiguracionService.setDireccionConsultorio(
        _direccion.text.trim().isEmpty
            ? null
            : _direccion.text.trim());
    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
    // Sincronizar con Supabase
    await ConfiguracionService.sincronizarConfiguracion();
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (imagen == null) return;
    await ref
        .read(consultorioProvider.notifier)
        .actualizarLogo(imagen.path);
    await ConfiguracionService.subirLogoASupabase(imagen.path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo actualizado')),
      );
    }
  }

  Future<void> _eliminarLogo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar logo'),
        content: const Text(
            '¿Estás seguro? Se usará el ícono por defecto.'),
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
      await ref.read(consultorioProvider.notifier).eliminarLogo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo eliminado')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _direccion.dispose();
    _codigoAcceso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consultorioAsync = ref.watch(consultorioProvider);
    final logoPath = consultorioAsync.valueOrNull?.logoPath;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vista previa
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Vista previa',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                const ConsultorioHeader(
                    logoSize: 56, fontSize: 22),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logo
          const Text('Logo del consultorio',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: logoPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(logoPath),
                            fit: BoxFit.contain),
                      )
                    : Icon(Icons.local_hospital_rounded,
                        size: 40,
                        color: Theme.of(context)
                            .colorScheme
                            .primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file,
                          size: 18),
                      label: Text(logoPath != null
                          ? 'Cambiar logo'
                          : 'Subir logo'),
                      onPressed: _seleccionarLogo,
                    ),
                    if (logoPath != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(
                                color: Colors.red)),
                        icon: const Icon(
                            Icons.delete_outline,
                            size: 18),
                        label:
                            const Text('Eliminar logo'),
                        onPressed: _eliminarLogo,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PNG o JPG recomendado. Máximo 512×512px.',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Datos del consultorio
          const Text('Datos del consultorio',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(
              labelText: 'Nombre del consultorio',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _direccion,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Dirección (opcional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
              helperText:
                  'Aparecerá en el encabezado del PDF',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefono,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono de contacto',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
              helperText:
                  'Aparece en los mensajes de WhatsApp',
            ),
          ),
          const SizedBox(height: 24),

          // Código de acceso
          // Reemplaza el Container con el texto 'MEDI-2024' por esto:
          const Text('Código de acceso',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codigoAcceso,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
              helperText:
                  'Comparte este código con tu equipo para que puedan unirse',
            ),
          ),
          const SizedBox(height: 24),
          const Text('Colores institucionales',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Se aplican en la app y en los PDFs generados',
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // Vista previa
          Consumer(
            builder: (context, ref, _) {
              final tema = ref.watch(temaProvider).valueOrNull
                  ?? TemaState.inicial;
              return Column(
                children: [
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tema.colorFondo,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tema.colorPrimario,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: tema.colorSecundario,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Vista previa del tema',
                          style: TextStyle(
                              color: tema.colorPrimario,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 24),
                  const Text('Especialidades del consultorio',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final especialidadesAsync = ref.watch(especialidadesProvider);
                      return especialidadesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                        data: (especialidades) {
                          return Column(
                            children: [
                              ...especialidades.map((esp) => Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(esp.nombre),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: esp.activa,
                                            onChanged: (v) => ref
                                                .read(especialidadesProvider.notifier)
                                                .cambiarEstado(esp.id, v),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            onPressed: () => _editarEspecialidad(
                                                context, ref, esp),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                size: 18, color: Colors.red),
                                            onPressed: () => _eliminarEspecialidad(
                                                context, ref, esp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Agregar especialidad'),
                                  onPressed: () => _agregarEspecialidad(context, ref),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  // Botones de color
                  Row(
                    children: [
                      Expanded(
                        child: _BotonColor(
                          label: 'Color primario',
                          color: tema.colorPrimario,
                          onTap: () => _mostrarSelectorColor(
                            context,
                            'color primario',
                            tema.colorPrimario,
                            (c) => ref
                                .read(temaProvider.notifier)
                                .actualizarPrimario(c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BotonColor(
                          label: 'Color secundario',
                          color: tema.colorSecundario,
                          onTap: () => _mostrarSelectorColor(
                            context,
                            'color secundario',
                            tema.colorSecundario,
                            (c) => ref
                                .read(temaProvider.notifier)
                                .actualizarSecundario(c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BotonColor(
                          label: 'Fondo',
                          color: tema.colorFondo,
                          onTap: () => _mostrarSelectorColor(
                            context,
                            'color de fondo',
                            tema.colorFondo,
                            (c) => ref
                                .read(temaProvider.notifier)
                                .actualizarFondo(c),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Restaurar colores por defecto'),
                      onPressed: () => ref
                          .read(temaProvider.notifier)
                          .restaurarDefecto(),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon: _guardando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Guardar configuración'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Horarios y disponibilidad',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          const Text(
            'Configura horarios de atención por día, bloqueos y envía disponibilidad por WhatsApp.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule_outlined),
            label: const Text('Configurar horarios'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HorariosScreen()),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Supabase del consultorio',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          const Text(
            'Migra tus datos a tu propio proyecto Supabase para mayor privacidad y control.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.move_up),
            label: const Text('Migrar a Supabase propio'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MigracionScreen()),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Respaldo de datos',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          const Text(
            'Genera una copia de tus pacientes, citas e historial en un '
            'archivo que puedes guardar en Drive, enviar por correo o '
            'quedarte como respaldo adicional.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: _generandoBackup
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.backup_outlined),
            label: Text(_generandoBackup
                ? 'Generando respaldo...'
                : 'Exportar respaldo'),
            onPressed: _generandoBackup ? null : _exportarBackup,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  // Paleta de colores predefinidos
  static const _paleta = [
    Color(0xFF1D9E75), // Verde teal (default)
    Color(0xFF2196F3), // Azul
    Color(0xFF9C27B0), // Morado
    Color(0xFFE91E63), // Rosa
    Color(0xFFFF5722), // Naranja
    Color(0xFF607D8B), // Azul gris
    Color(0xFF795548), // Café
    Color(0xFF009688), // Teal oscuro
    Color(0xFF3F51B5), // Índigo
    Color(0xFF4CAF50), // Verde
  ];

  /// Convierte Color a string HEX sin canal alpha (ej. "1D9E75")
  String _colorAHex(Color c) =>
      c.value.toRadixString(16).substring(2).toUpperCase();

  /// Convierte string HEX a Color; retorna null si inválido
  Color? _hexAColor(String hex) {
    final limpio = hex.replaceAll('#', '').trim();
    if (limpio.length != 6) return null;
    final valor = int.tryParse('FF$limpio', radix: 16);
    return valor != null ? Color(valor) : null;
  }

  Future<void> _mostrarSelectorColor(
    BuildContext context,
    String titulo,
    Color colorActual,
    ValueChanged<Color> onColorCambiado,
  ) async {
    Color colorTemporal = colorActual;
    final hexCtrl = TextEditingController(text: _colorAHex(colorActual));
    String? hexError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text('Seleccionar $titulo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Paleta predefinida
                const Text('Colores predefinidos',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _paleta.map((color) {
                    final seleccionado =
                        colorTemporal.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        setDialog(() {
                          colorTemporal = color;
                          hexCtrl.text = _colorAHex(color);
                          hexError = null;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: seleccionado
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: seleccionado
                              ? [BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 6)]
                              : null,
                        ),
                        child: seleccionado
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Campo HEX manual
                const Text('Código HEX',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Preview del color actual
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorTemporal,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: hexCtrl,
                        maxLength: 7,
                        decoration: InputDecoration(
                          prefixText: '#',
                          hintText: 'ej. 1D9E75',
                          counterText: '',
                          border: const OutlineInputBorder(),
                          errorText: hexError,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.check_circle_outline,
                                size: 20),
                            tooltip: 'Aplicar HEX',
                            onPressed: () {
                              final color = _hexAColor(hexCtrl.text);
                              if (color != null) {
                                setDialog(() {
                                  colorTemporal = color;
                                  hexError = null;
                                });
                              } else {
                                setDialog(() =>
                                    hexError = 'HEX inválido (6 caracteres)');
                              }
                            },
                          ),
                        ),
                        onChanged: (val) {
                          final color = _hexAColor(val);
                          if (color != null) {
                            setDialog(() {
                              colorTemporal = color;
                              hexError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Selector libre (slider)
                const Text('Color personalizado',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ColorPicker(
                  pickerColor: colorTemporal,
                  onColorChanged: (c) => setDialog(() {
                    colorTemporal = c;
                    hexCtrl.text = _colorAHex(c);
                    hexError = null;
                  }),
                  enableAlpha: false,
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                onColorCambiado(colorTemporal);
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    hexCtrl.dispose();
  }

  Future<void> _agregarEspecialidad(
      BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva especialidad'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      await ref.read(especialidadesProvider.notifier).agregar(resultado);
    }
  }

  Future<void> _editarEspecialidad(
      BuildContext context, WidgetRef ref,
      EspecialidadPersonalizada esp) async {
    final ctrl = TextEditingController(text: esp.nombre);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar especialidad'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (resultado != null && resultado.isNotEmpty) {
      await ref
          .read(especialidadesProvider.notifier)
          .renombrar(esp.id, resultado);
    }
  }

  Future<void> _eliminarEspecialidad(
      BuildContext context, WidgetRef ref,
      EspecialidadPersonalizada esp) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar especialidad'),
        content: Text(
            '¿Eliminar "${esp.nombre}"? Las notas y citas existentes con esta especialidad conservarán el dato, pero ya no podrá seleccionarse para nuevos registros.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(especialidadesProvider.notifier).eliminar(esp.id);
    }
  }

}

class _BotonColor extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BotonColor({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}