import '../models/usuario.dart';

/// Guarda una referencia simple al usuario autenticado actual, para que
/// servicios que no tienen acceso a Riverpod (como AuditoriaService) puedan
/// saber quién está realizando una acción sin tener que pasar el usuario
/// como parámetro en cada llamada.
///
/// Se actualiza desde AuthNotifier cada vez que cambia la sesión.
class SesionActual {
  static Usuario? actual;
}
