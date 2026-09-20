import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import 'app_header_curve_clipper.dart';

/// Branded curved-gradient header used in place of the default [AppBar] on
/// every secondary/inner screen (Profile menu, Passbook, About Us, Contact
/// Us, Loans, Delete Account, ...).
///
/// Same gradient + curve + font language as [AppHomeSliverHeader] and the
/// auth screens' header, just sized as a fixed, non-collapsing app bar —
/// this is the "one appbar header" pattern the rest of the app should
/// reuse instead of every screen rolling its own [AppBar].
class AppSubPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppSubPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
    this.showBackButton = true,
    this.height = 104,
  });

  final String title;

  final String? subtitle;

  final VoidCallback? onBack;

  /// Trailing icon buttons (e.g. a share/export icon on Passbook). Use
  /// [AppHeaderIconButton] so they match the back button's styling.
  final List<Widget>? actions;

  final bool showBackButton;

  /// Height of the visible header area BELOW the status bar / camera
  /// cutout — the status-bar inset is added on top of this (see
  /// [preferredSize]), so the header keeps the same comfortable size on
  /// every device instead of shrinking on phones with a tall notch.
  final double height;

  /// Total header height with the default [height] — what a screen that
  /// lets its content scroll UNDER the header (`extendBodyBehindAppBar`)
  /// adds as top padding so the content starts just below it.
  static double totalHeight({double height = 104}) => _statusBarHeight() + height;

  static double _statusBarHeight() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.padding.top / view.devicePixelRatio;
  }

  @override
  Size get preferredSize => Size.fromHeight(_statusBarHeight() + height);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const AppHeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        height: preferredSize.height,
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            // Keeps the title/back button clear of the curved bottom edge
            // (the clip dips ~45px at the left), so they sit visually
            // centered in the solid part of the header.
            padding: EdgeInsets.only(bottom: 22.px(context)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 64.px(context)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.px(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.px(context)),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.85),
                            fontSize: 12.px(context),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showBackButton)
                  Positioned(
                    left: 6.px(context),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onBack ?? () => Get.back(),
                      child: SizedBox(
                        width: 48.px(context),
                        height: 48.px(context),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22.px(context),
                        ),
                      ),
                    ),
                  ),
                if (actions != null && actions!.isNotEmpty)
                  Positioned(
                    right: 12.px(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small translucent-circle icon button used on top of the gradient header
/// (back button, notification bell, share/export action, ...).
class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badgeCount,
    this.size = 40,
  });

  final IconData icon;

  final VoidCallback onTap;

  /// When set and > 0, a small red badge is drawn on the top-right corner
  /// (e.g. unread notification count on the Home header bell).
  final int? badgeCount;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.16),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size.px(context),
          height: size.px(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: (size * 0.5).px(context),
                ),
              ),
              if ((badgeCount ?? 0) > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                    child: Text(
                      badgeCount! > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
