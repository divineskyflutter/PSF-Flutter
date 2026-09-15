/// The signed-in member's full profile data, as returned by the (future)
/// Login API's success response. Field set intentionally mirrors
/// `MemberProfileEntity` (lib/features/profile/domain/entities/
/// member_profile_entity.dart) — `toJson()` below emits the same key
/// names `MemberProfileModel.fromJson` already reads, so once this model
/// is saved to secure storage (see AppSecureStorage.saveLoggedInUser),
/// Profile can parse it back straight into a profile entity with no
/// extra glue code. See ProfileController's local-fallback loading.
///
/// The exact response shape isn't confirmed yet — there is no real login
/// endpoint to test against — so, like MemberModel/MemberProfileModel,
/// every field is read case-insensitively with a few plausible key
/// spellings tried in order. Once the real API exists and its response
/// is seen, this parsing can be tightened.
class LoginModel {
  final int memberId;

  /// e.g. `"PSF12545"`.
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

  /// Auth tokens, if the login API issues them — kept separate from
  /// [toJson] on purpose: tokens already have their own dedicated
  /// storage (AppSecureStorage.saveTokens/getAccessToken/...), so they
  /// are not duplicated into the "logged in user" JSON blob.
  final String? accessToken;
  final String? refreshToken;

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
    this.accessToken,
    this.refreshToken,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      memberId: _parseInt(
        _ciGet(json, 'memberId') ??
            _ciGet(json, 'member_id') ??
            _ciGet(json, 'id'),
      ),
      memberCode: _firstNonEmptyKey(json, const [
        'memberCode', 'memberIdLabel', 'memberId',
      ]),
      fullName: _firstNonEmptyKey(json, const [
        'fullName', 'name', 'memberName',
      ]),
      mobile: _firstNonEmptyKey(json, const [
        'mobile', 'mobileNo', 'mobile1',
      ]),
      fatherName: _firstNonEmptyKey(json, const ['fatherName']),
      dateOfBirth: _firstNonEmptyKey(json, const ['dateOfBirth']),
      gender: _firstNonEmptyKey(json, const ['gender']),
      maritalStatus: _firstNonEmptyKey(json, const ['maritalStatus']),
      address: _firstNonEmptyKey(json, const ['address']),
      occupation: _firstNonEmptyKey(json, const ['occupation']),
      photoUrl: _firstNonEmptyKey(json, const [
        'photoUrl', 'profileImage', 'profileImageUrl', 'imageUrl',
      ]),
      schemeName: _firstNonEmptyKey(json, const ['schemeName']),
      joiningDate: _firstNonEmptyKey(json, const ['joiningDate']),
      accessToken: _firstNonEmptyKey(json, const [
        'accessToken', 'token', 'access_token',
      ]),
      refreshToken: _firstNonEmptyKey(json, const [
        'refreshToken', 'refresh_token',
      ]),
    );
  }

  /// Same key names `MemberProfileModel.fromJson` reads — see this
  /// class's doc comment.
  Map<String, dynamic> toJson() {
    return {
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
