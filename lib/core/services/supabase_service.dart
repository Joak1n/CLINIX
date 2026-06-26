import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'configuracion_service.dart';

class SupabaseService {
  // Cliente del Supabase CENTRAL de Clinix (siempre disponible)
  static SupabaseClient? _clienteCentral;

  // Cliente del Supabase PROPIO del consultorio (se configura en onboarding)
  static SupabaseClient? _clientePropio;

  /// Cliente activo: propio si existe, central como fallback
  static SupabaseClient get client =>
      _clientePropio ?? _clienteCentral ?? Supabase.instance.client;

  /// Cliente central siempre disponible (para registro de consultorios)
  static SupabaseClient get clienteCentral =>
      _clienteCentral ?? Supabase.instance.client;

  /// Inicialización al arrancar la app
  static Future<void> initialize() async {
    // 1. Inicializar Supabase central (hardcodeado de Clinix)
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _clienteCentral = Supabase.instance.client;

    // 2. Si el consultorio ya tiene Supabase propio guardado, conectarlo
    final url = await ConfiguracionService.getSupabaseUrl();
    final key = await ConfiguracionService.getSupabaseAnonKey();
    if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
      await conectarSupabasePropio(url, key);
    }
  }

  /// Conectar el Supabase propio del consultorio en tiempo de ejecución
  static Future<void> conectarSupabasePropio(String url, String anonKey) async {
    try {
      _clientePropio = SupabaseClient(url, anonKey);
      // Verificar conexión
      await _clientePropio!.from('configuracion').select('clave').limit(1);
    } catch (e) {
      _clientePropio = null;
      rethrow;
    }
  }

  /// Desconectar Supabase propio (por si se necesita resetear)
  static void desconectarSupabasePropio() {
    _clientePropio = null;
  }

  /// Verificar si el cliente activo tiene conexión
  static Future<bool> isConnected() async {
    try {
      await client.from('pacientes').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Verificar credenciales antes de guardarlas (usado en onboarding)
  static Future<bool> verificarCredenciales(String url, String anonKey) async {
    try {
      final tempClient = SupabaseClient(url, anonKey);
      await tempClient.from('configuracion').select('clave').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }
}