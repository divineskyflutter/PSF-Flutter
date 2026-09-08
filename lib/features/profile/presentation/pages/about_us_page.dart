import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/content_section_card.dart';

/// Static, localized content — the Foundation's mission, vision and
/// values. Reached from Profile > About Us.
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final values = [
      AppStrings.valueCompassion.tr,
      AppStrings.valueIntegrity.tr,
      AppStrings.valueTransparency.tr,
      AppStrings.valueEquality.tr,
      AppStrings.valueServiceToHumanity.tr,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.aboutUs.tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.px(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentIntroBanner(text: AppStrings.knowAboutUsDescription.tr),
            SizedBox(height: 16.px(context)),
            ContentSectionCard(title: AppStrings.ourMission.tr, body: AppStrings.ourMissionText.tr),
            SizedBox(height: 14.px(context)),
            ContentSectionCard(title: AppStrings.ourVision.tr, body: AppStrings.ourVisionText.tr),
            SizedBox(height: 14.px(context)),
            ContentSectionCard(
              title: AppStrings.ourValues.tr,
              child: Padding(
                padding: EdgeInsets.only(top: 4.px(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final value in values)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.px(context)),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 6.px(context), color: AppColors.primary),
                            SizedBox(width: 10.px(context)),
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 13.px(context),
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.px(context)),
          ],
        ),
      ),
    );
  }
}
