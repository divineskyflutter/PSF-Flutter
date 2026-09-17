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

/// Drives the Login screen's API call.
class LoginController extends GetxController {
  LoginController(this._repository, this._enumBundleRepository);

  final LoginRepository _repository;

  final EnumBundleRepository _enumBundleRepository;

  final RxBool isLoggingIn = false.obs;

  final Rx<LoginModel?> loggedInUser = Rx<LoginModel?>(null);

  Future<bool> login({
    required String mobile,
    required String password,
  }) async {
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
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
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
