/// Model for `POST /api/Nominee/SaveNominee` (request body) and one entry
/// of the list returned by `POST /api/Nominee/GetNomineeByMemberId` —
/// both use the same shape, per the API's own schema:
/// `{nomineeId, name, dateOfBirth, relation, share, profilePhoto,
/// memberId, hName, gName, aadharFrontImage, aadharBackImage,
/// passBook_Cheque, aadharNo}`.
///
/// Replaces an older, unused version of this file that modeled a
/// first/middle/surname + mobile + Aadhaar/PAN nominee — that shape never
/// matched any real endpoint (no SaveNominee API existed yet when it was
/// written) and nothing in the app referenced it.
class NomineeModel {
  /// 0 means "create a new nominee"; a real id means "update this
  /// existing nominee" — same create-vs-update convention every other
  /// Save* endpoint on this API uses for its id field.
  final int nomineeId;

  final String name;

  /// Hindi/Gujarati transliterations of [name]. Now confirmed part of
  /// SaveNominee's documented schema — the swagger spec's `NomineeModel`
  /// lists these as `hName`/`gName` (capital N), NOT the lowercase
  /// `hname`/`gname` this app originally sent before that field existed on
  /// the backend — see toJson for the exact key spelling that matters.
  final String hName;
  final String gName;

  /// ISO-8601 date-time string.
  final String dateOfBirth;

  /// Id from `GetEnumBundle`'s `Relation` list (requested via the
  /// `relation: true` flag) — not a hardcoded app-side enum, same pattern
  /// as Gender/Marital Status. Null only while the user hasn't picked one
  /// yet on the form; the save flow blocks submission before that happens.
  final int? relation;

  /// Share of the scheme benefit allocated to this nominee. The API
  /// defines this as a plain nullable number with no further rules
  /// documented (e.g. no confirmed 0-100 range or "must sum to 100 across
  /// nominees" requirement), so this app only collects it as a free-form
  /// number and does not enforce either.
  final double? share;

  /// Document id returned by `SaveDocument` for the nominee's photo.
  final int profilePhoto;

  final int memberId;

  /// Nominee's Aadhaar number — no format enforced by the swagger schema
  /// beyond it being a plain string, so this app validates it the same
  /// way as the Member step's own Aadhaar field when non-empty (see
  /// AppValidators.aadhar), but — unlike the member's own Aadhaar — never
  /// requires it, since it's a newer, optional addition to this form.
  final String aadharNo;

  /// Document ids returned by `SaveDocument` for this nominee's Aadhaar
  /// front/back photos and passbook/cheque photo — all three added to the
  /// swagger schema alongside [aadharNo] above, none required.
  final int aadharFrontImage;
  final int aadharBackImage;

  /// Matches the swagger schema's own field name exactly — `passBook_
  /// Cheque` (capital C, underscore), not `passbookCheque` — see toJson.
  final int passBookCheque;

  /// Full, directly-loadable image URL for the already-uploaded photo, if
  /// the response happened to include one. Nothing in the API's published
  /// schema documents this (GetNomineeByMemberId's response shape isn't
  /// specified at all), so this is a best-effort, multi-key-fallback parse
  /// (see fromJson) purely so a resumed nominee's photo CAN show without a
  /// local File — see NomineeSlot.photoUrl. `null` when no such field is
  /// present, which is the expected/normal case today.
  final String? photoUrl;

  /// Same best-effort URL parsing as [photoUrl], for the three new
  /// document photos above — see NomineeSlot.aadharFrontImageUrl /
  /// aadharBackImageUrl / passbookChequeUrl.
  final String? aadharFrontImageUrl;
  final String? aadharBackImageUrl;
  final String? passBookChequeUrl;

  const NomineeModel({
    required this.nomineeId,
    required this.name,
    this.hName = '',
    this.gName = '',
    required this.dateOfBirth,
    required this.relation,
    required this.share,
    required this.profilePhoto,
    required this.memberId,
    this.aadharNo = '',
    this.aadharFrontImage = 0,
    this.aadharBackImage = 0,
    this.passBookCheque = 0,
    this.photoUrl,
    this.aadharFrontImageUrl,
    this.aadharBackImageUrl,
    this.passBookChequeUrl,
  });

