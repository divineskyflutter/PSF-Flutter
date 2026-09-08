import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';

/// A small centered decorative section-break: a diamond glyph flanked by
/// two short lines that fade out toward the edges. Used wherever a plain
/// [Divider] would feel too heavy — e.g. below the tagline on the splash
/// screen (between "FOUNDATION" and the CIN/PAN/License block) and on
/// each onboarding slide (between the illustration and its title).
class OrnamentalDivider extends StatelessWidget {
  const OrnamentalDivider({
    super.key,
    this.color,
    this.lineLength = 34,
    this.spacing = 8,
    this.iconSize = 12,
  });

  /// Defaults to [AppColors.primary] when not given.
  final Color? color;

  /// Width of each fading line segment on either side of the icon.
  final double lineLength;

  /// Gap between the icon and each line.
  final double spacing;

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FadingLine(color: dividerColor, length: lineLength, reversed: true),
        SizedBox(width: spacing),
        Icon(
          Icons.diamond_outlined,
          size: iconSize,
          color: dividerColor.withOpacity(0.75),
        ),
        SizedBox(width: spacing),
        _FadingLine(color: dividerColor, length: lineLength),
      ],
    );
  }
}

class _FadingLine extends StatelessWidget {
  const _FadingLine({
    required this.color,
    required this.length,
    this.reversed = false,
  });

  final Color color;
  final double length;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: length,
      height: 1.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: reversed ? Alignment.centerRight : Alignment.centerLeft,
          end: reversed ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            color.withOpacity(0.0),
            color.withOpacity(0.55),
          ],
        ),
      ),
    );
  }
}
