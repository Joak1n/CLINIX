import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Un lienzo simple para capturar una firma a mano (con el dedo o mouse).
/// No depende de paquetes externos: usa CustomPainter + RepaintBoundary
/// para poder exportar la firma como PNG.
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  SignaturePadState createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _trazos = [];
  final GlobalKey _repaintKey = GlobalKey();

  bool get tieneFirma => _trazos.isNotEmpty;

  void limpiar() => setState(() => _trazos.clear());

  void _iniciarTrazo(Offset punto) {
    setState(() => _trazos.add([punto]));
  }

  void _continuarTrazo(Offset punto) {
    setState(() => _trazos.last.add(punto));
  }

  /// Exporta la firma actual como bytes PNG. Retorna null si no hay firma.
  Future<Uint8List?> exportarPng() async {
    if (_trazos.isEmpty) return null;
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        color: Colors.white,
        child: GestureDetector(
          onPanStart: (details) =>
              _iniciarTrazo(details.localPosition),
          onPanUpdate: (details) =>
              _continuarTrazo(details.localPosition),
          child: CustomPaint(
            painter: _TrazosPainter(_trazos),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _TrazosPainter extends CustomPainter {
  final List<List<Offset>> trazos;
  _TrazosPainter(this.trazos);

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final trazo in trazos) {
      for (var i = 0; i < trazo.length - 1; i++) {
        canvas.drawLine(trazo[i], trazo[i + 1], pintura);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrazosPainter oldDelegate) => true;
}
