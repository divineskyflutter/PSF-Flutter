import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/features/navigation/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:psf_application/features/profile/presentation/widgets/profile_card_style.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

/// The Passbook tab of the bottom bar: two account tabs — Deposit Account and
/// Loan Account — switched by tapping a tab OR swiping the page sideways. No
/// passbook API feeds these yet, so each tab shows its empty state; when an
/// API arrives, only [_AccountTab] needs to render its entries.
class PassbookTabsScreen extends StatefulWidget {
  const PassbookTabsScreen({super.key});

  @override
  State<PassbookTabsScreen> createState() => _PassbookTabsScreenState();
}

class _PassbookTabsScreenState extends State<PassbookTabsScreen> {
  final PageController _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppStrings.depositAccountTab.tr,
      AppStrings.loanAccountTab.tr,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(
        title: AppStrings.passbook.tr,
        // A tab, not a pushed page: back goes to Home.
        onBack: () => Get.find<MainNavigationController>()
            .changeTab(MainNavigationController.homeTab),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18.px(context),
            AppSubPageHeader.totalHeight() + 14.px(context),
            18.px(context),
            0,
          ),
          child: Column(
            children: [
              _AccountTabSelector(
                labels: labels,
                pages: _pages,
                onTap: (i) => _pages.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                ),
              ),
              SizedBox(height: 18.px(context)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppBottomNavBar.occupiedHeight(context)),
                  // Swipe sideways to change tab; the selector above follows.
                  child: PageView(
                    controller: _pages,
                    children: [
                      for (var i = 0; i < labels.length; i++) _AccountTab(index: i),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Body of one account tab. Empty for now (see the screen's doc comment).
class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return AppStateView.empty(message: AppStrings.passbookTabEmpty.tr);
  }
}

/// Segmented control with a sliding gradient pill — same look as the Profile
/// tab selector, but text-only. The pill is driven by [pages]' scroll
/// position, so it slides along with the finger while the page is swiped.
class _AccountTabSelector extends StatelessWidget {
  const _AccountTabSelector({
    required this.labels,
    required this.pages,
    required this.onTap,
  });

  final List<String> labels;
  final PageController pages;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pages,
      builder: (context, _) {
        final position = pages.hasClients && pages.position.haveDimensions
            ? (pages.page ?? 0).clamp(0.0, labels.length - 1.0)
            : 0.0;
        return _buildSelector(context, position);
      },
    );
  }

  Widget _buildSelector(BuildContext context, double position) {
    final selectedIndex = position.round();

    return Container(
      padding: EdgeInsets.all(4.px(context)),
      decoration: profileCardDecoration(context).copyWith(
        borderRadius: BorderRadius.circular(20.px(context)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment(-1 + position * (2 / (labels.length - 1)), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(16.px(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.38),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.px(context),
                        vertical: 12.px(context),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.px(context),
                          height: 1.25,
                          fontWeight: selectedIndex == i ? FontWeight.w800 : FontWeight.w600,
                          color: selectedIndex == i ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
