import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/profile_controller.dart';
import '../controllers/profile_document.dart';

/// Bottom sheet listing the documents the member can download (application
/// form, ID card, receipt, certificate, agreement). Tapping one closes the
/// sheet and downloads it straight away via
/// [ProfileController.downloadDocument]. Open it with
/// [DownloadDocumentsSheet.show].
class DownloadDocumentsSheet extends StatelessWidget {
  const DownloadDocumentsSheet({super.key, required this.controller});

  final ProfileController controller;

  static void show(ProfileController controller) {
    Get.bottomSheet(
      DownloadDocumentsSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final documents = ProfileDocument.all;

    return Container(
      padding: EdgeInsets.fromLTRB(20.px(context), 16.px(context), 20.px(context), 24.px(context)),
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
              AppStrings.downloadDocumentsTitle.tr,
              style: TextStyle(fontSize: 16.px(context), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.px(context)),
            for (var i = 0; i < documents.length; i++)
              _DocumentTile(
                document: documents[i],
                showDivider: i != documents.length - 1,
                onTap: () {
                  Get.back();
                  controller.downloadDocument(documents[i]);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.showDivider,
    required this.onTap,
  });

  final ProfileDocument document;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13.px(context)),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38.px(context),
              height: 38.px(context),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(document.icon, color: AppColors.primary, size: 19.px(context)),
            ),
            SizedBox(width: 14.px(context)),
            Expanded(
              child: Text(
                document.labelKey.tr,
                style: TextStyle(
                  fontSize: 14.5.px(context),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.download_rounded, color: AppColors.textSecondary, size: 20.px(context)),
          ],
        ),
      ),
    );
  }
}
