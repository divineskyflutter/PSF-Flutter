class AppAssets {
  AppAssets._();

  // ------------------------------------------------------------
  // Logo
  // ------------------------------------------------------------

  static const String logo =
      'assets/images/logo/logo.svg';

  static const String paperTexture =
      'assets/images/logo/paper_texture_2.png';

  // ------------------------------------------------------------
  // Onboarding
  //
  // Static illustrations — replaced the earlier Lottie animations
  // (onboarding_community.json / onboarding_family.json /
  // onboarding_finance.json, still in assets/images/onboarding/ but no
  // longer referenced anywhere) with commissioned artwork matching the
  // app's design. OnboardingScreen renders these via Image.asset now,
  // not Lottie.asset — see that file.
  // ------------------------------------------------------------

  static const String onboardingCommunity =
      'assets/images/onboarding/onboarding_welcome.png';

  static const String onboardingFamily =
      'assets/images/onboarding/onboarding_family.png';

  static const String onboardingFinance =
      'assets/images/onboarding/onboarding_grow.png';

  // ------------------------------------------------------------
  // Rules
  // ------------------------------------------------------------


  static const String registerRulesIncomeText =
      'assets/images/rules_doc_images/income_tex.jpg';

  static const String registerRulesPanCardId =
      'assets/images/rules_doc_images/pan_card_id.jpg';

  static const String registerRulesSection8 =
      'assets/images/rules_doc_images/section_8.jpg';

  static const String registerRulesCertificateOfIncorporation =
      'assets/images/rules_doc_images/certificate_of_incorporation.jpg';


  // ------------------------------------------------------------
  // animations
  // ------------------------------------------------------------

  static const String indianFlagGif =
      'assets/animations/gif/India-flag-xs.gif';

}