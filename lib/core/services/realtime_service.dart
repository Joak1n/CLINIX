import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'sync_service.dart';
import '../providers/realtime_provider.dart';
import 'package:sqflite/sqflite.dart';

class RealtimeService {
  static final List<RealtimeChannel> _canales = [];
  static ProviderContainer? _container;

  static void inicializar(ProviderContainer container) {
    _container = container;
    _suscribirTodo();
  }

  static void _suscribirTodo() {
    _suscribir('pacientes');
    _suscribir('notas_clinicas');
    _suscribir('citas');
    _suscribir('historia_clinica');
    _suscribir('signos_vitales');
    _suscribir('notas_internas');
    _suscribir('adjuntos');
    _suscribir('usuarios');
  }

  static void _suscribir(String tabla) {
    final canal = SupabaseService.client
        .channel('public:$tabla')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tabla,
          callback: (payload) async {
            await _procesarCambio(tabla, payload);
          },
        )
        .subscribe();

    _canales.add(canal);
  }

  static Future<void> _procesarCambio(
    String tabla,
    PostgresChangePayload payload,
  ) async {
    try {
      switch (tabla) {
        case 'pacientes':
          await _manejarCambioPaciente(payload);
          break;
        case 'notas_clinicas':
          await _manejarCambioNotaClinica(payload);
          break;
        case 'citas':
          await _manejarCambioCita(payload);
          break;
        case 'historia_clinica':
          await _manejarCambioHistoria(payload);
          break;
        case 'signos_vitales':
          await _manejarCambioSignos(payload);
          break;
        case 'notas_internas':
          await _manejarCambioNotaInterna(payload);
          break;
        case 'usuarios':
          await _manejarCambioUsuario(payload);
          break;
      }
      if (_container != null) {
        notificarCambio(_container!);
      }
    } catch (_) {}
  }

  static Future<void> _manejarCambioPaciente(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('notas_clinicas',
            where: 'paciente_id = ?', whereArgs: [oldId]);
        await db.delete('citas',
            where: 'paciente_id = ?', whereArgs: [oldId]);
        await db.delete('pacientes',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;
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
        'created_at': SyncService.toLocalTime(
            r['created_at']),
        'updated_at': SyncService.toLocalTime(
            r['updated_at']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _manejarCambioNotaClinica(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('notas_clinicas',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;
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
        'created_at': SyncService.toLocalTime(
            r['created_at']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _manejarCambioCita(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('citas',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;
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
        'created_at': SyncService.toLocalTime(
            r['created_at']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _manejarCambioHistoria(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('historia_clinica',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;
    await db.insert(
      'historia_clinica',
      {
        'id': r['id'],
        'paciente_id': r['paciente_id'],
        'hf_diabetes': r['hf_diabetes'] == true ? 1 : 0,
        'hf_hipertension':
            r['hf_hipertension'] == true ? 1 : 0,
        'hf_cancer': r['hf_cancer'] == true ? 1 : 0,
        'hf_cardiopatia':
            r['hf_cardiopatia'] == true ? 1 : 0,
        'hf_obesidad': r['hf_obesidad'] == true ? 1 : 0,
        'hf_otros': r['hf_otros'],
        'ap_diabetes': r['ap_diabetes'] == true ? 1 : 0,
        'ap_hipertension':
            r['ap_hipertension'] == true ? 1 : 0,
        'ap_cardiopatia':
            r['ap_cardiopatia'] == true ? 1 : 0,
        'ap_asma': r['ap_asma'] == true ? 1 : 0,
        'ap_cancer': r['ap_cancer'] == true ? 1 : 0,
        'ap_fracturas':
            r['ap_fracturas'] == true ? 1 : 0,
        'ap_transfusiones':
            r['ap_transfusiones'] == true ? 1 : 0,
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
        'created_at': SyncService.toLocalTime(
            r['created_at']),
        'updated_at': SyncService.toLocalTime(
            r['updated_at']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _manejarCambioSignos(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('signos_vitales',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;
    await db.insert(
      'signos_vitales',
      {
        'id': r['id'],
        'paciente_id': r['paciente_id'],
        'fecha': r['fecha'],
        'tension_sistolica': r['tension_sistolica'],
        'tension_diastolica': r['tension_diastolica'],
        'frecuencia_cardiaca': r['frecuencia_cardiaca'],
        'frecuencia_respiratoria':
            r['frecuencia_respiratoria'],
        'temperatura': r['temperatura'],
        'peso': r['peso'],
        'talla': r['talla'],
        'imc': r['imc'],
        'saturacion_oxigeno': r['saturacion_oxigeno'],
        'glucosa': r['glucosa'],
        'notas': r['notas'],
        'created_at': SyncService.toLocalTime(
            r['created_at']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _manejarCambioNotaInterna(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('notas_internas',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;
    await db.insert(
      'notas_internas',
      {
        'id': r['id'],
        'paciente_id': r['paciente_id'],
        'nota_clinica_id': r['nota_clinica_id'],
        'contenido': r['contenido'],
        'autor': r['autor'],
        'created_at': SyncService.toLocalTime(
            r['created_at']),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> _manejarCambioUsuario(
      PostgresChangePayload payload) async {
    final db = await SyncService.getDb();
    if (payload.eventType == PostgresChangeEvent.delete) {
      final oldId = payload.oldRecord['id'];
      if (oldId != null) {
        await db.delete('usuarios',
            where: 'id = ?', whereArgs: [oldId]);
      }
      return;
    }

    final r = payload.newRecord;
    if (r.isEmpty) return;

    final existente = await db.query('usuarios',
        where: 'email = ?', whereArgs: [r['email']]);
    if (existente.isEmpty) {
      await db.insert('usuarios', {
        'id': r['id'],
        'nombre': r['nombre'],
        'email': r['email'],
        'password_hash': r['password_hash'],
        'rol': r['rol'],
        'activo': r['activo'] == true ? 1 : 0,
        'created_at': SyncService.toLocalTime(
            r['created_at']),
        'updated_at': SyncService.toLocalTime(
            r['updated_at']),
      });
    } else {
      await db.update(
        'usuarios',
        {
          'nombre': r['nombre'],
          'password_hash': r['password_hash'],
          'rol': r['rol'],
          'activo': r['activo'] == true ? 1 : 0,
          'updated_at': SyncService.toLocalTime(
              r['updated_at']),
        },
        where: 'email = ?',
        whereArgs: [r['email']],
      );
    }
  }

  static void cancelarTodo() {
    for (final canal in _canales) {
      SupabaseService.client.removeChannel(canal);
    }
    _canales.clear();
  }
}

