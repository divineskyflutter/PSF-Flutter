import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_header_curve_clipper.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart'
    show AppHeaderIconButton;

/// One "label / value" pair shown in [HomeHeader] — as a text line (member
/// no, mobile) or inside a small tile (fees, loans).
class HeaderInfoLine {
  const HeaderInfoLine(this.label, this.value);

  final String label;

  /// Already formatted; "-" when there is nothing to show.
  final String value;
}

/// The Home tab's header — a pinned [SliverPersistentHeader] that keeps the
/// SAME wavy, gradient look at every height.
///
/// Top bar (always visible): the menu button, then "Welcome" over the
/// member's name right beside it, and the logo at the far right.
///
/// Open: below the top bar, a row with the member no and mobile number
/// ([infoLines]), then the money figures ([statLines]) as wide frosted tiles
/// in two columns — the first half of the list stacked in the left column
/// (fee / niti), the second half stacked in the right column (loans). Every
/// value shrinks to fit its tile, so long amounts never overflow.
///
/// Scrolling shrinks the header: the block under the top bar fades away and
/// only the top bar remains, while the wave along the bottom edge scales down
/// with the height (it never turns into a flat bar).
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
    this.infoLines = const [],
    this.statLines = const [],
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onMenuTap,
  });

  final String greeting;

  final String memberName;

  /// "label: value" items in one row under the top bar (member no, mobile).
  final List<HeaderInfoLine> infoLines;

  /// Tiles under that row: the first half fills the left column, the second
  /// half the right column.
  final List<HeaderInfoLine> statLines;

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
        infoLines: infoLines,
        statLines: statLines,
        notificationCount: notificationCount,
        onNotificationTap: onNotificationTap,
        onMenuTap: onMenuTap,
        topInset: topInset,
        minHeight: topInset + 76.px(context),
        maxHeight: topInset + (statLines.isEmpty ? 136 : 232).px(context),
        unit: 1.px(context),
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HomeHeaderDelegate({
    required this.greeting,
    required this.memberName,
    required this.infoLines,
    required this.statLines,
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
  final List<HeaderInfoLine> infoLines;
  final List<HeaderInfoLine> statLines;
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

  static bool _sameLines(List<HeaderInfoLine> a, List<HeaderInfoLine> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label || a[i].value != b[i].value) return false;
    }
    return true;
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate old) =>
      greeting != old.greeting ||
      memberName != old.memberName ||
      !_sameLines(infoLines, old.infoLines) ||
      !_sameLines(statLines, old.statLines) ||
      notificationCount != old.notificationCount ||
      topInset != old.topInset ||
      minHeight != old.minHeight ||
      maxHeight != old.maxHeight ||
      unit != old.unit;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxHeight - minHeight;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);

    // The block under the top bar fades out over the first ~55% of the collapse.
    final expandedOpacity = (1 - t * 1.8).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _HeaderBackgroundPainter(
          waveScale: 1 - .55 * t,
          glowOpacity: expandedOpacity,
          unit: unit,
        ),
        child: Stack(
          children: [
            // Top bar: menu button, "Welcome" over the name, logo.
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
                  SizedBox(width: 12 * unit),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.82),
                            fontSize: 11.5 * unit,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          memberName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * unit,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * unit),
                  // Notification bell, just left of the logo.
                  if (onNotificationTap != null) ...[
                    AppHeaderIconButton(
                      icon: Icons.notifications_outlined,
                      badgeCount: notificationCount,
                      onTap: onNotificationTap!,
                    ),
                    SizedBox(width: 8 * unit),
                  ],
                  // Logo — a white badge at the far right.
                  Container(
                    width: 40 * unit,
                    height: 40 * unit,
                    padding: EdgeInsets.all(6 * unit),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(AppAssets.logo, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),

            // Open block: member no + mobile, then the tiles.
            if (expandedOpacity > 0)
              Positioned(
                left: 20 * unit,
                right: 20 * unit,
                top: topInset + 72 * unit - 14 * unit * t,
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (infoLines.isNotEmpty)
                        Row(
                          children: [
                            for (var i = 0; i < infoLines.length; i++) ...[
                              if (i > 0) SizedBox(width: 18 * unit),
                              Flexible(child: _InfoLine(line: infoLines[i], unit: unit)),
                            ],
                          ],
                        ),
                      if (statLines.isNotEmpty) ...[
                        SizedBox(height: 14 * unit),
                        _StatTiles(lines: statLines, unit: unit),
                      ],
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

/// "Member No: 5" — muted label, bold value, one line.
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.line, required this.unit});

  final HeaderInfoLine line;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${line.label}: ',
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(
            text: line.value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12.5 * unit),
    );
  }
}

/// The money figures as wide frosted tiles in two columns: the first half of
/// [lines] stacked on the left, the second half stacked on the right. A tile
/// is a tiny label over a bold value; the value shrinks to fit so a long
/// amount never overflows.
class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.lines, required this.unit});

  final List<HeaderInfoLine> lines;
  final double unit;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    final half = (lines.length + 1) ~/ 2;
    final left = lines.sublist(0, half);
    final right = lines.sublist(half);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _TileColumn(lines: left, unit: unit)),
        SizedBox(width: 10 * unit),
        Expanded(child: _TileColumn(lines: right, unit: unit)),
      ],
    );
  }
}

class _TileColumn extends StatelessWidget {
  const _TileColumn({required this.lines, required this.unit});

  final List<HeaderInfoLine> lines;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: 8 * unit),
          _Tile(line: lines[i], unit: unit),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.line, required this.unit});

  final HeaderInfoLine line;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12 * unit, vertical: 7 * unit),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(12 * unit),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(.78),
              fontSize: 10 * unit,
              height: 1.2,
            ),
          ),
          // Shrinks the value to fit the tile instead of overflowing.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              line.value,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * unit,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
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
