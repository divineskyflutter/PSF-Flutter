import 'package:flutter/material.dart';
import 'package:psf_application/app/constants/app_colors.dart';

/// Common highly customizable button for the entire application.
///
/// Examples:
///
/// AppButton(
///   label: 'Continue',
///   onPressed: () {},
/// )
///
/// AppButton.circle(
///   label: 'Continue',
///   onPressed: () {},
/// )
///
/// AppButton.rectangular(
///   label: 'Submit',
///   onPressed: () {},
/// )
///
/// AppButton.outlined(
///   label: 'Cancel',
///   onPressed: () {},
/// )
class AppButton extends StatelessWidget {
// ===========================================================================
// DEFAULT BUTTON
// ===========================================================================

  const AppButton({
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.gradient,
    this.borderRadius = 32,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.padding,
    this.leading,
    this.trailing,
    this.alignment = Alignment.center,
    this.splashColor,
    this.onLongPress,
    this.showShadow = true,
    super.key,
  });

// ===========================================================================
// CIRCLE / PILL BUTTON
// ===========================================================================

  const AppButton.circle({
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.gradient,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.padding,
    this.leading,
    this.trailing,
    this.alignment = Alignment.center,
    this.splashColor,
    this.onLongPress,
    this.showShadow = true,
    super.key,
  }) : borderRadius = 1000;

// ===========================================================================
// RECTANGULAR BUTTON
// ===========================================================================

  const AppButton.rectangular({
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.gradient,
    this.borderRadius = 12,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.padding,
    this.leading,
    this.trailing,
    this.alignment = Alignment.center,
    this.splashColor,
    this.onLongPress,
    this.showShadow = true,
    super.key,
  });

// ===========================================================================
// OUTLINED BUTTON
// ===========================================================================

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor = Colors.transparent,
    this.foregroundColor,
    this.gradient,
    this.borderRadius = 32,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.padding,
    this.leading,
    this.trailing,
    this.alignment = Alignment.center,
    this.splashColor,
    this.onLongPress,
    this.showShadow = false,
    super.key,
  });

// ===========================================================================
// ICON BUTTON
// ===========================================================================

  const AppButton.icon({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.gradient,
    this.borderRadius = 32,
    this.border,
    this.boxShadow,
    this.textStyle,
    this.padding,
    this.alignment = Alignment.center,
    this.splashColor,
    this.onLongPress,
    this.showShadow = true,
    super.key,
  });

// ===========================================================================
// PROPERTIES
// ===========================================================================

  final String label;

  final VoidCallback? onPressed;

  final VoidCallback? onLongPress;

  final double? width;

  final double height;

  /// Solid background color.
  ///
  /// If [gradient] is provided, gradient takes priority.
  final Color? backgroundColor;

  /// Text and icon color.
  final Color? foregroundColor;

  /// Custom gradient.
  ///
  /// If null, [AppColors.buttonGradient] is used automatically.
  final Gradient? gradient;

  final double borderRadius;

  final BorderSide? border;

  final List<BoxShadow>? boxShadow;

  final TextStyle? textStyle;

  final EdgeInsetsGeometry? padding;

  final Widget? leading;

  final Widget? trailing;

  final AlignmentGeometry alignment;

  final Color? splashColor;

  final bool showShadow;

// ===========================================================================
// BUILD
// ===========================================================================

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    final Color effectiveForegroundColor = foregroundColor ?? AppColors.primary;

    final Gradient? effectiveGradient =
        gradient ?? (backgroundColor == null ? AppColors.buttonGradient : null);

    final Color? effectiveBackgroundColor =
        effectiveGradient == null ? backgroundColor : null;

    final TextStyle effectiveTextStyle = (textStyle ??
            const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ))
        .copyWith(
      color: effectiveForegroundColor,
    );

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border != null ? Border.fromBorderSide(border!) : null,
          // boxShadow: showShadow ? (boxShadow ?? _defaultShadow) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            onLongPress: isEnabled ? onLongPress : null,
            splashColor: splashColor,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
              child: _buildContent(effectiveTextStyle),
            ),
          ),
        ),
      ),
    );
  }

// ===========================================================================
// CONTENT
// ===========================================================================

  Widget _buildContent(TextStyle textStyle) {
    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }

// ===========================================================================
// DEFAULT SHADOW
// ===========================================================================

  static const List<BoxShadow> _defaultShadow = [
    BoxShadow(
      color: Color(0x26005C57),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}
