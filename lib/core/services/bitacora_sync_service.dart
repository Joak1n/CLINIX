import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../database/database_helper.dart';
import 'supabase_service.dart';

/// Sincroniza la tabla `bitacora_sesiones` (bitácora de progreso por
/// sesión de paciente) con Supabase. Antes de esto era 100% local por
/// dispositivo.
class BitacoraSyncService {
  static void subirRegistro(Map<String, dynamic> registro) async {
    try {
      await SupabaseService.client.from('bitacora_sesiones').upsert(registro);
    } catch (_) {
      // Se reintentará con "Sincronizar con la nube".
    }
  }

  static Future<void> eliminarRegistro(String id) async {
    try {
      await SupabaseService.client
          .from('bitacora_sesiones')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  static Future<void> subirTodo() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('bitacora_sesiones');
    for (final m in maps) {
      try {
        await SupabaseService.client.from('bitacora_sesiones').upsert(m);
      } catch (_) {}
    }
  }

  static Future<void> bajarTodo() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final rows =
          await SupabaseService.client.from('bitacora_sesiones').select();
      for (final r in rows) {
        await db.insert('bitacora_sesiones', r,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
  }
}
