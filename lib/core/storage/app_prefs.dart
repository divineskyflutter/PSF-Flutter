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

  // ============================================================
  // Registration completed (see AppPrefsKeys.registrationCompleted)
  // ============================================================

  static bool get isRegistrationCompleted {
    return _instance.getBool(AppPrefsKeys.registrationCompleted) ?? false;
  }

  static Future<bool> setRegistrationCompleted(bool value) {
    return _instance.setBool(AppPrefsKeys.registrationCompleted, value);
  }

  // ============================================================
  // Enum Bundle (see AppPrefsKeys.enumBundle)
  // ============================================================

  static String? get enumBundleJson =>
      _instance.getString(AppPrefsKeys.enumBundle);

  static Future<bool> setEnumBundleJson(String json) =>
      _instance.setString(AppPrefsKeys.enumBundle, json);

  // ============================================================
  // Yojna id (see AppPrefsKeys.yojnaId) — saved at login, never shown
  // ============================================================

  static String? get fcmSentToken => _instance.getString(AppPrefsKeys.fcmSentToken);

  static int? get fcmSentMemberId => _instance.getInt(AppPrefsKeys.fcmSentMemberId);

  /// Remembers which FCM token was uploaded for which member; pass nulls to forget.
  static Future<void> setFcmSent({required String? token, required int? memberId}) async {
    if (token == null || memberId == null) {
      await _instance.remove(AppPrefsKeys.fcmSentToken);
      await _instance.remove(AppPrefsKeys.fcmSentMemberId);
      return;
    }
    await _instance.setString(AppPrefsKeys.fcmSentToken, token);
    await _instance.setInt(AppPrefsKeys.fcmSentMemberId, memberId);
  }

  static int? get yojnaId => _instance.getInt(AppPrefsKeys.yojnaId);

  /// Stores [id], or clears the saved value when [id] is null.
  static Future<bool> setYojnaId(int? id) => id == null
      ? _instance.remove(AppPrefsKeys.yojnaId)
      : _instance.setInt(AppPrefsKeys.yojnaId, id);
}
