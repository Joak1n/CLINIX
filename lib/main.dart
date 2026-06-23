import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/tema_provider.dart';
import 'core/database/database_helper.dart';
import 'core/models/usuario.dart';
import 'core/services/configuracion_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/configuracion_screen.dart';
import 'features/auth/usuarios_screen.dart';
import 'features/pacientes/pacientes_screen.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'shared/widgets/consultorio_header.dart';
import 'core/services/supabase_service.dart';
import 'core/services/sync_service.dart';
import 'core/providers/sync_provider.dart';
import 'core/services/realtime_service.dart';
import 'core/providers/realtime_provider.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);
  await SupabaseService.initialize();
  await DatabaseHelper.instance.database;

  // Sincronizar al iniciar
  try {
    final conectado = await SupabaseService.isConnected();
    if (conectado) {
      await SyncService.bajarTodo();
      await ConfiguracionService.descargarLogoDeSupabase();
    }
  } catch (_) {}

  final container = ProviderContainer();

  // Iniciar sincronización en tiempo real
  try {
    RealtimeService.inicializar(container);
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MediconfortApp(),
    ),
  );
}

class MediconfortApp extends ConsumerWidget {
  const MediconfortApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temaAsync = ref.watch(temaProvider);

    final tema = temaAsync.valueOrNull ??
        TemaState.inicial;

    return MaterialApp(
      title: 'CLINIX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLight(
        primaryColor: tema.colorPrimario,
        backgroundColor: tema.colorFondo,
      ),
      darkTheme: AppTheme.buildDark(
        primaryColor: tema.colorPrimario,
      ),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

// Decide si mostrar login o la app principal
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ConfiguracionService.isOnboardingCompleto(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Primera vez → onboarding
        if (!snapshot.data!) {
          return const OnboardingScreen();
        }

        // Ya configurado → verificar login
        final authAsync = ref.watch(authProvider);
        return authAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => const LoginScreen(),
          data: (auth) {
            if (!auth.autenticado) return const LoginScreen();
            return HomeShell(usuario: auth.usuario!);
          },
        );
      },
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  final Usuario usuario;   // ← tipo explícito
  const HomeShell({super.key, required this.usuario});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final rol = widget.usuario.rol;

    // Pantallas según rol
    final screens = [
      if (rol.puedeVerExpedientes) const PacientesScreen(),
      if (rol.puedeVerAgenda) const AgendaScreen(),
      if (rol.puedeVerExpedientes)
        const DashboardScreen(),
      if (rol.puedeGestionarUsuarios) const UsuariosScreen(),
    ];

    final destinations = [
      if (rol.puedeVerExpedientes)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Pacientes',
        ),
        // El dashboard es visible para todos los roles, pero solo se muestra en el menú si el rol tiene permisos de gestión de usuarios
      if (rol.puedeVerAgenda)
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Agenda',
        ),
        // El dashboard es visible para todos los roles, pero solo se muestra en el menú si el rol tiene permisos de gestión de usuarios
      if (rol.puedeVerExpedientes)
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Dashboard',
        ),
        // El dashboard es visible para todos los roles, pero solo se muestra en el menú si el rol tiene permisos de gestión de usuarios
      if (rol.puedeGestionarUsuarios)
        const NavigationDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: 'Usuarios',
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const ConsultorioHeader(logoSize: 32, fontSize: 16),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final version = ref.watch(realtimeVersionProvider);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: version > 0
                    ? Padding(
                        key: ValueKey(version),
                        padding:
                            const EdgeInsets.only(right: 4),
                        child: const Icon(
                          Icons.sync,
                          size: 16,
                          color: Colors.teal,
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _mostrarMenuUsuario(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        widget.usuario.nombre[0].toUpperCase(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.usuario.nombre,
                            style: const TextStyle(fontSize: 13)),
                        Text(widget.usuario.rol.etiqueta,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: screens.isEmpty
          ? const Center(child: Text('Sin módulos disponibles'))
          : screens[_tab.clamp(0, screens.length - 1)],
      bottomNavigationBar: destinations.length > 1
          ? NavigationBar(
              selectedIndex: _tab.clamp(0, destinations.length - 1),
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: destinations,
            )
          : null,
    );
  }

  void _mostrarMenuUsuario(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                child: Text(widget.usuario.nombre[0].toUpperCase()),
              ),
              title: Text(widget.usuario.nombre),
              subtitle: Text(widget.usuario.rol.etiqueta),
            ),
            ListTile(
              leading: Consumer(
                builder: (context, ref, _) {
                  final syncEstado = ref.watch(syncEstadoProvider);
                  return Icon(
                    syncEstado == SyncEstado.sincronizando
                        ? Icons.sync
                        : Icons.cloud_sync_outlined,
                    color: syncEstado == SyncEstado.error
                        ? Colors.red
                        : Colors.teal,
                  );
                },
              ),
              title: const Text('Sincronizar con la nube'),
              onTap: () async {
                Navigator.pop(context);
                ref.read(syncEstadoProvider.notifier).state =
                    SyncEstado.sincronizando;
                try {
                  await SyncService.subirTodo();
                  await SyncService.bajarTodo();
                  ref.read(syncEstadoProvider.notifier).state =
                      SyncEstado.sincronizado;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Sincronización completada'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                } catch (e) {
                  ref.read(syncEstadoProvider.notifier).state =
                      SyncEstado.error;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error de sincronización: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const Divider(),
            if (widget.usuario.rol.puedeGestionarUsuarios)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConfiguracionScreen()),
                  );
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

