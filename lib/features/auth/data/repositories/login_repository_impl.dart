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
// TEMPORARY — MemberLogin currently sends back `status: false` even on a
// genuine successful login (a fully-populated `data.memberDetail`) — a
// backend bug, confirmed against a real response on 2026-09-17. Until
// that's fixed server-side, [LoginRepositoryImpl.login] treats "status
// false but data.memberDetail is present" as success instead of failure.
//
// TO REVERT once the backend fixes this (i.e. to go back to strictly
// honoring `response.status`, which is the correct long-term behavior):
// change this single flag to `false`. Nothing else in this file needs to
// change — the `if` block below that reads it will simply stop applying.
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

    final hasMemberDetail = data is Map && data['memberDetail'] is Map;

    final treatAsSuccess = response.status ||
        (ignoreLoginStatusUntilBackendFixesIt && hasMemberDetail);

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
