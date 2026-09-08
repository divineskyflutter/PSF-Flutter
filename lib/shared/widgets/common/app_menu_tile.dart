import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// One row in a settings/menu-style list — used by the Profile screen for
/// Profile / Membership Card / Passbook / Language / About Us / Terms &
/// Conditions / Privacy Policy / Contact Us / Logout / Delete Account, and
/// reusable anywhere else a similar "icon + label + chevron" row is
/// needed.
class AppMenuTile extends StatelessWidget {
  const AppMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconBackgroundColor,
    this.iconColor,
    this.labelColor,
    this.trailing,
    this.showDivider = true,
  });

  final IconData icon;

  final String label;

  final VoidCallback? onTap;

  final Color? iconBackgroundColor;

  final Color? iconColor;

  final Color? labelColor;

  /// Defaults to a chevron. Pass `const SizedBox.shrink()` to hide it.
  final Widget? trailing;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 18.px(context),
                vertical: 14.px(context),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38.px(context),
                    height: 38.px(context),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor ?? AppColors.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(11.px(context)),
                    ),
                    child: Icon(
                      icon,
                      size: 19.px(context),
                      color: iconColor ?? AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 14.px(context)),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5.px(context),
                        fontWeight: FontWeight.w600,
                        color: labelColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary.withOpacity(.6),
                        size: 22.px(context),
                      ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 70.px(context)),
            child: const Divider(height: 1, color: AppColors.border),
          ),
      ],
    );
  }
}
