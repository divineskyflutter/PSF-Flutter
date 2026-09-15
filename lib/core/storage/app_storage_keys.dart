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

  // ------------------------------------------------------------
  // Registration completion (splash-screen routing)
  // ------------------------------------------------------------

  /// Set once the member finishes every registration step AND taps
  /// "Complete Registration" on the Preview screen — see
  /// RegistrationPreviewScreen._completeRegistration(). Combined with
  /// AppSecureStorage's memberId (cleared on logout) to decide, on the
  /// next app launch, whether SplashScreen should go straight to Home.
  static const String registrationCompleted = 'registration_completed';
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

  // Login — the signed-in member's full profile data, as returned by the
  // (future) login API and parsed into LoginModel. Stored as a JSON
  // string; see AppSecureStorage.saveLoggedInUser/getLoggedInUser.
  static const String loggedInUser = 'logged_in_user';

// Add more secure keys here when required.
// static const String userId = 'user_id';
}
