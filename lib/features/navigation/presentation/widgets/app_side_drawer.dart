import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';
import 'package:psf_application/features/profile/presentation/widgets/language_settings_sheet.dart';
import 'package:psf_application/features/profile/presentation/widgets/profile_avatar_block.dart';
import 'package:psf_application/features/profile/presentation/widgets/profile_card_style.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_menu_tile.dart';
import 'package:psf_application/shared/widgets/dialogs/app_dialog.dart';

import '../controllers/main_navigation_controller.dart';

/// The side window opened by swiping in from the left edge (or the Home
/// header's menu button) — a normal light drawer (the app's own background,
/// not full screen width; see [MainNavigationScreen]'s `Drawer`).
///
/// On it: a horizontal profile card (photo on the left, name + mobile on
/// the right, same look as the old Profile summary card — tapping it opens
/// the Profile tab, same as tapping it in the bottom bar), then a menu:
/// Membership Card, About Us, Contact Us,
/// Language, Logout. Both fade/slide in one after another each time it
/// opens.
class AppSideDrawer extends StatefulWidget {
  const AppSideDrawer({super.key});

  @override
  State<AppSideDrawer> createState() => _AppSideDrawerState();
}

class _AppSideDrawerState extends State<AppSideDrawer> with SingleTickerProviderStateMixin {
  // The drawer's content is built each time it opens, so this plays every
  // time: the profile card fades in, then the menu follows.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Fade + slide-up for the [index]-th item of the staggered entrance.
  Widget _reveal(int index, Widget child) {
    final start = (index * .15).clamp(0.0, .6);
    final curved = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, (start + .5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, .12), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }

  void _confirmLogout(ProfileController profile) {
    AppDialog.logout(
      title: AppStrings.logout.tr,
      message: AppStrings.logoutConfirmMessage.tr,
      logoutText: AppStrings.logout.tr,
      cancelText: AppStrings.cancel.tr,
      onLogout: profile.logout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    final nav = Get.find<MainNavigationController>();

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 12.px(context)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.px(context)),
              child: _reveal(
                0,
                _ProfileCard(
                  profile: profile,
                  // Same tab switch as the "Membership Card" tile below —
                  // the Profile tab is already just one tap away in the
                  // bottom bar, this is the same shortcut from the drawer.
                  // Back-button-returns-to-Home already applies to every
                  // non-Home tab regardless of how it was opened (see
                  // MainNavigationScreen._onBackPressed), so no extra
                  // handling is needed here for that.
                  onTap: () {
                    nav.changeTab(MainNavigationController.profileTab);
                    nav.closeDrawer();
                  },
                ),
              ),
            ),
            SizedBox(height: 22.px(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.px(context), 0, 18.px(context), 20.px(context)),
                child: _reveal(
                  1,
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 6.px(context)),
                    decoration: profileCardDecoration(context),
                    child: Column(
                      children: [
                        AppMenuTile(
                          icon: Icons.badge_outlined,
                          label: AppStrings.membershipCard.tr,
                          // The Card tab IS the member card — just switch to
                          // it and close the drawer, instead of also
                          // opening MembershipCardPage as a second screen.
                          onTap: () {
                            nav.changeTab(MainNavigationController.cardTab);
                            nav.closeDrawer();
                          },
                        ),
                        AppMenuTile(
                          icon: Icons.info_outline_rounded,
                          label: AppStrings.aboutUs.tr,
                          onTap: () => Get.toNamed(
                            AppRoutes.aboutUs,
                            arguments: const {'viaDrawer': true},
                          ),
                        ),
                        AppMenuTile(
                          icon: Icons.support_agent_outlined,
                          label: AppStrings.contactUs.tr,
                          onTap: () => Get.toNamed(
                            AppRoutes.contactUs,
                            arguments: const {'viaDrawer': true},
                          ),
                        ),
                        AppMenuTile(
                          icon: Icons.translate_rounded,
                          label: AppStrings.language.tr,
                          onTap: LanguageSettingsSheet.show,
                        ),
                        AppMenuTile(
                          icon: Icons.logout_rounded,
                          label: AppStrings.logout.tr,
                          iconBackgroundColor: AppColors.warning.withOpacity(.10),
                          iconColor: AppColors.warning,
                          showDivider: false,
                          onTap: () => _confirmLogout(profile),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The horizontal profile card at the top of the drawer: photo on the left,
/// name + mobile stacked on the right in the same row — the same layout and
/// dark card look as the Profile tab's old summary card. Tapping it calls
/// [onTap] (opens the Profile tab — see the drawer's own build method).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onTap});

  final ProfileController profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final member = profile.memberDetails.value;
      final summary = profile.profile.value;

      final photoUrl = member?.imageUrl ?? summary?.photoUrl;
      final name = (member?.fullName.isNotEmpty ?? false)
          ? member!.fullName
          : (summary?.fullName ?? '');
      final mobile = (member?.mobile?.isNotEmpty ?? false)
          ? member!.mobile!
          : (summary?.mobile ?? '');

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.px(context)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.px(context)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.px(context)),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20.px(context)),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            child: ProfileAvatarBlock(
              name: name.isEmpty ? AppStrings.myProfile.tr : name,
              mobile: mobile.isEmpty ? '-' : mobile,
              photoUrl: photoUrl,
            ),
          ),
        ),
      );
    });
  }
}
