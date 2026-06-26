import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/migration_service.dart';
import '../../core/services/configuracion_service.dart';

class MigracionScreen extends StatefulWidget {
  const MigracionScreen({super.key});

  @override
  State<MigracionScreen> createState() => _MigracionScreenState();
}

class _MigracionScreenState extends State<MigracionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  // Estados
  bool _verificando = false;
  bool? _conexionValida;
  String? _errorConexion;

  bool _migrando = false;
  String _pasoActual = '';
  double _progreso = 0;
  List<PasoMigracion> _resultados = [];
  bool _migracionCompleta = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _verificarConexion() async {
    if (_urlCtrl.text.trim().isEmpty || _keyCtrl.text.trim().isEmpty) return;
    setState(() {
      _verificando = true;
      _conexionValida = null;
      _errorConexion = null;
    });
    try {
      final ok = await SupabaseService.verificarCredenciales(
        _urlCtrl.text.trim(),
        _keyCtrl.text.trim(),
      );
      setState(() {
        _conexionValida = ok;
        _errorConexion = ok ? null : 'No se pudo conectar. Verifica las credenciales.';
      });
    } catch (e) {
      setState(() {
        _conexionValida = false;
        _errorConexion = e.toString().length > 150
            ? '${e.toString().substring(0, 150)}...'
            : e.toString();
      });
    } finally {
      setState(() => _verificando = false);
    }
  }

  Future<void> _iniciarMigracion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_conexionValida != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verifica la conexión antes de migrar'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Iniciar migración?'),
        content: const Text(
          'Se copiarán todos tus datos clínicos al nuevo proyecto Supabase. '
          'Los datos originales NO se borrarán del Supabase central.\n\n'
          'Este proceso puede tardar unos minutos según la cantidad de registros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Migrar ahora'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _migrando = true;
      _resultados = [];
      _progreso = 0;
      _pasoActual = 'Preparando migración...';
    });

    try {
      final url = _urlCtrl.text.trim();
      final key = _keyCtrl.text.trim();
      final codigo = await ConfiguracionService.getCodigoAcceso() ?? 'SIN-CODIGO';

      final service = MigrationService(
        destinoUrl: url,
        destinoAnonKey: key,
        codigoAcceso: codigo,
        onProgreso: (paso, progreso) {
          if (mounted) setState(() { _pasoActual = paso; _progreso = progreso; });
        },
      );

      final resultados = await service.migrar();

      // Registrar en central y guardar credenciales locales
      await service.registrarEnCentral(supabaseUrl: url, supabaseAnonKey: key);
      await ConfiguracionService.setSupabaseCredenciales(url, key);
      await SupabaseService.conectarSupabasePropio(url, key);

      setState(() {
        _resultados = resultados;
        _migracionCompleta = true;
        _migrando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _migrando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migrar a Supabase propio'),
      ),
      body: _migracionCompleta
          ? _buildResultados()
          : _migrando
              ? _buildMigrando()
              : _buildFormulario(),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.move_up, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('Migración de datos',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.teal)),
                ]),
                SizedBox(height: 10),
                Text(
                  'Copia todos tus datos clínicos al proyecto Supabase de tu consultorio. '
                  'Después de migrar, tu app apuntará exclusivamente a ese proyecto.\n\n'
                  '1. Crea un proyecto gratuito en supabase.com\n'
                  '2. Pega la URL y el anon key aquí\n'
                  '3. Verifica la conexión\n'
                  '4. Inicia la migración',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Credenciales del nuevo proyecto',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'URL del proyecto *',
              hintText: 'https://xxxxxxxxxxxx.supabase.co',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            onChanged: (_) => setState(() {
              _conexionValida = null;
              _errorConexion = null;
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _keyCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Anon key *',
              hintText: 'eyJhbGci...',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(),
              helperText: 'Settings → API → Project API keys → anon public',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            onChanged: (_) => setState(() {
              _conexionValida = null;
              _errorConexion = null;
            }),
          ),
          const SizedBox(height: 16),

          // Botón verificar
          OutlinedButton.icon(
            onPressed: _verificando ? null : _verificarConexion,
            icon: _verificando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _conexionValida == true
                        ? Icons.check_circle
                        : _conexionValida == false
                            ? Icons.error_outline
                            : Icons.wifi_tethering,
                    color: _conexionValida == true
                        ? Colors.green
                        : _conexionValida == false
                            ? Colors.red
                            : null,
                  ),
            label: Text(
              _verificando
                  ? 'Verificando...'
                  : _conexionValida == true
                      ? 'Conexión exitosa ✓'
                      : _conexionValida == false
                          ? 'Fallo en conexión — reintentar'
                          : 'Verificar conexión',
              style: TextStyle(
                color: _conexionValida == true
                    ? Colors.green
                    : _conexionValida == false
                        ? Colors.red
                        : null,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _conexionValida == true
                    ? Colors.green
                    : _conexionValida == false
                        ? Colors.red
                        : Colors.grey.shade400,
              ),
            ),
          ),
          if (_errorConexion != null) ...[
            const SizedBox(height: 6),
            Text(_errorConexion!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _conexionValida == true ? _iniciarMigracion : null,
            icon: const Icon(Icons.move_up),
            label: const Text('Iniciar migración'),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrando() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 32),
          Text('Migrando datos...',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(_pasoActual,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: _progreso),
          const SizedBox(height: 8),
          Text('${(_progreso * 100).toInt()}%',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    final exitosos = _resultados.where((p) => p.exitoso).length;
    final fallidos = _resultados.where((p) => !p.exitoso).length;
    final totalRegistros = _resultados.fold<int>(0, (s, p) => s + p.registros);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: fallidos == 0
                ? Colors.green.withValues(alpha: 0.08)
                : Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: fallidos == 0
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                fallidos == 0 ? Icons.check_circle : Icons.warning_amber,
                size: 48,
                color: fallidos == 0 ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 12),
              Text(
                fallidos == 0
                    ? '¡Migración completada!'
                    : 'Migración con advertencias',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalRegistros registros migrados · $exitosos/8 tablas exitosas',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Detalle por tabla',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._resultados.map((p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                p.exitoso ? Icons.check_circle : Icons.error_outline,
                color: p.exitoso ? Colors.green : Colors.red,
              ),
              title: Text(p.nombre),
              subtitle: p.exitoso
                  ? Text('${p.registros} registros')
                  : Text(p.error ?? 'Error desconocido',
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
              trailing: p.exitoso
                  ? Chip(
                      label: Text('${p.registros}'),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
            )),
        const SizedBox(height: 32),
        if (fallidos == 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Text(
              'Tu app ahora apunta a tu Supabase propio. '
              'Los demás usuarios del consultorio podrán unirse con el mismo código de acceso de siempre.',
              style: TextStyle(fontSize: 13, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 24),
        ],
        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.check),
          label: const Text('Listo'),
        ),
      ],
    );
  }
}