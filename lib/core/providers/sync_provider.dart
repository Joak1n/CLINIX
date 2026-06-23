import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

// Estado de sincronización
enum SyncEstado { sincronizado, sincronizando, error, offline }

final conectadoProvider = FutureProvider<bool>((ref) async {
  return SupabaseService.isConnected();
});

final syncEstadoProvider =
    StateProvider<SyncEstado>((ref) => SyncEstado.sincronizado);

