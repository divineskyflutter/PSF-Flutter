import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';
import 'card_download_sheet.dart';

// Small controls shared by every wallet layout (vertical and horizontal):
// the Download button.

class WalletDownloadButton extends StatelessWidget {
  const WalletDownloadButton({required this.controller});

  final MemberCardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isDownloading.value;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : () => CardDownloadSheet.show(controller),
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
            // Cross-fades between the two states instead of popping straight
            // from one Row to the other — the render itself (a couple of
            // seconds) then ends in the native Save dialog appearing with
            // no transition at all, which read as abrupt/glitchy with no
            // loader; this keeps a visible "something is happening" cue the
            // whole way through instead.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: busy
                  ? Row(
                      key: const ValueKey('busy'),
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
                      key: const ValueKey('idle'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white, size: 22.px(context)),
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
        ),
      );
    });
  }
}
