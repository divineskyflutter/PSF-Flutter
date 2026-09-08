import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';
import 'package:psf_application/shared/widgets/common/scheme_progress_bar.dart';

import '../../domain/entities/member_dashboard_entity.dart';

/// The Home tab's primary card — the member's membership-scheme progress
/// (scheme name, total/paid/remaining amount, due date, % completed).
class MemberSummaryCard extends StatelessWidget {
  const MemberSummaryCard({super.key, required this.dashboard});

  final MemberDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.memberSummary.tr,
                  style: TextStyle(
                    fontSize: 15.5.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.passbook),
                child: Text(
                  AppStrings.viewAll.tr,
                  style: TextStyle(
                    fontSize: 12.5.px(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.px(context)),
          InfoRow(label: AppStrings.schemeName.tr, value: dashboard.schemeName),
          SizedBox(height: 14.px(context)),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  label: AppStrings.totalAmount.tr,
                  value: currency.format(dashboard.totalAmount),
                ),
              ),
              Expanded(
                child: InfoRow(
                  label: AppStrings.paidAmount.tr,
                  value: currency.format(dashboard.paidAmount),
                  valueColor: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.px(context)),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  label: AppStrings.remainingAmount.tr,
                  value: currency.format(dashboard.remainingAmount),
                  valueColor: AppColors.danger,
                ),
              ),
              Expanded(
                child: InfoRow(
                  label: AppStrings.dueDate.tr,
                  value: dashboard.dueDate != null
                      ? DateFormat('dd MMM yyyy').format(dashboard.dueDate!)
                      : '-',
                ),
              ),
            ],
          ),
          SizedBox(height: 16.px(context)),
          SchemeProgressBar(progress: dashboard.progress),
          SizedBox(height: 8.px(context)),
          Text(
            '${(dashboard.progress * 100).round()}% ${AppStrings.percentCompleted.tr}',
            style: TextStyle(
              fontSize: 11.5.px(context),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
