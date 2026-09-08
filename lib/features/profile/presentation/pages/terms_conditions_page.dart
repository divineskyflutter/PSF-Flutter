import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/content_section_card.dart';

/// Static, localized Terms & Conditions. Reached from Profile > Terms &
/// Conditions Apply.
class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.termsAndConditions.tr),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.px(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentIntroBanner(text: AppStrings.termsAndConditionsIntro.tr),
            SizedBox(height: 24.px(context)),
          ],
        ),
      ),
    );
  }
}
