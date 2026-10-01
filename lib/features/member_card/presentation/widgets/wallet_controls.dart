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
      // Still guards against a double tap starting two downloads at once —
      // just silently, with no visible "preparing..." state. Rendering a
      // card face takes a couple of seconds either way; a spinner for that
      // whole stretch read as the button getting stuck, so now the button
      // stays exactly as it was and the download/save success (or
      // cancelled) toast alone — same as tapping "save" on a bank app's QR
      // code — tells the member it's done.
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
                color: AppColors.primaryDark.withOpacity(.40),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Row(
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
      );
    });
  }
}
