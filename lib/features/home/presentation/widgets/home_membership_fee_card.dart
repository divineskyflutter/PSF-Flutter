import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../../../profile/data/models/scheme_reference_model.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

/// Home's membership-fee section, separate from [HomeBalanceCard]: the
/// member's scheme (yojna) name, its total amount and how much of it is paid.
///
///  * Fee fully paid (`isMemberShipFeePaid == true`) → the total is shown as
///    paid, with a "Fully Paid" badge and no pending line.
///  * Otherwise → what has been paid so far (`+`, green) and what is still
///    pending (`−`, red), with a progress bar under the total.
///
/// Always shown; when the login response carried no scheme amount, the name,
/// amounts and progress read "-" instead. Reads [ProfileController.scheme]
/// (filled from the last login), so no network call.
class HomeMembershipFeeCard extends StatelessWidget {
  const HomeMembershipFeeCard({super.key});

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Obx(() {
      // No scheme in the login response yet → every value reads "-".
      final scheme = controller.scheme.value ?? const MembershipSchemeInfo();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.px(context)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18.px(context)),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: _FeeBody(scheme: scheme),
      );
    });
  }
}

class _FeeBody extends StatelessWidget {
  const _FeeBody({required this.scheme});

  final MembershipSchemeInfo scheme;

  @override
  Widget build(BuildContext context) {
    final fmt = HomeMembershipFeeCard._currency;
    final hasAmount = scheme.totalAmount > 0;
    String money(double v, [String sign = '']) => hasAmount ? '$sign${fmt.format(v)}' : '-';
    final paidFraction = !hasAmount
        ? 0.0
        : (scheme.paidAmount / scheme.totalAmount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- title + yojna name -------------------------------------
        Row(
          children: [
            Container(
              width: 42.px(context),
              height: 42.px(context),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primary,
                size: 21.px(context),
              ),
            ),
            SizedBox(width: 12.px(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.membershipFeeTitle.tr,
                    style: TextStyle(
                      fontSize: 12.5.px(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 3.px(context)),
                  Text(
                    scheme.yojnaName ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.px(context),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (hasAmount && scheme.isFullyPaid) const _FullyPaidBadge(),
          ],
        ),

        SizedBox(height: 14.px(context)),

        // ---- total ---------------------------------------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                AppStrings.feeTotal.tr,
                style: TextStyle(
                  fontSize: 13.px(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              money(scheme.totalAmount),
              style: TextStyle(
                fontSize: 20.px(context),
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),

        SizedBox(height: 10.px(context)),

        // ---- progress ------------------------------------------------
        if (hasAmount) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(8.px(context)),
          child: LinearProgressIndicator(
            value: paidFraction,
            minHeight: 8.px(context),
            backgroundColor: scheme.isFullyPaid
                ? AppColors.success.withOpacity(.18)
                : AppColors.danger.withOpacity(.14),
            valueColor: const AlwaysStoppedAnimation(AppColors.success),
          ),
        ),
        ],

        SizedBox(height: 12.px(context)),
        Divider(height: 1, color: AppColors.border),
        SizedBox(height: 12.px(context)),

        // ---- paid / pending -----------------------------------------
        _AmountRow(
          label: AppStrings.feePaid.tr,
          value: money(scheme.paidAmount, '+ '),
          color: hasAmount ? AppColors.success : AppColors.textSecondary,
        ),
        if (hasAmount && scheme.isFullyPaid) ...[
          SizedBox(height: 8.px(context)),
          Text(
            AppStrings.feeFullyPaidNote.tr,
            style: TextStyle(
              fontSize: 12.px(context),
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: AppColors.success,
            ),
          ),
        ] else ...[
          SizedBox(height: 8.px(context)),
          _AmountRow(
            label: AppStrings.feePending.tr,
            value: money(scheme.pendingAmount, '− '),
            color: hasAmount ? AppColors.danger : AppColors.textSecondary,
          ),
        ],
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.px(context),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.px(context),
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FullyPaidBadge extends StatelessWidget {
  const _FullyPaidBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8.px(context)),
      padding: EdgeInsets.symmetric(horizontal: 10.px(context), vertical: 5.px(context)),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(.12),
        borderRadius: BorderRadius.circular(20.px(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14.px(context), color: AppColors.success),
          SizedBox(width: 4.px(context)),
          Text(
            AppStrings.feeFullyPaid.tr,
            style: TextStyle(
              fontSize: 11.5.px(context),
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
