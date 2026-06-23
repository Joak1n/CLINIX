import '../database/database_helper.dart';
import 'supabase_service.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  static final _db = DatabaseHelper.instance;
  static final _client = SupabaseService.client;
  /// Convierte timestamp de Supabase (UTC) a hora local
  static String _toLocalTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now().toIso8601String();
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      return dt.toIso8601String();
    } catch (_) {
      return DateTime.now().toIso8601String();
    }
  }


  /// Exponer la BD para uso interno
  static Future<Database> getDb() async {
    return _db.database;
  }

  /// Exponer el helper de zona horaria
  static String toLocalTime(dynamic timestamp) {
    return _toLocalTime(timestamp);
  }

  // ── SUBIR todo lo local a Supabase ────────────────────────

  static Future<void> subirTodo() async {
    await subirUsuarios();
    await subirPacientes();
    await subirNotasClinicas();
    await subirNotasInternas();
    await subirCitas();
    await subirHistoriaClinica();
    await subirSignosVitales();
  }

  static Future<void> subirUsuarios() async {
    final db = await _db.database;
    final maps = await db.query('usuarios');
    for (final m in maps) {
      await _client.from('usuarios').upsert({
        'id': m['id'],
        'nombre': m['nombre'],
        'email': m['email'],
        'password_hash': m['password_hash'],
        'rol': m['rol'],
        'activo': m['activo'] == 1,
      });
    }
  }

  static Future<void> subirPacientes() async {
    final db = await _db.database;
    final maps = await db.query('pacientes');
    for (final m in maps) {
      await _client.from('pacientes').upsert({
        'id': m['id'],
        'nombre': m['nombre'],
        'apellido_paterno': m['apellido_paterno'],
        'apellido_materno': m['apellido_materno'],
        'fecha_nacimiento': m['fecha_nacimiento'],
        'sexo': m['sexo'],
        'curp': m['curp'],
        'telefono': m['telefono'],
        'email': m['email'],
        'alergias': m['alergias'],
      });
    }
  }

  static Future<void> subirNotasClinicas() async {
    final db = await _db.database;
    final maps = await db.query('notas_clinicas');
    for (final m in maps) {
      await _client.from('notas_clinicas').upsert({
        'id': m['id'],
        'paciente_id': m['paciente_id'],
        'especialidad': m['especialidad'],
        'subjetivo': m['subjetivo'],
        'objetivo': m['objetivo'],
        'evaluacion': m['evaluacion'],
        'plan': m['plan'],
        'terapeuta': m['terapeuta'],
      });
    }
  }

  static Future<void> subirNotasInternas() async {
    final db = await _db.database;
    final maps = await db.query('notas_internas');
    for (final m in maps) {
      await _client.from('notas_internas').upsert({
        'id': m['id'],
        'paciente_id': m['paciente_id'],
        'nota_clinica_id': m['nota_clinica_id'],
        'contenido': m['contenido'],
        'autor': m['autor'],
      });
    }
  }

  static Future<void> subirCitas() async {
    final db = await _db.database;
    final maps = await db.query('citas');
    for (final m in maps) {
      await _client.from('citas').upsert({
        'id': m['id'],
        'paciente_id': m['paciente_id'],
        'especialidad': m['especialidad'],
        'fecha': m['fecha'],
        'hora': m['hora'],
        'duracion_minutos': m['duracion_minutos'],
        'terapeuta': m['terapeuta'],
        'estado': m['estado'],
        'notas': m['notas'],
      });
    }
  }

  static Future<void> subirHistoriaClinica() async {
    final db = await _db.database;
    final maps = await db.query('historia_clinica');
    for (final m in maps) {
      await _client.from('historia_clinica').upsert({
        'id': m['id'],
        'paciente_id': m['paciente_id'],
        'hf_diabetes': m['hf_diabetes'] == 1,
        'hf_hipertension': m['hf_hipertension'] == 1,
        'hf_cancer': m['hf_cancer'] == 1,
        'hf_cardiopatia': m['hf_cardiopatia'] == 1,
        'hf_obesidad': m['hf_obesidad'] == 1,
        'hf_otros': m['hf_otros'],
        'ap_diabetes': m['ap_diabetes'] == 1,
        'ap_hipertension': m['ap_hipertension'] == 1,
        'ap_cardiopatia': m['ap_cardiopatia'] == 1,
        'ap_asma': m['ap_asma'] == 1,
        'ap_cancer': m['ap_cancer'] == 1,
        'ap_fracturas': m['ap_fracturas'] == 1,
        'ap_transfusiones': m['ap_transfusiones'] == 1,
        'ap_cirugias': m['ap_cirugias'],
        'ap_traumatismos': m['ap_traumatismos'],
        'ap_hospitalizaciones': m['ap_hospitalizaciones'],
        'ap_otros': m['ap_otros'],
        'anp_tabaquismo': m['anp_tabaquismo'],
        'anp_alcoholismo': m['anp_alcoholismo'],
        'anp_drogas': m['anp_drogas'],
        'anp_actividad_fisica': m['anp_actividad_fisica'],
        'anp_ocupacion': m['anp_ocupacion'],
        'go_menarca': m['go_menarca'],
        'go_fur': m['go_fur'],
        'go_gestas': m['go_gestas'],
        'go_partos': m['go_partos'],
        'go_cesareas': m['go_cesareas'],
        'go_abortos': m['go_abortos'],
        'go_anticonceptivos': m['go_anticonceptivos'],
        'padecimiento_actual': m['padecimiento_actual'],
        'medicamentos_actuales': m['medicamentos_actuales'],
        'escala_eva': m['escala_eva'],
        'escala_daniels': m['escala_daniels'],
        'escala_glasgow': m['escala_glasgow'],
        'escala_norton': m['escala_norton'],
      });
    }
  }

  static Future<void> subirSignosVitales() async {
    final db = await _db.database;
    final maps = await db.query('signos_vitales');
    for (final m in maps) {
      await _client.from('signos_vitales').upsert({
        'id': m['id'],
        'paciente_id': m['paciente_id'],
        'fecha': m['fecha'],
        'tension_sistolica': m['tension_sistolica'],
        'tension_diastolica': m['tension_diastolica'],
        'frecuencia_cardiaca': m['frecuencia_cardiaca'],
        'frecuencia_respiratoria': m['frecuencia_respiratoria'],
        'temperatura': m['temperatura'],
        'peso': m['peso'],
        'talla': m['talla'],
        'imc': m['imc'],
        'saturacion_oxigeno': m['saturacion_oxigeno'],
        'glucosa': m['glucosa'],
        'notas': m['notas'],
      });
    }
  }

  // ── BAJAR todo de Supabase a local ────────────────────────

  static Future<void> bajarTodo() async {
    // El orden importa — primero las tablas padre, luego las hijas
    await bajarUsuarios();
    await bajarPacientes();           // 1. padre
    await bajarNotasClinicas();       // 2. depende de pacientes
    await bajarNotasInternas();       // 3. depende de notas_clinicas
    await bajarCitas();               // 4. depende de pacientes
    await bajarHistoriaClinica();     // 5. depende de pacientes
    await bajarSignosVitales();       // 6. depende de pacientes
  }

  static Future<void> bajarUsuarios() async {
    final db = await _db.database;
    final rows = await _client.from('usuarios').select();
    for (final r in rows) {
      await db.insert(
        'usuarios',
        {
          'id': r['id'],
          'nombre': r['nombre'],
          'email': r['email'],
          'password_hash': r['password_hash'],
          'rol': r['rol'],
          'activo': r['activo'] == true ? 1 : 0,
          'created_at': _toLocalTime(r['created_at']),
          'updated_at': _toLocalTime(r['updated_at'])
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> bajarPacientes() async {
    final db = await _db.database;
    final rows = await _client.from('pacientes').select();
    for (final r in rows) {
      await db.insert(
        'pacientes',
        {
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
          'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': r['updated_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> bajarNotasClinicas() async {
    final db = await _db.database;
    final rows = await _client.from('notas_clinicas').select();
    for (final r in rows) {
      await db.insert(
        'notas_clinicas',
        {
          'id': r['id'],
          'paciente_id': r['paciente_id'],
          'especialidad': r['especialidad'],
          'subjetivo': r['subjetivo'],
          'objetivo': r['objetivo'],
          'evaluacion': r['evaluacion'],
          'plan': r['plan'],
          'terapeuta': r['terapeuta'],
          'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> bajarNotasInternas() async {
    final db = await _db.database;
    final rows = await _client.from('notas_internas').select();
    for (final r in rows) {
      await db.insert(
        'notas_internas',
        {
          'id': r['id'],
          'paciente_id': r['paciente_id'],
          'nota_clinica_id': r['nota_clinica_id'],
          'contenido': r['contenido'],
          'autor': r['autor'],
          'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> bajarCitas() async {
    final db = await _db.database;
    final rows = await _client.from('citas').select();
    for (final r in rows) {
      await db.insert(
        'citas',
        {
          'id': r['id'],
          'paciente_id': r['paciente_id'],
          'especialidad': r['especialidad'],
          'fecha': r['fecha'],
          'hora': r['hora'],
          'duracion_minutos': r['duracion_minutos'],
          'terapeuta': r['terapeuta'],
          'estado': r['estado'],
          'notas': r['notas'],
          'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> bajarHistoriaClinica() async {
    final db = await _db.database;
    final rows = await _client.from('historia_clinica').select();
    for (final r in rows) {
      await db.insert(
        'historia_clinica',
        {
          'id': r['id'],
          'paciente_id': r['paciente_id'],
          'hf_diabetes': r['hf_diabetes'] == true ? 1 : 0,
          'hf_hipertension': r['hf_hipertension'] == true ? 1 : 0,
          'hf_cancer': r['hf_cancer'] == true ? 1 : 0,
          'hf_cardiopatia': r['hf_cardiopatia'] == true ? 1 : 0,
          'hf_obesidad': r['hf_obesidad'] == true ? 1 : 0,
          'hf_otros': r['hf_otros'],
          'ap_diabetes': r['ap_diabetes'] == true ? 1 : 0,
          'ap_hipertension': r['ap_hipertension'] == true ? 1 : 0,
          'ap_cardiopatia': r['ap_cardiopatia'] == true ? 1 : 0,
          'ap_asma': r['ap_asma'] == true ? 1 : 0,
          'ap_cancer': r['ap_cancer'] == true ? 1 : 0,
          'ap_fracturas': r['ap_fracturas'] == true ? 1 : 0,
          'ap_transfusiones': r['ap_transfusiones'] == true ? 1 : 0,
          'ap_cirugias': r['ap_cirugias'],
          'ap_traumatismos': r['ap_traumatismos'],
          'ap_hospitalizaciones': r['ap_hospitalizaciones'],
          'ap_otros': r['ap_otros'],
          'anp_tabaquismo': r['anp_tabaquismo'],
          'anp_alcoholismo': r['anp_alcoholismo'],
          'anp_drogas': r['anp_drogas'],
          'anp_actividad_fisica': r['anp_actividad_fisica'],
          'anp_ocupacion': r['anp_ocupacion'],
          'go_menarca': r['go_menarca'],
          'go_fur': r['go_fur'],
          'go_gestas': r['go_gestas'],
          'go_partos': r['go_partos'],
          'go_cesareas': r['go_cesareas'],
          'go_abortos': r['go_abortos'],
          'go_anticonceptivos': r['go_anticonceptivos'],
          'padecimiento_actual': r['padecimiento_actual'],
          'medicamentos_actuales': r['medicamentos_actuales'],
          'escala_eva': r['escala_eva'],
          'escala_daniels': r['escala_daniels'],
          'escala_glasgow': r['escala_glasgow'],
          'escala_norton': r['escala_norton'],
          'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': r['updated_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  static Future<void> bajarSignosVitales() async {
    final db = await _db.database;
    final rows = await _client.from('signos_vitales').select();
    for (final r in rows) {
      await db.insert(
        'signos_vitales',
        {
          'id': r['id'],
          'paciente_id': r['paciente_id'],
          'fecha': r['fecha'],
          'tension_sistolica': r['tension_sistolica'],
          'tension_diastolica': r['tension_diastolica'],
          'frecuencia_cardiaca': r['frecuencia_cardiaca'],
          'frecuencia_respiratoria': r['frecuencia_respiratoria'],
          'temperatura': r['temperatura'],
          'peso': r['peso'],
          'talla': r['talla'],
          'imc': r['imc'],
          'saturacion_oxigeno': r['saturacion_oxigeno'],
          'glucosa': r['glucosa'],
          'notas': r['notas'],
          'created_at': r['created_at'] ?? DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}

