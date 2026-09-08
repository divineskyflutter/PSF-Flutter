import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../../domain/entities/member_dashboard_entity.dart';

/// Small reminder banner shown under the member summary card whenever an
/// amount is still due on the scheme.
class PaymentReminderCard extends StatelessWidget {
  const PaymentReminderCard({super.key, required this.dashboard});

  final MemberDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.px(context)),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(.10),
        borderRadius: BorderRadius.circular(18.px(context)),
        border: Border.all(color: AppColors.warning.withOpacity(.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42.px(context),
            height: 42.px(context),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: AppColors.warning,
              size: 21.px(context),
            ),
          ),
          SizedBox(width: 14.px(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.paymentReminder.tr,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.px(context)),
                Text(
                  '${AppStrings.remainingAmount.tr}: ${currency.format(dashboard.remainingAmount)}',
                  style: TextStyle(
                    fontSize: 12.px(context),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (dashboard.dueDate != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppStrings.dueDate.tr,
                  style: TextStyle(fontSize: 10.5.px(context), color: AppColors.textSecondary),
                ),
                SizedBox(height: 2.px(context)),
                Text(
                  DateFormat('dd MMM yyyy').format(dashboard.dueDate!),
                  style: TextStyle(
                    fontSize: 12.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
