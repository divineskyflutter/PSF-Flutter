import 'package:flutter/material.dart';

enum AppLanguage {
  english,
  hindi,
  gujarati,
}

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.hindi:
        return 'hi';
      case AppLanguage.gujarati:
        return 'gu';
    }
  }

  String get name {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'हिंदी';
      case AppLanguage.gujarati:
        return 'ગુજરાતી';
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en', 'US');
      case AppLanguage.hindi:
        return const Locale('hi', 'IN');
      case AppLanguage.gujarati:
        return const Locale('gu', 'IN');
    }
  }

  static AppLanguage fromCode(String? code) {
    switch (code?.toLowerCase()) {
      case 'hi':
        return AppLanguage.hindi;
      case 'gu':
        return AppLanguage.gujarati;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }

  static AppLanguage fromLocale(Locale locale) {
    return fromCode(locale.languageCode);
  }
}