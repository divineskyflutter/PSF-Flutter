import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_home_sliver_header.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../controllers/home_controller.dart';
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

        return AppRefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              AppHomeSliverHeader(
                greeting: AppStrings.welcomeBack.tr,
                memberName: (dashboard?.memberName.isNotEmpty ?? false)
                    ? dashboard!.memberName
                    : AppStrings.appName.tr,
                memberIdLabel: dashboard != null
                    ? '${AppStrings.memberId.tr}: ${dashboard.memberIdLabel}'
                    : '',
                collapsedTitle: AppStrings.navHome.tr,
                notificationCount: dashboard?.unreadNotificationCount ?? 0,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18.px(context),
                    18.px(context),
                    18.px(context),
                    32.px(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SchemeSection(controller: controller, dashboard: dashboard),
                      SizedBox(height: 26.px(context)),
                      _QuickActionsSection(),
                    ],
                  ),
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
