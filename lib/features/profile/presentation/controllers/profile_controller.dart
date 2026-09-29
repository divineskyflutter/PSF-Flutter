import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/network/auth/token_manager.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/features/auth/data/models/health_declaration_model.dart';
import 'package:psf_application/features/auth/data/models/member_model.dart';
import 'package:psf_application/features/auth/data/models/nominee_model.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/features/enum_bundle/data/repository/enum_bundle_repository.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

import '../../data/models/member_profile_model.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/entities/member_profile_entity.dart';
import '../../domain/entities/passbook_entry_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController(this._repository, this._enumBundleRepository);

  final ProfileRepository _repository;

  final EnumBundleRepository _enumBundleRepository;

  // ============================================================
  // PROFILE
  // ============================================================

  final Rx<MemberProfileEntity?> profile = Rx<MemberProfileEntity?>(null);

  final RxBool isProfileLoading = false.obs;

  final RxBool hasProfileError = false.obs;

  final RxString profileErrorMessage = ''.obs;

  final RxBool isSavingProfile = false.obs;

  // ============================================================
  // MY PROFILE TABS — the richer data behind [profile]'s narrow summary
  // fields, all parsed from the same cached login blob (see
  // `loadProfileFromLocalLogin`): full personal detail (Aadhaar/PAN,
  // document images, ...), nominees and the health declaration.
  // ============================================================

  final Rx<MemberModel?> memberDetails = Rx<MemberModel?>(null);

  final RxList<NomineeModel> nominees = <NomineeModel>[].obs;

  final Rx<HealthDeclarationModel?> healthDeclaration =
      Rx<HealthDeclarationModel?>(null);

  /// Cached `GetEnumBundle` result (see `LoginController._cacheEnumBundle`)
  /// — used to resolve the numeric ids Login returns for gender/marital
  /// status/nominee relation/member status into display text. `null`
  /// until a login has fetched it at least once.
  final Rx<EnumBundleModel?> enumBundle = Rx<EnumBundleModel?>(null);

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
    // so re-enabling this once the API exists is a one-line change.
    // fetchProfile();

    // Local, network-free fallback: if a login was completed (see
    // LoginController.login), the signed-in member's data is already
    // sitting in secure storage — show it immediately on app open
    // instead of waiting on a real profile API that doesn't exist yet.
    // Until a real login has actually happened, this finds nothing and
    // the Profile screen falls back to its existing default labels
    // exactly as before (see ProfileScreen._ProfileHeader).
    loadProfileFromLocalLogin();
    ensureEnumBundle();
  }

  // ============================================================
  // LOCAL FALLBACK — show whatever Login already stored, no network
  // ============================================================

  Future<void> loadProfileFromLocalLogin() async {
    final storedUser = await AppSecureStorage.getLoggedInUser();

    if (storedUser == null) return;

    profile.value = MemberProfileModel.fromJson(storedUser);
    memberDetails.value = MemberModel.fromJson(storedUser);

    final nomineesJson = _ciGet(storedUser, 'nominees') ??
        _ciGet(storedUser, 'nomineeList') ??
        _ciGet(storedUser, 'nomineeProfile');

    if (nomineesJson is List) {
      nominees.assignAll(
        nomineesJson
            .whereType<Map>()
            .map((e) => NomineeModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } else {
      nominees.clear();
    }

    final healthJson = _ciGet(storedUser, 'healthDeclaration') ??
        _ciGet(storedUser, 'memberHealthDeclaration');

    healthDeclaration.value = healthJson is Map
        ? HealthDeclarationModel.fromJson(Map<String, dynamic>.from(healthJson))
        : null;
  }

  /// Reads whatever `GetEnumBundle` result Login last cached (see
  /// `LoginController._cacheEnumBundle`) — network-free, same "show
  /// whatever is already stored, no waiting" approach as
  /// [loadProfileFromLocalLogin].
  void loadCachedEnumBundle() {
    final cached = AppPrefs.enumBundleJson;
    if (cached == null || cached.isEmpty) return;

    try {
      enumBundle.value = EnumBundleModel.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    } catch (_) {
      // Corrupt/old-format cache — ignore, id-based fields just fall back
      // to showing the raw id until the next successful login re-caches it.
    }
  }

  /// Loads the cached bundle and, when there is none yet (login caches it
  /// asynchronously, so it can still be in flight when this controller is
  /// created), fetches it from `GetEnumBundle` and caches it. Updating
  /// [enumBundle] is what makes `MyProfilePage`/the Card screen rebuild
  /// with real names instead of raw numeric ids.
  Future<void> ensureEnumBundle() async {
    loadCachedEnumBundle();

    if (enumBundle.value != null) return;

    try {
      final bundle = await _enumBundleRepository.getEnumBundle();
      enumBundle.value = bundle;
      await AppPrefs.setEnumBundleJson(jsonEncode(bundle.toJson()));
    } catch (_) {
      // Ignored — id-based fields fall back to the raw id until the next
      // successful fetch.
    }
  }

  // ============================================================
  // ENUM ID -> DISPLAY NAME (Gender / Marital Status / Relation /
  // Member Status) — resolved against [enumBundle], see its doc comment.
  // ============================================================

  String genderName(String? id) => EnumBundleModel.nameFor(
        enumBundle.value?.gender ?? const [],
        int.tryParse(id ?? ''),
        fallback: id,
      );

  String maritalStatusName(String? id) => EnumBundleModel.nameFor(
        enumBundle.value?.maritalStatus ?? const [],
        int.tryParse(id ?? ''),
        fallback: id,
      );

  String relationName(int? id) => EnumBundleModel.nameFor(
        enumBundle.value?.relation ?? const [],
        id,
      );

  String memberStatusName(int? id) => EnumBundleModel.nameFor(
        enumBundle.value?.memberStatus ?? const [],
        id,
      );

  static dynamic _ciGet(Map<String, dynamic> json, String key) {
    final target = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == target) return entry.value;
    }
    return null;
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
      TokenManager.instance.clear(),
      AppSecureStorage.deleteMemberId(),
      AppSecureStorage.clearLoggedInUser(),
      // Set alongside the member id on a successful login (see
      // LoginScreen._onLoginPressed) so SplashScreen._routeNext() skips
      // straight to Home on the next app open — cleared here too so a
      // logged-out device never carries that flag with no member id
      // behind it.
      AppPrefs.setRegistrationCompleted(false),
    ]);
  }

  // ============================================================
  // DOWNLOAD APPLICATION PDF — My Profile's header download button.
  // ============================================================

  final RxBool isDownloadingPdf = false.obs;

  Future<void> downloadApplicationPdf() async {
    if (isDownloadingPdf.value) return;

    isDownloadingPdf.value = true;

    try {
      final bytes = await _repository.generateApplicationPdf();

      final savedPath = await FilePicker.platform.saveFile(
        fileName: 'PSF_Application.pdf',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: 'download_pdf'.tr,
      );

      if (savedPath != null) {
        ToastUtil.success('pdf_saved_successfully'.tr);
      } else {
        ToastUtil.error('pdf_save_cancelled'.tr);
      }
    } catch (_) {
      ToastUtil.error('pdf_generation_failed'.tr);
    } finally {
      isDownloadingPdf.value = false;
    }
  }
}
