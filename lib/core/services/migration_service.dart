import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'configuracion_service.dart';

/// Resultado de cada paso de migración
class PasoMigracion {
  final String nombre;
  final int registros;
  final bool exitoso;
  final String? error;

  PasoMigracion({
    required this.nombre,
    required this.registros,
    required this.exitoso,
    this.error,
  });
}

/// Migra todos los datos del Supabase central al Supabase propio del consultorio.
class MigrationService {
  final SupabaseClient _origen;
  final SupabaseClient _destino;
  final String codigoAcceso;
  final void Function(String paso, double progreso)? onProgreso;

  MigrationService._({
    required SupabaseClient origen,
    required SupabaseClient destino,
    required this.codigoAcceso,
    this.onProgreso,
  })  : _origen = origen,
        _destino = destino;

  /// Crea una instancia con un cliente destino construido desde URL y key
  factory MigrationService({
    required String destinoUrl,
    required String destinoAnonKey,
    required String codigoAcceso,
    void Function(String paso, double progreso)? onProgreso,
  }) {
    final destino = SupabaseClient(destinoUrl, destinoAnonKey);
    return MigrationService._(
      origen: SupabaseService.clienteCentral,
      destino: destino,
      codigoAcceso: codigoAcceso,
      onProgreso: onProgreso,
    );
  }

  /// Ejecuta la migración completa. Retorna la lista de pasos con su resultado.
  Future<List<PasoMigracion>> migrar() async {
    final pasos = <PasoMigracion>[];
    final total = 8; // número de pasos
    int actual = 0;

    Future<PasoMigracion> ejecutar(
      String nombre,
      Future<int> Function() fn,
    ) async {
      actual++;
      onProgreso?.call(nombre, actual / total);
      try {
        final count = await fn();
        final paso = PasoMigracion(nombre: nombre, registros: count, exitoso: true);
        pasos.add(paso);
        return paso;
      } catch (e) {
        final paso = PasoMigracion(
            nombre: nombre, registros: 0, exitoso: false, error: e.toString());
        pasos.add(paso);
        return paso;
      }
    }

    // ── Orden importante: primero tablas padre, luego hijas ─────────────
    await ejecutar('Usuarios',          _migrarUsuarios);
    await ejecutar('Pacientes',         _migrarPacientes);
    await ejecutar('Historia clínica',  _migrarHistoriaClinica);
    await ejecutar('Notas clínicas',    _migrarNotasClinicas);
    await ejecutar('Notas internas',    _migrarNotasInternas);
    await ejecutar('Citas',             _migrarCitas);
    await ejecutar('Signos vitales',    _migrarSignosVitales);
    await ejecutar('Configuración',     _migrarConfiguracion);

    return pasos;
  }

  /// Registra las credenciales del consultorio en el Supabase central
  /// para que otros dispositivos puedan encontrarlo por código de acceso.
  Future<void> registrarEnCentral({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await _origen.from('consultorios').upsert({
      'codigo_acceso': codigoAcceso.toUpperCase(),
      'supabase_url': supabaseUrl,
      'supabase_anon_key': supabaseAnonKey,
      'registrado_en': DateTime.now().toIso8601String(),
    });
  }

  // ── Migración tabla por tabla ────────────────────────────────────────────

  Future<int> _migrarUsuarios() async {
    final rows = await _origen.from('usuarios').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('usuarios').upsert({
        'id': r['id'],
        'nombre': r['nombre'],
        'email': r['email'],
        'password_hash': r['password_hash'],
        'rol': r['rol'],
        'activo': r['activo'],
        'created_at': r['created_at'],
        'updated_at': r['updated_at'],
      });
    }
    return rows.length;
  }

  Future<int> _migrarPacientes() async {
    final rows = await _origen.from('pacientes').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('pacientes').upsert({
        'id': r['id'],
        'nombre': r['nombre'],
        'apellido_paterno': r['apellido_paterno'],
        'apellido_materno': r['apellido_materno'],
        'fecha_nacimiento': r['fecha_nacimiento'],
        'sexo': r['sexo'],
        'curp': r['curp'],
        'telefono': r['telefono'],
        'email': r['email'],
        'alergias': r['alergias'],
        'es_menor': r['es_menor'],
        'responsable_nombre': r['responsable_nombre'],
        'responsable_parentesco': r['responsable_parentesco'],
        'responsable_telefono': r['responsable_telefono'],
        'responsable_curp': r['responsable_curp'],
        'consentimiento_tutor': r['consentimiento_tutor'],
        'created_at': r['created_at'],
        'updated_at': r['updated_at'],
      });
    }
    return rows.length;
  }

  Future<int> _migrarNotasClinicas() async {
    final rows = await _origen.from('notas_clinicas').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('notas_clinicas').upsert({
        'id': r['id'],
        'paciente_id': r['paciente_id'],
        'especialidad': r['especialidad'],
        'subjetivo': r['subjetivo'],
        'objetivo': r['objetivo'],
        'evaluacion': r['evaluacion'],
        'plan': r['plan'],
        'terapeuta': r['terapeuta'],
        'created_at': r['created_at'],
      });
    }
    return rows.length;
  }

  Future<int> _migrarNotasInternas() async {
    final rows = await _origen.from('notas_internas').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('notas_internas').upsert({
        'id': r['id'],
        'paciente_id': r['paciente_id'],
        'nota_clinica_id': r['nota_clinica_id'],
        'contenido': r['contenido'],
        'autor': r['autor'],
        'created_at': r['created_at'],
      });
    }
    return rows.length;
  }

  Future<int> _migrarCitas() async {
    final rows = await _origen.from('citas').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('citas').upsert({
        'id': r['id'],
        'paciente_id': r['paciente_id'],
        'nombre_temporal': r['nombre_temporal'],
        'telefono_temporal': r['telefono_temporal'],
        'especialidad': r['especialidad'],
        'fecha': r['fecha'],
        'hora': r['hora'],
        'duracion_minutos': r['duracion_minutos'],
        'terapeuta': r['terapeuta'],
        'estado': r['estado'],
        'notas': r['notas'],
        'created_at': r['created_at'],
      });
    }
    return rows.length;
  }

  Future<int> _migrarHistoriaClinica() async {
    final rows = await _origen.from('historia_clinica').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('historia_clinica').upsert(Map<String, dynamic>.from(r));
    }
    return rows.length;
  }

  Future<int> _migrarSignosVitales() async {
    final rows = await _origen.from('signos_vitales').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('signos_vitales').upsert(Map<String, dynamic>.from(r));
    }
    return rows.length;
  }

  Future<int> _migrarConfiguracion() async {
    final rows = await _origen.from('configuracion').select();
    if (rows.isEmpty) return 0;
    for (final r in rows) {
      await _destino.from('configuracion').upsert({
        'clave': r['clave'],
        'valor': r['valor'],
      });
    }
    return rows.length;
  }
}