import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/features/home/presentation/pages/home_screen.dart';
import 'package:psf_application/features/member_card/presentation/pages/member_card_screen.dart';
import 'package:psf_application/features/profile/presentation/pages/profile_screen.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

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
///
/// **Back button, everywhere in the signed-in app:** only Home has no back
/// arrow. Every other tab's arrow (and the system back gesture, since both
/// are funnelled through this same [PopScope]) returns to Home instead of
/// leaving the app — there's nothing "beneath" a tab to pop to, since tabs
/// are just [IndexedStack] children, not their own routes. On Home itself,
/// back shows a "press again to exit" snackbar instead of exiting
/// immediately. Screens pushed from the drawer (About Us, Contact Us) have
/// their own matching behaviour — see their `viaDrawer` argument handling.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  static const _tabs = [
    ProfileScreen(),
    HomeScreen(),
    MemberCardScreen(),
  ];

  DateTime? _lastBackPressTime;

  void _onBackPressed(MainNavigationController controller) {
    // The drawer's own scrim-tap/swipe-to-close already works — this just
    // makes the system back gesture do the same instead of falling through
    // to the tab/exit logic underneath it.
    final drawerState = controller.scaffoldKey.currentState;
    if (drawerState != null && drawerState.isDrawerOpen) {
      drawerState.closeDrawer();
      return;
    }

    if (controller.currentIndex.value != MainNavigationController.homeTab) {
      controller.changeTab(MainNavigationController.homeTab);
      return;
    }

    final now = DateTime.now();
    final withinDoubleTapWindow = _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2);

    if (withinDoubleTapWindow) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressTime = now;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('press_back_again_to_exit'.tr),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainNavigationController>();

    return Obx(() {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onBackPressed(controller);
        },
        child: Scaffold(
          key: controller.scaffoldKey,
          backgroundColor: AppColors.background,
          // The bar floats over the page instead of reserving a strip of
          // background under it, so only the pill itself takes space.
          extendBody: true,
          // A generous swipe zone (28% of the screen width) so the drawer
          // opens from an easy, natural swipe — not only from the very edge.
          drawerEdgeDragWidth: MediaQuery.sizeOf(context).width * .28,
          // A normal drawer now: it doesn't cover the full width, so the rest
          // of the page stays visible (dimmed by the default scrim) behind it.
          drawer: Drawer(
            width: MediaQuery.sizeOf(context).width * .82,
            backgroundColor: AppColors.background,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(26.px(context)),
                bottomRight: Radius.circular(26.px(context)),
              ),
            ),
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
        ),
      );
    });
  }
}
