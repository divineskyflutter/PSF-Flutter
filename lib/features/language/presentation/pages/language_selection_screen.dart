import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/features/language/presentation/controllers/language_selection_controller.dart';
import 'package:psf_application/shared/widgets/common/language_option_card.dart';


class LanguageSelectionScreen extends GetView<LanguageSelectionController> {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 74),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 80.px(context)),

                      _Header(),
                      SizedBox(height: 30.px(context)),
                      Obx(
                        () => Column(
                          children: [
                            for (final language in controller.languages) ...[
                              LanguageOptionCard(
                                language: language,
                                isSelected: controller.selectedCode.value ==
                                    language.code,
                                onTap: () => controller.select(language),
                              ),
                              if (language != controller.languages.last)
                                const SizedBox(height: 22),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 42.px(context)),
                      AppButton(
                        label: AppStrings.continueText.tr,
                        onPressed: controller.continueToNextScreen,
                        trailing: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 25.px(context),
                        ),
                      ),
                      SizedBox(height: 12.px(context)),
                      const _LanguageHint(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(
          () {
        // Reading locale makes this widget react to language changes.
        languageController.locale.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppStrings.chooseLanguage.tr,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 24.px(context),
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 15.px(context)),
            Text(
              AppStrings.selectPreferredLanguage.tr,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14.px(context),
                height: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageHint extends StatelessWidget {
  const _LanguageHint();

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(
          () {
            languageController.locale.value;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7EE).withOpacity(.86),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0x110E5B55),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF278076),
                size: 20,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  AppStrings.languageChangeHint.tr,
                  style: const TextStyle(
                    color: Color(0xFF586069),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
