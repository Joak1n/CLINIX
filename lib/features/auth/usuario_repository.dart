import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/usuario.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/auditoria_service.dart';
import '../../core/utils/hash_util.dart';

class UsuarioRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<Usuario?> login(String email, String password) async {
    final db = await _db.database;
    final maps = await db.query(
      'usuarios',
      where: 'email = ? AND activo = 1',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (maps.isEmpty) return null;

    final usuario = maps.first;
    final hashGuardado = usuario['password_hash'] as String;

    // Soportar tanto hash como texto plano (migración gradual)
    final passwordCorrecta =
        HashUtil.verificar(password, hashGuardado) ||
        hashGuardado == password;

    if (!passwordCorrecta) return null;

    // Si la contraseña estaba en texto plano, migrarla a hash
    if (hashGuardado == password) {
      await _migrarPasswordAHash(
          usuario['id'] as String, password);
    }

    return Usuario.fromMap(usuario);
  }

  Future<void> _migrarPasswordAHash(
      String id, String password) async {
    final hash = HashUtil.hashPassword(password);
    final db = await _db.database;
    await db.update(
      'usuarios',
      {
        'password_hash': hash,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    try {
      await SupabaseService.client
          .from('usuarios')
          .update({'password_hash': hash}).eq('id', id);
    } catch (_) {}
  }

  Future<List<Usuario>> obtenerTodos() async {
    final db = await _db.database;
    final maps = await db.query('usuarios',
        orderBy: 'nombre ASC');
    return maps.map((m) => Usuario.fromMap(m)).toList();
  }

  Future<void> crear({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    final db = await _db.database;
    final ahora = DateTime.now().toIso8601String();
    final id = _uuid.v4();
    final hash = HashUtil.hashPassword(password);

    await db.insert('usuarios', {
      'id': id,
      'nombre': nombre.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': hash,
      'rol': rol.valor,
      'activo': 1,
      'created_at': ahora,
      'updated_at': ahora,
    });

    try {
      await SupabaseService.client.from('usuarios').upsert({
        'id': id,
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'password_hash': hash,
        'rol': rol.valor,
        'activo': true,
      });
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'crear',
      entidad: 'usuario',
      entidadId: id,
      detalle: '${nombre.trim()} (${rol.etiqueta})',
    );
  }

  Future<void> actualizarEstado(String id, bool activo) async {
    final db = await _db.database;
    await db.update(
      'usuarios',
      {
        'activo': activo ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    try {
      await SupabaseService.client
          .from('usuarios')
          .update({'activo': activo}).eq('id', id);
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'cambiar_estado',
      entidad: 'usuario',
      entidadId: id,
      detalle: activo ? 'Activado' : 'Desactivado',
    );
  }

  Future<void> cambiarPassword(
      String id, String nuevaPassword) async {
    final hash = HashUtil.hashPassword(nuevaPassword);
    final db = await _db.database;
    await db.update(
      'usuarios',
      {
        'password_hash': hash,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    try {
      await SupabaseService.client
          .from('usuarios')
          .update({'password_hash': hash}).eq('id', id);
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'actualizar',
      entidad: 'usuario',
      entidadId: id,
      detalle: 'Contraseña actualizada',
    );
  }

  Future<void> eliminar(String id) async {
    final db = await _db.database;
    await db.delete('usuarios',
        where: 'id = ?', whereArgs: [id]);
    try {
      await SupabaseService.client
          .from('usuarios')
          .delete()
          .eq('id', id);
    } catch (_) {}
    AuditoriaService.registrar(
      accion: 'eliminar',
      entidad: 'usuario',
      entidadId: id,
    );
  }
}

