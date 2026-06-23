import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/paciente.dart';
import 'paciente_repository.dart';
import '../../core/providers/realtime_provider.dart';

enum OrdenPacientes {
  nombreAsc,
  nombreDesc,
  recientes,
}

extension OrdenPacientesExt on OrdenPacientes {
  String get etiqueta {
    switch (this) {
      case OrdenPacientes.nombreAsc:  return 'A → Z';
      case OrdenPacientes.nombreDesc: return 'Z → A';
      case OrdenPacientes.recientes:  return 'Más recientes';
    }
  }

  String get sqlOrder {
    switch (this) {
      case OrdenPacientes.nombreAsc:  return 'apellido_paterno ASC, nombre ASC';
      case OrdenPacientes.nombreDesc: return 'apellido_paterno DESC, nombre DESC';
      case OrdenPacientes.recientes:  return 'created_at DESC';
    }
  }

  IconData get icono {
    switch (this) {
      case OrdenPacientes.nombreAsc:  return Icons.sort_by_alpha;
      case OrdenPacientes.nombreDesc: return Icons.sort_by_alpha;
      case OrdenPacientes.recientes:  return Icons.schedule;
    }
  }
}

final pacienteRepositoryProvider = Provider((ref) => PacienteRepository());

final ordenPacientesProvider =
    StateProvider<OrdenPacientes>((ref) => OrdenPacientes.nombreAsc);

final pacientesProvider =
    AsyncNotifierProvider<PacientesNotifier, List<Paciente>>(
  PacientesNotifier.new,
);
final busquedaProvider = StateProvider<String>((ref) => '');

final pacientesFiltradosProvider =
    AsyncNotifierProvider<PacientesFiltradosNotifier, List<Paciente>>(
    PacientesFiltradosNotifier.new,
  );

  class PacientesFiltradosNotifier
      extends AsyncNotifier<List<Paciente>> {
    @override
    Future<List<Paciente>> build() async {
      ref.watch(realtimeVersionProvider);
      final query = ref.watch(busquedaProvider);
      if (query.isEmpty) {
        final orden = ref.watch(ordenPacientesProvider);
        return ref
            .read(pacienteRepositoryProvider)
            .obtenerTodos(orderBy: orden.sqlOrder);
      }
      return ref
          .read(pacienteRepositoryProvider)
          .buscar(query);
    }
  }

class PacientesNotifier extends AsyncNotifier<List<Paciente>> {
  @override
  Future<List<Paciente>> build() async {
    final orden = ref.watch(ordenPacientesProvider);
    return ref
        .read(pacienteRepositoryProvider)
        .obtenerTodos(orderBy: orden.sqlOrder);
  }

  Future<void> agregar({
    required String nombre,
    required String apellidoPaterno,
    String? apellidoMaterno,
    required String fechaNacimiento,
    required String sexo,
    String? curp,
    String? telefono,
    String? email,
    String? alergias,
  }) async {
    await ref.read(pacienteRepositoryProvider).crear(
          nombre: nombre,
          apellidoPaterno: apellidoPaterno,
          apellidoMaterno: apellidoMaterno,
          fechaNacimiento: fechaNacimiento,
          sexo: sexo,
          curp: curp,
          telefono: telefono,
          email: email,
          alergias: alergias,
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> actualizar(Paciente paciente) async {
    await ref.read(pacienteRepositoryProvider).actualizar(paciente);
    ref.invalidateSelf();
    await future;
  }

  Future<void> eliminar(String id) async {
    await ref.read(pacienteRepositoryProvider).eliminar(id);
    ref.invalidateSelf();
    await future;
  }
}

