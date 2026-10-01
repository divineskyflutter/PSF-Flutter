import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/loaders/app_shimmer.dart';

import '../../../profile/presentation/controllers/profile_controller.dart';

/// Home's "what's my balance right now" glance — the most recent entry's
/// running balance from the member's own Passbook
/// (ProfileController.passbook/fetchPassbook, the same data
/// PassbookPage itself shows), or ₹0 while there's no passbook history yet
/// (there's no real transaction history behind this today — once there is,
/// this reads it the same way). This card only ever shows that single
/// current number, not a ledger. Tapping through to the full Passbook is
/// disabled for now — PassbookPage itself currently crashes on open
/// (`setState() called during build`, unrelated to this card) — re-enable
/// the `onTap` below once that's fixed.
class HomeBalanceCard extends StatefulWidget {
  const HomeBalanceCard({super.key});

  @override
  State<HomeBalanceCard> createState() => _HomeBalanceCardState();
}

class _HomeBalanceCardState extends State<HomeBalanceCard> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ProfileController>();
    // Same "fetch once, reuse everywhere" guard PassbookPage itself uses.
    if (_controller.passbook.isEmpty && !_controller.isPassbookLoading.value) {
      _controller.fetchPassbook();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = _controller.isPassbookLoading.value;
      final entries = _controller.passbook;

      // Always shown — there's no real passbook-transaction history behind
      // this yet (see this card's own doc comment), so a brand-new/no-data
      // member just reads ₹0 here instead of the card disappearing or
      // showing an unrelated "no active scheme" message; once there's real
      // history, [balance] below naturally takes over.
      double balance = 0;
      if (entries.isNotEmpty) {
        // The API gives no ordering guarantee, so pick the entry with the
        // latest date rather than assuming the list is already sorted.
        final latest = entries.reduce((a, b) {
          if (a.date == null) return b;
          if (b.date == null) return a;
          return a.date!.isAfter(b.date!) ? a : b;
        });
        balance = latest.balanceAmount;
      }

      // Only while the very first fetch is still in flight (and nothing to
      // show yet) does the number itself shimmer-placeholder — a retry
      // failure still resolves to the ₹0 fallback above, not a stuck
      // loader.
      final showShimmer = isLoading && entries.isEmpty;

      final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

      return InkWell(
        borderRadius: BorderRadius.circular(18.px(context)),
        onTap: null,
        child: Container(
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
          child: Row(
            children: [
              Container(
                width: 42.px(context),
                height: 42.px(context),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 20.px(context),
                ),
              ),
              SizedBox(width: 12.px(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.currentBalance.tr,
                      style: TextStyle(
                        fontSize: 12.5.px(context),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.px(context)),
                    if (showShimmer)
                      AppShimmer(
                        child: Container(
                          width: 90.px(context),
                          height: 18.px(context),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    else
                      Text(
                        currency.format(balance),
                        style: TextStyle(
                          fontSize: 17.px(context),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary.withOpacity(.6),
              ),
            ],
          ),
        ),
      );
    });
  }
}
