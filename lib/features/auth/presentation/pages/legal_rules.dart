import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/routes/app_routes.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/features/auth/domain/entities/banner_entity.dart';
import 'package:psf_application/features/auth/presentation/widgets/network_banner.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/images/common_image_view.dart';
import 'package:psf_application/shared/widgets/sliders/app_image_slider.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import '../controllers/auth_banner_controller.dart';

class LegalRules extends StatefulWidget {
  const LegalRules({super.key});

  @override
  State<LegalRules> createState() =>
      _LegalRulesState();
}

class _LegalRulesState extends State<LegalRules> {
  final AuthBannerController bannerController =
  Get.find<AuthBannerController>();


  final List<String> ruleImages = [
    AppAssets.registerRulesIncomeText,
    AppAssets.registerRulesPanCardId,
    AppAssets.registerRulesSection8,
    AppAssets.registerRulesCertificateOfIncorporation,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // --------------------------------------------------
              // LOGO
              // --------------------------------------------------

              Padding(
                padding: EdgeInsets.fromLTRB(
                  20.px(context),
                  20.px(context),
                  20.px(context),
                  8.px(context),
                ),
                child: Row(
                  children: [
                    /// LEFT SIDE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'know_about_us'.tr,
                            style: TextStyle(
                              fontSize: 24.px(context),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),

                          SizedBox(height: 6.px(context)),

                          Text(
                            'know_about_us_description'.tr,
                            style: TextStyle(
                              fontSize: 10.px(context),
                              height: 1.5,
                              color: AppColors.primaryDark.withOpacity(0.65),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 16.px(context)),

                    /// RIGHT SIDE LOGO
                    SvgPicture.asset(
                      AppAssets.logo,
                      fit: BoxFit.contain,
                      width: 75.px(context),
                      height: 75.px(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),


              // --------------------------------------------------
              // IMAGE SLIDER
              // --------------------------------------------------

              _buildSlider(),

              const SizedBox(height: 18),

              // --------------------------------------------------
              // LEGAL & COMPLIANCE
              // --------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'legal_compliance'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // --------------------------------------------------
              // INFORMATION CARDS
              // --------------------------------------------------

              SizedBox(
                height: 150.px(context),
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.px(context),
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: ruleImages.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(width: 12.px(context)),
                  itemBuilder: (context, index) {
                    return _buildInformationCard(
                      context,
                      index,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --------------------------------------------------
              // INFORMATION TEXT
              // --------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'family_welfare_information'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.primaryDark.withOpacity(0.70),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // --------------------------------------------------
              // REGISTRATION INFORMATION
              // --------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'registration_form_information'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // --------------------------------------------------
              // REGISTRATION FORM BUTTON
              // --------------------------------------------------

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.toNamed(AppRoutes.memberRegistrationStep1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'continue_registration'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),

      // --------------------------------------------------
      // BOTTOM NAVIGATION
      // --------------------------------------------------

      // bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ==========================================================
  // SLIDER
  // ==========================================================

  Widget _buildSlider() {
    return Obx(() {
      return AppImageSlider(
        images: bannerController.registrationBanners
            .map((banner) => banner.imageUrl)
            .toList(),

        imageType: CommonImageType.network,

        isLoading:
        bannerController.isRegistrationLoading.value,

        height: Get.height * 0.22,

        horizontalPadding: 18,

        borderRadius: 18,

        autoSlide: true,

        autoSlideDuration: const Duration(
          seconds: 4,
        ),

        animationDuration: const Duration(
          milliseconds: 600,
        ),

        showIndicators: true,

        showEmptyPlaceholder: false,
      );
    });
  }

  // ==========================================================
  // INFORMATION CARD
  // ==========================================================

  Widget _buildInformationCard(
      BuildContext context,
      int index,
      ) {
    final imagePath = ruleImages[index];

    return GestureDetector(
      onTap: () {
        CommonImagePreview.show(
          context: context,

          images: ruleImages
              .map(
                (image) => PreviewImageItem(
              imagePath: image,
              type: PreviewImageType.asset,
            ),
          )
              .toList(),

          initialIndex: index,

          // Small preview window
          mode: ImagePreviewMode.dialog,
        );
      },
      child: Container(
        width: 130.px(context),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(
            14.px(context),
          ),
          border: Border.all(
            color: AppColors.primaryDark.withOpacity(0.10),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            14.px(context),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CommonImageView(
                image: imagePath,
                type: CommonImageType.asset,
                index: index,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(
                  14.px(context),
                ),
              ),

              // Small dark overlay for better preview effect
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.20),
                    ],
                  ),
                ),
              ),

              // Zoom icon
              Positioned(
                right: 8.px(context),
                bottom: 8.px(context),
                child: Container(
                  width: 30.px(context),
                  height: 30.px(context),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.zoom_in_rounded,
                    size: 18.px(context),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ==========================================================
  // BOTTOM NAVIGATION
  // ==========================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'home'.tr,
                selected: true,
              ),

              _buildNavItem(
                icon: Icons.category_outlined,
                label: 'schemes'.tr,
              ),

              _buildNavItem(
                icon: Icons.info_outline_rounded,
                label: 'about_us'.tr,
              ),

              _buildNavItem(
                icon: Icons.support_agent_outlined,
                label: 'contact_us'.tr,
              ),

              _buildNavItem(
                icon: Icons.login_rounded,
                label: 'login'.tr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: navigation
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected
                ? AppColors.primary
                : AppColors.primaryDark.withOpacity(0.45),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
              selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : AppColors.primaryDark.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}
