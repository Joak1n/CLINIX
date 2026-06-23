import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/paciente.dart';
import '../models/nota_clinica.dart';
import '../models/historia_clinica.dart';
import '../models/signos_vitales.dart';
import 'configuracion_service.dart';
import 'package:flutter/foundation.dart';
import '../models/comprobante.dart';
import '../models/ejercicio.dart';
import '../models/adjunto.dart';
import 'package:flutter/material.dart' show Color hide Color;

class PdfService {
  /// Genera el PDF completo del expediente y retorna la ruta del archivo
  static Future<String> generarExpediente({
    required Paciente paciente,
    required List<NotaClinica> notas,
    HistoriaClinica? historia,
    List<SignosVitales> signosVitales = const [],
    List<Adjunto> adjuntos = const [],
  }) async {
    final pdf = pw.Document();
    final nombreConsultorio =
        await ConfiguracionService.getNombreConsultorio();
    final direccionConsultorio =
      await ConfiguracionService.getDireccionConsultorio();
    final telefonoConsultorio =
        await ConfiguracionService.getTelefonoConsultorio();
    final logoPath = await ConfiguracionService.getLogoPath();

    // Cargar logo si existe
    pw.ImageProvider? logoImage;
    if (logoPath != null && await File(logoPath).exists()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    }

    // Colores corporativos
    final colorPrimario = await getColorPrimarioPdf();
    final colorFondo = await getColorFondoPdf();
    final colorTextoGris = PdfColor.fromHex('#666666');
    final colorBorde = PdfColor.fromHex('#E0E0E0');

    // Calcular edad
    int edad = 0;
    try {
      final fn = DateTime.parse(paciente.fechaNacimiento);
      final hoy = DateTime.now();
      edad = hoy.year - fn.year;
      if (hoy.month < fn.month ||
          (hoy.month == fn.month && hoy.day < fn.day)) {
        edad--;
      }
    } catch (_) {}

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _encabezado(nombreConsultorio, telefonoConsultorio,
                logoImage, colorPrimario, colorBorde, direccionConsultorio),
        footer: (context) =>
            _piePagina(context, colorTextoGris, colorBorde),
        build: (context) => [
          // Datos del paciente
          _seccionPaciente(paciente, edad, colorPrimario,
              colorFondo, colorBorde, colorTextoGris),
          pw.SizedBox(height: 16),

          // Historia clínica
          if (historia != null) ...[
            _seccionHistoria(historia, colorPrimario,
                colorFondo, colorBorde, colorTextoGris),
            pw.SizedBox(height: 16),
          ],

          // Signos vitales
          if (signosVitales.isNotEmpty) ...[
            _seccionSignosVitales(signosVitales.first,
                colorPrimario, colorFondo, colorBorde,
                colorTextoGris),
            pw.SizedBox(height: 16),
          ],

          // Adjuntos (imágenes)
          if (adjuntos.isNotEmpty) ...[
            _seccionAdjuntos(adjuntos, colorPrimario,
                colorFondo, colorBorde, colorTextoGris),
            pw.SizedBox(height: 16),
          ],

          // Notas de evolución
          if (notas.isNotEmpty)
            _seccionNotas(notas, colorPrimario, colorFondo,
                colorBorde, colorTextoGris),
        ],
      ),
    );

    // Guardar archivo
    // Guardar en ruta accesible según plataforma
    final String dirPath;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // En Android usar directorio de descargas temporal
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dirPath = dir.path;
    }

    final nombreArchivo =
        'Expediente_${paciente.apellidoPaterno}_${paciente.nombre}_'
        '${DateTime.now().millisecondsSinceEpoch}.pdf';
    final archivo = File('$dirPath/$nombreArchivo');
    await archivo.writeAsBytes(await pdf.save());
    return archivo.path;
  }

  static Future<PdfColor> getColorPrimarioPdf() async {
    final colorInt =
        await ConfiguracionService.getColorPrimario();
    final r = ((colorInt >> 16) & 0xFF) / 255.0;
    final g = ((colorInt >> 8) & 0xFF) / 255.0;
    final b = (colorInt & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  static Future<PdfColor> getColorFondoPdf() async {
    final colorInt =
        await ConfiguracionService.getColorFondo();
    final r = ((colorInt >> 16) & 0xFF) / 255.0;
    final g = ((colorInt >> 8) & 0xFF) / 255.0;
    final b = (colorInt & 0xFF) / 255.0;
    return PdfColor(r, g, b);
  }

  static pw.Widget _seccionAdjuntos(    // Solo se incluyen imágenes en el PDF, los PDFs se mantienen como adjuntos separados
    List<Adjunto> adjuntos,
    PdfColor colorPrimario,
    PdfColor colorFondo,
    PdfColor colorBorde,
    PdfColor colorTextoGris,
  ) {
    // Solo incluir imágenes en el PDF
    final imagenes = adjuntos
        .where((a) =>
            a.esImagen &&
            a.rutaLocal != null &&
            File(a.rutaLocal!).existsSync())
        .toList();

    if (imagenes.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion(
            'ESTUDIOS DE GABINETE', colorPrimario),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: imagenes.map((a) {
            final bytes =
                File(a.rutaLocal!).readAsBytesSync();
            return pw.Container(
              width: 240,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: colorBorde),
                borderRadius:
                    pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    a.descripcion ?? a.nombre,
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Image(
                    pw.MemoryImage(bytes),
                    height: 160,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    a.fechaFormateada,
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: colorTextoGris),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  // ── Encabezado ────────────────────────────────────────────────────────

  static pw.Widget _encabezado(
    String nombre,
    String telefono,
    pw.ImageProvider? logo,
    PdfColor colorPrimario,
    PdfColor colorBorde,
    String? direccion,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 48,
                height: 48,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 48,
                height: 48,
                decoration: pw.BoxDecoration(
                  color: colorPrimario,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'M',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(nombre,
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario)),
                  if (direccion != null)
                    pw.Text(direccion,
                        style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromHex('#444444'))),
                  pw.Text('Tel: $telefono',
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromHex('#666666'))),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('EXPEDIENTE CLÍNICO',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario)),
                pw.Text(
                  'NOM-004-SSA3-2012',
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('#666666')),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: colorPrimario, thickness: 1.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  // ── Pie de página ────────────────────────────────────────────────────

  static pw.Widget _piePagina(
    pw.Context context,
    PdfColor colorTextoGris,
    PdfColor colorBorde,
  ) {
    final ahora = DateTime.now();
    final fecha =
        '${ahora.day.toString().padLeft(2, '0')}/'
        '${ahora.month.toString().padLeft(2, '0')}/'
        '${ahora.year}';
    return pw.Column(
      children: [
        pw.Divider(color: colorBorde),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generado el $fecha',
                style: pw.TextStyle(
                    fontSize: 8, color: colorTextoGris)),
            pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: pw.TextStyle(
                    fontSize: 8, color: colorTextoGris)),
            pw.Text('Documento confidencial',
                style: pw.TextStyle(
                    fontSize: 8, color: colorTextoGris)),
          ],
        ),
      ],
    );
  }

  // ── Sección: datos del paciente ───────────────────────────────────────

  static pw.Widget _seccionPaciente(
    Paciente p,
    int edad,
    PdfColor colorPrimario,
    PdfColor colorFondo,
    PdfColor colorBorde,
    PdfColor colorTextoGris,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('DATOS DEL PACIENTE', colorPrimario),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: colorFondo,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: colorBorde),
          ),
          child: pw.Column(
            children: [
              _filaDatos([
                _dato('Nombre completo', p.nombreCompleto),
                _dato('Fecha de nacimiento', p.fechaNacimiento),
                _dato('Edad', '$edad años'),
              ]),
              pw.SizedBox(height: 8),
              _filaDatos([
                _dato('Sexo', p.sexo),
                _dato('CURP', p.curp ?? '—'),
                _dato('Teléfono', p.telefono ?? '—'),
              ]),
              if (p.alergias != null) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF3F3'),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                        color: PdfColor.fromHex('#FFCCCC')),
                  ),
                  child: pw.Text(
                    '⚠ Alergias: ${p.alergias}',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#CC0000')),
                  ),
                ),
              ],
              if (p.esMenorDeEdad) ...[
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF8E1'),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(
                        color: PdfColor.fromHex('#FFB300')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PACIENTE MENOR DE EDAD — Responsable Legal',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#E65100')),
                      ),
                      pw.SizedBox(height: 4),
                      _filaDatos([
                        _dato('Responsable',
                            p.responsableNombre ?? '—'),
                        _dato('Parentesco',
                            p.responsableParentesco ?? '—'),
                        _dato('Teléfono',
                            p.responsableTelefono ?? '—'),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        p.consentimientoTutor
                            ? '✓ Consentimiento informado firmado por responsable legal (Art. 10 NOM-004-SSA3-2012)'
                            : '⚠ PENDIENTE: Consentimiento informado del responsable legal',
                        style: pw.TextStyle(
                            fontSize: 8,
                            color: p.consentimientoTutor
                                ? PdfColor.fromHex('#2E7D32')
                                : PdfColor.fromHex('#C62828')),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Sección: historia clínica ─────────────────────────────────────────

  static pw.Widget _seccionHistoria(
    HistoriaClinica h,
    PdfColor colorPrimario,
    PdfColor colorFondo,
    PdfColor colorBorde,
    PdfColor colorTextoGris,
  ) {
    // Heredofamiliares
    final hf = <String>[];
    if (h.hfDiabetes) hf.add('Diabetes');
    if (h.hfHipertension) hf.add('Hipertensión');
    if (h.hfCancer) hf.add('Cáncer');
    if (h.hfCardiopatia) hf.add('Cardiopatía');
    if (h.hfObesidad) hf.add('Obesidad');
    if (h.hfOtros != null) hf.add(h.hfOtros!);

    // Patológicos
    final ap = <String>[];
    if (h.apDiabetes) ap.add('Diabetes');
    if (h.apHipertension) ap.add('Hipertensión');
    if (h.apCardiopatia) ap.add('Cardiopatía');
    if (h.apAsma) ap.add('Asma');
    if (h.apCancer) ap.add('Cáncer');
    if (h.apFracturas) ap.add('Fracturas');
    if (h.apTransfusiones) ap.add('Transfusiones');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion('HISTORIA CLÍNICA', colorPrimario),

        // ── Padecimiento actual ──────────────────────────────
        if (h.padecimientoActual != null) ...[
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: colorFondo,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: colorBorde),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _subtitulo('Padecimiento actual', colorTextoGris),
                pw.Text(h.padecimientoActual!,
                    style: const pw.TextStyle(fontSize: 10)),
                if (h.medicamentosActuales != null) ...[
                  pw.SizedBox(height: 6),
                  _subtitulo('Medicamentos actuales', colorTextoGris),
                  pw.Text(h.medicamentosActuales!,
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
          ),
        ],

        // ── Antecedentes heredofamiliares ────────────────────
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: colorFondo,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: colorBorde),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _subtitulo('Antecedentes heredofamiliares',
                  colorTextoGris),
              pw.Text(
                  hf.isEmpty ? 'Niega antecedentes' : hf.join(', '),
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),

        // ── Antecedentes patológicos ─────────────────────────
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: colorFondo,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: colorBorde),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _subtitulo('Antecedentes patológicos personales',
                  colorTextoGris),
              pw.Text(
                  ap.isEmpty ? 'Niega antecedentes' : ap.join(', '),
                  style: const pw.TextStyle(fontSize: 10)),
              if (h.apCirugias != null) ...[
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Cirugías: ',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTextoGris),
                      ),
                      pw.TextSpan(
                        text: h.apCirugias!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
              if (h.apTraumatismos != null) ...[
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Traumatismos: ',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTextoGris),
                      ),
                      pw.TextSpan(
                        text: h.apTraumatismos!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
              if (h.apHospitalizaciones != null) ...[
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Hospitalizaciones: ',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTextoGris),
                      ),
                      pw.TextSpan(
                        text: h.apHospitalizaciones!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
              if (h.apOtros != null) ...[
                pw.SizedBox(height: 4),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Otros: ',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: colorTextoGris),
                      ),
                      pw.TextSpan(
                        text: h.apOtros!,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Antecedentes no patológicos ──────────────────────
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: colorFondo,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: colorBorde),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _subtitulo('Antecedentes no patológicos',
                  colorTextoGris),
              pw.SizedBox(height: 4),
              _filaDatos([
                _dato('Ocupación', h.anpOcupacion ?? '—'),
                _dato('Tabaquismo', h.anpTabaquismo ?? 'Niega'),
                _dato('Alcoholismo',
                    h.anpAlcoholismo ?? 'Niega'),
              ]),
              pw.SizedBox(height: 4),
              _filaDatos([
                _dato('Drogas', h.anpDrogas ?? 'Niega'),
                _dato('Actividad física',
                    h.anpActividadFisica ?? '—'),
                _dato('', ''),
              ]),
            ],
          ),
        ),

        // ── Antecedentes gineco-obstétricos ──────────────────
        if (h.goMenarca != null ||
            h.goFur != null ||
            h.goGestas != null ||
            h.goPartos != null ||
            h.goCesareas != null ||
            h.goAbortos != null ||
            h.goAnticonceptivos != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: colorFondo,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: colorBorde),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _subtitulo('Antecedentes gineco-obstétricos',
                    colorTextoGris),
                pw.SizedBox(height: 4),
                _filaDatos([
                  _dato('Menarca', h.goMenarca ?? '—'),
                  _dato('FUR', h.goFur ?? '—'),
                  _dato('Anticonceptivos',
                      h.goAnticonceptivos ?? '—'),
                ]),
                pw.SizedBox(height: 4),
                _filaDatos([
                  _dato('Gestas',
                      h.goGestas?.toString() ?? '—'),
                  _dato('Partos',
                      h.goPartos?.toString() ?? '—'),
                  _dato('Cesáreas',
                      h.goCesareas?.toString() ?? '—'),
                ]),
                if (h.goAbortos != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: _dato('Abortos',
                        h.goAbortos!.toString()),
                  ),
              ],
            ),
          ),

        // ── Escalas clínicas ─────────────────────────────────
        if (h.escalaEva != null ||
            h.escalaDaniels != null ||
            h.escalaGlasgow != null ||
            h.escalaNorton != null)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(
              color: colorFondo,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: colorBorde),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _subtitulo('Escalas clínicas', colorTextoGris),
                pw.SizedBox(height: 4),
                _filaDatos([
                  _dato('EVA (dolor 0-10)',
                      h.escalaEva != null
                          ? '${h.escalaEva}/10'
                          : '—'),
                  _dato('Daniels (fuerza 0-5)',
                      h.escalaDaniels != null
                          ? '${h.escalaDaniels}/5'
                          : '—'),
                  _dato('Glasgow (conciencia 3-15)',
                      h.escalaGlasgow != null
                          ? '${h.escalaGlasgow}/15'
                          : '—'),
                ]),
                if (h.escalaNorton != null) ...[
                  pw.SizedBox(height: 4),
                  _dato('Norton (úlceras 5-20)',
                      '${h.escalaNorton}/20'),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // ── Sección: signos vitales ───────────────────────────────────────────

  static pw.Widget _seccionSignosVitales(
    SignosVitales sv,
    PdfColor colorPrimario,
    PdfColor colorFondo,
    PdfColor colorBorde,
    PdfColor colorTextoGris,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion(
            'SIGNOS VITALES (último registro)', colorPrimario),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: colorFondo,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: colorBorde),
          ),
          child: pw.Column(
            children: [
              _filaDatos([
                _dato('T.A.', sv.tensionArterial),
                _dato('Frec. cardiaca',
                    sv.frecuenciaCardiaca != null
                        ? '${sv.frecuenciaCardiaca} lpm'
                        : '—'),
                _dato('Temperatura',
                    sv.temperatura != null
                        ? '${sv.temperatura} °C'
                        : '—'),
              ]),
              pw.SizedBox(height: 8),
              _filaDatos([
                _dato('Peso',
                    sv.peso != null ? '${sv.peso} kg' : '—'),
                _dato('Talla',
                    sv.talla != null ? '${sv.talla} cm' : '—'),
                _dato('IMC',
                    sv.imc != null ? '${sv.imc} kg/m²' : '—'),
              ]),
              pw.SizedBox(height: 8),
              _filaDatos([
                _dato('Sat. O₂',
                    sv.saturacionOxigeno != null
                        ? '${sv.saturacionOxigeno}%'
                        : '—'),
                _dato('Glucosa',
                    sv.glucosa != null
                        ? '${sv.glucosa} mg/dL'
                        : '—'),
                _dato('Fecha registro', sv.fechaFormateada),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sección: notas SOAP ───────────────────────────────────────────────

  static pw.Widget _seccionNotas(
    List<NotaClinica> notas,
    PdfColor colorPrimario,
    PdfColor colorFondo,
    PdfColor colorBorde,
    PdfColor colorTextoGris,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSeccion(
            'NOTAS DE EVOLUCIÓN (${notas.length})', colorPrimario),
        ...notas.map((nota) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: colorFondo,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: colorBorde),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: colorPrimario,
                          borderRadius:
                              pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(nota.especialidad.nombre,
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                                fontWeight:
                                    pw.FontWeight.bold)),
                      ),
                      pw.Text(nota.fechaFormateada,
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: colorTextoGris)),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  if (nota.subjetivo != null)
                    _filaSoap('S', 'Subjetivo',
                        nota.subjetivo!, colorPrimario),
                  if (nota.objetivo != null)
                    _filaSoap('O', 'Objetivo',
                        nota.objetivo!, colorPrimario),
                  if (nota.evaluacion != null)
                    _filaSoap('A', 'Evaluación',
                        nota.evaluacion!, colorPrimario),
                  if (nota.plan != null)
                    _filaSoap(
                        'P', 'Plan', nota.plan!, colorPrimario),
                  pw.SizedBox(height: 4),
                  pw.Text('Terapeuta: ${nota.terapeuta}',
                      style: pw.TextStyle(
                          fontSize: 9,
                          color: colorTextoGris,
                          fontStyle: pw.FontStyle.italic)),
                ],
              ),
            )),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static pw.Widget _tituloSeccion(
      String titulo, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 4,
            height: 16,
            color: color,
            margin: const pw.EdgeInsets.only(right: 8),
          ),
          pw.Text(titulo,
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  static pw.Widget _subtitulo(
      String texto, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(texto,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: color)),
    );
  }

  static pw.Widget _filaDatos(
      List<pw.Widget> items) {
    return pw.Row(
      children: items
          .map((item) => pw.Expanded(child: item))
          .toList(),
    );
  }

  static pw.Widget _dato(String label, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromHex('#999999'))),
        pw.Text(valor,
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _filaSoap(
      String letra, String titulo, String contenido,
      PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 16,
            height: 16,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(letra,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(titulo,
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text(contenido,
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // ── Comprobante de consulta ─────────────────────────────────────────
  static Future<String> generarComprobante({
    required Comprobante comprobante,
  }) async {
    final pdf = pw.Document();
    final nombreConsultorio =
        await ConfiguracionService.getNombreConsultorio();
    final telefonoConsultorio =
        await ConfiguracionService.getTelefonoConsultorio();
    final direccionConsultorio =
        await ConfiguracionService.getDireccionConsultorio();
    final logoPath = await ConfiguracionService.getLogoPath();

    pw.ImageProvider? logoImage;
    if (logoPath != null && await File(logoPath).exists()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    }

    final colorPrimario = await getColorPrimarioPdf();
    final colorFondo = await getColorFondoPdf();
    final colorBorde = PdfColor.fromHex('#E0E0E0');
    final colorTextoGris = PdfColor.fromHex('#666666');

    // Número de folio aleatorio
    final folio =
        'MC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Encabezado
            _encabezado(
              nombreConsultorio,
              telefonoConsultorio,
              logoImage,
              colorPrimario,
              colorBorde,
              direccionConsultorio,
            ),
            pw.SizedBox(height: 16),

            // Título del documento
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 8),
              decoration: pw.BoxDecoration(
                color: colorPrimario,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'COMPROBANTE DE CONSULTA',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Folio: $folio',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Datos de la consulta
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: colorFondo,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: colorBorde),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  _subtitulo('Datos de la consulta',
                      colorTextoGris),
                  pw.SizedBox(height: 6),
                  _filaDatos([
                    _dato('Fecha', comprobante.fecha),
                    _dato('Hora', comprobante.hora),
                    _dato('Especialidad',
                        comprobante.especialidad),
                  ]),
                  pw.SizedBox(height: 6),
                  _dato('Terapeuta', comprobante.terapeuta),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Datos del paciente
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: colorFondo,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: colorBorde),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  _subtitulo(
                      'Datos del paciente', colorTextoGris),
                  pw.SizedBox(height: 6),
                  _filaDatos([
                    _dato('Nombre',
                        comprobante.pacienteNombre),
                    _dato('Fecha de nacimiento',
                        comprobante.pacienteFechaNacimiento),
                  ]),
                  if (comprobante.pacienteTelefono !=
                      null) ...[
                    pw.SizedBox(height: 4),
                    _dato('Teléfono',
                        comprobante.pacienteTelefono!),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Motivo y diagnóstico
            if (comprobante.motivoConsulta != null ||
                comprobante.diagnostico != null)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: colorFondo,
                  borderRadius:
                      pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: colorBorde),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    if (comprobante.motivoConsulta !=
                        null) ...[
                      _subtitulo('Motivo de consulta',
                          colorTextoGris),
                      pw.Text(comprobante.motivoConsulta!,
                          style: const pw.TextStyle(
                              fontSize: 10)),
                      pw.SizedBox(height: 8),
                    ],
                    if (comprobante.diagnostico !=
                        null) ...[
                      _subtitulo(
                          'Diagnóstico / Impresión diagnóstica',
                          colorTextoGris),
                      pw.Text(comprobante.diagnostico!,
                          style: const pw.TextStyle(
                              fontSize: 10)),
                    ],
                  ],
                ),
              ),
            pw.SizedBox(height: 10),

            // Indicaciones
            if (comprobante.indicaciones != null)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: colorFondo,
                  borderRadius:
                      pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: colorBorde),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    _subtitulo('Indicaciones y tratamiento',
                        colorTextoGris),
                    pw.SizedBox(height: 4),
                    pw.Text(comprobante.indicaciones!,
                        style: const pw.TextStyle(
                            fontSize: 10)),
                  ],
                ),
              ),
            pw.SizedBox(height: 10),

            // Próxima cita y observaciones
            if (comprobante.proximaCita != null ||
                comprobante.observaciones != null)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: colorFondo,
                  borderRadius:
                      pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: colorBorde),
                ),
                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,
                  children: [
                    if (comprobante.proximaCita !=
                        null) ...[
                      _subtitulo(
                          'Próxima cita', colorTextoGris),
                      pw.Text(comprobante.proximaCita!,
                          style: const pw.TextStyle(
                              fontSize: 10)),
                      pw.SizedBox(height: 8),
                    ],
                    if (comprobante.observaciones !=
                        null) ...[
                      _subtitulo(
                          'Observaciones', colorTextoGris),
                      pw.Text(comprobante.observaciones!,
                          style: const pw.TextStyle(
                              fontSize: 10)),
                    ],
                  ],
                ),
              ),

            pw.Spacer(),

            // Firma
            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 180,
                      height: 1,
                      color: colorPrimario,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      comprobante.terapeuta,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: colorPrimario,
                      ),
                    ),
                    pw.Text(
                      comprobante.especialidad,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: colorTextoGris,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Pie
            pw.Divider(color: colorBorde),
            pw.Text(
              'Documento generado el ${comprobante.fecha} · $nombreConsultorio',
              style: pw.TextStyle(
                  fontSize: 8, color: colorTextoGris),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final archivo = File(
        '${dir.path}/comprobante_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await archivo.writeAsBytes(await pdf.save());
    return archivo.path;
  }
  static Future<String> generarRutina({
    required Paciente paciente,
    required List<EjercicioEnRutina> ejercicios,
    required String terapeuta,
    String? observacionesGenerales,
  }) async {
    final pdf = pw.Document();
    final nombreConsultorio =
        await ConfiguracionService.getNombreConsultorio();
    final telefonoConsultorio =
        await ConfiguracionService.getTelefonoConsultorio();
    final direccionConsultorio =
        await ConfiguracionService.getDireccionConsultorio();
    final logoPath = await ConfiguracionService.getLogoPath();

    pw.ImageProvider? logoImage;
    if (logoPath != null && await File(logoPath).exists()) {
      final bytes = await File(logoPath).readAsBytes();
      logoImage = pw.MemoryImage(bytes);
    }

    final colorPrimario = await getColorPrimarioPdf();
    final colorFondo = await getColorFondoPdf();
    final colorBorde = PdfColor.fromHex('#E0E0E0');
    final colorTextoGris = PdfColor.fromHex('#666666');

    final fecha = DateTime.now();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          children: [
            _encabezado(
              nombreConsultorio,
              telefonoConsultorio,
              logoImage,
              colorPrimario,
              colorBorde,
              direccionConsultorio,
            ),
            pw.SizedBox(height: 8),
            // Título
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 6),
              color: colorPrimario,
              child: pw.Text(
                'PLAN DE EJERCICIOS',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            // Datos paciente y fecha
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: colorFondo,
                border: pw.Border.all(color: colorBorde),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Paciente:',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: colorTextoGris)),
                      pw.Text(paciente.nombreCompleto,
                          style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Fecha: $fechaStr',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: colorTextoGris)),
                      pw.Text('Terapeuta: $terapeuta',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: colorTextoGris)),
                      pw.Text(
                          'Total: ${ejercicios.length} ejercicios',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: colorPrimario,
                              fontWeight:
                                  pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: colorBorde),
            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '$nombreConsultorio · $fechaStr',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: colorTextoGris),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: colorTextoGris),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Observaciones generales
          if (observacionesGenerales != null &&
              observacionesGenerales.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E8F5E9'),
                border: pw.Border.all(
                    color: colorPrimario.flatten()),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Indicaciones generales:',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario)),
                  pw.Text(observacionesGenerales,
                      style: const pw.TextStyle(
                          fontSize: 10)),
                ],
              ),
            ),
          ],

          // Tabla de ejercicios
          pw.Table(
            border: pw.TableBorder.all(
                color: colorBorde, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2.5),
            },
            children: [
              // Encabezado tabla
              pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: colorPrimario),
                children: [
                  _celdaHeader('#'),
                  _celdaHeader('Ejercicio'),
                  _celdaHeader('Músculo'),
                  _celdaHeader('Dosis'),
                  _celdaHeader('Notas / Ilustración'),
                ],
              ),
              // Ejercicios
              ...ejercicios.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final colorFila = i % 2 == 0
                    ? PdfColors.white
                    : PdfColor.fromHex('#F9F9F9');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: colorFila),
                  children: [
                    _celda('${i + 1}',
                        centro: true,
                        bold: true,
                        color: colorPrimario),
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(e.ejercicio.name,
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight:
                                      pw.FontWeight.bold)),
                          pw.Text(
                            '${e.ejercicio.category} · ${e.ejercicio.level}',
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: colorTextoGris),
                          ),
                          pw.Text(
                            'Obj: ${e.ejercicio.objective}',
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: colorTextoGris),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                              e.ejercicio.mainMuscle,
                              style: const pw.TextStyle(
                                  fontSize: 9)),
                          if (e.ejercicio
                              .secondaryMuscles
                              .isNotEmpty)
                            pw.Text(
                              e.ejercicio
                                  .secondaryMuscles
                                  .take(2)
                                  .join(', '),
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  color: colorTextoGris),
                            ),
                        ],
                      ),
                    ),
                    _celda(e.resumen,
                        centro: true,
                        bold: true,
                        color: colorPrimario),
                    // Espacio para notas/dibujo
                    pw.Padding(
                      padding:
                          const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,
                        children: [
                          if (e.notas != null &&
                              e.notas!.isNotEmpty)
                            pw.Text(e.notas!,
                                style:
                                    const pw.TextStyle(
                                        fontSize: 8)),
                          // Espacio para ilustración
                          pw.Container(
                            height: 48,
                            width: double.infinity,
                            margin:
                                const pw.EdgeInsets.only(
                                    top: 4),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColor.fromHex(
                                    '#CCCCCC'),
                                style:
                                    pw.BorderStyle.dashed,
                              ),
                              borderRadius:
                                  pw.BorderRadius.circular(
                                      3),
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                'Ilustración',
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  color: PdfColor.fromHex(
                                      '#BBBBBB'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),

          // Firma terapeuta
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                      width: 160,
                      height: 1,
                      color: colorPrimario),
                  pw.SizedBox(height: 4),
                  pw.Text(terapeuta,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: colorPrimario)),
                  pw.Text('Terapeuta',
                      style: pw.TextStyle(
                          fontSize: 8,
                          color: colorTextoGris)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final archivo = File(
        '${dir.path}/rutina_${paciente.apellidoPaterno}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await archivo.writeAsBytes(await pdf.save());
    return archivo.path;
  }

  // Helpers para tabla
  static pw.Widget _celdaHeader(String texto) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          texto,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          textAlign: pw.TextAlign.center,
        ),
      );

  static pw.Widget _celda(
    String texto, {
    bool centro = false,
    bool bold = false,
    PdfColor? color,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          texto,
          textAlign: centro
              ? pw.TextAlign.center
              : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );
}

