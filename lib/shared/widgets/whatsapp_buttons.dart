import 'package:flutter/material.dart';
import '../../core/models/cita.dart';
import '../../core/models/nota_clinica.dart';
import '../../core/models/paciente.dart';
import '../../core/services/whatsapp_service.dart';

class BotonWhatsAppCitaNueva extends StatelessWidget {
  final Cita cita;
  final Paciente paciente;

  const BotonWhatsAppCitaNueva({
    super.key,
    required this.cita,
    required this.paciente,
  });

  Future<void> _enviar(BuildContext context) async {
    if (paciente.telefono == null || paciente.telefono!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El paciente no tiene teléfono registrado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final partesFecha = cita.fecha.split('-');
    final fechaFormateada =
        '${partesFecha[2]}/${partesFecha[1]}/${partesFecha[0]}';

    final mensaje = await WhatsAppService.mensajeCitaNueva(
      nombrePaciente: paciente.nombre,
      fecha: fechaFormateada,
      hora: cita.hora,
      especialidad: cita.especialidad.nombre,
      terapeuta: cita.terapeuta,
    );

    final enviado = await WhatsAppService.enviarMensaje(
      telefono: paciente.telefono!,
      mensaje: mensaje,
    );

    if (!enviado && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF25D366),
        side: const BorderSide(color: Color(0xFF25D366)),
      ),
      icon: const Icon(Icons.message),
      label: const Text('Notificar por WhatsApp'),
      onPressed: () => _enviar(context),
    );
  }
}

class BotonWhatsAppRecordatorio extends StatelessWidget {
  final Cita cita;
  final Paciente paciente;

  const BotonWhatsAppRecordatorio({
    super.key,
    required this.cita,
    required this.paciente,
  });

  Future<void> _enviar(BuildContext context) async {
    if (paciente.telefono == null || paciente.telefono!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El paciente no tiene teléfono registrado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final mensaje = await WhatsAppService.mensajeRecordatorio(
      nombrePaciente: paciente.nombre,
      hora: cita.hora,
      especialidad: cita.especialidad.nombre,
      terapeuta: cita.terapeuta,
    );

    await WhatsAppService.enviarMensaje(
      telefono: paciente.telefono!,
      mensaje: mensaje,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Enviar recordatorio WhatsApp',
      icon: const Icon(Icons.message, color: Color(0xFF25D366)),
      onPressed: () => _enviar(context),
    );
  }
}

