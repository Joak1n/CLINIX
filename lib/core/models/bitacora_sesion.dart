import 'package:flutter/material.dart';

class BitacoraSesion {
  final String id;
  final String pacienteId;
  final String fecha;
  final int numeroSesion;
  final int? sesionesPrescitas;
  final String terapeuta;
  final int? dolorEva;
  final String? tratamientoRealizado;
  final String? respuestaTratamiento;
  final String? ejerciciosRealizados;
  final String? observaciones;
  final String createdAt;

  BitacoraSesion({
    required this.id,
    required this.pacienteId,
    required this.fecha,
    required this.numeroSesion,
    this.sesionesPrescitas,
    required this.terapeuta,
    this.dolorEva,
    this.tratamientoRealizado,
    this.respuestaTratamiento,
    this.ejerciciosRealizados,
    this.observaciones,
    required this.createdAt,
  });

  factory BitacoraSesion.fromMap(Map<String, dynamic> m) => BitacoraSesion(
        id: m['id'],
        pacienteId: m['paciente_id'],
        fecha: m['fecha'],
        numeroSesion: m['numero_sesion'] ?? 1,
        sesionesPrescitas: m['sesiones_prescritas'],
        terapeuta: m['terapeuta'],
        dolorEva: m['dolor_eva'],
        tratamientoRealizado: m['tratamiento_realizado'],
        respuestaTratamiento: m['respuesta_tratamiento'],
        ejerciciosRealizados: m['ejercicios_realizados'],
        observaciones: m['observaciones'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'paciente_id': pacienteId,
        'fecha': fecha,
        'numero_sesion': numeroSesion,
        'sesiones_prescritas': sesionesPrescitas,
        'terapeuta': terapeuta,
        'dolor_eva': dolorEva,
        'tratamiento_realizado': tratamientoRealizado,
        'respuesta_tratamiento': respuestaTratamiento,
        'ejercicios_realizados': ejerciciosRealizados,
        'observaciones': observaciones,
        'created_at': createdAt,
      };

  /// Texto corto de EVA para mostrar en tarjeta
  String get evaTexto {
    if (dolorEva == null) return 'Sin registro';
    if (dolorEva! == 0) return '0 — Sin dolor';
    if (dolorEva! <= 3) return '$dolorEva — Leve';
    if (dolorEva! <= 6) return '$dolorEva — Moderado';
    return '$dolorEva — Severo';
  }

  Color get evaColor {
    if (dolorEva == null || dolorEva! == 0) return const Color(0xFF4CAF50);
    if (dolorEva! <= 3) return const Color(0xFF8BC34A);
    if (dolorEva! <= 6) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }
}