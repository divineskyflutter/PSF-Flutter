/// Public web links the app opens in the phone's browser.
class AppLinks {
  AppLinks._();

  /// The privacy policy page Google Play lists for this app.
  static const String privacyPolicy = 'https://divinesky.tech/PSF-privacy-policy.html';

  // The three "Click here" rows on the login-choice screen open these in the
  // browser. The addresses haven't been given yet — while one is `null`, tapping
  // its row does nothing. Put the real address here when it is ready.
  static const String? aboutUs = null;
  static const String? contactUs = null;
  static const String? rulesAndTerms = null;
}
