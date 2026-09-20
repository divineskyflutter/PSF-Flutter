import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';

import '../../data/member_qr_image.dart';

/// The member's QR code inside a white rounded panel. Shows a spinner while
/// [isLoading], the image once loaded, and an inline "unavailable — tap to
/// retry" state otherwise (the QR endpoint can fail independently of
/// everything else on the card, so this never blocks the rest of the UI).
///
/// Lays itself out to whatever square the parent gives it (falling back to
/// [size] when unconstrained), so the message/retry text always fits.
class MemberQrView extends StatelessWidget {
  const MemberQrView({
    super.key,
    required this.qr,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.size,
  });

  final MemberQrImage? qr;

  final bool isLoading;

  final bool hasError;

  final VoidCallback onRetry;

  final double size;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actual = constraints.hasBoundedWidth && constraints.hasBoundedHeight
            ? math.min(constraints.maxWidth, constraints.maxHeight)
            : size;

        return Container(
          width: actual,
          height: actual,
          padding: EdgeInsets.all(actual * .07),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(actual * .1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _content(actual),
        );
      },
    );
  }

  Widget _content(double actual) {
    final image = qr;

    if (isLoading && image == null) return _spinner();

    if (image?.bytes != null) {
      return Image.memory(
        image!.bytes!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      );
    }

    if (image?.url != null) {
      return Image.network(
        image!.url!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        loadingBuilder: (context, imageChild, progress) =>
            progress == null ? imageChild : _spinner(),
        errorBuilder: (_, __, ___) => _unavailable(actual),
      );
    }

    return _unavailable(actual);
  }

  Widget _spinner() {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.primary),
      ),
    );
  }

  Widget _unavailable(double actual) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRetry,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 44,
                color: AppColors.textSecondary.withOpacity(.55),
              ),
              const SizedBox(height: 4),
              Text(
                'qr_unavailable'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'tap_to_retry'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
