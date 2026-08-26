import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:psf_application/app/constants/app_colors.dart';

/// Common text field widget.
///
/// Normal:
/// AppTextField(
///   label: 'Email',
///   hintText: 'Enter your email',
/// )
///
/// Form:
/// AppTextField.form(
///   label: 'Email',
///   validator: (value) {},
/// )
///
/// OTP:
/// AppTextField.otp(
///   controller: controller,
///   length: 6,
/// )
class AppTextField extends StatelessWidget {
// ===========================================================================
// NORMAL TEXT FIELD
// ===========================================================================

  const AppTextField({
    this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.onUnfocus,
    this.inputFormatters,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.fillColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.borderRadius = 14,
    this.borderWidth = 1,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.errorText,
    this.helperText,
    this.focusedBorder,
    this.enabledBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.cursorColor,
    this.cursorHeight,
    this.cursorWidth = 2,
    this.showClearButton = false,
    this.onClear,
    this.scrollPadding = const EdgeInsets.all(20),
    super.key,
  })  : validator = null,
        autovalidateMode = null,
        otpLength = null,
        onCompleted = null,
        obscuringCharacter = '•',
        borderColor = null,
        boxWidth = 52,
        boxHeight = 56,
        spacing = 10,
        pinAnimationDuration = const Duration(milliseconds: 150),
        showCursor = true,
        useNativeKeyboard = true,
        pasteAllowed = true,
        isFormField = false;

// ===========================================================================
// FORM TEXT FIELD
// ===========================================================================

  const AppTextField.form({
    this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.onUnfocus,
    this.validator,
    this.inputFormatters,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.fillColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.borderRadius = 14,
    this.borderWidth = 1,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.errorText,
    this.helperText,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.focusedBorder,
    this.enabledBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.cursorColor,
    this.cursorHeight,
    this.cursorWidth = 2,
    this.showClearButton = false,
    this.onClear,
    this.scrollPadding = const EdgeInsets.all(20),
    super.key,
  })  : otpLength = null,
        onCompleted = null,
        obscuringCharacter = '•',
        borderColor = null,
        boxWidth = 52,
        boxHeight = 56,
        spacing = 10,
        pinAnimationDuration = const Duration(milliseconds: 150),
        showCursor = true,
        useNativeKeyboard = true,
        pasteAllowed = true,
        isFormField = true;

// ===========================================================================
// OTP FIELD
// ===========================================================================

  const AppTextField.otp({
    this.controller,
    this.otpLength = 6,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType = TextInputType.number,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.textStyle,
    this.cursorColor,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.borderRadius = 12,
    this.borderWidth = 1,
    this.boxWidth = 52,
    this.boxHeight = 56,
    this.spacing = 10,
    this.validator,
    this.errorText,
    this.autovalidateMode =
        AutovalidateMode.onUserInteraction,
    this.pinAnimationDuration =
    const Duration(milliseconds: 150),
    this.showCursor = true,
    this.useNativeKeyboard = true,
    this.pasteAllowed = true,
    this.inputFormatters,
    super.key,
  })  : label = '',
        hintText = null,
        prefixIcon = null,
        suffixIcon = null,
        prefix = null,
        suffix = null,
        helperText = null, // <-- ADD THIS
        textInputAction = TextInputAction.done,
        textCapitalization = TextCapitalization.none,
        readOnly = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        onSubmitted = null,
        onTap = null,
        onEditingComplete = null,
        hintStyle = null,
        labelStyle = null,
        enabledBorderColor = null,
        contentPadding = null,
        prefixIconConstraints = null,
        suffixIconConstraints = null,
        focusedBorder = null,
        enabledBorder = null,
        errorBorder = null,
        focusedErrorBorder = null,
        cursorHeight = null,
        cursorWidth = 2,
        showClearButton = false,
        onClear = null,
        scrollPadding = const EdgeInsets.all(20),
        onUnfocus = null,
        isFormField = false;
// ===========================================================================
// COMMON PROPERTIES
// ===========================================================================

