import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/features/home/presentation/pages/home_screen.dart';
import 'package:psf_application/features/loans/presentation/pages/loans_screen.dart';
import 'package:psf_application/features/profile/presentation/pages/profile_screen.dart';
import 'package:psf_application/shared/widgets/common/app_bottom_nav_bar.dart';

import '../controllers/main_navigation_controller.dart';

/// The single bottom-navigation shell for the signed-in app: Home / Loans
/// / Profile, each kept alive in an [IndexedStack] so switching tabs never
/// loses scroll position or re-triggers an API call.
///
/// This is what `AppRoutes.home` now points to — every earlier
/// `Get.offAllNamed(AppRoutes.home)` call site (login, registration
/// success, ...) lands here unchanged.
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  static const _tabs = [
    HomeScreen(),
    LoansScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainNavigationController>();

    return Obx(() {
      return Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: _tabs,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
          items: [
            AppBottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: AppStrings.navHome.tr,
            ),
            AppBottomNavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet_rounded,
              label: AppStrings.navLoans.tr,
            ),
            AppBottomNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: AppStrings.navProfile.tr,
            ),
          ],
        ),
      );
    });
  }
}
