class AppPrefsKeys {
  AppPrefsKeys._();

  // ------------------------------------------------------------
  // Onboarding
  // ------------------------------------------------------------

  static const String onboardingCompleted = 'onboarding_completed';

  // ------------------------------------------------------------
  // Language
  // ------------------------------------------------------------

  static const String language = 'language';

  // ------------------------------------------------------------
  // Theme
  // ------------------------------------------------------------

  static const String isDarkMode = 'is_dark_mode';
  static const String registrationStatus = 'registration_status';
}

class AppSecureKeys {
  AppSecureKeys._();

  // ------------------------------------------------------------
  // Authentication
  // ------------------------------------------------------------

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // Registration
  static const String memberId = 'member_id';

// Add more secure keys here when required.
// static const String userId = 'user_id';
}
