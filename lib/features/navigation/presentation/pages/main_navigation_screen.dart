import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/features/home/presentation/pages/home_screen.dart';
import 'package:psf_application/features/member_card/presentation/pages/member_card_screen.dart';
import 'package:psf_application/features/profile/presentation/pages/profile_screen.dart';

import '../controllers/main_navigation_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';

/// The single bottom-navigation shell for the signed-in app: Profile /
/// Home (center) / Card, each kept alive in an [IndexedStack] so switching
/// tabs never loses scroll position or re-triggers an API call. Also hosts
/// the swipe-from-left-edge side drawer ([AppSideDrawer]).
///
/// This is what `AppRoutes.home` points to — every earlier
/// `Get.offAllNamed(AppRoutes.home)` call site (login, registration
/// success, ...) lands here unchanged, on the Home tab.
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  static const _tabs = [
    ProfileScreen(),
    HomeScreen(),
    MemberCardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainNavigationController>();

    return Obx(() {
      return Scaffold(
        key: controller.scaffoldKey,
        backgroundColor: AppColors.background,
        // The bar floats over the page instead of reserving a strip of
        // background under it, so only the pill itself takes space.
        extendBody: true,
        // The drawer paints its own blur + gradient over the whole screen,
        // so Scaffold's default dark scrim would just muddy it.
        drawerScrimColor: Colors.transparent,
        // A generous swipe zone (28% of the screen width) so the drawer
        // opens from an easy, natural swipe — not only from the very edge.
        drawerEdgeDragWidth: MediaQuery.sizeOf(context).width * .28,
        drawer: Drawer(
          width: MediaQuery.sizeOf(context).width,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
          child: const AppSideDrawer(),
        ),
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: _tabs,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
          centerIndex: MainNavigationController.homeTab,
          items: [
            AppBottomNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: AppStrings.navProfile.tr,
            ),
            AppBottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: AppStrings.navHome.tr,
            ),
            AppBottomNavItem(
              icon: Icons.credit_card_outlined,
              activeIcon: Icons.credit_card_rounded,
              label: 'nav_card'.tr,
            ),
          ],
        ),
      );
    });
  }
}
