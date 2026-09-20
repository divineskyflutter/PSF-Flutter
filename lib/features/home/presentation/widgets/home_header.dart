import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_header_curve_clipper.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart'
    show AppHeaderIconButton;

/// The Home tab's header — a pinned [SliverPersistentHeader] that keeps the
/// SAME wavy, gradient look at every height. Scrolling the dashboard only
/// shrinks it: the logo/greeting/name/member-id block fades away and the
/// member's name fades in centered between the menu and notification
/// buttons, while the wave along the bottom edge scales down with the
/// height (it never turns into a flat bar).
///
/// The background (gradient + wave + soft glows) is ONE painted shape
/// ([_HeaderBackgroundPainter]) inside its own repaint boundary — not a
/// clipped stack of widgets — so scrolling only repaints a single path
/// fill instead of re-clipping and re-compositing the whole header every
/// frame, which is what made it look choppy.
///
/// Drop this straight into a [CustomScrollView]'s `slivers` list — this
/// widget **is** the sliver, not a plain box.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.memberName,
    required this.memberIdLabel,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onMenuTap,
  });

  final String greeting;

  final String memberName;

  final String memberIdLabel;

  final int notificationCount;

  final VoidCallback? onNotificationTap;

  /// Opens the side drawer (also reachable by swiping from the left edge).
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        greeting: greeting,
        memberName: memberName,
        memberIdLabel: memberIdLabel,
        notificationCount: notificationCount,
        onNotificationTap: onNotificationTap,
        onMenuTap: onMenuTap,
        topInset: topInset,
        minHeight: topInset + 76.px(context),
        maxHeight: topInset + 184.px(context),
        unit: 1.px(context),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.greeting,
    required this.memberName,
    required this.memberIdLabel,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onMenuTap,
    required this.topInset,
    required this.minHeight,
    required this.maxHeight,
    required this.unit,
  });

  final String greeting;
  final String memberName;
  final String memberIdLabel;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final double topInset;
  final double minHeight;
  final double maxHeight;

  /// `1.px(context)` — the screen's scale factor, so sizes here follow the
  /// same responsive scaling as everywhere else without needing a context
  /// inside the delegate.
  final double unit;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate old) =>
      greeting != old.greeting ||
      memberName != old.memberName ||
      memberIdLabel != old.memberIdLabel ||
      notificationCount != old.notificationCount ||
      topInset != old.topInset ||
      minHeight != old.minHeight ||
      maxHeight != old.maxHeight ||
      unit != old.unit;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxHeight - minHeight;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // Big block fades out over the first ~55% of the collapse; the centered
    // name fades in over the last ~45%.
    final expandedOpacity = (1 - t * 1.8).clamp(0.0, 1.0);
    final titleOpacity = ((t - .55) / .45).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _HeaderBackgroundPainter(
          waveScale: 1 - .55 * t,
          glowOpacity: expandedOpacity,
          unit: unit,
        ),
        child: Stack(
          children: [
            // Menu + notifications, always in the same spot.
            Positioned(
              left: 14 * unit,
              right: 14 * unit,
              top: topInset + 8 * unit,
              height: 44 * unit,
              child: Row(
                children: [
                  if (onMenuTap != null)
                    AppHeaderIconButton(icon: Icons.menu_rounded, onTap: onMenuTap!)
                  else
                    SizedBox(width: 40 * unit),
                  Expanded(
                    child: titleOpacity <= 0
                        ? const SizedBox.shrink()
                        : Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8 * unit),
                              child: Text(
                                memberName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(titleOpacity),
                                  fontSize: 17 * unit,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                  ),
                  AppHeaderIconButton(
                    icon: Icons.notifications_outlined,
                    badgeCount: notificationCount,
                    onTap: onNotificationTap ?? () {},
                  ),
                ],
              ),
            ),

            // Logo + greeting + name + member id (only while it can be seen).
            if (expandedOpacity > 0)
              Positioned(
                left: 22 * unit,
                right: 22 * unit,
                top: topInset + 62 * unit - 18 * unit * t,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Row(
                    children: [
                      Container(
                        width: 54 * unit,
                        height: 54 * unit,
                        padding: EdgeInsets.all(8 * unit),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SvgPicture.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 14 * unit),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(.85),
                                fontSize: 12 * unit,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 2 * unit),
                            Text(
                              memberName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18 * unit,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (memberIdLabel.isNotEmpty) ...[
                              SizedBox(height: 2 * unit),
                              Text(
                                memberIdLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.75),
                                  fontSize: 11.5 * unit,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paints the whole header background in one pass: the gradient filling the
/// wavy shape, then two soft glows clipped to that same shape.
class _HeaderBackgroundPainter extends CustomPainter {
  _HeaderBackgroundPainter({
    required this.waveScale,
    required this.glowOpacity,
    required this.unit,
  });

  final double waveScale;
  final double glowOpacity;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final path = AppHeaderCurveClipper(waveScale: waveScale).getClip(size);

    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = true
        ..shader = AppColors.headerGradient.createShader(Offset.zero & size),
    );

    if (glowOpacity <= 0) return;

    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      Offset(size.width + 24 * unit - 65 * unit, -30 * unit + 65 * unit),
      65 * unit,
      Paint()..color = Colors.white.withOpacity(.08 * glowOpacity),
    );
    canvas.drawCircle(
      Offset(-26 * unit + 55 * unit, size.height + 6 * unit - 55 * unit),
      55 * unit,
      Paint()..color = AppColors.primaryLight.withOpacity(.22 * glowOpacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeaderBackgroundPainter old) =>
      old.waveScale != waveScale || old.glowOpacity != glowOpacity || old.unit != unit;
}
