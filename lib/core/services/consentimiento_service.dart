import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/consentimiento_informado.dart';
import 'supabase_service.dart';
import 'auditoria_service.dart';

/// Plantilla de consentimiento informado usada para fisioterapia,
/// quiropráctica, spa y asesoría deportiva. Genérica y en español;
/// no sustituye asesoría legal, pero cubre los puntos básicos que
/// se esperan en un consentimiento de este tipo de servicios.
const String textoConsentimientoInformado = '''
CONSENTIMIENTO INFORMADO PARA TRATAMIENTO

Por medio del presente documento, yo declaro que:

1. He sido informado(a) de manera clara sobre la naturaleza, objetivos, 
   beneficios y posibles riesgos del tratamiento de fisioterapia, 
   quiropráctica, spa y/o asesoría deportiva que se me brindará en este 
   consultorio.

2. He tenido la oportunidad de realizar preguntas sobre el tratamiento 
   propuesto y estas han sido respondidas a mi satisfacción.

3. Entiendo que, como en cualquier procedimiento terapéutico, pueden 
   presentarse molestias temporales (dolor muscular, sensibilidad, 
   enrojecimiento de la piel, entre otros) como parte normal del proceso, 
   y que el equipo del consultorio tomará las precauciones razonables 
   para minimizar cualquier riesgo.

4. Me comprometo a informar al personal del consultorio sobre 
   cualquier condición médica preexistente, lesión, embarazo o 
   medicamento que esté tomando y que pudiera ser relevante para mi 
   tratamiento.

5. Entiendo que puedo suspender el tratamiento en cualquier momento 
   si experimento molestias que considere importantes, y que debo 
   comunicarlo de inmediato al terapeuta.

6. Autorizo al personal de este consultorio a brindarme el tratamiento 
   descrito, así como a registrar mi evolución clínica con fines de 
   seguimiento del tratamiento.

7. Mis datos personales y clínicos serán tratados de forma 
   confidencial y solo serán utilizados para fines del seguimiento 
   de mi atención en este consultorio.

Al firmar este documento, confirmo que he leído y comprendido la 
información anterior, y otorgo mi consentimiento de manera libre 
y voluntaria.
''';

class ConsentimientoService {
  static const _uuid = Uuid();
  static const versionActual = 1;

  static Future<void> _asegurarTabla() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS consentimientos_informados (
        id TEXT PRIMARY KEY,
        paciente_id TEXT NOT NULL,
        fecha_firma TEXT NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        firma_base64 TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Guarda un nuevo consentimiento firmado para el paciente indicado.
  static Future<ConsentimientoInformado> guardar({
    required String pacienteId,
    required String firmaBase64,
  }) async {
    await _asegurarTabla();
    final db = await DatabaseHelper.instance.database;
    final ahora = DateTime.now().toIso8601String();
    final consentimiento = ConsentimientoInformado(
      id: _uuid.v4(),
      pacienteId: pacienteId,
      fechaFirma: ahora,
      version: versionActual,
      firmaBase64: firmaBase64,
      createdAt: ahora,
    );
    await db.insert('consentimientos_informados', consentimiento.toMap());
    _subir(consentimiento);
    AuditoriaService.registrar(
      accion: 'crear',
      entidad: 'consentimiento',
      entidadId: consentimiento.id,
      detalle: 'Consentimiento informado firmado',
    );
    return consentimiento;
  }

  static void _subir(ConsentimientoInformado c) async {
    try {
      await SupabaseService.client
          .from('consentimientos_informados')
          .upsert(c.toMap());
    } catch (_) {
      // Se reintentará con "Sincronizar con la nube".
    }
  }

  /// Devuelve el consentimiento más reciente de un paciente, o null si
  /// nunca ha firmado uno.
  static Future<ConsentimientoInformado?> obtenerMasReciente(
      String pacienteId) async {
    await _asegurarTabla();
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'consentimientos_informados',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'fecha_firma DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ConsentimientoInformado.fromMap(maps.first);
  }

  static Future<void> subirTodo() async {
    await _asegurarTabla();
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('consentimientos_informados');
    for (final m in maps) {
      try {
        await SupabaseService.client
            .from('consentimientos_informados')
            .upsert(m);
      } catch (_) {}
    }
  }

  static Future<void> bajarTodo() async {
    await _asegurarTabla();
    try {
      final rows =
          await SupabaseService.client.from('consentimientos_informados').select();
      final db = await DatabaseHelper.instance.database;
      for (final r in rows) {
        await db.insert(
          'consentimientos_informados',
          {
            'id': r['id'],
            'paciente_id': r['paciente_id'],
            'fecha_firma': r['fecha_firma'],
            'version': r['version'],
            'firma_base64': r['firma_base64'],
            'created_at': r['created_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }
}
