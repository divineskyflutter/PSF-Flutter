import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// The wallet's rear panel — a slightly wider, darker leather-look shape
/// standing behind the card, so the card reads as sitting *inside* the
/// wallet. Only its side edges and top lip are visible around the card.
class WalletBack extends StatelessWidget {
  const WalletBack({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.px(context)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F6F68), AppColors.primaryDark],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The wallet's front pocket, covering ~90% of the card: teal gradient,
/// stitched border, a gold clasp line and the member's QR code. [qrView] is supplied by the caller, so this widget
/// knows nothing about loading the QR. Sizes come from `.px(context)` and
/// the pocket's own height, so it holds up on any screen.
class WalletPocket extends StatelessWidget {
  const WalletPocket({super.key, required this.qrView, this.shape, this.border});

  final Widget qrView;

  /// Corner shape; defaults to the vertical pocket (big radius on top).
  final BorderRadius? shape;

  /// Trim line on the pocket's opening edge; defaults to gold along the top
  /// (the horizontal wallet passes one along its right edge instead).
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final topRadius = Radius.circular(38.px(context));
    final bottomRadius = Radius.circular(30.px(context));
    final shape = this.shape ??
        BorderRadius.only(
          topLeft: topRadius,
          topRight: topRadius,
          bottomLeft: bottomRadius,
          bottomRight: bottomRadius,
        );

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final qrSize = math.min(h * .42, w * .52);

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, Color(0xFF2E9A8E), AppColors.primaryLight],
              ),
              border: border ??
                  Border(
                    top: BorderSide(color: AppColors.accentGold.withOpacity(.85), width: 1.6),
                  ),
            ),
            child: ClipRRect(
              borderRadius: shape,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _PocketPatternPainter())),
                  Padding(
                    padding: EdgeInsets.all(10.px(context)),
                    child: CustomPaint(
                      painter: _StitchPainter(radius: 28.px(context)),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: qrSize, height: qrSize, child: qrView),
                        SizedBox(height: 12.px(context)),
                        Text(
                          'scan_qr'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(.95),
                            fontSize: 13.px(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PocketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white.withOpacity(.05);
    canvas.drawCircle(Offset(size.width * .95, 0), size.width * .5, fill);
    canvas.drawCircle(Offset(0, size.height), size.width * .45, fill);

    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(.14), Colors.white.withOpacity(0)],
        stops: const [0, .5],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sheen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StitchPainter extends CustomPainter {
  _StitchPainter({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));

    final paint = Paint()
      ..color = const Color(0xFF0B322F).withOpacity(.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    const dash = 8.0;
    const gap = 5.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + dash, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StitchPainter oldDelegate) => oldDelegate.radius != radius;
}

/// A soft diagonal band of light that sweeps across the wallet cover every
/// few seconds while it is closed, so the cover feels like glossy leather.
/// Lives in its own repaint layer above the cover, so animating it never
/// re-rasterizes the cover (QR code, stitching) underneath. [animation] runs
/// 0 -> 1 per cycle; the band crosses during the first part and rests.
class WalletShine extends StatelessWidget {
  const WalletShine({super.key, required this.animation, required this.shape});

  final Animation<double> animation;

  final BorderRadius shape;

  static const double _sweepShare = .34;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: shape,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final bandWidth = width * .34;

              return AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  if (animation.value > _sweepShare) return const SizedBox.expand();

                  final t = Curves.easeInOut.transform(animation.value / _sweepShare);
                  final dx = -bandWidth * 1.4 + t * (width + bandWidth * 2.2);

                  // A second, thinner golden streak trails slightly behind
                  // the main white one — two-tone instead of a single flat
                  // sweep, like light catching an embossed edge a beat
                  // after the main glare passes.
                  final goldT = ((animation.value - .05) / _sweepShare).clamp(0.0, 1.0);
                  final goldWidth = bandWidth * .4;
                  final goldDx = -goldWidth * 1.4 + Curves.easeInOut.transform(goldT) * (width + goldWidth * 2.2);

                  return Stack(
                    children: [
                      Positioned(
                        left: dx,
                        top: -10,
                        bottom: -10,
                        width: bandWidth,
                        child: Transform(
                          transform: Matrix4.skewX(-.34),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0x00FFFFFF), Color(0x38FFFFFF), Color(0x00FFFFFF)],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (goldT > 0 && goldT < 1)
                        Positioned(
                          left: goldDx,
                          top: -10,
                          bottom: -10,
                          width: goldWidth,
                          child: Transform(
                            transform: Matrix4.skewX(-.34),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0x00E3C16F), Color(0x55E3C16F), Color(0x00E3C16F)],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A soft shadow that trails the wallet cover as it peels away — like a
/// sticker or a sheet of paper being lifted off the card underneath it,
/// rather than the cover simply vanishing. Thickest while the cover is
/// closed, it thins to nothing as the cover finishes opening.
///
/// [axis] matches the cover's own travel: horizontal for the landscape
/// wallet (the cover peels to the left), vertical for the portrait one
/// (the cover peels upward).
class CardRevealShadow extends StatelessWidget {
  const CardRevealShadow({super.key, required this.animation, this.axis = Axis.horizontal});

  /// 0 (cover fully closed) -> 1 (cover fully open) — typically the same
  /// curved animation driving the cover itself.
  final Animation<double> animation;

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value.clamp(0.0, 1.0);
            if (t >= 1) return const SizedBox.shrink();

            final begin = axis == Axis.horizontal ? Alignment.centerLeft : Alignment.topCenter;
            final end = axis == Axis.horizontal ? Alignment.centerRight : Alignment.bottomCenter;

            return FractionallySizedBox(
              alignment: begin,
              widthFactor: axis == Axis.horizontal ? (1 - t) : 1,
              heightFactor: axis == Axis.vertical ? (1 - t) : 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: begin,
                    end: end,
                    colors: [
                      Colors.black.withOpacity(.24 * (1 - t)),
                      Colors.black.withOpacity(0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
