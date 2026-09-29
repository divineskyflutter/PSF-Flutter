import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/shared/utils/image_picker_util.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.locale,
    required this.nativeName,
    required this.englishName,
    required this.letter,
    required this.color,
  });

  final String code;
  final Locale locale;
  final String nativeName;
  final String englishName;
  final String letter;
  final Color color;
}

class LanguageSelectionController extends GetxController {
  late final LanguageController _languageController;

  final languages = const [
    LanguageOption(
      code: 'gu',
      locale: Locale('gu', 'IN'),
      nativeName: 'ગુજરાતી',
      englishName: 'Gujarati',
      letter: 'અ',
      color: Color(0xFF19794F),
    ),
    LanguageOption(
      code: 'hi',
      locale: Locale('hi', 'IN'),
      nativeName: 'हिंदी',
      englishName: 'Hindi',
      letter: 'अ',
      color: Color(0xFFFF9700),
    ),
    LanguageOption(
      code: 'en',
      locale: Locale('en', 'US'),
      nativeName: 'English',
      englishName: 'English',
      letter: 'E',
      color: Color(0xFF811A31),
    ),
  ];

  final selectedCode = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _languageController = Get.find<LanguageController>();
    final currentCode = _languageController.locale.value.languageCode;
    if (languages.any((language) => language.code == currentCode)) {
      selectedCode.value = currentCode;
    }
  }

  Future<void> select(LanguageOption language) async {
    selectedCode.value = language.code;

    await _languageController.changeLanguage(
      language.locale,
    );
  }

  Future<void> continueToNextScreen() async {
    final language = languages.firstWhere(
          (option) => option.code == selectedCode.value,
    );

    await _languageController.changeLanguage(
      language.locale,
    );

    // Ask for Camera + Gallery/Photos permission here, right after
    // language selection — see ImagePickerUtil.requestStartupPermissions'
    // doc comment for why this is asked this early. Deliberately NOT
    // awaited: the two native OS prompts (camera, then storage/photos)
    // used to block this whole method, which made tapping Continue feel
    // like the app had frozen for however long it took to answer both of
    // them one after another. They still show up moments later, just over
    // onboarding/auth-choice instead of before it — a normal enough thing
    // for an app to do, and worth it for a Continue tap that responds
    // immediately.
    unawaited(ImagePickerUtil.requestStartupPermissions());

    if (AppPrefs.isOnboardingCompleted) {
      Get.offAllNamed(AppRoutes.authChoice);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}
