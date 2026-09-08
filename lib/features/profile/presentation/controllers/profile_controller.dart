import 'package:get/get.dart';

import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/member_profile_entity.dart';
import '../../domain/entities/passbook_entry_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._repository);

  final ProfileRepository _repository;

  // ============================================================
  // PROFILE
  // ============================================================

  final Rx<MemberProfileEntity?> profile = Rx<MemberProfileEntity?>(null);

  final RxBool isProfileLoading = false.obs;

  final RxBool hasProfileError = false.obs;

  final RxString profileErrorMessage = ''.obs;

  final RxBool isSavingProfile = false.obs;

  // ============================================================
  // PASSBOOK
  // ============================================================

  final RxList<PassbookEntryEntity> passbook = <PassbookEntryEntity>[].obs;

  final RxBool isPassbookLoading = false.obs;

  final RxBool hasPassbookError = false.obs;

  final RxString passbookErrorMessage = ''.obs;

  // ============================================================
  // CONTACT US
  // ============================================================

  final RxList<ContactEntity> contacts = <ContactEntity>[].obs;

  final RxBool isContactsLoading = false.obs;

  final RxBool hasContactsError = false.obs;

  final RxString contactsErrorMessage = ''.obs;

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  final RxBool isDeletingAccount = false.obs;

  @override
  void onInit() {
    super.onInit();

    // There's no member-profile API to call yet. Auto-fetching here used
    // to fire GetMemberProfile as soon as the Profile tab's controller
    // was constructed (i.e. as soon as the bottom-nav shell loads — see
    // MainNavigationBinding), which always failed and — via the global
    // ErrorInterceptor, not this class — surfaced as an error toast the
    // moment the app reached Home/Profile. Left commented, not deleted,
    // so re-enabling this once the API exists is a one-line change. Until
    // then the Profile screen just shows its default/fallback labels
    // (see ProfileScreen._ProfileHeader, which already falls back to
    // AppStrings.myProfile / '-' when profile.value is null).
    // fetchProfile();
  }

  // ============================================================
  // FETCH PROFILE
  // ============================================================

  Future<void> fetchProfile() async {
    try {
      isProfileLoading.value = true;
      hasProfileError.value = false;

      final result = await _repository.getMemberProfile();

      profile.value = result;
    } catch (e) {
      hasProfileError.value = true;
      profileErrorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isProfileLoading.value = false;
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    try {
      isSavingProfile.value = true;

      await _repository.updateMemberProfile(fields);

      await fetchProfile();

      return true;
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isSavingProfile.value = false;
    }
  }

  // ============================================================
  // PASSBOOK
  // ============================================================

  Future<void> fetchPassbook() async {
    try {
      isPassbookLoading.value = true;
      hasPassbookError.value = false;

      final result = await _repository.getPassbook();

      passbook.assignAll(result);
    } catch (e) {
      hasPassbookError.value = true;
      passbookErrorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isPassbookLoading.value = false;
    }
  }

  // ============================================================
  // CONTACT US
  // ============================================================

  Future<void> fetchContacts() async {
    try {
      isContactsLoading.value = true;
      hasContactsError.value = false;

      final result = await _repository.getContactUsList();

      contacts.assignAll(result);
    } catch (e) {
      hasContactsError.value = true;
      contactsErrorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isContactsLoading.value = false;
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<bool> deleteAccount() async {
    try {
      isDeletingAccount.value = true;

      await _repository.deleteAccount();
      await _clearSession();

      return true;
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      isDeletingAccount.value = false;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _clearSession();
    Get.offAllNamed(AppRoutes.authChoice);
  }

  Future<void> _clearSession() async {
    await Future.wait([
      AppSecureStorage.clearTokens(),
      AppSecureStorage.deleteMemberId(),
    ]);
  }
}
