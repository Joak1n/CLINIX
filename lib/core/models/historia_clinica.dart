class HistoriaClinica {
  final String id;
  final String pacienteId;

  // Antecedentes heredofamiliares
  final bool hfDiabetes;
  final bool hfHipertension;
  final bool hfCancer;
  final bool hfCardiopatia;
  final bool hfObesidad;
  final String? hfOtros;

  // Antecedentes patológicos personales
  final bool apDiabetes;
  final bool apHipertension;
  final bool apCardiopatia;
  final bool apAsma;
  final bool apCancer;
  final bool apFracturas;
  final bool apTransfusiones;
  final String? apCirugias;
  final String? apTraumatismos;
  final String? apHospitalizaciones;
  final String? apOtros;

  // Antecedentes no patológicos (sin alimentación)
  final String? anpTabaquismo;
  final String? anpAlcoholismo;
  final String? anpDrogas;
  final String? anpActividadFisica;
  final String? anpOcupacion;

  // Antecedentes gineco-obstétricos
  final String? goMenarca;
  final String? goFur;
  final int? goGestas;
  final int? goPartos;
  final int? goCesareas;
  final int? goAbortos;
  final String? goAnticonceptivos;

  // Padecimiento y medicamentos
  final String? padecimientoActual;
  final String? medicamentosActuales;

  // Escalas clínicas
  final int? escalaEva;
  final int? escalaDaniels;
  final int? escalaGlasgow;
  final int? escalaNorton;

  final String createdAt;
  final String updatedAt;

  HistoriaClinica({
    required this.id,
    required this.pacienteId,
    this.hfDiabetes = false,
    this.hfHipertension = false,
    this.hfCancer = false,
    this.hfCardiopatia = false,
    this.hfObesidad = false,
    this.hfOtros,
    this.apDiabetes = false,
    this.apHipertension = false,
    this.apCardiopatia = false,
    this.apAsma = false,
    this.apCancer = false,
    this.apFracturas = false,
    this.apTransfusiones = false,
    this.apCirugias,
    this.apTraumatismos,
    this.apHospitalizaciones,
    this.apOtros,
    this.anpTabaquismo,
    this.anpAlcoholismo,
    this.anpDrogas,
    this.anpActividadFisica,
    this.anpOcupacion,
    this.goMenarca,
    this.goFur,
    this.goGestas,
    this.goPartos,
    this.goCesareas,
    this.goAbortos,
    this.goAnticonceptivos,
    this.padecimientoActual,
    this.medicamentosActuales,
    this.escalaEva,
    this.escalaDaniels,
    this.escalaGlasgow,
    this.escalaNorton,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HistoriaClinica.fromMap(Map<String, dynamic> m) {
    return HistoriaClinica(
      id: m['id'],
      pacienteId: m['paciente_id'],
      hfDiabetes: m['hf_diabetes'] == 1,
      hfHipertension: m['hf_hipertension'] == 1,
      hfCancer: m['hf_cancer'] == 1,
      hfCardiopatia: m['hf_cardiopatia'] == 1,
      hfObesidad: m['hf_obesidad'] == 1,
      hfOtros: m['hf_otros'],
      apDiabetes: m['ap_diabetes'] == 1,
      apHipertension: m['ap_hipertension'] == 1,
      apCardiopatia: m['ap_cardiopatia'] == 1,
      apAsma: m['ap_asma'] == 1,
      apCancer: m['ap_cancer'] == 1,
      apFracturas: m['ap_fracturas'] == 1,
      apTransfusiones: m['ap_transfusiones'] == 1,
      apCirugias: m['ap_cirugias'],
      apTraumatismos: m['ap_traumatismos'],
      apHospitalizaciones: m['ap_hospitalizaciones'],
      apOtros: m['ap_otros'],
      anpTabaquismo: m['anp_tabaquismo'],
      anpAlcoholismo: m['anp_alcoholismo'],
      anpDrogas: m['anp_drogas'],
      anpActividadFisica: m['anp_actividad_fisica'],
      anpOcupacion: m['anp_ocupacion'],
      goMenarca: m['go_menarca'],
      goFur: m['go_fur'],
      goGestas: m['go_gestas'],
      goPartos: m['go_partos'],
      goCesareas: m['go_cesareas'],
      goAbortos: m['go_abortos'],
      goAnticonceptivos: m['go_anticonceptivos'],
      padecimientoActual: m['padecimiento_actual'],
      medicamentosActuales: m['medicamentos_actuales'],
      escalaEva: m['escala_eva'],
      escalaDaniels: m['escala_daniels'],
      escalaGlasgow: m['escala_glasgow'],
      escalaNorton: m['escala_norton'],
      createdAt: m['created_at'],
      updatedAt: m['updated_at'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'paciente_id': pacienteId,
        'hf_diabetes': hfDiabetes ? 1 : 0,
        'hf_hipertension': hfHipertension ? 1 : 0,
        'hf_cancer': hfCancer ? 1 : 0,
        'hf_cardiopatia': hfCardiopatia ? 1 : 0,
        'hf_obesidad': hfObesidad ? 1 : 0,
        'hf_otros': hfOtros,
        'ap_diabetes': apDiabetes ? 1 : 0,
        'ap_hipertension': apHipertension ? 1 : 0,
        'ap_cardiopatia': apCardiopatia ? 1 : 0,
        'ap_asma': apAsma ? 1 : 0,
        'ap_cancer': apCancer ? 1 : 0,
        'ap_fracturas': apFracturas ? 1 : 0,
        'ap_transfusiones': apTransfusiones ? 1 : 0,
        'ap_cirugias': apCirugias,
        'ap_traumatismos': apTraumatismos,
        'ap_hospitalizaciones': apHospitalizaciones,
        'ap_otros': apOtros,
        'anp_tabaquismo': anpTabaquismo,
        'anp_alcoholismo': anpAlcoholismo,
        'anp_drogas': anpDrogas,
        'anp_actividad_fisica': anpActividadFisica,
        'anp_ocupacion': anpOcupacion,
        'go_menarca': goMenarca,
        'go_fur': goFur,
        'go_gestas': goGestas,
        'go_partos': goPartos,
        'go_cesareas': goCesareas,
        'go_abortos': goAbortos,
        'go_anticonceptivos': goAnticonceptivos,
        'padecimiento_actual': padecimientoActual,
        'medicamentos_actuales': medicamentosActuales,
        'escala_eva': escalaEva,
        'escala_daniels': escalaDaniels,
        'escala_glasgow': escalaGlasgow,
        'escala_norton': escalaNorton,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

