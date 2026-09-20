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
/// stitched border, a gold clasp line, the member's QR code and a
/// "tap to open" pill. [qrView] is supplied by the caller, so this widget
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
                        SizedBox(height: 16.px(context)),
                        Container(
                          constraints: BoxConstraints(maxWidth: w - 44.px(context)),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.px(context),
                            vertical: 9.px(context),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.16),
                            borderRadius: BorderRadius.circular(30.px(context)),
                            border: Border.all(
                              color: AppColors.accentGold.withOpacity(.9),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_open_rounded,
                                color: AppColors.accentGold,
                                size: 16.px(context),
                              ),
                              SizedBox(width: 7.px(context)),
                              Flexible(
                                child: Text(
                                  'tap_to_open_card'.tr,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5.px(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
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
