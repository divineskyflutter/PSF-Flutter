import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';

/// Bottom sheet letting the member pick PDF or Image before Download does
/// anything — opened from [WalletDownloadButton]. Slides up with GetX's own
/// entrance animation. Picking an option closes the sheet and starts that
/// download; the Download button itself then shows its own loading state
/// until it's done (see MemberCardController.isDownloading).
class CardDownloadSheet extends StatelessWidget {
  const CardDownloadSheet({super.key, required this.controller});

  final MemberCardController controller;

  static void show(MemberCardController controller) {
    Get.bottomSheet(
      CardDownloadSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.px(context),
        16.px(context),
        20.px(context),
        28.px(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.px(context))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16.px(context)),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'choose_download_format'.tr,
              style: TextStyle(
                fontSize: 16.px(context),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: 16.px(context)),
            _option(
              context,
              icon: Icons.picture_as_pdf_rounded,
              label: 'download_as_pdf'.tr,
              hint: 'download_as_pdf_hint'.tr,
              onTap: () {
                Get.back();
                controller.downloadCardAs(CardDownloadFormat.pdf);
              },
            ),
            SizedBox(height: 12.px(context)),
            _option(
              context,
              icon: Icons.image_rounded,
              label: 'download_as_image'.tr,
              hint: 'download_as_image_hint'.tr,
              onTap: () {
                Get.back();
                controller.downloadCardAs(CardDownloadFormat.image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.px(context)),
      child: Container(
        padding: EdgeInsets.all(14.px(context)),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16.px(context)),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44.px(context),
              height: 44.px(context),
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(12.px(context)),
              ),
              child: Icon(icon, color: Colors.white, size: 22.px(context)),
            ),
            SizedBox(width: 14.px(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.px(context),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 2.px(context)),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12.px(context),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withOpacity(.6),
            ),
          ],
        ),
      ),
    );
  }
}
