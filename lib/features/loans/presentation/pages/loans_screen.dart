import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../../domain/entities/loan_entity.dart';
import '../controllers/loans_controller.dart';

/// Loans tab root — foreclosure amount, loan amount, current due amount
/// and pending instalments for the member's active loan, all from the
/// API via [LoansController]. A separate, clearly-labelled feature from
/// the Home tab's membership-scheme summary.
class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoansController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(
        title: AppStrings.loanDetails.tr,
        showBackButton: false,
      ),
      body: Obx(() {
        final loan = controller.loan.value;

        return AppRefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(18.px(context)),
            child: _buildBody(context, controller, loan),
          ),
        );
      }),
    );
  }

  Widget _buildBody(BuildContext context, LoansController controller, LoanEntity? loan) {
    if (controller.isLoading.value && !controller.hasFetchedOnce.value) {
      return const AppStateView.loading();
    }

    if (controller.hasError.value && loan == null) {
      return AppStateView.error(
        message: controller.errorMessage.value.isEmpty
            ? AppStrings.somethingWentWrong.tr
            : controller.errorMessage.value,
        onRetry: controller.fetchLoanDetails,
      );
    }

    if (loan == null || !loan.hasActiveLoan) {
      return AppStateView.empty(message: AppStrings.noActiveLoanMessage.tr);
    }

    return _LoanDetailsCard(loan: loan);
  }
}

class _LoanDetailsCard extends StatelessWidget {
  const _LoanDetailsCard({required this.loan});

  final LoanEntity loan;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.px(context)),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20.px(context)),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            children: [
              if (loan.upcomingDate != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.px(context),
                    vertical: 8.px(context),
                  ),
                  margin: EdgeInsets.only(bottom: 18.px(context)),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12.px(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_outlined, size: 15.px(context), color: AppColors.warning),
                      SizedBox(width: 8.px(context)),
                      Text(
                        '${AppStrings.upcomingOn.tr} ${DateFormat('dd MMM yyyy').format(loan.upcomingDate!)}',
                        style: TextStyle(
                          fontSize: 12.px(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                width: 68.px(context),
                height: 68.px(context),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.currency_rupee_rounded,
                  color: AppColors.primary,
                  size: 32.px(context),
                ),
              ),
              SizedBox(height: 12.px(context)),
              Text(
                AppStrings.foreclosureAmount.tr,
                style: TextStyle(fontSize: 12.px(context), color: AppColors.textSecondary),
              ),
              SizedBox(height: 4.px(context)),
              Text(
                currency.format(loan.foreclosureAmount),
                style: TextStyle(
                  fontSize: 24.px(context),
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.px(context)),
              const Divider(height: 1, color: AppColors.border),
              InfoListTile(label: AppStrings.loanAmount.tr, value: currency.format(loan.loanAmount)),
              InfoListTile(
                label: AppStrings.currentDueAmount.tr,
                value: currency.format(loan.currentDueAmount),
                valueColor: AppColors.danger,
              ),
              InfoListTile(
                label: AppStrings.pendingInstallments.tr,
                value: '${loan.pendingInstallments} ${loan.totalInstallments > 0 ? "of ${loan.totalInstallments}" : ""}',
              ),
              InfoListTile(label: AppStrings.loanId.tr, value: loan.loanId, showDivider: false),
            ],
          ),
        ),
        SizedBox(height: 18.px(context)),
        AppButton.outlined(
          label: AppStrings.viewInstalmentDetails.tr,
          onPressed: () => Get.toNamed(AppRoutes.loanInstallments),
          trailing: Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20.px(context)),
        ),
      ],
    );
  }
}
