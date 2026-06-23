import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ejercicio.dart';

class EjercicioService {
  static List<Ejercicio>? _cache;

  static Future<List<Ejercicio>> cargarTodos() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle
        .loadString('assets/data/exercises.json');
    final lista = jsonDecode(jsonStr) as List;
    _cache =
        lista.map((e) => Ejercicio.fromJson(e)).toList();
    return _cache!;
  }

  static Future<List<Ejercicio>> filtrar({
    String? categoria,
    String? musculoPrincipal,
    String? nivel,
    String? impacto,
    String? objetivo,
    String? busqueda,
  }) async {
    final todos = await cargarTodos();
    return todos.where((e) {
      if (categoria != null && e.category != categoria) {
        return false;
      }
      if (musculoPrincipal != null &&
          e.mainMuscle != musculoPrincipal) {
        return false;
      }
      if (nivel != null && e.level != nivel) {
        return false;
      }
      if (impacto != null && e.impact != impacto) {
        return false;
      }
      if (objetivo != null && e.objective != objetivo) {
        return false;
      }
      if (busqueda != null && busqueda.isNotEmpty) {
        final q = busqueda.toLowerCase();
        if (!e.name.toLowerCase().contains(q) &&
            !e.mainMuscle.toLowerCase().contains(q) &&
            !e.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  static Future<List<String>> getCategorias() async {
    final todos = await cargarTodos();
    return todos.map((e) => e.category).toSet().toList()
      ..sort();
  }

  static Future<List<String>> getMusculos(
      {String? categoria}) async {
    final todos = await cargarTodos();
    return todos
        .where((e) =>
            categoria == null || e.category == categoria)
        .map((e) => e.mainMuscle)
        .toSet()
        .toList()
      ..sort();
  }

  static Future<List<String>> getNiveles() async {
    final todos = await cargarTodos();
    return todos.map((e) => e.level).toSet().toList()
      ..sort();
  }

  static Future<List<String>> getImpactos() async {
    final todos = await cargarTodos();
    return todos.map((e) => e.impact).toSet().toList()
      ..sort();
  }

  static Future<List<String>> getObjetivos() async {
    final todos = await cargarTodos();
    return todos.map((e) => e.objective).toSet().toList()
      ..sort();
  }
}

