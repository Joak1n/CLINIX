import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/configuracion_service.dart';
import '../../core/database/database_helper.dart';
import '../auth/login_screen.dart';
import '../auth/auth_provider.dart';
import '../../main.dart' show HomeShell;
import 'package:sqflite/sqflite.dart';
import '../../../core/services/supabase_service.dart';
import '../../core/utils/hash_util.dart';
import '../../shared/widgets/consultorio_header.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _paso = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildPaso(),
        ),
      ),
    );
  }

  Widget _buildPaso() {
    switch (_paso) {
      case 0:
        return _PasoBienvenida(
          key: const ValueKey(0),
          onContinuar: () => setState(() => _paso = 1),
        );
      case 1:
        return _PasoElegirRol(
          key: const ValueKey(1),
          onCrear: () => setState(() => _paso = 2),
          onUnirse: () => setState(() => _paso = 3),
        );
      case 2:
        return _PasoCrearConsultorio(
          key: const ValueKey(2),
          onVolver: () => setState(() => _paso = 1),
        );
      case 3:
        return _PasoUnirseConsultorio(
          key: const ValueKey(3),
          onVolver: () => setState(() => _paso = 1),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─── Paso 0: Bienvenida ───────────────────────────────────────────────────

class _PasoBienvenida extends StatelessWidget {
  final VoidCallback onContinuar;
  const _PasoBienvenida({super.key, required this.onContinuar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const LogoConsultorio(size: 80),
          const SizedBox(height: 24),
          Text(
            'Bienvenido a\nCLINIX',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sistema de expedientes clínicos\ncumpliendo la NOM-004-SSA3-2012',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onContinuar,
            child: const Text('Comenzar configuración'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Paso 1: Elegir rol ───────────────────────────────────────────────────

class _PasoElegirRol extends StatelessWidget {
  final VoidCallback onCrear;
  final VoidCallback onUnirse;

  const _PasoElegirRol({
    super.key,
    required this.onCrear,
    required this.onUnirse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            '¿Cómo deseas usar\nMediconfort?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 48),
          _TarjetaOpcion(
            icono: Icons.add_business_outlined,
            titulo: 'Crear mi consultorio',
            descripcion:
                'Soy el dueño o administrador.\nConfiguro el consultorio por primera vez.',
            color: Theme.of(context).colorScheme.primary,
            onTap: onCrear,
          ),
          const SizedBox(height: 16),
          _TarjetaOpcion(
            icono: Icons.group_add_outlined,
            titulo: 'Unirme a un consultorio',
            descripcion:
                'Soy terapeuta o recepcionista.\nMe invitaron a unirme con un código.',
            color: Colors.indigo,
            onTap: onUnirse,
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _TarjetaOpcion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  const SizedBox(height: 4),
                  Text(descripcion,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// ─── Paso 2: Crear consultorio ────────────────────────────────────────────

class _PasoCrearConsultorio extends ConsumerStatefulWidget {
  final VoidCallback onVolver;
  const _PasoCrearConsultorio({super.key, required this.onVolver});

  @override
  ConsumerState<_PasoCrearConsultorio> createState() =>
      _PasoCrearConsultorioState();
}

class _PasoCrearConsultorioState
    extends ConsumerState<_PasoCrearConsultorio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreConsultorio = TextEditingController();
  final _telefonoConsultorio = TextEditingController();
  final _direccionConsultorio = TextEditingController();
  final _nombreAdmin = TextEditingController();
  final _emailAdmin = TextEditingController();
  final _passwordAdmin = TextEditingController();
  final _codigoAcceso = TextEditingController();
  bool _verPassword = false;
  bool _guardando = false;
  String? _logoPath;

  @override
  void dispose() {
    _nombreConsultorio.dispose();
    _telefonoConsultorio.dispose();
    _direccionConsultorio.dispose();
    _nombreAdmin.dispose();
    _emailAdmin.dispose();
    _passwordAdmin.dispose();
    _codigoAcceso.dispose();
    super.dispose();
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (imagen != null) {
      setState(() => _logoPath = imagen.path);
    }
  }

  Future<void> _finalizar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      await ConfiguracionService.setNombreConsultorio(
          _nombreConsultorio.text.trim());
      await ConfiguracionService.setTelefonoConsultorio(
          _telefonoConsultorio.text.trim());
      await ConfiguracionService.setDireccionConsultorio(
          _direccionConsultorio.text.trim().isEmpty
              ? null
              : _direccionConsultorio.text.trim());

      if (_logoPath != null) {
        await ConfiguracionService.guardarLogo(_logoPath!);
        await ConfiguracionService.subirLogoASupabase(_logoPath!);
      }

      final db = await DatabaseHelper.instance.database;
      await db.delete('usuarios',
          where: 'email = ?',
          whereArgs: ['admin@mediconfort.com']);

      final ahora = DateTime.now().toIso8601String();
      final hash = HashUtil.hashPassword(_passwordAdmin.text);
      await db.insert('usuarios', {
        'id': '00000000-0000-0000-0000-000000000001',
        'nombre': _nombreAdmin.text.trim(),
        'email': _emailAdmin.text.trim().toLowerCase(),
        'password_hash': hash, // ← hash en lugar de texto plano
        'rol': 'admin',
        'activo': 1,
        'created_at': ahora,
        'updated_at': ahora,
      });

      // Subir admin a Supabase con hash
      try {
        await SupabaseService.client.from('usuarios').upsert({
          'id': '00000000-0000-0000-0000-000000000001',
          'nombre': _nombreAdmin.text.trim(),
          'email': _emailAdmin.text.trim().toLowerCase(),
          'password_hash': hash,
          'rol': 'admin',
          'activo': true,
        });
      } catch (_) {}

      // Guardar código de acceso personalizado
      final codigo = _codigoAcceso.text.trim().isEmpty
          ? 'MEDI-${DateTime.now().year}'
          : _codigoAcceso.text.trim().toUpperCase();
      await ConfiguracionService.setCodigoAcceso(codigo);
      // Subir código a Supabase para que otros dispositivos puedan usarlo
      await ConfiguracionService.sincronizarConfiguracion();

      await ConfiguracionService.setOnboardingCompleto();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const _OnboardingCompleto()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onVolver,
        ),
        title: const Text('Configurar consultorio'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _seccion(context, 'Datos del consultorio',
                Icons.business_outlined),
            const SizedBox(height: 12),
            _campo(
              controller: _nombreConsultorio,
              label: 'Nombre del consultorio',
              icono: Icons.business,
              obligatorio: true,
            ),
            const SizedBox(height: 12),
            _campo(
              controller: _telefonoConsultorio,
              label: 'Teléfono de contacto',
              icono: Icons.phone,
              tipo: TextInputType.phone,
              obligatorio: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _direccionConsultorio,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Dirección del consultorio (opcional)',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
                helperText: 'Aparecerá en el encabezado del PDF',
              ),
            ),
            const SizedBox(height: 16),

            // Código de acceso personalizado
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoAcceso,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código de acceso para tu equipo (opcional)',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: const OutlineInputBorder(),
                helperText: 'Si lo dejas vacío se genera automáticamente',
                hintText: 'Ej: CLINICA-2024',
              ),
            ),

            // Selector de logo
            GestureDetector(
              onTap: _seleccionarLogo,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _logoPath == null
                    ? Column(
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Subir logo del consultorio (opcional)',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_logoPath!),
                              width: 56,
                              height: 56,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Logo seleccionado ✓',
                            style: TextStyle(color: Colors.teal),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                setState(() => _logoPath = null),
                            child: const Text('Quitar'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // Cuenta admin
            _seccion(context, 'Cuenta de administrador',
                Icons.admin_panel_settings_outlined),
            const SizedBox(height: 12),
            _campo(
              controller: _nombreAdmin,
              label: 'Tu nombre completo',
              icono: Icons.person,
              obligatorio: true,
            ),
            const SizedBox(height: 12),
            _campo(
              controller: _emailAdmin,
              label: 'Correo electrónico',
              icono: Icons.email_outlined,
              tipo: TextInputType.emailAddress,
              obligatorio: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordAdmin,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                labelText: 'Contraseña *',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_verPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _verPassword = !_verPassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Mínimo 6 caracteres'
                  : null,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _guardando ? null : _finalizar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Crear consultorio'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _seccion(
      BuildContext context, String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono,
            size: 20,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(titulo,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary)),
      ],
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    bool obligatorio = false,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: obligatorio ? '$label *' : label,
        prefixIcon: Icon(icono),
        border: const OutlineInputBorder(),
      ),
      validator: obligatorio
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Requerido' : null
          : null,
    );
  }
}

// ─── Paso 3: Unirse a consultorio ─────────────────────────────────────────

class _PasoUnirseConsultorio extends StatefulWidget {
  final VoidCallback onVolver;
  const _PasoUnirseConsultorio({super.key, required this.onVolver});

  @override
  State<_PasoUnirseConsultorio> createState() =>
      _PasoUnirseConsultorioState();
}

class _PasoUnirseConsultorioState
    extends State<_PasoUnirseConsultorio> {
  final _formKey = GlobalKey<FormState>();
  final _codigo = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _verPassword = false;
  bool _verificando = false;
  String? _errorCodigo;

  @override
  void dispose() {
    _codigo.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _verificarYUnirse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _verificando = true;
      _errorCodigo = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final codigoIngresado = _codigo.text.trim().toUpperCase();

    // Obtener código remoto y local
    final codigoRemoto =
        await ConfiguracionService.getCodigoAccesoRemoto();
    final codigoLocal =
        await ConfiguracionService.getCodigoAcceso();
    debugPrint('=== DEBUG CÓDIGO ===');
    debugPrint('Ingresado: $codigoIngresado');
    debugPrint('Remoto: $codigoRemoto');
    debugPrint('Local: $codigoLocal');
    debugPrint('====================');

    final codigoValido = codigoRemoto ?? codigoLocal;
    debugPrint('Código válido final: $codigoValido');
    debugPrint('¿Coinciden?: ${codigoIngresado == codigoValido}');

    if (codigoIngresado != codigoValido) {
      debugPrint('FALLO EN COMPARACIÓN');
      setState(() {
        _errorCodigo =
            'Código inválido. Solicita el código al administrador.';
        _verificando = false;
      });
      return;
    }
    debugPrint('CÓDIGO VÁLIDO - continuando...');

    // Descargar nombre del consultorio desde Supabase
    try {
      final rows = await SupabaseService.client
          .from('configuracion')
          .select();

      for (final row in rows) {
        final clave = row['clave'] as String;
        final valor = row['valor'] as String;
        switch (clave) {
          case 'nombre_consultorio':
            await ConfiguracionService.setNombreConsultorio(valor);
            break;
          case 'telefono_consultorio':
            await ConfiguracionService.setTelefonoConsultorio(valor);
            break;
          case 'direccion_consultorio':
            await ConfiguracionService.setDireccionConsultorio(valor);
            break;
          case 'codigo_acceso':
            await ConfiguracionService.setCodigoAcceso(valor);
            break;
        }
      }
      // Descargar logo desde Supabase Storage
      await ConfiguracionService.descargarLogoDeSupabase();
    } catch (_) {}

    try {
      final db = await DatabaseHelper.instance.database;

      // Descargar usuarios desde Supabase
      final usuarios = await SupabaseService.client
          .from('usuarios')
          .select();
      for (final u in usuarios) {
        final existente = await db.query(
          'usuarios',
          where: 'email = ?',
          whereArgs: [u['email']],
        );

        if (existente.isEmpty) {
          await db.insert('usuarios', {
            'id': u['id'],
            'nombre': u['nombre'],
            'email': u['email'],
            'password_hash': u['password_hash'],
            'rol': u['rol'],
            'activo': u['activo'] == true ? 1 : 0,
            'created_at': u['created_at'] ??
                DateTime.now().toIso8601String(),
            'updated_at': u['updated_at'] ??
                DateTime.now().toIso8601String(),
          });
        } else {
          await db.update(
            'usuarios',
            {
              'nombre': u['nombre'],
              'password_hash': u['password_hash'],
              'rol': u['rol'],
              'activo': u['activo'] == true ? 1 : 0,
              'updated_at': u['updated_at'] ??
                  DateTime.now().toIso8601String(),
            },
            where: 'email = ?',
            whereArgs: [u['email']],
          );
        }
      }

      await ConfiguracionService.setCodigoConsultorio(
          codigoIngresado);
      await ConfiguracionService.setCodigoAcceso(
          codigoIngresado);
      await ConfiguracionService.setOnboardingCompleto();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const _OnboardingCompleto()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorCodigo = 'Error al conectar: $e';
        _verificando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onVolver,
        ),
        title: const Text('Unirse a consultorio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.indigo, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Solicita el código de acceso al '
                      'administrador de tu consultorio '
                      'antes de continuar.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.indigo.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _codigo,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Código del consultorio *',
                prefixIcon:
                    const Icon(Icons.vpn_key_outlined),
                border: const OutlineInputBorder(),
                hintText: 'Ej: MEDI-2024',
                errorText: _errorCodigo,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Requerido'
                      : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Tu correo electrónico *',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Requerido'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                labelText: 'Tu contraseña *',
                prefixIcon: const Icon(Icons.lock_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_verPassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _verPassword = !_verPassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo),
              onPressed: _verificando ? null : _verificarYUnirse,
              icon: _verificando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    )
                  : const Icon(Icons.login),
              label: const Text('Verificar y acceder'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Pantalla de transición ───────────────────────────────────────────────

class _OnboardingCompleto extends StatefulWidget {
  const _OnboardingCompleto();

  @override
  State<_OnboardingCompleto> createState() =>
      _OnboardingCompletoState();
}

class _OnboardingCompletoState
    extends State<_OnboardingCompleto> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const _AppRoot()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text('¡Todo listo!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Redirigiendo al inicio de sesión...',
              style:
                  TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    return authAsync.when(
      loading: () => const Scaffold(
          body:
              Center(child: CircularProgressIndicator())),
      error: (e, _) => const LoginScreen(),
      data: (auth) {
        if (!auth.autenticado) return const LoginScreen();
        return HomeShell(usuario: auth.usuario!);
      },
    );
  }
}

