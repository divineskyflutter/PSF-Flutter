import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_colors.dart';

enum AppDialogType {
  success,
  error,
  warning,
  info,
  confirmation,
  logout,
  noInternet,
}

class AppDialog {
  AppDialog._();

  // ===========================================================================
  // COLORS
  // ===========================================================================

  static const Color _successColor = Color(0xFF2E9D68);
  static const Color _errorColor = Color(0xFFD94B4B);
  static const Color _warningColor = Color(0xFFE7A72E);
  static const Color _infoColor = Color(0xFF3985C6);

  // ===========================================================================
  // COMMON SHOW
  // ===========================================================================

  static Future<bool?> show({
    required String title,
    required String message,

    AppDialogType type = AppDialogType.info,

    IconData? icon,
    Widget? customIcon,

    String primaryButtonText = 'OK',
    String? secondaryButtonText,

    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,

    bool barrierDismissible = true,
    bool showCloseButton = false,

    Color? primaryButtonColor,
    Color? secondaryButtonColor,

    Color? backgroundColor,

    double borderRadius = 24,
    EdgeInsetsGeometry padding =
    const EdgeInsets.all(24),

    TextStyle? titleStyle,
    TextStyle? messageStyle,

    Widget? customContent,

    bool showIcon = true,

    bool closeOnPrimary = true,
    bool closeOnSecondary = true,
  }) async {
    final config = _getConfig(type);

    final result = await Get.dialog<bool>(
      _AppDialogView(
        title: title,
        message: message,

        icon: icon ?? config.icon,
        customIcon: customIcon,

        iconColor:
        primaryButtonColor ?? config.color,

        primaryButtonText:
        primaryButtonText,

        secondaryButtonText:
        secondaryButtonText,

        onPrimaryPressed:
        onPrimaryPressed,

        onSecondaryPressed:
        onSecondaryPressed,

        backgroundColor:
        backgroundColor ?? Colors.white,

        primaryButtonColor:
        primaryButtonColor ?? config.color,

        secondaryButtonColor:
        secondaryButtonColor ??
            Colors.grey.shade100,

        borderRadius: borderRadius,
        padding: padding,

        titleStyle: titleStyle,
        messageStyle: messageStyle,

        customContent: customContent,

        showIcon: showIcon,
        showCloseButton: showCloseButton,

        closeOnPrimary:
        closeOnPrimary,

        closeOnSecondary:
        closeOnSecondary,
      ),
      barrierDismissible: barrierDismissible,
      barrierColor:
      Colors.black.withValues(alpha: 0.45),
    );

    return result;
  }

  // ===========================================================================
  // SUCCESS
  // ===========================================================================

  static Future<bool?> success({
    required String title,
    required String message,

    String buttonText = 'OK',

    VoidCallback? onPressed,

    bool barrierDismissible = true,
  }) {
    return show(
      title: title,
      message: message,

      type: AppDialogType.success,

      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,

      barrierDismissible:
      barrierDismissible,
    );
  }

  // ===========================================================================
  // ERROR
  // ===========================================================================

  static Future<bool?> error({
    required String title,
    required String message,

    String buttonText = 'OK',

    VoidCallback? onPressed,

    bool barrierDismissible = true,
  }) {
    return show(
      title: title,
      message: message,

      type: AppDialogType.error,

      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,

      barrierDismissible:
      barrierDismissible,
    );
  }

  // ===========================================================================
  // WARNING
  // ===========================================================================

  static Future<bool?> warning({
    required String title,
    required String message,

    String buttonText = 'OK',

    VoidCallback? onPressed,

    bool barrierDismissible = true,
  }) {
    return show(
      title: title,
      message: message,

      type: AppDialogType.warning,

      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,

      barrierDismissible:
      barrierDismissible,
    );
  }

  // ===========================================================================
  // INFO
  // ===========================================================================

  static Future<bool?> info({
    required String title,
    required String message,

    String buttonText = 'OK',

    VoidCallback? onPressed,
  }) {
    return show(
      title: title,
      message: message,

      type: AppDialogType.info,

      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed,
    );
  }

  // ===========================================================================
  // CONFIRMATION
  // ===========================================================================

