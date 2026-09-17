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
  // Enum Bundle (Gender / Marital Status / Relation / Member Status, live
  // from GetEnumBundle) — cached as JSON so ids in a locally-stored login
  // response (e.g. gender: 1) can be resolved to display text without a
  // network call. See EnumBundleModel.toJson/fromJson and
  // LoginController's post-login fetch.
  // ------------------------------------------------------------

  static const String enumBundle = 'enum_bundle';

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
