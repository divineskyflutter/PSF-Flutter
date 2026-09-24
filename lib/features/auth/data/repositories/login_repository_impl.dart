import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_datasource.dart';
import '../models/login_model.dart';
import '../models/login_request_model.dart';

/// Keys stripped out of `memberDetail` before it's flattened and cached
/// locally (see [LoginRepositoryImpl.login]) — none of these are ever
/// shown in the UI, and `password`/`mpin`/`deviceToken`/`qr` are sensitive
/// enough that they shouldn't sit in on-device storage just because they
/// happened to ride along in the login response.
const _memberDetailKeysToStrip = [
  'password',
  'mpin',
  'deviceToken',
  'qr',
  'createdby',
  'createdDateTime',
  'modifiedBy',
  'modifiedDateTime',
  'createdByAdmin',
  'createdByAgent',
  'modifiedByAdmin',
  'modifiedByAgent',
  'isDeleted',
];

// ============================================================
// TEMPORARY — MemberLogin's `status` field can't be trusted right now: the
// web admin panel it depends on isn't live yet, so `status` currently comes
// back `false` even for a member whose data is genuinely in the database.
// Until the panel ships, [LoginRepositoryImpl.login] doesn't check `status`
// at all — it treats login as successful whenever the API actually
// returned usable member data, and as a failure only when it didn't.
//
// TO REVERT once the web panel is live and `status` is trustworthy again
// (the correct long-term behavior): change this single flag to `false`.
// Nothing else in this file needs to change — the `if` block below that
// reads it will simply stop applying, and `response.status` alone decides.
// ============================================================
const bool ignoreLoginStatusUntilBackendFixesIt = true;

class LoginRepositoryImpl implements LoginRepository {
  final LoginRemoteDataSource _remoteDataSource;

  LoginRepositoryImpl(this._remoteDataSource);

  @override
  Future<LoginModel> login({
    required String mobile,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(mobile: mobile, password: password),
    );

    final data = response.data;

    // "Usable member data" is deliberately loose here — either the usual
    // nested `data.memberDetail`, or (some responses put the member fields
    // straight on `data` with no `memberDetail` wrapper) any non-empty
    // `data` map at all. Either shape is handled below.
    final hasMemberData = data is Map && data.isNotEmpty;

    final treatAsSuccess =
        response.status || (ignoreLoginStatusUntilBackendFixesIt && hasMemberData);

    if (!treatAsSuccess) {
      throw Exception(
        response.message.isEmpty
            ? 'Login failed. Please try again.'
            : response.message,
      );
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid login response.');
    }

    // The real response nests everything under `data`: the flat member
    // fields live in `memberDetail`, with `nominees`, `healthDeclaration`
    // and `authorizeToken` as siblings — not at `data`'s own top level.
    final memberDetail = Map<String, dynamic>.from(
      (data['memberDetail'] as Map?) ?? data,
    )..removeWhere((key, _) => _memberDetailKeysToStrip.contains(key));

    // Flattened so LoginModel.fromJson (and, later, ProfileController's
    // MemberModel/NomineeModel/HealthDeclarationModel parsing of the same
    // cached blob) can all read from one map — see LoginModel's doc
    // comment.
    final merged = <String, dynamic>{
      ...memberDetail,
      if (data['nominees'] != null) 'nominees': data['nominees'],
      if (data['healthDeclaration'] != null)
        'healthDeclaration': data['healthDeclaration'],
      // Same fallback as MemberRepositoryImpl.saveMemberStep1 — some
      // endpoints only carry the new/authenticated id on the response
      // envelope's own top-level `id`, not inside `data` itself.
      if (memberDetail['memberId'] == null && memberDetail['id'] == null)
        'memberId': response.id,
      // Sibling of `memberDetail`, not part of it (confirmed against a
      // live response) — `true` even on an otherwise-successful login
      // means this member's registration is still open for correction,
      // so LoginScreen sends them to the wizard instead of Home. See
      // LoginModel.isInEditMode.
      'isInEditMode': data['isInEditMode'] == true,
    };

    var result = LoginModel.fromJson(merged);

    // `authorizeToken` is a sibling of `memberDetail`, not part of it —
    // attached via withTokens (not folded into `merged` above) so the
    // tokens never end up cached in the "logged in user" blob; see
    // LoginModel.withTokens's doc comment.
    final authorizeToken = data['authorizeToken'];
    if (authorizeToken is Map) {
      result = result.withTokens(
        accessToken: authorizeToken['accessToken']?.toString(),
        refreshToken: authorizeToken['refreshToken']?.toString(),
      );
    }

    return result;
  }
}
