import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/database_helper.dart';
import 'configuracion_service.dart';

/// Genera un respaldo manual de los datos del consultorio en un archivo
/// JSON que el usuario puede guardar donde quiera (Drive, correo, USB...).
/// No sustituye la sincronización con Supabase, es una copia adicional
/// para tranquilidad del usuario.
class BackupService {
  /// Tablas incluidas en el respaldo. Se excluye `password_hash` de
  /// usuarios por seguridad: un respaldo no debería contener credenciales.
  static const _tablas = [
    'pacientes',
    'citas',
    'notas_clinicas',
    'horarios_atencion',
    'bloqueos_horario',
    'auditoria',
    'consentimientos_informados',
  ];

  /// Genera el archivo de respaldo y devuelve su ruta local.
  static Future<File> generar() async {
    final db = await DatabaseHelper.instance.database;
    final data = <String, dynamic>{};

    for (final tabla in _tablas) {
      try {
        data[tabla] = await db.query(tabla);
      } catch (_) {
        // Si la tabla no existe en este dispositivo, se omite.
        data[tabla] = [];
      }
    }

    // Usuarios sin password_hash (no deben viajar en un respaldo).
    try {
      final usuarios = await db.query('usuarios');
      data['usuarios'] = usuarios
          .map((u) => {
                'id': u['id'],
                'nombre': u['nombre'],
                'email': u['email'],
                'rol': u['rol'],
                'activo': u['activo'],
              })
          .toList();
    } catch (_) {
      data['usuarios'] = [];
    }

    final nombreConsultorio = await ConfiguracionService.getNombreConsultorio();
    final ahora = DateTime.now();

    final contenido = <String, dynamic>{
      'tipo': 'respaldo_clinix',
      'version': 1,
      'consultorio': nombreConsultorio,
      'generado_en': ahora.toIso8601String(),
      'datos': data,
    };

    final json = const JsonEncoder.withIndent('  ').convert(contenido);

    final dir = await getApplicationDocumentsDirectory();
    final marcaTiempo =
        '${ahora.year}${_pad(ahora.month)}${_pad(ahora.day)}_${_pad(ahora.hour)}${_pad(ahora.minute)}';
    final nombreArchivo = 'respaldo_clinix_$marcaTiempo.json';
    final file = File('${dir.path}/$nombreArchivo');
    await file.writeAsString(json);
    return file;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
