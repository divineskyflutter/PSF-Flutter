/// Model for `POST /api/HealthDeclaration/SaveMemberHealthDeclaration`
/// (request body) and `POST /api/HealthDeclaration/GetHealthDeclarationByMemberId`
/// (one `data` object) — both use the same shape, per the API's own
/// `SaveHealthDeclarationModel` schema.
///
/// Field groups, per the swagger schema:
///  * Five yes/no questions each pair with their own free-text detail,
///    shown in the UI only once the question is answered "yes":
///    [isSeriousIllness] -> [seriousIllness] (translated: [hSeriousIllness]/
///    [gSeriousIllness]), [anyHerediatry] -> [other] (translated: [hOther]/
///    [gOther] — "which hereditary disease"), [isSurgery] -> [surgery] +
///    [surgeryDate] (translated: [hSurgery]/[gSurgery]),
///    [ismedicationRegularly] -> [medicationRegularly] (NOT translated — the
///    swagger schema has no h/g pair for this one field), [anyAllergies] ->
///    [allergies] (translated: [hAllergies]/[gAllergies]).
///  * Thirteen fixed yes/no disease-history flags with no attached detail
///    field at all: [heartDisease] through [anyHerediatry] (see
///    RegistrationController.diseaseKeys, which lists them in the same
///    order).
///  * Three fixed yes/no habit flags, also with no attached detail:
///    [tabaccoBidiCigarates], [addictionToAlcohol], [drugs].
///  * One standalone, always-optional free-text field with no yes/no gate:
///    [otherDetails] (translated: [hotherDetails]/[gotherDetails]).
class HealthDeclarationModel {
  /// 0 means "create a new declaration for this member"; a real id (either
  /// already known from a previous save, or returned by
  /// GetHealthDeclarationByMemberId when resuming) means "update this
  /// existing declaration" — same create-vs-update convention every other
  /// Save* endpoint on this API uses for its id field.
  final int healthDeclarationId;

  final int memberId;

  final bool isSeriousIllness;
  final String seriousIllness;
  final String hSeriousIllness;
  final String gSeriousIllness;

  final bool heartDisease;
  final bool heartAttack;
  final bool highBloodPressure;
  final bool diabetes;
  final bool breathingProblem;
  final bool tb;
  final bool cancerTumor;
  final bool liverDisease;
  final bool hiv;
  final bool infectiousDiseas;
  final bool stroke;
  final bool anxiety;
  final bool anyHerediatry;

  /// "Please specify" detail for [anyHerediatry] — the swagger schema
  /// places this field immediately after `anyHerediatry`, and it's the
  /// only disease-history field with an h/g translation pair, which is
  /// why it reads as that flag's own detail rather than a stray field.
  final String other;
  final String hOther;
  final String gOther;

  final bool isSurgery;
  final String surgery;
  final String hSurgery;
  final String gSurgery;
  final DateTime? surgeryDate;

  final bool ismedicationRegularly;
  final String medicationRegularly;

  final bool anyAllergies;
  final String allergies;
  final String hAllergies;
  final String gAllergies;

  final bool tabaccoBidiCigarates;
  final bool addictionToAlcohol;
  final bool drugs;

  final String otherDetails;
  final String hotherDetails;
  final String gotherDetails;

