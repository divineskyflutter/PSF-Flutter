import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// Thin rounded progress track used for the membership scheme's
/// paid-vs-total progress on Home, and reusable for any other "% complete"
/// indicator (e.g. a loan's paid installments).
class SchemeProgressBar extends StatelessWidget {
  const SchemeProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.color,
    this.trackColor,
  });

  /// 0.0 - 1.0. Values outside that range are clamped.
  final double progress;

  final double height;

  final Color? color;

  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height.px(context)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: double.infinity,
                height: height.px(context),
                color: trackColor ?? AppColors.primary.withOpacity(.12),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                width: constraints.maxWidth * clamped,
                height: height.px(context),
                decoration: BoxDecoration(
                  color: color,
                  gradient: color == null ? AppColors.buttonGradient : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
