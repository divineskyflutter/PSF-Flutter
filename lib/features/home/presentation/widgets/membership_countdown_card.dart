import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../../../profile/presentation/controllers/profile_controller.dart';

/// How long after joining a membership activates — day 366 is "Active",
/// so the countdown itself covers the 365 days before it.
const _activationWindow = Duration(days: 365);

/// Home's "when do I activate" glance: counts down from the member's own
/// joining date (cached locally at login — see
/// ProfileController.loadProfileFromLocalLogin, no network call needed) to
/// joiningDate + 365 days, then switches to a plain "Active" state once
/// that window has passed. Hidden entirely when there's no joining date yet
/// to count from.
class MembershipCountdownCard extends StatefulWidget {
  const MembershipCountdownCard({super.key});

  @override
  State<MembershipCountdownCard> createState() => _MembershipCountdownCardState();
}

class _MembershipCountdownCardState extends State<MembershipCountdownCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Down to the second now that Seconds is one of the displayed units.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

    return Obx(() {
      final joiningDate = profileController.profile.value?.joiningDate;
      if (joiningDate == null) return const SizedBox.shrink();

      final activatesAt = joiningDate.add(_activationWindow);
      final remaining = activatesAt.difference(DateTime.now());
      // remaining counts DOWN to activation — positive means still
      // counting down, negative/zero means activatesAt has passed.
      final isActive = remaining.isNegative || remaining == Duration.zero;

      final elapsed = DateTime.now().difference(joiningDate);
      final progress = (elapsed.inMinutes / _activationWindow.inMinutes).clamp(0.0, 1.0);

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.px(context)),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(18.px(context)),
          // HomeHeader (the pinned top header) and the banner's own
          // placeholder both paint this exact same gradient, so as this
          // card scrolls up near either of them they read as one fused
          // teal shape with no visible edge. A thin gold outline — the
          // same accent the printed membership card itself trims with —
          // keeps this card visually separate from whatever teal is
          // behind it, scroll position or not.
          border: Border.all(color: AppColors.accentGold.withOpacity(.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30.px(context),
                  height: 30.px(context),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                    color: Colors.white,
                    size: 16.px(context),
                  ),
                ),
                SizedBox(width: 10.px(context)),
                Expanded(
                  child: Text(
                    isActive ? AppStrings.membershipActiveTitle.tr : AppStrings.membershipCountdownTitle.tr,
                    style: TextStyle(
                      fontSize: 13.5.px(context),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.px(context)),
            if (isActive)
              Text(
                AppStrings.membershipActiveSubtitle.tr,
                style: TextStyle(
                  fontSize: 12.px(context),
                  color: Colors.white.withOpacity(.9),
                ),
              )
            else ...[
              // A darker "pill" set against the lighter gradient, holding
              // the four numbers — same layered-card look as the reference
              // countdown designs, in the app's own palette instead of a
              // generic black/white one.
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.px(context)),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(.35),
                  borderRadius: BorderRadius.circular(14.px(context)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _CountdownUnit(value: remaining.inDays, label: AppStrings.daysLabel.tr)),
                    _divider(context),
                    Expanded(child: _CountdownUnit(value: remaining.inHours % 24, label: AppStrings.hoursLabel.tr)),
                    _divider(context),
                    Expanded(
                      child: _CountdownUnit(value: remaining.inMinutes % 60, label: AppStrings.minutesLabel.tr),
                    ),
                    _divider(context),
                    Expanded(
                      child: _CountdownUnit(value: remaining.inSeconds % 60, label: AppStrings.secondsLabel.tr),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.px(context)),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5.px(context),
                  backgroundColor: Colors.white.withOpacity(.25),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accentGold),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 28.px(context), color: Colors.white.withOpacity(.25));
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({required this.value, required this.label});

  final int value;

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 19.px(context),
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        SizedBox(height: 3.px(context)),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.px(context),
            color: Colors.white.withOpacity(.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