  final String? label;

  final TextEditingController? controller;

  final FocusNode? focusNode;

  final String? hintText;

  final Widget? prefixIcon;

  final Widget? suffixIcon;

  final Widget? prefix;

  final Widget? suffix;

  final TextInputType? keyboardType;

  final TextInputAction? textInputAction;

  final TextCapitalization textCapitalization;

  final bool obscureText;

  final bool enabled;

  final bool readOnly;

  final bool autofocus;

  final int maxLines;

  final int? minLines;

  final int? maxLength;

  final ValueChanged<String>? onChanged;

  final ValueChanged<String>? onSubmitted;

  final VoidCallback? onTap;

  final VoidCallback? onEditingComplete;

  final VoidCallback? onUnfocus;

  final String? Function(String?)? validator;

  final List<TextInputFormatter>? inputFormatters;

  final TextStyle? textStyle;

  final TextStyle? hintStyle;

  final TextStyle? labelStyle;

  final Color? fillColor;

  final Color? focusedBorderColor;

  final Color? enabledBorderColor;

  final Color? errorBorderColor;

  final double borderRadius;

  final double borderWidth;

  final EdgeInsetsGeometry? contentPadding;

  final BoxConstraints? prefixIconConstraints;

  final BoxConstraints? suffixIconConstraints;

  final String? errorText;

  final String? helperText;

  final AutovalidateMode? autovalidateMode;

  final InputBorder? focusedBorder;

  final InputBorder? enabledBorder;

  final InputBorder? errorBorder;

  final InputBorder? focusedErrorBorder;

  final Color? cursorColor;

  final double? cursorHeight;

  final double cursorWidth;

  final bool showClearButton;

  final VoidCallback? onClear;

  final EdgeInsets scrollPadding;

// ===========================================================================
// OTP PROPERTIES
// ===========================================================================

  final int? otpLength;

  final ValueChanged<String>? onCompleted;

  final String obscuringCharacter;

  final Color? borderColor;

  final double boxWidth;

  final double boxHeight;

  final double spacing;

  final Duration pinAnimationDuration;

  final bool showCursor;

  final bool useNativeKeyboard;

  final bool pasteAllowed;

// ===========================================================================
// INTERNAL
// ===========================================================================

  final bool isFormField;

  @override
  Widget build(BuildContext context) {
    if (otpLength != null) {
      return _buildOtpField();
    }

    return _buildTextField();
  }

// ===========================================================================
// NORMAL / FORM FIELD
// ===========================================================================

