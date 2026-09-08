import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/shared/widgets/loaders/app_loader.dart';

/// Shared loading / empty / error placeholder for any API-backed section
/// (Passbook, Loans, Contact Us, ...) — one widget instead of every screen
/// hand-rolling its own icon + message + retry button.
class AppStateView extends StatelessWidget {
  const AppStateView.loading({super.key})
      : _kind = _StateKind.loading,
        message = null,
        onRetry = null,
        icon = null;

  const AppStateView.empty({
    super.key,
    required String this.message,
    this.icon = Icons.inbox_outlined,
  })  : _kind = _StateKind.empty,
        onRetry = null;

  const AppStateView.error({
    super.key,
    required String this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  }) : _kind = _StateKind.error;

  final _StateKind _kind;

  final String? message;

  final VoidCallback? onRetry;

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (_kind == _StateKind.loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 48.px(context)),
        child: AppLoader.inline(),
      );
    }

    final isError = _kind == _StateKind.error;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 32.px(context),
        vertical: 40.px(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.px(context),
            height: 64.px(context),
            decoration: BoxDecoration(
              color: (isError ? AppColors.danger : AppColors.primary).withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30.px(context),
              color: isError ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 14.px(context)),
          Text(
            message ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5.px(context),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (isError && onRetry != null) ...[
            SizedBox(height: 18.px(context)),
            AppButton.rectangular(
              label: 'retry'.tr,
              onPressed: onRetry,
              width: 140.px(context),
              height: 42.px(context),
              textStyle: TextStyle(fontSize: 13.px(context), fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

enum _StateKind { loading, empty, error }
