import 'query_item_model.dart';

/// The signed-in member's basic profile data, parsed out of the real
/// `POST /api/Api/MemberLogin` success response's `data.memberDetail`
/// object (see `LoginRepositoryImpl`, which flattens `memberDetail` plus
/// the sibling `nominees`/`healthDeclaration` blocks into one map before
/// calling [LoginModel.fromJson]). Field set intentionally mirrors
/// `MemberProfileEntity` (lib/features/profile/domain/entities/
/// member_profile_entity.dart) — `toJson()` below emits the same key
/// names `MemberProfileModel.fromJson` already reads, so once this model
/// is saved to secure storage (see AppSecureStorage.saveLoggedInUser),
/// Profile can parse it back straight into a profile entity with no
/// extra glue code. See ProfileController's local-fallback loading.
///
/// [gender] and [maritalStatus] come back as numeric enum ids (e.g. `"1"`),
/// not display text — resolve them against `GetEnumBundle`'s `Gender`/
/// `MaritalStatus` lists (see ProfileController) before showing them.
class LoginModel {
  final int memberId;

  /// e.g. `"PSF12545"` — the confirmed response calls this `memberNo`
  /// (currently always null on this test data), so [memberId] is tried
  /// last, purely as a fallback so this is never blank.
  final String? memberCode;

  final String? fullName;
  final String? mobile;
  final String? fatherName;
  final String? dateOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? address;
  final String? occupation;
  final String? photoUrl;
  final String? schemeName;
  final String? joiningDate;

  /// `true` when this member's registration is still open for correction —
  /// a sibling of `memberDetail` in the real response, `false`/missing on a
  /// normal completed member. Login still succeeds either way (this isn't
  /// a rejection like the "pending"/"in review" cases — see
  /// LoginRepositoryImpl/LoginBlockedReason); LoginScreen reads this to
  /// send the member to the registration wizard (editable, prefilled)
  /// instead of Home.
  final bool isInEditMode;

  /// Admin-flagged fields still needing correction (a sibling of
  /// `memberDetail` in the real response) — empty on a normal login. Not
  /// included in [toJson]/persisted storage on purpose: a stale cached
  /// list could block on already-resolved queries or miss new ones, so
  /// this is only ever fresh, in-memory data for the current login
  /// session. See [hasUnresolvedQueries] and `QueryResolutionState`.
  final List<QueryItem> queries;

  /// `true` only when there's an active registration edit AND specific
  /// fields have been flagged for correction — the trigger for the
  /// restricted query-resolution flow (see LoginScreen), as opposed to
  /// the full open-everything edit wizard [isInEditMode] alone leads to.
  bool get hasUnresolvedQueries => isInEditMode && queries.isNotEmpty;

  /// Auth tokens from `data.authorizeToken` — kept separate from [toJson]
  /// on purpose: tokens already have their own dedicated storage (see
  /// `TokenManager`/`AppSecureStorage.saveTokens`), so they are not
  /// duplicated into the "logged in user" JSON blob.
  final String? accessToken;
  final String? refreshToken;

  /// The exact (flattened) JSON object this model was parsed from — kept
  /// around so fields this model doesn't itself model (Aadhaar/PAN
  /// numbers, document image ids, nominee list, health declaration, ...)
  /// aren't lost when caching "logged in user" locally. See [toJson] and
  /// `AppSecureStorage.saveLoggedInUser` — ProfileController parses this
  /// same blob into the richer `MemberModel`/`NomineeModel`/
  /// `HealthDeclarationModel` for the My Profile tabs.
  final Map<String, dynamic> raw;

  const LoginModel({
    required this.memberId,
    this.memberCode,
    this.fullName,
    this.mobile,
    this.fatherName,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.address,
    this.occupation,
    this.photoUrl,
    this.schemeName,
    this.joiningDate,
    this.isInEditMode = false,
    this.queries = const [],
    this.accessToken,
    this.refreshToken,
    this.raw = const {},
  });

  /// Returns a copy with the auth tokens attached — kept separate from
  /// [fromJson] so the tokens (from `data.authorizeToken`, a sibling of
  /// `memberDetail`, not part of it) never pass through [raw], and so
  /// never get duplicated into the cached "logged in user" blob via
  /// [toJson] — [TokenManager] is the one place they're persisted. See
  /// `LoginRepositoryImpl.login`.
  LoginModel withTokens({String? accessToken, String? refreshToken}) {
    return LoginModel(
      memberId: memberId,
      memberCode: memberCode,
      fullName: fullName,
      mobile: mobile,
      fatherName: fatherName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      maritalStatus: maritalStatus,
      address: address,
      occupation: occupation,
      photoUrl: photoUrl,
      schemeName: schemeName,
      joiningDate: joiningDate,
      isInEditMode: isInEditMode,
      queries: queries,
      accessToken: accessToken,
      refreshToken: refreshToken,
      raw: raw,
    );
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final surname = json['surname']?.toString() ?? '';
    final fullNameFromParts = [firstName, lastName, surname]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return LoginModel(
      memberId: _parseInt(
        _ciGet(json, 'memberId') ??
            _ciGet(json, 'member_id') ??
            _ciGet(json, 'id'),
      ),
      memberCode: _firstNonEmptyKey(json, const [
        'memberCode', 'memberNo', 'memberIdLabel', 'memberId',
      ]),
      fullName: _firstNonEmptyKey(json, const ['fullName', 'name', 'memberName']) ??
          (fullNameFromParts.isNotEmpty ? fullNameFromParts : null),
      mobile: _firstNonEmptyKey(json, const [
        'mobile', 'mobileNo', 'mobile1',
      ]),
      fatherName: _firstNonEmptyKey(json, const ['fatherName']),
      dateOfBirth: _firstNonEmptyKey(json, const ['dateOfBirth']),
      // Numeric enum ids on the real response (e.g. "1") — resolved to
      // display text via GetEnumBundle elsewhere, not here.
      gender: _firstNonEmptyKey(json, const ['gender']),
      maritalStatus: _firstNonEmptyKey(json, const ['maritalStatus']),
      address: _firstNonEmptyKey(json, const ['address']),
      occupation: _firstNonEmptyKey(json, const ['occupation']),
      photoUrl: _firstNonEmptyKey(json, const [
        'photoUrl', 'profilePhotourl', 'profileImage', 'profileImageUrl', 'imageUrl',
      ]),
      schemeName: _firstNonEmptyKey(json, const ['schemeName']),
      joiningDate: _firstNonEmptyKey(json, const ['joiningDate']),
      isInEditMode: json['isInEditMode'] == true,
      queries: (json['queries'] as List? ?? [])
          .map((e) => QueryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      raw: json,
    );
  }

  /// Everything from [raw] (Aadhaar/PAN, document image ids, nominee list,
  /// health declaration, etc.), overlaid with this model's own resolved
  /// canonical keys — same key names `MemberProfileModel.fromJson` reads,
  /// see this class's doc comment — so both the narrow profile model and
  /// the richer `MemberModel`/`NomineeModel`/`HealthDeclarationModel` can
  /// parse the same cached blob.
  Map<String, dynamic> toJson() {
    return {
      ...raw,
      'memberId': memberId,
      'memberCode': memberCode,
      'fullName': fullName,
      'mobile': mobile,
      'fatherName': fatherName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'address': address,
      'occupation': occupation,
      'photoUrl': photoUrl,
      'schemeName': schemeName,
      'joiningDate': joiningDate,
    };
  }

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
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}
