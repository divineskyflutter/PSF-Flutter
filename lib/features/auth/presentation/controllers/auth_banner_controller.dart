import 'dart:async';

import 'package:get/get.dart';
import 'package:psf_application/features/auth/domain/repositories/banner_repository.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

import '../../domain/entities/banner_entity.dart';

class AuthBannerController extends GetxController {
  AuthBannerController(this.repository);

  final BannerRepository repository;

  StreamSubscription<void>? _reconnectSubscription;

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

    // Banners load automatically (no button the user could re-tap), so if a
    // connectivity drop cancelled the initial load, pick it back up on its
    // own the moment the connection returns — but only when the earlier
    // attempt actually failed; a reconnect after banners already loaded
    // fine shouldn't re-fetch for no reason.
    _reconnectSubscription =
        Get.find<ConnectivityService>().onReconnected.listen((_) {
      if (hasBannerError.value) fetchBanners();
      if (hasRegistrationBannerError.value) fetchRegistrationBanners();
    });
  }

  @override
  void onClose() {
    _reconnectSubscription?.cancel();
    super.onClose();
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
      await repository.getBannerListByType(3);

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