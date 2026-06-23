import 'package:url_launcher/url_launcher.dart';
import 'configuracion_service.dart';

class WhatsAppService {
  static Future<bool> enviarMensaje({
    required String telefono,
    required String mensaje,
  }) async {
    final numero = _limpiarTelefono(telefono);
    final mensajeCodificado = Uri.encodeComponent(mensaje);
    final url = Uri.parse('https://wa.me/$numero?text=$mensajeCodificado');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  static String _limpiarTelefono(String telefono) {
    String limpio = telefono.replaceAll(RegExp(r'[^\d]'), '');
    if (limpio.startsWith('0')) {
      limpio = '52${limpio.substring(1)}';
    } else if (limpio.length == 10) {
      limpio = '52$limpio';
    }
    return limpio;
  }

  // Ahora lee nombre y teléfono dinámicamente
  static Future<String> mensajeCitaNueva({
  required String nombrePaciente,
  required String fecha,
  required String hora,
  required String especialidad,
  required String terapeuta,
  }) async {
    final nombreConsultorio =
        await ConfiguracionService.getNombreConsultorio();
    final telefonoConsultorio =
        await ConfiguracionService.getTelefonoConsultorio();

    return 'Hola $nombrePaciente!\n\n'
        'Tu cita en *$nombreConsultorio* ha sido registrada exitosamente.\n\n'
        '*Fecha:* $fecha\n'
        '*Hora:* $hora\n'
        '*Servicio:* $especialidad\n'
        '*Terapeuta:* $terapeuta\n\n'
        'Para *confirmar* tu cita responde este mensaje con la palabra CONFIRMO.\n\n'
        'Para *cancelar o reprogramar* comunicate al $telefonoConsultorio.\n\n'
        'Te esperamos!';
  }

  static Future<String> mensajeRecordatorio({
    required String nombrePaciente,
    required String hora,
    required String especialidad,
    required String terapeuta,
  }) async {
    final nombreConsultorio =
        await ConfiguracionService.getNombreConsultorio();
    final telefonoConsultorio =
        await ConfiguracionService.getTelefonoConsultorio();

    return 'Buenos dias $nombrePaciente!\n\n'
        'Te recordamos que *hoy* tienes una cita en *$nombreConsultorio*.\n\n'
        '*Hora:* $hora\n'
        '*Servicio:* $especialidad\n'
        '*Terapeuta:* $terapeuta\n\n'
        'Para *confirmar tu asistencia* responde CONFIRMO.\n\n'
        'Si necesitas *cancelar o cambiar* tu cita, llamanos al $telefonoConsultorio.\n\n'
        'Hasta pronto!';
  }

  static Future<String> mensajeCancelacion({
    required String nombrePaciente,
    required String fecha,
    required String hora,
  }) async {
    final nombreConsultorio =
        await ConfiguracionService.getNombreConsultorio();
    final telefonoConsultorio =
        await ConfiguracionService.getTelefonoConsultorio();

    return 'Hola $nombrePaciente,\n\n'
        'Lamentamos informarte que tu cita del *$fecha a las $hora* '
        'en *$nombreConsultorio* ha sido cancelada.\n\n'
        'Para reprogramar tu cita comunicate con nosotros al $telefonoConsultorio.\n\n'
        'Disculpa los inconvenientes.';
  }
}

