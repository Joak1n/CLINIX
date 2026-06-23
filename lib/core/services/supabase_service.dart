import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Verificar conexión
  static Future<bool> isConnected() async {
    try {
      await client.from('pacientes').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }
}

