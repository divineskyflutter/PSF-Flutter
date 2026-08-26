import 'package:get/get.dart';
import 'package:psf_application/features/auth/domain/repositories/banner_repository.dart';

import '../../domain/entities/banner_entity.dart';

class AuthBannerController extends GetxController {
  AuthBannerController(this.repository);

  final BannerRepository repository;

  // ============================================================
  // TYPE 1 - AUTH CHOICE BANNERS
  // ============================================================

  final RxList<BannerEntity> banners = <BannerEntity>[].obs;

  final RxBool isLoading = false.obs;

  final RxBool hasBannerError = false.obs;

  // ============================================================
  // TYPE 2 - REGISTRATION BANNERS
  // ============================================================

  final RxList<BannerEntity> registrationBanners =
      <BannerEntity>[].obs;

  final RxBool isRegistrationLoading = false.obs;

  final RxBool hasRegistrationBannerError = false.obs;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void onInit() {
    super.onInit();

    fetchBanners();
    fetchRegistrationBanners();
  }

  // ============================================================
  // TYPE 1
  // ============================================================

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      hasBannerError.value = false;

      final result =
      await repository.getBannerListByType(1);

      banners.assignAll(result);
    } catch (e) {
      hasBannerError.value = true;

      // Keep existing banners if refresh fails.
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // TYPE 2
  // ============================================================

  Future<void> fetchRegistrationBanners() async {
    try {
      isRegistrationLoading.value = true;
      hasRegistrationBannerError.value = false;

      final result =
      await repository.getBannerListByType(2);

      registrationBanners.assignAll(result);
    } catch (e) {
      hasRegistrationBannerError.value = true;

      // Keep existing banners if refresh fails.
    } finally {
      isRegistrationLoading.value = false;
    }
  }

  // ============================================================
  // REFRESH ALL
  // ============================================================

  Future<void> refreshAllBanners() async {
    await Future.wait([
      fetchBanners(),
      fetchRegistrationBanners(),
    ]);
  }
}