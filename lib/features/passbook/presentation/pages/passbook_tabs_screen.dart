import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/features/passbook/presentation/passbook_tab_request.dart';
import 'package:psf_application/features/navigation/presentation/widgets/app_bottom_nav_bar.dart';
import 'package:psf_application/features/profile/presentation/widgets/profile_card_style.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/passbook_book/passbook_book_view.dart';
import 'package:psf_application/shared/widgets/passbook_book/passbook_record.dart';

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
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    PassbookTabRequest.requested.addListener(_applyRequest);
    _applyRequest();
  }

  @override
  void dispose() {
    PassbookTabRequest.requested.removeListener(_applyRequest);
    _pages.dispose();
    super.dispose();
  }

  /// A notification asked for a particular tab: slide to it, then clear the
  /// request so a later normal visit is not affected.
  void _applyRequest() {
    final tab = PassbookTabRequest.requested.value;
    if (tab == null) return;
    PassbookTabRequest.requested.value = null;

    void go() {
      if (!mounted) return;
      if (_pages.hasClients) {
        _goTo(tab.clamp(0, 1));
      } else {
        // Not laid out yet: try once more on the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pages.hasClients) _goTo(tab.clamp(0, 1));
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => go());
  }

  void _goTo(int i) => _pages.animateToPage(
        i,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );

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
      // No SafeArea bottom: the bottom-bar height below already includes the
      // system inset, and counting it twice left a gap under the page.
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18.px(context),
            AppSubPageHeader.totalHeight() + 14.px(context),
            18.px(context),
            0,
          ),
          child: Column(
            children: [
              // The book below takes sideways swipes (they turn its pages), so
              // the tabs change by tapping them or by swiping on this bar.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() < 200) return;
                  _goTo((_selected + (v < 0 ? 1 : -1)).clamp(0, labels.length - 1));
                },
                child: _AccountTabSelector(
                  labels: labels,
                  pages: _pages,
                  onTap: _goTo,
                ),
              ),
              SizedBox(height: 12.px(context)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: AppBottomNavBar.occupiedHeight(context) - 6.px(context),
                  ),
                  // Swipe sideways to change tab; the selector above follows.
                  child: PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _selected = i),
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        _AccountTab(index: i, active: i == _selected),
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

/// Body of one account tab: its ledger as a paper book. No passbook API feeds
/// these yet, so each is one blank ruled page with just the headings; when an
/// API arrives, swap the empty [ListPassbookPageSource] for a real
/// [PassbookPageSource] (it pages as the member turns pages). The book is only
/// built while its tab is selected, so every visit starts with whole pages.
class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return PassbookBookView(
      source: const ListPassbookPageSource([]),
      active: active,
    );
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
