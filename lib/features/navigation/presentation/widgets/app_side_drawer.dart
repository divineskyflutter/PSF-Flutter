import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/member_card/presentation/widgets/member_wallet_panel.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';
import 'package:psf_application/features/profile/presentation/widgets/profile_card_style.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/main_navigation_controller.dart';

/// The full-screen side window opened by swiping in from the left edge (or
/// the Home header's menu button).
///
/// A frosted, blurred backdrop with one smooth gradient that starts dark
/// teal in the top-left corner and gradually lightens toward the
/// bottom-right (no hard band). On it: the member's photo, name and mobile
/// number at the top — tapping the photo opens My Profile — and the
/// wallet + member card centered below (see [MemberWalletPanel]). Tapping
/// the empty background closes the window.
class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<MainNavigationController>();
    final profile = Get.find<ProfileController>();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: nav.closeDrawer,
            child: RepaintBoundary(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0, .3, .6, .85, 1],
                        colors: [
                          AppColors.primaryDark.withOpacity(.97),
                          const Color(0xFF1F6F68).withOpacity(.90),
                          AppColors.primary.withOpacity(.62),
                          AppColors.primaryLight.withOpacity(.28),
                          Colors.white.withOpacity(.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Soft glow behind the wallet so it lifts off the gradient.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, .05),
                  radius: .75,
                  colors: [
                    Colors.white.withOpacity(.20),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24.px(context), 10.px(context), 24.px(context), 0),
                child: Obx(() {
                  final member = profile.memberDetails.value;
                  final summary = profile.profile.value;

                  final photoUrl = member?.imageUrl ?? summary?.photoUrl;
                  final name = (member?.fullName.isNotEmpty ?? false)
                      ? member!.fullName
                      : (summary?.fullName ?? '');
                  final mobile = (member?.mobile?.isNotEmpty ?? false)
                      ? member!.mobile!
                      : (summary?.mobile ?? '');

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tapping the photo opens My Profile. The drawer is
                      // deliberately NOT closed first: closing it while the
                      // new page slides in left the drawer's close animation
                      // frozen underneath, and it then resumed (with the
                      // heavy wallet still on screen) right as you came
                      // back — the stutter on Back. Now Back simply returns
                      // to the drawer exactly as it was.
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Get.toNamed(AppRoutes.myProfile),
                        child: Container(
                          padding: EdgeInsets.all(3.px(context)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.accentGold, Color(0xFFB8922F)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGold.withOpacity(.35),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: FramedImage(
                            url: photoUrl,
                            size: 76.px(context),
                            circle: true,
                            fallbackIcon: Icons.person_rounded,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.px(context)),
                      Text(
                        name.isEmpty ? AppStrings.myProfile.tr : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.px(context),
                          fontWeight: FontWeight.w800,
                          letterSpacing: .2,
                        ),
                      ),
                      if (mobile.isNotEmpty) ...[
                        SizedBox(height: 6.px(context)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.px(context),
                            vertical: 5.px(context),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(20.px(context)),
                            border: Border.all(color: Colors.white.withOpacity(.28)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.call_rounded,
                                size: 13.px(context),
                                color: AppColors.accentGold,
                              ),
                              SizedBox(width: 6.px(context)),
                              Text(
                                mobile,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.px(context),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: .4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
              const Expanded(child: MemberWalletPanel()),
              SizedBox(height: 6.px(context)),
            ],
          ),
        ),
      ],
    );
  }
}