  Widget _buildTextField() {
    final Color effectiveFillColor = fillColor ?? Colors.white;

    final Color effectiveFocusedColor = focusedBorderColor ?? AppColors.primary;

    final Color effectiveEnabledColor =
        enabledBorderColor ?? const Color(0xFFD5D5D5);

    final Color effectiveErrorColor = errorBorderColor ?? Colors.red;

    final InputBorder defaultEnabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: effectiveEnabledColor,
        width: borderWidth,
      ),
    );

    final InputBorder defaultFocusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: effectiveFocusedColor,
        width: borderWidth + 0.3,
      ),
    );

    final InputBorder defaultErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: effectiveErrorColor,
        width: borderWidth,
      ),
    );

    final Widget? effectiveSuffixIcon = showClearButton && controller != null
        ? IconButton(
            tooltip: 'Clear',
            onPressed: onClear ??
                () {
                  controller!.clear();
                  onChanged?.call('');
                },
            icon: const Icon(Icons.clear),
          )
        : suffixIcon;

    final InputDecoration decoration = InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: labelStyle ??
          const TextStyle(
            fontSize: 15,
          ),
      hintStyle: hintStyle ??
          TextStyle(
            fontSize: 15,
            color: Colors.grey.shade500,
          ),
      filled: true,
      fillColor: effectiveFillColor,
      prefixIcon: prefixIcon,
      prefix: prefix,
      suffixIcon: effectiveSuffixIcon,
      suffix: suffix,
      prefixIconConstraints: prefixIconConstraints,
      suffixIconConstraints: suffixIconConstraints,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
      enabledBorder: enabledBorder ?? defaultEnabledBorder,
      focusedBorder: focusedBorder ?? defaultFocusedBorder,
      errorBorder: errorBorder ?? defaultErrorBorder,
      focusedErrorBorder: focusedErrorBorder ?? defaultErrorBorder,
      errorText: errorText,
      helperText: helperText,
      counterText: ''
    );

    final TextStyle effectiveTextStyle = textStyle ??
        const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        );

    final Widget field = isFormField
        ? TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: decoration,
            keyboardType: keyboardType ?? TextInputType.text,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            enabled: enabled,
            readOnly: readOnly,
            autofocus: autofocus,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            onTap: onTap,
            onEditingComplete: onEditingComplete,
            validator: validator,
            inputFormatters: inputFormatters ?? const [],
            style: effectiveTextStyle,
            cursorColor: cursorColor ?? AppColors.primary,
            cursorHeight: cursorHeight,
            cursorWidth: cursorWidth,
            scrollPadding: scrollPadding,
            autovalidateMode: autovalidateMode,
          )
        : TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: decoration,
            keyboardType: keyboardType ?? TextInputType.text,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            enabled: enabled,
            readOnly: readOnly,
            autofocus: autofocus,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            onEditingComplete: onEditingComplete,
            inputFormatters: inputFormatters ?? const [],
            style: effectiveTextStyle,
            cursorColor: cursorColor ?? AppColors.primary,
            cursorHeight: cursorHeight,
            cursorWidth: cursorWidth,
            scrollPadding: scrollPadding,
          );

    if (onUnfocus != null) {
      return Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            onUnfocus?.call();
          }
        },
        child: field,
      );
    }

    return field;
  }

// ===========================================================================
// OTP FIELD
// ===========================================================================

  Widget _buildOtpField() {
    final Color effectiveBorderColor = borderColor ?? const Color(0xFFD5D5D5);

    final Color effectiveFocusedColor = focusedBorderColor ?? AppColors.primary;

    final Color effectiveErrorColor = errorBorderColor ?? Colors.red;

    final TextStyle effectiveTextStyle = textStyle ??
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        );

    final PinTheme defaultTheme = PinTheme(
      width: boxWidth,
      height: boxHeight,
      textStyle: effectiveTextStyle,
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
      ),
    );

    final PinTheme focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveFocusedColor,
          width: borderWidth + 0.5,
        ),
      ),
    );

    final PinTheme submittedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveFocusedColor,
          width: borderWidth,
        ),
      ),
    );

    final PinTheme errorTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: fillColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveErrorColor,
          width: borderWidth,
        ),
      ),
    );

    return Pinput(
      controller: controller,
      focusNode: focusNode,
      length: otpLength!,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: keyboardType ?? TextInputType.number,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: focusedTheme,
      submittedPinTheme: submittedTheme,
      errorPinTheme: errorTheme,
      separatorBuilder: (_) => SizedBox(width: spacing),
      showCursor: showCursor,
      useNativeKeyboard: useNativeKeyboard,
      animationDuration: pinAnimationDuration,
      onChanged: onChanged,
      onCompleted: onCompleted,
      validator: validator,
      errorText: errorText,
      inputFormatters: inputFormatters ?? const [],
      closeKeyboardWhenCompleted: false,
      hapticFeedbackType: HapticFeedbackType.lightImpact,
      preFilledWidget: const SizedBox(),
      cursor: Container(
        width: 2,
        height: 24,
        color: cursorColor ?? AppColors.primary,
      ),
    );
  }
}
