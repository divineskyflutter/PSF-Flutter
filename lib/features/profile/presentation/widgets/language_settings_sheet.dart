import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// Bottom sheet to switch the app language. Applies the chosen language
/// immediately and closes — a settings-style picker with no confirm step.
/// Open it with [LanguageSettingsSheet.show].
class LanguageSettingsSheet extends StatelessWidget {
  const LanguageSettingsSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const LanguageSettingsSheet(),
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
              AppStrings.chooseLanguage.tr,
              style: TextStyle(fontSize: 16.px(context), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16.px(context)),
            const _LanguageOptionsList(),
          ],
        ),
      ),
    );
  }
}

/// Applies the chosen language immediately and closes the sheet — unlike
/// the onboarding language screen (which routes onward on "Continue"),
/// this is a settings-style picker: no separate confirm step.
class _LanguageOptionsList extends StatelessWidget {
  const _LanguageOptionsList();

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final currentLanguage = languageController.currentAppLanguage;

      return Column(
        children: [
          for (final language in AppLanguage.values) ...[
            _LanguageTile(
              language: language,
              isSelected: language == currentLanguage,
              onTap: () async {
                await languageController.changeAppLanguage(language);
                if (context.mounted) Get.back();
              },
            ),
            if (language != AppLanguage.values.last) SizedBox(height: 10.px(context)),
          ],
        ],
      );
    });
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacity(.08) : AppColors.background,
      borderRadius: BorderRadius.circular(16.px(context)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.px(context)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.px(context), vertical: 14.px(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.px(context)),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.displayName,
                  style: TextStyle(
                    fontSize: 15.px(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(.5),
                size: 20.px(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
