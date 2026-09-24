import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:psf_application/core/network/auth/token_manager.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/features/enum_bundle/data/repository/enum_bundle_repository.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

import '../../data/models/login_model.dart';
import '../../domain/repositories/login_repository.dart';

/// A login that failed not because the credentials were wrong, but because
/// the member's registration itself isn't in a loggable-in state yet — the
/// API says so via [LoginController.lastBlockedReason] instead of the
/// usual error toast, so the login screen can send the member somewhere
/// useful instead of just leaving them stuck on a red error message.
///
/// MemberLogin never says which of these it means beyond the message text
/// itself (no separate status code, no member data at all comes back
/// either way — confirmed against live responses for accounts in each
/// state) — [LoginController.login] tells them apart by sniffing that text
/// for "review" vs "pending". An account whose registration is resumable
/// but not finished (e.g. still sitting on an earlier wizard step) also
/// currently comes back with the same "pending" wording — it's routed the
/// same as [pending] below, which is correct: the existing register/resume
/// flow (RegisterScreen -> RegistrationController.getMemberStatus ->
/// RegistrationNavigator) already reopens a member exactly where they left
/// off, on whatever step, editable, from nothing more than their name and
/// mobile number.
enum LoginBlockedReason {
  /// "...Pending Please Complete First..." — registration was started but
  /// not finished. Routed to RegisterScreen, which resumes it.
  pending,

  /// "...In Review..." — registration is complete and awaiting an
  /// administrator's decision; nothing left for the member to fill in.
  /// Routed straight to RegistrationPendingScreen.
  review,
}

/// Drives the Login screen's API call.
class LoginController extends GetxController {
  LoginController(this._repository, this._enumBundleRepository);

  final LoginRepository _repository;

  final EnumBundleRepository _enumBundleRepository;

  final RxBool isLoggingIn = false.obs;

  final Rx<LoginModel?> loggedInUser = Rx<LoginModel?>(null);

  /// Set by the last failed [login] call when the API blocked it for a
  /// recognized reason (see [LoginBlockedReason]) rather than a plain
  /// wrong-credentials/server error — `null` for a successful login, for a
  /// login that hasn't been attempted yet, or for any other failure (which
  /// shows the usual error toast instead). The login screen reads this
  /// right after `login()` returns `false` to decide where to send the
  /// member.
  LoginBlockedReason? lastBlockedReason;

  Future<bool> login({
    required String mobile,
    required String password,
  }) async {
    lastBlockedReason = null;

    try {
      isLoggingIn.value = true;

      final result = await _repository.login(
        mobile: mobile,
        password: password,
      );

      loggedInUser.value = result;

      // Persist so Profile can show this on the next app open without a
      // network call — see AppSecureStorage.saveLoggedInUser's doc
      // comment and ProfileController's local-fallback loading. The full
      // raw blob (not just the narrow profile fields) is cached so the My
      // Profile tabs can parse the richer member/nominee/health-
      // declaration data straight back out of it.
      await AppSecureStorage.saveMemberId(result.memberId);
      await AppSecureStorage.saveLoggedInUser(result.toJson());

      if (result.accessToken != null && result.refreshToken != null) {
        await TokenManager.instance.setTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken!,
        );
      }

      ToastUtil.success('login_successful'.tr);

      // Best-effort — a member's gender/marital status/nominee relation
      // all come back from Login as bare numeric ids (see LoginModel's
      // doc comment); this cache is what lets My Profile resolve them to
      // display text. A failure here must never fail the login itself.
      unawaited(_cacheEnumBundle());

      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final normalized = message.toLowerCase();

      if (normalized.contains('review')) {
        lastBlockedReason = LoginBlockedReason.review;
      } else if (normalized.contains('pending')) {
        lastBlockedReason = LoginBlockedReason.pending;
      } else {
        // A genuine error (wrong password, server error, ...) — nothing to
        // redirect to, so this is the one case that still gets the toast.
        ToastUtil.error(message);
      }

      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  Future<void> _cacheEnumBundle() async {
    try {
      final bundle = await _enumBundleRepository.getEnumBundle();
      await AppPrefs.setEnumBundleJson(jsonEncode(bundle.toJson()));
    } catch (_) {
      // Ignored — My Profile falls back to showing the raw id when no
      // cached bundle is available yet.
    }
  }
}
