import 'package:get/get.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

import '../../data/models/login_model.dart';
import '../../domain/repositories/login_repository.dart';

/// Drives the (future) Login API call.
///
/// Not wired to the Login screen's button yet — see
/// `LoginScreen._onLoginPressed`'s comment — because there is no real
/// login endpoint on the backend yet (the same reason
/// `ProfileController.fetchProfile()` is built but not auto-called from
/// `onInit`; see that class's doc comment). Once the real API exists,
/// pointing the button at [login] is the only change needed — this
/// controller, LoginRepository, LoginRemoteDataSource and LoginModel are
/// already built and registered in AuthBinding.
class LoginController extends GetxController {
  LoginController(this._repository);

  final LoginRepository _repository;

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
      // comment and ProfileController's local-fallback loading.
      await AppSecureStorage.saveMemberId(result.memberId);
      await AppSecureStorage.saveLoggedInUser(result.toJson());

      if (result.accessToken != null && result.refreshToken != null) {
        await AppSecureStorage.saveTokens(
          accessToken: result.accessToken!,
          refreshToken: result.refreshToken!,
        );
      }

      ToastUtil.success('login_successful'.tr);

      return true;
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }
}
