import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/content_section_card.dart';

/// Static, localized Privacy Policy. Reached from Profile > Privacy
/// Policy.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      (AppStrings.informationWeCollect.tr, AppStrings.informationWeCollectText.tr),
      (AppStrings.dataProtection.tr, AppStrings.dataProtectionText.tr),
      (AppStrings.informationSharing.tr, AppStrings.informationSharingText.tr),
      (AppStrings.yourRights.tr, AppStrings.yourRightsText.tr),
      (AppStrings.policyUpdates.tr, AppStrings.policyUpdatesText.tr),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.privacyPolicy.tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.px(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentIntroBanner(text: AppStrings.privacyPolicyIntro.tr),
            for (final section in sections) ...[
              SizedBox(height: 14.px(context)),
              ContentSectionCard(title: section.$1, body: section.$2),
            ],
            SizedBox(height: 24.px(context)),
          ],
        ),
      ),
    );
  }
}
