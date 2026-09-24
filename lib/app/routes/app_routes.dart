abstract class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const language = '/language';
  static const authChoice = '/auth-choice';
  static const login = '/login';
  static const registerScreen = '/register-screen';
  static const legalRules = '/legal-rules';
  static const memberRegistrationStep1 = '/member-registration-step1';
  static const memberRegistrationStep2 = '/member-registration-step2';
  static const memberRegistrationStep3 = '/member-registration-step3';
  static const memberRegistrationStep4 = '/member-registration-step4';
  static const registrationPreview = '/registration-preview';
  static const registrationPending = '/registration-pending';

  /// The bottom-navigation shell (Home / Loans / Profile tabs) — not a
  /// single screen. Kept as the literal string every earlier screen
  /// already navigates to on login/registration success.
  static const home = '/home';

  // ------------------------------------------------------------
  // Profile
  // ------------------------------------------------------------

  static const membershipCard = '/profile/membership-card';
  static const passbook = '/profile/passbook';
  static const aboutUs = '/profile/about-us';
  static const termsAndConditions = '/profile/terms-and-conditions';
  static const privacyPolicy = '/profile/privacy-policy';
  static const contactUs = '/profile/contact-us';
  static const deleteAccount = '/profile/delete-account';

  // ------------------------------------------------------------
  // Loans
  // ------------------------------------------------------------

  static const loans = '/loans';
  static const loanInstallments = '/loans/installments';
}
