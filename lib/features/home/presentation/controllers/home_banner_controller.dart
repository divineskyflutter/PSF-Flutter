import 'dart:async';

import 'package:get/get.dart';
import 'package:psf_application/features/auth/domain/entities/banner_entity.dart';
import 'package:psf_application/features/auth/domain/repositories/banner_repository.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

/// Drives the Home tab's own banner carousel — bannerType 2 ("Member"),
/// the id the backend reserves for banners shown once a member is signed
/// in, distinct from type 1 (auth choice screen) and type 3 (registration)
/// that [AuthBannerController] already covers.
class HomeBannerController extends GetxController {
  HomeBannerController(this.repository);

  final BannerRepository repository;

  StreamSubscription<void>? _reconnectSubscription;

  final RxList<BannerEntity> banners = <BannerEntity>[].obs;

  final RxBool isLoading = false.obs;

  final RxBool hasBannerError = false.obs;

  @override
  void onInit() {
    super.onInit();

    fetchBanners();

    // Same pattern as AuthBannerController: banners load automatically with
    // no retry button, so pick a failed load back up once connectivity
    // actually returns instead of leaving the carousel empty for the rest
    // of the session.
    _reconnectSubscription =
        Get.find<ConnectivityService>().onReconnected.listen((_) {
      if (hasBannerError.value) fetchBanners();
    });
  }

  @override
  void onClose() {
    _reconnectSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchBanners() async {
    try {
      isLoading.value = true;
      hasBannerError.value = false;

      final result = await repository.getBannerListByType(2);

      banners.assignAll(result);
    } catch (e) {
      hasBannerError.value = true;
      // Keep existing banners if a refresh fails.
    } finally {
      isLoading.value = false;
    }
  }
}
