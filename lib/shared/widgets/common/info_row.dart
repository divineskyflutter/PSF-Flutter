import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// A small "label above value" pair — reused everywhere a screen needs to
/// show a field (Home's member summary, My Profile, Membership Card, Loan
/// Details) instead of every screen redeclaring the same two `Text`
/// widgets.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;

  final String value;

  final Color? valueColor;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5.px(context),
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.px(context)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5.px(context),
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Same idea, but a full-width row: label on the left, value on the right
/// — used for dense detail lists (My Profile fields, Loan Details rows).
class InfoListTile extends StatelessWidget {
  const InfoListTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
    this.dividerColor,
    this.showDivider = true,
  });

  final String label;

  final String value;

  final Color? valueColor;

  /// Defaults to [AppColors.textSecondary] — pass an explicit light color
  /// (e.g. `Colors.white70`) when this tile sits on a dark card, like My
  /// Profile's profile card.
  final Color? labelColor;

  /// Defaults to [AppColors.border] — same reasoning as [labelColor].
  final Color? dividerColor;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12.px(context)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    color: labelColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 12.px(context)),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.5.px(context),
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: dividerColor ?? AppColors.border),
      ],
    );
  }
}