  const HealthDeclarationModel({
    this.healthDeclarationId = 0,
    required this.memberId,
    this.isSeriousIllness = false,
    this.seriousIllness = '',
    this.hSeriousIllness = '',
    this.gSeriousIllness = '',
    this.heartDisease = false,
    this.heartAttack = false,
    this.highBloodPressure = false,
    this.diabetes = false,
    this.breathingProblem = false,
    this.tb = false,
    this.cancerTumor = false,
    this.liverDisease = false,
    this.hiv = false,
    this.infectiousDiseas = false,
    this.stroke = false,
    this.anxiety = false,
    this.anyHerediatry = false,
    this.other = '',
    this.hOther = '',
    this.gOther = '',
    this.isSurgery = false,
    this.surgery = '',
    this.hSurgery = '',
    this.gSurgery = '',
    this.surgeryDate,
    this.ismedicationRegularly = false,
    this.medicationRegularly = '',
    this.anyAllergies = false,
    this.allergies = '',
    this.hAllergies = '',
    this.gAllergies = '',
    this.tabaccoBidiCigarates = false,
    this.addictionToAlcohol = false,
    this.drugs = false,
    this.otherDetails = '',
    this.hotherDetails = '',
    this.gotherDetails = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'healthDeclarationId': healthDeclarationId,
      'memberId': memberId,
      'isSeriousIllness': isSeriousIllness,
      'seriousIllness': seriousIllness,
      'heartDisease': heartDisease,
      'heartAttack': heartAttack,
      'highBloodPressure': highBloodPressure,
      'diabetes': diabetes,
      'breathingProblem': breathingProblem,
      'tb': tb,
      'cancerTumor': cancerTumor,
      'liverDisease': liverDisease,
      'hiv': hiv,
      'infectiousDiseas': infectiousDiseas,
      'stroke': stroke,
      'anxiety': anxiety,
      'anyHerediatry': anyHerediatry,
      'other': other,
      'isSurgery': isSurgery,
      'surgery': surgery,
      'surgeryDate': surgeryDate?.toIso8601String(),
      'ismedicationRegularly': ismedicationRegularly,
      'medicationRegularly': medicationRegularly,
      'anyAllergies': anyAllergies,
      'allergies': allergies,
      'tabaccoBidiCigarates': tabaccoBidiCigarates,
      'addictionToAlcohol': addictionToAlcohol,
      'drugs': drugs,
      'otherDetails': otherDetails,
      'hSeriousIllness': hSeriousIllness,
      'gSeriousIllness': gSeriousIllness,
      'hOther': hOther,
      'gOther': gOther,
      'hSurgery': hSurgery,
      'gSurgery': gSurgery,
      'hAllergies': hAllergies,
      'gAllergies': gAllergies,
      'hotherDetails': hotherDetails,
      'gotherDetails': gotherDetails,
    };
  }

  factory HealthDeclarationModel.fromJson(Map<String, dynamic> json) {
    return HealthDeclarationModel(
      healthDeclarationId: _parseInt(
        json['healthDeclarationId'] ?? json['id'],
      ),
      memberId: _parseInt(json['memberId']),
      isSeriousIllness: _parseBool(json['isSeriousIllness']),
      seriousIllness: json['seriousIllness']?.toString() ?? '',
      // Case-insensitive — the confirmed real response sends these h/g
      // pairs all-lowercase (`hseriousIllness`/`gseriousIllness`, etc.),
      // not the capitalized `hSeriousIllness` the save/request schema
      // documents, so a plain `json['hSeriousIllness']` lookup silently
      // returns null against a real login response.
      hSeriousIllness: _ciGet(json, 'hSeriousIllness')?.toString() ?? '',
      gSeriousIllness: _ciGet(json, 'gSeriousIllness')?.toString() ?? '',
      heartDisease: _parseBool(json['heartDisease']),
      heartAttack: _parseBool(json['heartAttack']),
      highBloodPressure: _parseBool(json['highBloodPressure']),
      diabetes: _parseBool(json['diabetes']),
      breathingProblem: _parseBool(json['breathingProblem']),
      tb: _parseBool(json['tb']),
      cancerTumor: _parseBool(json['cancerTumor']),
      liverDisease: _parseBool(json['liverDisease']),
      hiv: _parseBool(json['hiv']),
      infectiousDiseas: _parseBool(json['infectiousDiseas']),
      stroke: _parseBool(json['stroke']),
      anxiety: _parseBool(json['anxiety']),
      anyHerediatry: _parseBool(json['anyHerediatry']),
      other: json['other']?.toString() ?? '',
      hOther: _ciGet(json, 'hOther')?.toString() ?? '',
      gOther: _ciGet(json, 'gOther')?.toString() ?? '',
      isSurgery: _parseBool(json['isSurgery']),
      surgery: json['surgery']?.toString() ?? '',
      hSurgery: _ciGet(json, 'hSurgery')?.toString() ?? '',
      gSurgery: _ciGet(json, 'gSurgery')?.toString() ?? '',
      surgeryDate: DateTime.tryParse(json['surgeryDate']?.toString() ?? ''),
      ismedicationRegularly: _parseBool(json['ismedicationRegularly']),
      medicationRegularly: json['medicationRegularly']?.toString() ?? '',
      anyAllergies: _parseBool(json['anyAllergies']),
      allergies: json['allergies']?.toString() ?? '',
      hAllergies: _ciGet(json, 'hAllergies')?.toString() ?? '',
      gAllergies: _ciGet(json, 'gAllergies')?.toString() ?? '',
      tabaccoBidiCigarates: _parseBool(json['tabaccoBidiCigarates']),
      addictionToAlcohol: _parseBool(json['addictionToAlcohol']),
      drugs: _parseBool(json['drugs']),
      otherDetails: json['otherDetails']?.toString() ?? '',
      hotherDetails: json['hotherDetails']?.toString() ?? '',
      gotherDetails: json['gotherDetails']?.toString() ?? '',
    );
  }

  static dynamic _ciGet(Map<String, dynamic> json, String key) {
    final target = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
