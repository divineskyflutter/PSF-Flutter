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
import '../widgets/home_header.dart';
import '../widgets/member_summary_card.dart';
import '../widgets/payment_reminder_card.dart';

/// Home tab — a Foundation dashboard, not a finance one: the member's
/// membership-scheme progress (via [MemberSummaryCard] /
/// [PaymentReminderCard]), not a raw balance/loan ledger. All of the data
/// on this screen — member name, scheme progress, reminder — comes from
/// the API via [HomeController]; see `features/loans` for the separate,
/// clearly-labelled Loans tab.
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
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  18.px(context),
                  18.px(context),
                  18.px(context),
                  // Clear the bottom bar, which floats over the page.
                  32.px(context) + AppBottomNavBar.occupiedHeight(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SchemeSection(controller: controller, dashboard: dashboard),
                    SizedBox(height: 26.px(context)),
                    _QuickActionsSection(),
                    SizedBox(height: 26.px(context)),
                    const _RecentUpdatesSection(),
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

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions.tr,
          style: TextStyle(
            fontSize: 15.px(context),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 14.px(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionItem(icon: Icons.description_outlined, label: AppStrings.documents.tr),
            _ActionItem(icon: Icons.support_agent_outlined, label: AppStrings.support.tr),
          ],
        ),
      ],
    );
  }
}

/// Placeholder content only — there's no "recent activity" API yet, so
/// this is static dummy data. It exists purely so Home has enough
/// scrollable content to actually show HomeHeader's collapse-on-scroll
/// effect on a normal-height screen; swap it for real data once that
/// endpoint exists.
class _RecentUpdatesSection extends StatelessWidget {
  const _RecentUpdatesSection();

  static const _items = [
    _DummyUpdate(
      icon: Icons.campaign_outlined,
      title: 'Scheme update available',
      subtitle: 'New scheme details have been published.',
    ),
    _DummyUpdate(
      icon: Icons.receipt_long_outlined,
      title: 'Payment received',
      subtitle: 'Your last instalment was recorded successfully.',
    ),
    _DummyUpdate(
      icon: Icons.event_available_outlined,
      title: 'Upcoming due date',
      subtitle: 'Keep an eye on your next payment date.',
    ),
    _DummyUpdate(
      icon: Icons.badge_outlined,
      title: 'Profile reminder',
      subtitle: 'Keep your mobile number up to date.',
    ),
    _DummyUpdate(
      icon: Icons.support_agent_outlined,
      title: 'Need help?',
      subtitle: 'Reach out any time from the Support option.',
    ),
    _DummyUpdate(
      icon: Icons.verified_outlined,
      title: 'Membership active',
      subtitle: 'Your Parivar Suraksha membership is active.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentUpdates.tr,
          style: TextStyle(
            fontSize: 15.px(context),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 14.px(context)),
        for (final item in _items) ...[
          _UpdateTile(item: item),
          SizedBox(height: 10.px(context)),
        ],
      ],
    );
  }
}

class _DummyUpdate {
  const _DummyUpdate({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;

  final String title;

  final String subtitle;
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.item});

  final _DummyUpdate item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.px(context)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40.px(context),
            height: 40.px(context),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 20.px(context)),
          ),
          SizedBox(width: 12.px(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.px(context)),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.px(context),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label});

  final IconData icon;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.px(context)),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.px(context)),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 26.px(context)),
        ),
        SizedBox(height: 8.px(context)),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.px(context),
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
