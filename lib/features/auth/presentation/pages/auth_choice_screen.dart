import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_assets.dart';

import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/features/auth/presentation/widgets/auth_header.dart';
import 'package:psf_application/features/auth/presentation/widgets/empty_state.dart';
import 'package:psf_application/features/auth/presentation/controllers/auth_banner_controller.dart';
import 'package:psf_application/features/auth/presentation/widgets/network_banner.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/shared/widgets/images/common_image_view.dart';
import 'package:psf_application/shared/widgets/sliders/app_image_slider.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {
  late final PageController _pageController;
  late final AuthBannerController _bannerController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: 0,
    );

    _bannerController = Get.find<AuthBannerController>();
  }


  // ==============================================================
  // DISPOSE
  // ==============================================================

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  // ==============================================================
  // BUILD
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        top: false,
        child: Column(
          children: [

            // ======================================================
            // HEADER
            // ======================================================

            Padding(
              padding: EdgeInsets.fromLTRB(
                24.px(context),
                70.px(context),
                20.px(context),
                40.px(context),
              ),              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.welcomeToPsf.tr,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24.px(context),
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),

                        SizedBox(
                          height: 10.px(context),
                        ),

                        Text(
                          AppStrings.authHeaderSubtitle.tr,
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12.px(context),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),


                  SizedBox(
                    width: 12.px(context),
                  ),

                  // ======================================================
                  // RIGHT - LOGO
                  // ======================================================

                  SvgPicture.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                    width: 75.px(context),
                    height: 75.px(context),
                  ),
                ],
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Expanded(
              child: SingleChildScrollView(
                // Normal Android/iOS bounded scrolling.
                physics: const ClampingScrollPhysics(),

                child: Padding(
                  padding: EdgeInsets.only(
                    top: 16.px(context),
                    bottom: 20.px(context),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ==================================================
                      // BANNER SLIDER
                      // ==================================================

                      Obx(
                            () => _buildImageSlider(context),
                      ),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================

                      SizedBox(
                        height: 20.px(context),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.px(context),
                        ),
                        child: Column(
                          children: [

                            Text(
                              AppStrings.authWelcomeTitle.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20.px(context),
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),

                            SizedBox(
                              height: 8.px(context),
                            ),

                            Text(
                              AppStrings.authWelcomeDescription.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14.px(context),
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==================================================
                      // SIGN IN + REGISTER
                      // ==================================================

                      SizedBox(
                        height: 130.px(context),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.px(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [

                            // -----------------------------
                            // SIGN IN
                            // -----------------------------

                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: AppStrings.signIn.tr,
                                onPressed: () {
                                  // Get.toNamed(AppRoutes.login);
                                },
                                height: 56.px(context),
                                borderRadius: 14.px(context),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(
                                  fontSize: 15.px(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 14.px(context),
                            ),

                            // -----------------------------
                            // REGISTER
                            // -----------------------------

                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: AppStrings.register.tr,
                                onPressed: () {
                                  Get.toNamed(AppRoutes.registerScreen);
                                },
                                height: 56.px(context),
                                borderRadius: 14.px(context),
                                backgroundColor: Colors.transparent,
                                foregroundColor: AppColors.primary,
                                border: BorderSide(
                                  width: 1.5,
                                  color: AppColors.primary,
                                ),
                                textStyle: TextStyle(
                                  fontSize: 15.px(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Small bottom spacing only.
                      SizedBox(
                        height: 16.px(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // IMAGE SLIDER
  // ==============================================================

  Widget _buildImageSlider(BuildContext context) {
    return AppImageSlider(
      images: _bannerController.banners
          .map((banner) => banner.imageUrl)
          .toList(),

      imageType: CommonImageType.network,

      isLoading: _bannerController.isLoading.value,

      height: Get.height * 0.22,

      horizontalPadding: 18,

      borderRadius: 22,

      autoSlide: true,

      autoSlideDuration: const Duration(
        seconds: 4,
      ),

      animationDuration: const Duration(
        milliseconds: 500,
      ),

      showIndicators: true,

      showEmptyPlaceholder: true,
    );
  }
}