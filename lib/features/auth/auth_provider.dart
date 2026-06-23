import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/usuario.dart';
import 'usuario_repository.dart';

final usuarioRepositoryProvider =
    Provider((ref) => UsuarioRepository());

class AuthState {
  final Usuario? usuario;
  final bool cargando;
  final String? error;

  const AuthState({
    this.usuario,
    this.cargando = false,
    this.error,
  });

  bool get autenticado => usuario != null;

  AuthState copyWith({
    Usuario? usuario,
    bool? cargando,
    String? error,
    bool limpiarUsuario = false,
    bool limpiarError = false,
  }) {
    return AuthState(
      usuario:
          limpiarUsuario ? null : (usuario ?? this.usuario),
      cargando: cargando ?? this.cargando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('session_email');
    final passwordHash =
        prefs.getString('session_password_hash');

    if (email != null && passwordHash != null) {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'usuarios',
        where:
            'email = ? AND password_hash = ? AND activo = 1',
        whereArgs: [email, passwordHash],
      );
      if (maps.isNotEmpty) {
        return AuthState(
            usuario: Usuario.fromMap(maps.first));
      }
    }
    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncData(AuthState(cargando: true));

    final usuario = await ref
        .read(usuarioRepositoryProvider)
        .login(email, password);

    if (usuario == null) {
      state = const AsyncData(
        AuthState(
            error: 'Correo o contraseña incorrectos'),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'session_email', email.trim().toLowerCase());
    await prefs.setString(
        'session_password_hash', usuario.passwordHash);

    state = AsyncData(AuthState(usuario: usuario));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_email');
    await prefs.remove('session_password_hash');
    state = const AsyncData(AuthState());
  }
}

