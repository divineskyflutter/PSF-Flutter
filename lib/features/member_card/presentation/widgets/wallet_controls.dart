import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';

// Small controls shared by every wallet layout (vertical and horizontal):
// a dark label pill, the round flip arrows and the Download button.

/// Small dark translucent label — readable on any part of the drawer's
/// dark-to-light background.
class WalletPill extends StatelessWidget {
  const WalletPill({required this.textKey});

  final String textKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.px(context), vertical: 8.px(context)),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(.62),
        borderRadius: BorderRadius.circular(24.px(context)),
      ),
      child: Text(
        textKey.tr,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.5.px(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class WalletArrowButton extends StatelessWidget {
  const WalletArrowButton({required this.icon, required this.onTap});

  final IconData icon;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = 44.px(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 28.px(context), color: AppColors.primary),
      ),
    );
  }
}

class WalletDownloadButton extends StatelessWidget {
  const WalletDownloadButton({required this.controller});

  final MemberCardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isDownloading.value;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : controller.downloadCard,
        child: Container(
          width: double.infinity,
          height: 52.px(context),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(18.px(context)),
            border: Border.all(color: AppColors.accentGold.withOpacity(.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withOpacity(busy ? .15 : .40),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20.px(context),
                        height: 20.px(context),
                        child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      ),
                      SizedBox(width: 12.px(context)),
                      Flexible(
                        child: Text(
                          'card_downloading'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.px(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, color: AppColors.accentGold, size: 22.px(context)),
                      SizedBox(width: 10.px(context)),
                      Flexible(
                        child: Text(
                          'download_card'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.px(context),
                            fontWeight: FontWeight.w800,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
