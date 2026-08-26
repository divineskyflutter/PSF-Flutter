import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_keys.dart';

class AppPrefs {
  AppPrefs._();

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences once during app startup.
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    final prefs = _prefs;

    if (prefs == null) {
      throw StateError(
        'AppPrefs has not been initialized. '
            'Call AppPrefs.init() before using it.',
      );
    }

    return prefs;
  }

  // ============================================================
  // Onboarding
  // ============================================================

  static bool get isOnboardingCompleted {
    return _instance.getBool(
      AppPrefsKeys.onboardingCompleted,
    ) ??
        false;
  }

  static Future<bool> setOnboardingCompleted(bool value) {
    return _instance.setBool(
      AppPrefsKeys.onboardingCompleted,
      value,
    );
  }

  // ============================================================
  // Language
  // ============================================================

  static String? get language {
    return _instance.getString(AppPrefsKeys.language);
  }

  static Future<bool> setLanguage(String languageCode) {
    return _instance.setString(
      AppPrefsKeys.language,
      languageCode,
    );
  }

  // ============================================================
  // Theme
  // ============================================================

  static bool get isDarkMode {
    return _instance.getBool(
      AppPrefsKeys.isDarkMode,
    ) ??
        false;
  }

  static Future<bool> setDarkMode(bool value) {
    return _instance.setBool(
      AppPrefsKeys.isDarkMode,
      value,
    );
  }

  // ============================================================
  // Generic helpers
  // ============================================================

  static Future<bool> remove(String key) {
    return _instance.remove(key);
  }

  static Future<bool> clear() {
    return _instance.clear();
  }

  static bool containsKey(String key) {
    return _instance.containsKey(key);
  }

  static String? get registrationStatus =>
      _instance.getString(AppPrefsKeys.registrationStatus);

  static Future<bool> setRegistrationStatus(String value) =>
      _instance.setString(AppPrefsKeys.registrationStatus, value);
}