  static Future<bool> confirm({
    required String title,
    required String message,

    String confirmText = 'Confirm',
    String cancelText = 'Cancel',

    VoidCallback? onConfirm,
    VoidCallback? onCancel,

    bool barrierDismissible = true,
  }) async {
    final result = await show(
      title: title,
      message: message,

      type: AppDialogType.confirmation,

      primaryButtonText:
      confirmText,

      secondaryButtonText:
      cancelText,

      onPrimaryPressed:
      onConfirm,

      onSecondaryPressed:
      onCancel,

      barrierDismissible:
      barrierDismissible,
    );

    return result ?? false;
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  static Future<bool> logout({
    String title = 'Logout',
    String message =
    'Are you sure you want to logout?',

    String logoutText = 'Logout',
    String cancelText = 'Cancel',

    VoidCallback? onLogout,
    VoidCallback? onCancel,
  }) {
    return confirm(
      title: title,
      message: message,

      confirmText: logoutText,
      cancelText: cancelText,

      onConfirm: onLogout,
      onCancel: onCancel,
    );
  }

  // ===========================================================================
  // NO INTERNET
  // ===========================================================================

  static Future<bool?> noInternet({
    String title = 'No Internet Connection',
    String message =
    'Please check your internet connection and try again.',

    String retryText = 'Retry',
    String cancelText = 'Cancel',

    VoidCallback? onRetry,
    VoidCallback? onCancel,

    bool barrierDismissible = false,
  }) {
    return show(
      title: title,
      message: message,

      type: AppDialogType.noInternet,

      primaryButtonText:
      retryText,

      secondaryButtonText:
      cancelText,

      onPrimaryPressed:
      onRetry,

      onSecondaryPressed:
      onCancel,

      barrierDismissible:
      barrierDismissible,
    );
  }

  // ===========================================================================
  // CONFIG
  // ===========================================================================

  static _DialogConfig _getConfig(
      AppDialogType type,
      ) {
    switch (type) {
      case AppDialogType.success:
        return const _DialogConfig(
          icon: Icons.check_circle_rounded,
          color: _successColor,
        );

      case AppDialogType.error:
        return const _DialogConfig(
          icon: Icons.error_rounded,
          color: _errorColor,
        );

      case AppDialogType.warning:
        return const _DialogConfig(
          icon: Icons.warning_rounded,
          color: _warningColor,
        );

      case AppDialogType.info:
        return const _DialogConfig(
          icon: Icons.info_rounded,
          color: _infoColor,
        );

      case AppDialogType.confirmation:
        return _DialogConfig(
          icon: Icons.help_rounded,
          color: AppColors.primary,
        );

      case AppDialogType.logout:
        return const _DialogConfig(
          icon: Icons.logout_rounded,
          color: _errorColor,
        );

      case AppDialogType.noInternet:
        return const _DialogConfig(
          icon: Icons.wifi_off_rounded,
          color: _warningColor,
        );
    }
  }
}

// ==============================================================================
// CONFIG MODEL
// ==============================================================================

class _DialogConfig {
  const _DialogConfig({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}

// ==============================================================================
// DIALOG VIEW
// ==============================================================================

class _AppDialogView extends StatelessWidget {
  const _AppDialogView({
    required this.title,
    required this.message,
    required this.icon,
    required this.customIcon,
    required this.iconColor,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
    required this.backgroundColor,
    required this.primaryButtonColor,
    required this.secondaryButtonColor,
    required this.borderRadius,
    required this.padding,
    required this.titleStyle,
    required this.messageStyle,
    required this.customContent,
    required this.showIcon,
    required this.showCloseButton,
    required this.closeOnPrimary,
    required this.closeOnSecondary,
  });

  final String title;
  final String message;

  final IconData icon;
  final Widget? customIcon;

  final Color iconColor;

  final String primaryButtonText;
  final String? secondaryButtonText;

  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  final Color backgroundColor;

  final Color primaryButtonColor;
  final Color secondaryButtonColor;

  final double borderRadius;

  final EdgeInsetsGeometry padding;

  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  final Widget? customContent;

  final bool showIcon;
  final bool showCloseButton;

  final bool closeOnPrimary;
  final bool closeOnSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,

      insetPadding:
      const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),

      child: Container(
        width: double.infinity,

        padding: padding,

        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
          BorderRadius.circular(
            borderRadius,
          ),

          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),

        child: Stack(
          children: [
            Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                if (showIcon) ...[
                  customIcon ??
                      Container(
                        width: 70,
                        height: 70,

                        decoration:
                        BoxDecoration(
                          color: iconColor
                              .withValues(
                            alpha: 0.10,
                          ),
                          shape:
                          BoxShape.circle,
                        ),

                        child: Icon(
                          icon,
                          size: 38,
                          color: iconColor,
                        ),
                      ),

                  const SizedBox(height: 20),
                ],

                Text(
                  title,
                  textAlign:
                  TextAlign.center,

                  style:
                  titleStyle ??
                      const TextStyle(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Colors.black87,
                      ),
                ),

                const SizedBox(height: 10),

                Text(
                  message,
                  textAlign:
                  TextAlign.center,

                  style:
                  messageStyle ??
                      TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color:
                        Colors.grey
                            .shade600,
                      ),
                ),

                if (customContent != null) ...[
                  const SizedBox(height: 20),
                  customContent!,
                ],

                const SizedBox(height: 24),

                _buildButtons(context),
              ],
            ),

            if (showCloseButton)
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(
      BuildContext context,
      ) {
    if (secondaryButtonText == null) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: _DialogButton(
          label: primaryButtonText,
          color: primaryButtonColor,
          onPressed: () {
            onPrimaryPressed?.call();

            if (closeOnPrimary) {
              Get.back(result: true);
            }
          },
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: _DialogButton(
              label: secondaryButtonText!,
              color: secondaryButtonColor,
              textColor:
              Colors.black87,
              onPressed: () {
                onSecondaryPressed?.call();

                if (closeOnSecondary) {
                  Get.back(result: false);
                }
              },
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 50,
            child: _DialogButton(
              label: primaryButtonText,
              color: primaryButtonColor,
              onPressed: () {
                onPrimaryPressed?.call();

                if (closeOnPrimary) {
                  Get.back(result: true);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ==============================================================================
// BUTTON
// ==============================================================================

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.textColor = Colors.white,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius:
      BorderRadius.circular(14),

      child: InkWell(
        onTap: onPressed,

        borderRadius:
        BorderRadius.circular(14),

        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}