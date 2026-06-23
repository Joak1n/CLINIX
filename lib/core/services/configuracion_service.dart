import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfiguracionService {
  static const _keyTelefono           = 'config_telefono_consultorio';
  static const _keyNombre             = 'config_nombre_consultorio';
  static const _keyLogoPath           = 'config_logo_path';
  static const _keyOnboardingCompleto = 'onboarding_completo';
  static const _keyCodigoConsultorio  = 'codigo_consultorio';
  static const _keyDireccion          = 'config_direccion_consultorio';

  // ── Nombre ──────────────────────────────────────────────────────────────
  static Future<String> getNombreConsultorio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombre) ?? 'Mi Consultorio';
  }

  static Future<void> setNombreConsultorio(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNombre, nombre);
  }

  // ── Dirección ───────────────────────────────────────────────────────────
  static Future<String?> getDireccionConsultorio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDireccion);
  }

  static Future<void> setDireccionConsultorio(String? direccion) async {
    final prefs = await SharedPreferences.getInstance();
    if (direccion == null || direccion.trim().isEmpty) {
      await prefs.remove(_keyDireccion);
    } else {
      await prefs.setString(_keyDireccion, direccion.trim());
    }
  }

  // ── Teléfono ─────────────────────────────────────────────────────────────
  static Future<String> getTelefonoConsultorio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTelefono) ?? '5500000000';
  }

  static Future<void> setTelefonoConsultorio(String telefono) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTelefono, telefono);
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  static Future<String?> getLogoPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyLogoPath);
    if (path == null) return null;
    // Verificar que el archivo aún existe
    if (await File(path).exists()) return path;
    return null;
  }

  static Future<void> setLogoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLogoPath, path);
  }

  static Future<void> eliminarLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_keyLogoPath);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await prefs.remove(_keyLogoPath);
  }

  /// Copia el logo seleccionado a la carpeta de documentos de la app
  static Future<String> guardarLogo(String origenPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final destino = '${dir.path}/logo_consultorio.png';
    final origen = File(origenPath);
    await origen.copy(destino);
    await setLogoPath(destino);
    return destino;
  }

  /// Copia el logo a la carpeta de assets para usarlo como ícono
  static Future<void> copiarLogoComoIcono(String logoPath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final destino = '${dir.path}/app_icon.png';
      await File(logoPath).copy(destino);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_icon_path', destino);
    } catch (_) {}
  }

  static Future<String?> getAppIconPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_icon_path');
  }
  
  // ── Onboarding ────────────────────────────────────────────────────────────
  static Future<bool> isOnboardingCompleto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleto) ?? false;
  }

  static Future<void> setOnboardingCompleto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleto, true);
  }

  static Future<String?> getCodigoConsultorio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCodigoConsultorio);
  }

  static Future<void> setCodigoConsultorio(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCodigoConsultorio, codigo);
  }

  static const _keyCodigoAcceso = 'config_codigo_acceso';

  static Future<String> getCodigoAcceso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCodigoAcceso) ?? 'MEDI-2024';
  }

  static Future<void> setCodigoAcceso(String codigo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCodigoAcceso, codigo.trim().toUpperCase());
  }
  /// Sube el código de acceso a Supabase para que otros dispositivos lo lean
    static Future<void> sincronizarConfiguracion() async {
      try {
        final codigo = await getCodigoAcceso();
        final nombre = await getNombreConsultorio();
        final telefono = await getTelefonoConsultorio();
        final direccion = await getDireccionConsultorio();

        final datos = [
          {'clave': 'codigo_acceso', 'valor': codigo},
          {'clave': 'nombre_consultorio', 'valor': nombre},
          {'clave': 'telefono_consultorio', 'valor': telefono},
        ];

        if (direccion != null && direccion.isNotEmpty) {
          datos.add({
            'clave': 'direccion_consultorio',
            'valor': direccion
          });
        }

        await SupabaseService.client
            .from('configuracion')
            .upsert(datos);
      } catch (_) {}
    }

  /// Descarga el código de acceso desde Supabase
  static Future<String?> getCodigoAccesoRemoto() async {
    try {
      final rows = await SupabaseService.client
          .from('configuracion')
          .select('valor')
          .eq('clave', 'codigo_acceso')
          .limit(1);
      if (rows.isNotEmpty) return rows.first['valor'] as String;
    } catch (_) {}
    return null;
  }
  // Limpia el número de teléfono para formato internacional
  static Future<void> subirLogoASupabase(String logoPath) async {
    try {
      final file = File(logoPath);
      final bytes = await file.readAsBytes();
      await SupabaseService.client.storage
          .from('logos')
          .uploadBinary(
            'logo_consultorio.png',
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/png',
            ),
          );
    } catch (_) {}
  }
  // Descarga el logo desde Supabase y lo guarda localmente
  static Future<void> descargarLogoDeSupabase() async {
    try {
      final bytes = await SupabaseService.client.storage
          .from('logos')
          .download('logo_consultorio.png');

      final dir = await getApplicationDocumentsDirectory();
      final destino = '${dir.path}/logo_consultorio.png';
      await File(destino).writeAsBytes(bytes);
      await setLogoPath(destino);
    } catch (_) {}
  }
  static const _keyColorPrimario = 'config_color_primario';
  static const _keyColorSecundario = 'config_color_secundario';
  static const _keyColorFondo = 'config_color_fondo';

  static Future<int> getColorPrimario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyColorPrimario) ?? 0xFF1D9E75;
  }

  static Future<void> setColorPrimario(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorPrimario, color);
  }

  static Future<int> getColorSecundario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyColorSecundario) ?? 0xFF0D6E56;
  }

  static Future<void> setColorSecundario(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorSecundario, color);
  }

  static Future<int> getColorFondo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyColorFondo) ?? 0xFFF5F5F5;
  }

  static Future<void> setColorFondo(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyColorFondo, color);
  }
}

