import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm, Sqflite;
import '../database/database_helper.dart';
import '../models/horario_atencion.dart';
import 'supabase_service.dart';

class HorarioService {
  // ── Helpers internos ────────────────────────────────────────────────────

  /// Asegura que las tablas existan aunque la migración no haya corrido
  static Future<void> _asegurarTablas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS horarios_atencion (
        dia_semana INTEGER PRIMARY KEY,
        activo INTEGER NOT NULL DEFAULT 1,
        hora_inicio TEXT NOT NULL DEFAULT '09:00',
        hora_fin TEXT NOT NULL DEFAULT '18:00'
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bloqueos_horario (
        id TEXT PRIMARY KEY,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        hora_inicio TEXT,
        hora_fin TEXT,
        es_dia_completo INTEGER NOT NULL DEFAULT 0,
        motivo TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    // Si horarios_atencion está vacía, insertar defaults
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM horarios_atencion'));
    if (count == 0) {
      for (int dia = 1; dia <= 7; dia++) {
        await db.insert('horarios_atencion', {
          'dia_semana': dia,
          'activo': dia <= 6 ? 1 : 0,
          'hora_inicio': '09:00',
          'hora_fin': dia == 6 ? '14:00' : '18:00',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  // ── Horarios de atención ────────────────────────────────────────────────

  static Future<List<HorarioAtencion>> obtenerHorarios() async {
    final db = await DatabaseHelper.instance.database;
    await _asegurarTablas(db);
    final maps = await db.query('horarios_atencion', orderBy: 'dia_semana ASC');
    return maps.map((m) => HorarioAtencion.fromMap(m)).toList();
  }

  static Future<HorarioAtencion?> obtenerHorarioDia(int diaSemana) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'horarios_atencion',
      where: 'dia_semana = ?',
      whereArgs: [diaSemana],
      limit: 1,
    );
    return maps.isEmpty ? null : HorarioAtencion.fromMap(maps.first);
  }

  static Future<void> guardarTodos(List<HorarioAtencion> horarios) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final h in horarios) {
      batch.insert('horarios_atencion', h.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
    for (final h in horarios) {
      _subirHorario(h);
    }
  }

  static void _subirHorario(HorarioAtencion h) async {
    try {
      await SupabaseService.client.from('horarios_atencion').upsert(h.toMap());
    } catch (_) {
      // Se reintentará con "Sincronizar con la nube".
    }
  }

  // ── Bloqueos ────────────────────────────────────────────────────────────

  static Future<List<BloqueoHorario>> obtenerBloqueos({bool soloFuturos = false}) async {
    final db = await DatabaseHelper.instance.database;
    final hoy = _isoFecha(DateTime.now());
    final maps = await db.query(
      'bloqueos_horario',
      where: soloFuturos ? 'fecha_fin >= ?' : null,
      whereArgs: soloFuturos ? [hoy] : null,
      orderBy: 'fecha_inicio ASC',
    );
    return maps.map((m) => BloqueoHorario.fromMap(m)).toList();
  }

  static Future<void> agregarBloqueo(BloqueoHorario bloqueo) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('bloqueos_horario', bloqueo.toMap());
    try {
      await SupabaseService.client
          .from('bloqueos_horario')
          .upsert(bloqueo.toMap());
    } catch (_) {}
  }

  static Future<void> eliminarBloqueo(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('bloqueos_horario', where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('bloqueos_horario')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  // ── Sincronización con Supabase ─────────────────────────────────────────

  static Future<void> subirTodo() async {
    final db = await DatabaseHelper.instance.database;
    await _asegurarTablas(db);
    final horarios = await db.query('horarios_atencion');
    for (final h in horarios) {
      try {
        await SupabaseService.client.from('horarios_atencion').upsert(h);
      } catch (_) {}
    }
    final bloqueos = await db.query('bloqueos_horario');
    for (final b in bloqueos) {
      try {
        await SupabaseService.client.from('bloqueos_horario').upsert(b);
      } catch (_) {}
    }
  }

  static Future<void> bajarTodo() async {
    final db = await DatabaseHelper.instance.database;
    await _asegurarTablas(db);
    try {
      final horarios =
          await SupabaseService.client.from('horarios_atencion').select();
      for (final h in horarios) {
        await db.insert('horarios_atencion', h,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
    try {
      final bloqueos =
          await SupabaseService.client.from('bloqueos_horario').select();
      for (final b in bloqueos) {
        await db.insert('bloqueos_horario', b,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {}
  }

  // ── Disponibilidad ──────────────────────────────────────────────────────

  static Future<List<String>> slotsDisponibles({
    required DateTime fecha,
    required String terapeutaNombre,
    required int duracionMinutos,
  }) async {
    final horario = await obtenerHorarioDia(fecha.weekday);
    if (horario == null || !horario.activo) return [];

    final todos = horario.slots(duracionMinutos);
    if (todos.isEmpty) return [];

    final fechaStr = _isoFecha(fecha);
    final bloqueos = await obtenerBloqueos();
    final bloqueosDelDia = bloqueos.where((b) => b.abarcaFecha(fechaStr)).toList();

    final db = await DatabaseHelper.instance.database;
    final citasMaps = await db.query(
      'citas',
      where: 'fecha = ? AND terapeuta = ? AND estado != ?',
      whereArgs: [fechaStr, terapeutaNombre, 'cancelada'],
    );
    final horasCitas = citasMaps.map((c) => c['hora'] as String).toSet();

    return todos.where((slot) {
      if (horasCitas.contains(slot)) return false;
      for (final b in bloqueosDelDia) {
        if (b.bloqueaSlot(fechaStr, slot)) return false;
      }
      return true;
    }).toList();
  }

  /// Slots donde hay al menos un terapeuta libre (respetando terapeutasSimultaneos).
  /// Usado cuando el paciente no tiene preferencia de terapeuta.
  static Future<List<String>> slotsDisponiblesTotales({
    required DateTime fecha,
    required int duracionMinutos,
    required int terapeutasSimultaneos,
  }) async {
    final horario = await obtenerHorarioDia(fecha.weekday);
    if (horario == null || !horario.activo) return [];

    final todos = horario.slots(duracionMinutos);
    if (todos.isEmpty) return [];

    final fechaStr = _isoFecha(fecha);
    final bloqueos = await obtenerBloqueos();
    final bloqueosDelDia = bloqueos.where((b) => b.abarcaFecha(fechaStr)).toList();

    final db = await DatabaseHelper.instance.database;
    // Contar citas por slot (sin importar terapeuta)
    final citasMaps = await db.query(
      'citas',
      where: 'fecha = ? AND estado != ?',
      whereArgs: [fechaStr, 'cancelada'],
    );
    // Mapa slot → cantidad de citas en ese horario
    final conteo = <String, int>{};
    for (final c in citasMaps) {
      final hora = c['hora'] as String;
      conteo[hora] = (conteo[hora] ?? 0) + 1;
    }

    return todos.where((slot) {
      // Bloqueado si hay bloqueo activo
      for (final b in bloqueosDelDia) {
        if (b.bloqueaSlot(fechaStr, slot)) return false;
      }
      // Bloqueado si ya se llenó la capacidad simultánea
      final citasEnSlot = conteo[slot] ?? 0;
      return citasEnSlot < terapeutasSimultaneos;
    }).toList();
  }

  static Future<String> generarMensajeDisponibilidad({
    required DateTime fecha,
    required int duracionMinutos,
    required String nombreConsultorio,
    String? terapeutaNombre, // null = sin preferencia
    required int terapeutasSimultaneos,
  }) async {
    final horario = await obtenerHorarioDia(fecha.weekday);
    if (horario == null || !horario.activo) {
      return '📅 ${_fechaTexto(fecha)}\n\nLo sentimos, no tenemos disponibilidad ese día.';
    }

    final buffer = StringBuffer();
    buffer.writeln('📅 Disponibilidad para el ${_fechaTexto(fecha)}');
    buffer.writeln();

    if (terapeutaNombre != null) {
      // ── Terapeuta específico ──
      final slots = await slotsDisponibles(
        fecha: fecha,
        terapeutaNombre: terapeutaNombre,
        duracionMinutos: duracionMinutos,
      );
      if (slots.isEmpty) {
        return '📅 ${_fechaTexto(fecha)}\n\n'
            '$terapeutaNombre no tiene horarios disponibles ese día.';
      }
      buffer.writeln('👤 $terapeutaNombre');
      for (final slot in slots) {
        buffer.writeln('• $slot - ${_sumarMin(slot, duracionMinutos)}');
      }
    } else {
      // ── Sin preferencia: slots donde hay al menos un lugar libre ──
      final slots = await slotsDisponiblesTotales(
        fecha: fecha,
        duracionMinutos: duracionMinutos,
        terapeutasSimultaneos: terapeutasSimultaneos,
      );
      if (slots.isEmpty) {
        return '📅 ${_fechaTexto(fecha)}\n\nLo sentimos, no tenemos horarios disponibles ese día.';
      }
      for (final slot in slots) {
        buffer.writeln('• $slot - ${_sumarMin(slot, duracionMinutos)}');
      }
    }

    return buffer.toString().trimRight();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static String _isoFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fechaTexto(DateTime d) {
    const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    const meses = ['', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
        'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    return '${dias[d.weekday]} ${d.day} de ${meses[d.month]}';
  }

  static String _sumarMin(String hora, int min) {
    final p = hora.split(':');
    final t = int.parse(p[0]) * 60 + int.parse(p[1]) + min;
    return '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
  }
}