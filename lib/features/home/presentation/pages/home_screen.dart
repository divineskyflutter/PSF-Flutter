import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/features/navigation/presentation/widgets/app_bottom_nav_bar.dart';

import '../controllers/home_controller.dart';
import '../widgets/home_balance_card.dart';
import '../widgets/home_banner_slider.dart';
import '../widgets/home_header.dart';
import '../widgets/member_summary_card.dart';
import '../widgets/membership_countdown_card.dart';
import '../widgets/payment_reminder_card.dart';

/// Home tab — a Foundation dashboard: the member's own banner
/// ([HomeBannerSlider]), membership-activation countdown
/// ([MembershipCountdownCard]), current passbook balance at a glance
/// ([HomeBalanceCard]), and membership-scheme progress (via
/// [MemberSummaryCard] / [PaymentReminderCard]) — not a raw ledger, which
/// still lives in Passbook/Loans. [HomeController] itself only drives the
/// scheme-progress section; the other cards each read from their own
/// controller (banner, profile/passbook), see each widget's doc comment.
/// See `features/loans` for the separate, clearly-labelled Loans tab.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final dashboard = controller.dashboard.value;

        // HomeHeader is itself a SliverAppBar — it collapses down to a
        // normal app-bar height as this CustomScrollView scrolls, instead
        // of sitting fixed above it. See HomeHeader's doc comment.
        return AppRefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              HomeHeader(
                greeting: AppStrings.welcomeBack.tr,
                memberName: (dashboard?.memberName.isNotEmpty ?? false)
                    ? dashboard!.memberName
                    : AppStrings.appName.tr,
                memberIdLabel: dashboard != null
                    ? '${AppStrings.memberId.tr}: ${dashboard.memberIdLabel}'
                    : '',
                notificationCount: dashboard?.unreadNotificationCount ?? 0,
                onMenuTap: Get.find<MainNavigationController>().openDrawer,
              ),
              // Its own sliver, outside the padded content below — so it
              // can use its own horizontalPadding (matching
              // AuthChoiceScreen's slider exactly) instead of relying on
              // this screen's own padding. With 0 there, adjacent slides
              // had no gap between them specifically while mid-swipe (each
              // slide is padded individually inside the PageView, so that
              // padding is what separates one slide from the next as they
              // slide past each other, not just what margins the resting
              // slide), which read as the banners being stuck together
              // while scrolling.
              SliverPadding(
                padding: EdgeInsets.only(top: 18.px(context)),
                sliver: const SliverToBoxAdapter(child: HomeBannerSlider()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  18.px(context),
                  20.px(context),
                  18.px(context),
                  // Clear the bottom bar, which floats over the page.
                  32.px(context) + AppBottomNavBar.occupiedHeight(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const MembershipCountdownCard(),
                    SizedBox(height: 16.px(context)),
                    const HomeBalanceCard(),
                    SizedBox(height: 20.px(context)),
                    _SchemeSection(controller: controller, dashboard: dashboard),
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SchemeSection extends StatelessWidget {
  const _SchemeSection({required this.controller, required this.dashboard});

  final HomeController controller;

  final dynamic dashboard;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading.value && dashboard == null) {
      return const AppStateView.loading();
    }

    if (controller.hasError.value && dashboard == null) {
      return AppStateView.error(
        message: controller.errorMessage.value.isEmpty
            ? AppStrings.somethingWentWrong.tr
            : controller.errorMessage.value,
        onRetry: controller.fetchDashboard,
      );
    }

    if (dashboard == null || dashboard.hasActiveScheme != true) {
      return AppStateView.empty(message: AppStrings.noActiveSchemeMessage.tr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemberSummaryCard(dashboard: dashboard),
        if (dashboard.remainingAmount > 0) ...[
          SizedBox(height: 16.px(context)),
          PaymentReminderCard(dashboard: dashboard),
        ],
      ],
    );
  }
}

