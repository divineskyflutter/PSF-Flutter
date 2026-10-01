import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/shared/widgets/images/common_image_view.dart';
import 'package:psf_application/shared/widgets/sliders/app_image_slider.dart';

import '../controllers/home_banner_controller.dart';

/// Home tab's own banner carousel — bannerType 2 ("Member"), shown once the
/// member is signed in. Exactly the same [AppImageSlider] look/behaviour
/// AuthChoiceScreen's own banner uses, including its own 18px
/// `horizontalPadding` — the caller (HomeScreen) wraps this widget in a
/// matching *negative* 18px padding to cancel out its own SliverPadding, so
/// the resting-state margin is still 18px, but the slider's per-page
/// padding (which is what actually separates one slide from the next while
/// swiping, not just the resting margin) is intact.
class HomeBannerSlider extends StatelessWidget {
  const HomeBannerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeBannerController>();

    return Obx(
      () => AppImageSlider(
        images: controller.banners.map((banner) => banner.imageUrl).toList(),
        imageType: CommonImageType.network,
        isLoading: controller.isLoading.value,
        height: Get.height * 0.22,
        horizontalPadding: 18,
        borderRadius: 22,
        autoSlide: true,
        autoSlideDuration: const Duration(seconds: 4),
        animationDuration: const Duration(milliseconds: 500),
        showIndicators: true,
        showEmptyPlaceholder: true,
      ),
    );
  }
}
