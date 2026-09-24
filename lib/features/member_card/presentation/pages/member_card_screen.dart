import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/features/navigation/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../widgets/card_ambient_backdrop.dart';
import '../widgets/member_wallet_panel.dart';

/// The Card tab — the wallet and the member card on the app's normal
/// background.
///
/// No curved gradient header here on purpose (unlike the other sub-pages) —
/// just a plain title with a small back arrow, then the wallet directly
/// below it. The arrow switches to the Home tab instead of popping a route
/// (there is none to pop) — same destination as the system back gesture,
/// which every tab shares via MainNavigationScreen's own PopScope. The
/// `AppSubPageHeader` this screen used before is left commented out below
/// in case a fuller header is wanted back later.
///
/// A soft, slow-drifting [CardAmbientBackdrop] fills the space around the
/// wallet so the tab doesn't read as empty — a placeholder look, easy to
/// replace with something more specific later.
///
/// The wallet is only built while this tab is showing, so every visit
/// replays the wallet's entrance (the cover sliding in over the card) and
/// leaving the tab frees it instead of keeping the card animations alive
/// behind the other tabs.
class MemberCardScreen extends StatelessWidget {
  const MemberCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<MainNavigationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // appBar: AppSubPageHeader(title: 'nav_card'.tr, showBackButton: false),
      body: Stack(
        children: [
          const Positioned.fill(child: CardAmbientBackdrop()),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20.px(context),
                16.px(context),
                20.px(context),
                // Clear the bottom bar, which floats over the page.
                10.px(context) + AppBottomNavBar.occupiedHeight(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => nav.changeTab(MainNavigationController.homeTab),
                        child: Container(
                          width: 40.px(context),
                          height: 40.px(context),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18.px(context),
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.px(context)),
                      Text(
                        'nav_card'.tr,
                        style: TextStyle(
                          fontSize: 21.px(context),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.px(context)),
                  Expanded(
                    child: Obx(() {
                      final active = nav.currentIndex.value == MainNavigationController.cardTab;
                      return active ? const MemberWalletPanel() : const SizedBox.expand();
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
