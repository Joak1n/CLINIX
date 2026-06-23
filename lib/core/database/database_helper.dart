import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Windows y Linux requieren inicialización FFI
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mediconfort.db');

    return await openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {   //_onCreate se llama solo la primera vez que se crea la base de datos
    await db.execute('''
      CREATE TABLE pacientes (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        apellido_paterno TEXT NOT NULL,
        apellido_materno TEXT,
        fecha_nacimiento TEXT NOT NULL,
        sexo TEXT NOT NULL,
        curp TEXT,
        telefono TEXT,
        email TEXT,
        alergias TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
        es_menor INTEGER DEFAULT 0,
        responsable_nombre TEXT,
        responsable_parentesco TEXT,
        responsable_telefono TEXT,
        responsable_curp TEXT,
        consentimiento_tutor INTEGER DEFAULT 0,
      )
      
    ''');

    await db.execute('''
      CREATE TABLE notas_clinicas (
        id TEXT PRIMARY KEY,
        paciente_id TEXT NOT NULL,
        especialidad TEXT NOT NULL,
        subjetivo TEXT,
        objetivo TEXT,
        evaluacion TEXT,
        plan TEXT,
        terapeuta TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS citas (
        id TEXT PRIMARY KEY,
        paciente_id TEXT,
        nombre_temporal TEXT,
        telefono_temporal TEXT,
        especialidad TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        duracion_minutos INTEGER NOT NULL DEFAULT 60,
        terapeuta TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'confirmada',
        notas TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS historia_clinica (
        id TEXT PRIMARY KEY,
        paciente_id TEXT NOT NULL UNIQUE,
        hf_diabetes INTEGER DEFAULT 0,
        hf_hipertension INTEGER DEFAULT 0,
        hf_cancer INTEGER DEFAULT 0,
        hf_cardiopatia INTEGER DEFAULT 0,
        hf_obesidad INTEGER DEFAULT 0,
        hf_otros TEXT,
        ap_diabetes INTEGER DEFAULT 0,
        ap_hipertension INTEGER DEFAULT 0,
        ap_cardiopatia INTEGER DEFAULT 0,
        ap_asma INTEGER DEFAULT 0,
        ap_cancer INTEGER DEFAULT 0,
        ap_fracturas INTEGER DEFAULT 0,
        ap_transfusiones INTEGER DEFAULT 0,
        ap_cirugias TEXT,
        ap_traumatismos TEXT,
        ap_hospitalizaciones TEXT,
        ap_otros TEXT,
        anp_tabaquismo TEXT,
        anp_alcoholismo TEXT,
        anp_drogas TEXT,
        anp_actividad_fisica TEXT,
        anp_ocupacion TEXT,
        go_menarca TEXT,
        go_fur TEXT,
        go_gestas INTEGER,
        go_partos INTEGER,
        go_cesareas INTEGER,
        go_abortos INTEGER,
        go_anticonceptivos TEXT,
        padecimiento_actual TEXT,
        medicamentos_actuales TEXT,
        escala_eva INTEGER,
        escala_daniels INTEGER,
        escala_glasgow INTEGER,
        escala_norton INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS signos_vitales (
        id TEXT PRIMARY KEY,
        paciente_id TEXT NOT NULL,
        fecha TEXT NOT NULL,
        tension_sistolica INTEGER,
        tension_diastolica INTEGER,
        frecuencia_cardiaca INTEGER,
        frecuencia_respiratoria INTEGER,
        temperatura REAL,
        peso REAL,
        talla REAL,
        imc REAL,
        saturacion_oxigeno INTEGER,
        glucosa INTEGER,
        notas TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuarios (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL,
        activo INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Usuario administrador por defecto
    await db.insert('usuarios', {
      'id': '00000000-0000-0000-0000-000000000001',
      'nombre': 'Administrador',
      'email': 'admin@mediconfort.com',
      'password_hash': 'admin1234',
      'rol': 'admin',
      'activo': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notas_internas (
        id TEXT PRIMARY KEY,
        paciente_id TEXT NOT NULL,
        nota_clinica_id TEXT,
        contenido TEXT NOT NULL,
        autor TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
        FOREIGN KEY (nota_clinica_id) REFERENCES notas_clinicas(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS adjuntos (
        id TEXT PRIMARY KEY,
        paciente_id TEXT NOT NULL,
        nombre TEXT NOT NULL,
        tipo TEXT NOT NULL,
        tamano INTEGER,
        ruta_local TEXT,
        url TEXT,
        storage_path TEXT,
        descripcion TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS especialidades (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL UNIQUE,
        activa INTEGER NOT NULL DEFAULT 1,
        orden INTEGER NOT NULL DEFAULT 0
      )
    ''');

    

    // Especialidades por defecto
    final especialidadesDefault = [
      {'id': 'fisioterapia', 'nombre': 'Fisioterapia', 'orden': 0},
            {'id': 'spa', 'nombre': 'Spa', 'orden': 1},
      {'id': 'asesoria_deportiva', 'nombre': 'Asesoría deportiva', 'orden': 2},
    ];
    for (final e in especialidadesDefault) {
      await db.insert('especialidades', {...e, 'activa': 1});
    }
  }
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {     //_onUpgrade se llama cada vez que se detecta un cambio en la versión de la base de datos
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS citas (
          id TEXT PRIMARY KEY,
          paciente_id TEXT NOT NULL,
          especialidad TEXT NOT NULL,
          fecha TEXT NOT NULL,
          hora TEXT NOT NULL,
          duracion_minutos INTEGER NOT NULL DEFAULT 60,
          terapeuta TEXT NOT NULL,
          estado TEXT NOT NULL DEFAULT 'confirmada',
          notas TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS historia_clinica (
          id TEXT PRIMARY KEY,
          paciente_id TEXT NOT NULL UNIQUE,
          hf_diabetes INTEGER DEFAULT 0,
          hf_hipertension INTEGER DEFAULT 0,
          hf_cancer INTEGER DEFAULT 0,
          hf_cardiopatia INTEGER DEFAULT 0,
          hf_obesidad INTEGER DEFAULT 0,
          hf_otros TEXT,
          ap_diabetes INTEGER DEFAULT 0,
          ap_hipertension INTEGER DEFAULT 0,
          ap_cardiopatia INTEGER DEFAULT 0,
          ap_asma INTEGER DEFAULT 0,
          ap_cancer INTEGER DEFAULT 0,
          ap_cirugias TEXT,
          ap_traumatismos TEXT,
          ap_hospitalizaciones TEXT,
          ap_otros TEXT,
          anp_tabaquismo TEXT,
          anp_alcoholismo TEXT,
          anp_drogas TEXT,
          anp_actividad_fisica TEXT,
          anp_alimentacion TEXT,
          anp_ocupacion TEXT,
          go_menarca TEXT,
          go_fur TEXT,
          go_gestas INTEGER,
          go_partos INTEGER,
          go_cesareas INTEGER,
          go_abortos INTEGER,
          go_anticonceptivos TEXT,
          padecimiento_actual TEXT,
          medicamentos_actuales TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS signos_vitales (
          id TEXT PRIMARY KEY,
          paciente_id TEXT NOT NULL,
          fecha TEXT NOT NULL,
          tension_sistolica INTEGER,
          tension_diastolica INTEGER,
          frecuencia_cardiaca INTEGER,
          frecuencia_respiratoria INTEGER,
          temperatura REAL,
          peso REAL,
          talla REAL,
          imc REAL,
          saturacion_oxigeno INTEGER,
          glucosa INTEGER,
          notas TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS usuarios (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          rol TEXT NOT NULL,
          activo INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      final existe = await db.query('usuarios',
          where: 'id = ?',
          whereArgs: ['00000000-0000-0000-0000-000000000001']);
      if (existe.isEmpty) {
        await db.insert('usuarios', {
          'id': '00000000-0000-0000-0000-000000000001',
          'nombre': 'Administrador',
          'email': 'admin@mediconfort.com',
          'password_hash': 'admin1234',
          'rol': 'admin',
          'activo': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notas_internas (
          id TEXT PRIMARY KEY,
          paciente_id TEXT NOT NULL,
          nota_clinica_id TEXT,
          contenido TEXT NOT NULL,
          autor TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
          FOREIGN KEY (nota_clinica_id) REFERENCES notas_clinicas(id)
        )
      ''');
    }
    if (oldVersion < 6) {
      // Verificar y agregar columnas solo si no existen
      final tableInfo = await db.rawQuery(
          'PRAGMA table_info(historia_clinica)');
      final columnas =
          tableInfo.map((c) => c['name'] as String).toSet();

      if (!columnas.contains('ap_fracturas')) {
        await db.execute(
            'ALTER TABLE historia_clinica ADD COLUMN ap_fracturas INTEGER DEFAULT 0');
      }
      if (!columnas.contains('ap_transfusiones')) {
        await db.execute(
            'ALTER TABLE historia_clinica ADD COLUMN ap_transfusiones INTEGER DEFAULT 0');
      }
      if (!columnas.contains('escala_eva')) {
        await db.execute(
            'ALTER TABLE historia_clinica ADD COLUMN escala_eva INTEGER');
      }
      if (!columnas.contains('escala_daniels')) {
        await db.execute(
            'ALTER TABLE historia_clinica ADD COLUMN escala_daniels INTEGER');
      }
      if (!columnas.contains('escala_glasgow')) {
        await db.execute(
            'ALTER TABLE historia_clinica ADD COLUMN escala_glasgow INTEGER');
      }
      if (!columnas.contains('escala_norton')) {
        await db.execute(
            'ALTER TABLE historia_clinica ADD COLUMN escala_norton INTEGER');
      }
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS adjuntos (
          id TEXT PRIMARY KEY,
          paciente_id TEXT NOT NULL,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL,
          tamano INTEGER,
          ruta_local TEXT,
          url TEXT,
          storage_path TEXT,
          descripcion TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (paciente_id) REFERENCES pacientes(id)
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS especialidades (
          id TEXT PRIMARY KEY,
          nombre TEXT NOT NULL UNIQUE,
          activa INTEGER NOT NULL DEFAULT 1,
          orden INTEGER NOT NULL DEFAULT 0
        )
      ''');

      final existentes = await db.query('especialidades');
      if (existentes.isEmpty) {
        final especialidadesDefault = [
          {'id': 'fisioterapia', 'nombre': 'Fisioterapia', 'orden': 0},
          {'id': 'quiropractica', 'nombre': 'Quiropráctica', 'orden': 1},
          {'id': 'spa', 'nombre': 'Spa', 'orden': 2},
          {'id': 'asesoria_deportiva', 'nombre': 'Asesoría deportiva', 'orden': 3},
        ];
        for (final e in especialidadesDefault) {
          await db.insert('especialidades', {...e, 'activa': 1});
        }
      }
    }

    if (oldVersion < 9) {
      final cols = await db.rawQuery(
          'PRAGMA table_info(pacientes)');
      final nombres =
          cols.map((c) => c['name'] as String).toSet();

      if (!nombres.contains('es_menor')) {
        await db.execute(
            'ALTER TABLE pacientes ADD COLUMN es_menor INTEGER DEFAULT 0');
      }
      if (!nombres.contains('responsable_nombre')) {
        await db.execute(
            'ALTER TABLE pacientes ADD COLUMN responsable_nombre TEXT');
      }
      if (!nombres.contains('responsable_parentesco')) {
        await db.execute(
            'ALTER TABLE pacientes ADD COLUMN responsable_parentesco TEXT');
      }
      if (!nombres.contains('responsable_telefono')) {
        await db.execute(
            'ALTER TABLE pacientes ADD COLUMN responsable_telefono TEXT');
      }
      if (!nombres.contains('responsable_curp')) {
        await db.execute(
            'ALTER TABLE pacientes ADD COLUMN responsable_curp TEXT');
      }
      if (!nombres.contains('consentimiento_tutor')) {
        await db.execute(
            'ALTER TABLE pacientes ADD COLUMN consentimiento_tutor INTEGER DEFAULT 0');
      }
    }

    if (oldVersion < 10) {
      final colsCitas = await db.rawQuery('PRAGMA table_info(citas)');
      final nombresCitas = colsCitas.map((c) => c['name'] as String).toSet();

      if (!nombresCitas.contains('nombre_temporal')) {
        await db.execute(
            'ALTER TABLE citas ADD COLUMN nombre_temporal TEXT');
      }
      if (!nombresCitas.contains('telefono_temporal')) {
        await db.execute(
            'ALTER TABLE citas ADD COLUMN telefono_temporal TEXT');
      }
    }

  }
}