  NomineeModel copyWith({
    int? nomineeId,
    String? name,
    String? hName,
    String? gName,
    String? dateOfBirth,
    int? relation,
    double? share,
    int? profilePhoto,
    int? memberId,
    String? aadharNo,
    int? aadharFrontImage,
    int? aadharBackImage,
    int? passBookCheque,
    String? photoUrl,
    String? aadharFrontImageUrl,
    String? aadharBackImageUrl,
    String? passBookChequeUrl,
  }) {
    return NomineeModel(
      nomineeId: nomineeId ?? this.nomineeId,
      name: name ?? this.name,
      hName: hName ?? this.hName,
      gName: gName ?? this.gName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      relation: relation ?? this.relation,
      share: share ?? this.share,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      memberId: memberId ?? this.memberId,
      aadharNo: aadharNo ?? this.aadharNo,
      aadharFrontImage: aadharFrontImage ?? this.aadharFrontImage,
      aadharBackImage: aadharBackImage ?? this.aadharBackImage,
      passBookCheque: passBookCheque ?? this.passBookCheque,
      photoUrl: photoUrl ?? this.photoUrl,
      aadharFrontImageUrl: aadharFrontImageUrl ?? this.aadharFrontImageUrl,
      aadharBackImageUrl: aadharBackImageUrl ?? this.aadharBackImageUrl,
      passBookChequeUrl: passBookChequeUrl ?? this.passBookChequeUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomineeId': nomineeId,
      'name': name,
      // Capital N — matches the swagger spec's NomineeModel schema exactly
      // (`hName`/`gName`), not the lowercase `hname`/`gname` sent before
      // the backend documented this field. A casing mismatch here would
      // have meant the backend's model binder never actually populated
      // these from the request body even though nothing looked wrong
      // app-side.
      'hName': hName,
      'gName': gName,
      'dateOfBirth': dateOfBirth,
      'relation': relation,
      'share': share,
      'profilePhoto': profilePhoto,
      'memberId': memberId,
      // Added to the swagger schema after this model was first built —
      // omitting them is the likely cause of SaveNominee's "Something
      // Went Wrong" response once the backend started expecting them.
      'aadharNo': aadharNo,
      'aadharFrontImage': aadharFrontImage,
      'aadharBackImage': aadharBackImage,
      'passBook_Cheque': passBookCheque,
    };
  }

  factory NomineeModel.fromJson(Map<String, dynamic> json) {
    return NomineeModel(
      nomineeId: _parseInt(json['nomineeId'] ?? json['id']),
      name: json['name']?.toString() ?? '',
      hName: json['hname']?.toString() ??
          json['hName']?.toString() ??
          '',
      gName: json['gname']?.toString() ??
          json['gName']?.toString() ??
          '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      relation: _parseNullableInt(json['relation']),
      share: _parseNullableDouble(json['share']),
      profilePhoto: _parseInt(
        json['profilePhoto'] ?? json['profilePhotoId'] ?? json['image'],
      ),
      memberId: _parseInt(json['memberId']),
      aadharNo: json['aadharNo']?.toString() ?? '',
      aadharFrontImage: _parseInt(json['aadharFrontImage']),
      aadharBackImage: _parseInt(json['aadharBackImage']),
      passBookCheque: _parseInt(
        json['passBook_Cheque'] ?? json['passBookCheque'],
      ),
      // GetNomineeByMemberId's actual response uses all-lowercase keys
      // that don't match the request schema's own casing at all — e.g.
      // `hname`/`gname` (not `hName`/`gName`), and these URL fields come
      // back as `profilephotourl`, `aadharfrontphotourl`,
      // `aadharbackphotourl`, `passbookchequephotourl` (confirmed from a
      // real response — note "Photo", not "Image", in the word itself).
      // _firstNonEmptyKey matches case-insensitively so the exact casing
      // doesn't matter, but the WORD still has to match, hence trying both
      // the "Image"-based guesses (kept in case a differently-cased
      // deployment ever uses them) and the confirmed "Photo"-based ones.
      photoUrl: _firstNonEmptyKey(json, const [
        'profilePhotoUrl',
        'photoUrl',
        'imageUrl',
      ]),
      aadharFrontImageUrl: _firstNonEmptyKey(json, const [
        'aadharFrontPhotoUrl',
        'aadharFrontImageUrl',
      ]),
      aadharBackImageUrl: _firstNonEmptyKey(json, const [
        'aadharBackPhotoUrl',
        'aadharBackImageUrl',
      ]),
      passBookChequeUrl: _firstNonEmptyKey(json, const [
        'passBookChequePhotoUrl',
        'passBookChequeUrl',
        'passBook_ChequeUrl',
      ]),
    );
  }

  /// Case-insensitive lookup across several candidate key names — this
  /// API's GET responses use different key casing (and sometimes
  /// different wording) than its own POST/Save schemas document, so a
  /// plain `json['exactKey']` lookup silently misses real data (this is
  /// what caused resumed nominees' photos to never show despite the
  /// backend returning them — see the doc comment above). Tries each
  /// candidate in order, matching regardless of case, and returns the
  /// first non-empty string; `null` if nothing matches.
  static String? _firstNonEmptyKey(
      Map<String, dynamic> json, List<String> candidateKeys) {
    for (final key in candidateKeys) {
      final value = _ciGet(json, key);
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static dynamic _ciGet(Map<String, dynamic> json, String key) {
    final target = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
