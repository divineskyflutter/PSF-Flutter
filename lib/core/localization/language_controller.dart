import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/shared/enums/app_language.dart';

import '../storage/app_prefs.dart';

class LanguageController extends GetxController {

  final locale = const Locale('en', 'US').obs;

  AppLanguage get currentAppLanguage =>
      AppLanguageExtension.fromLocale(locale.value);

  @override
  void onInit() {
    super.onInit();
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final language = AppPrefs.language;

    Locale newLocale;

    switch (language) {
      case 'hi':
        newLocale = const Locale('hi', 'IN');
        break;

      case 'gu':
        newLocale = const Locale('gu', 'IN');
        break;

      case 'en':
      default:
        newLocale = const Locale('en', 'US');
        break;
    }

    locale.value = newLocale;

    await Get.updateLocale(newLocale);
  }

  Future<void> changeLanguage(Locale newLocale) async {
    locale.value = newLocale;

    await Get.updateLocale(newLocale);

    await AppPrefs.setLanguage(
      newLocale.languageCode,
    );
  }

  Future<void> changeAppLanguage(AppLanguage appLanguage) async {
    await changeLanguage(appLanguage.locale);
  }
}