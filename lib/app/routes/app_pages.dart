import 'package:get/get.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/auth/bindings/auth_binding.dart';
import 'package:psf_application/features/auth/presentation/pages/auth_choice_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/login_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/register_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/legal_rules.dart';
import 'package:psf_application/features/auth/presentation/pages/registration/registration_form_steps_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/registration/registration_preview_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/registration/registration_pending_screen.dart';
import 'package:psf_application/features/language/bindings/language_binding.dart';
import 'package:psf_application/features/language/presentation/pages/language_selection_screen.dart';
import 'package:psf_application/features/loans/presentation/pages/installment_details_screen.dart';
import 'package:psf_application/features/loans/presentation/pages/loans_screen.dart';
import 'package:psf_application/features/navigation/bindings/main_navigation_binding.dart';
import 'package:psf_application/features/navigation/presentation/pages/main_navigation_screen.dart';
import 'package:psf_application/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:psf_application/features/profile/presentation/pages/about_us_page.dart';
import 'package:psf_application/features/profile/presentation/pages/contact_us_page.dart';
import 'package:psf_application/features/profile/presentation/pages/delete_account_page.dart';
import 'package:psf_application/features/profile/presentation/pages/membership_card_page.dart';
import 'package:psf_application/features/profile/presentation/pages/passbook_page.dart';
import 'package:psf_application/features/profile/presentation/pages/privacy_policy_page.dart';
import 'package:psf_application/features/profile/presentation/pages/terms_conditions_page.dart';
import 'package:psf_application/features/splash/bindings/splash_binding.dart';
import 'package:psf_application/features/splash/presentation/splash_screen.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
    ),
    GetPage(
      name: AppRoutes.language,
      page: () => const LanguageSelectionScreen(),
      binding: LanguageBinding(),
    ),
    GetPage(
      name: AppRoutes.authChoice,
      page: () => const AuthChoiceScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.registerScreen,
      page: () => const RegisterScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.legalRules,
      page: () => const LegalRules(),
      binding: AuthBinding(),
    ),
    // All four wizard steps (Member / Nominee / Health / Rules) are one
    // widget internally — MemberRegistrationScreen owns a single PageView
    // driven by RegistrationController.currentStep, not four separate
    // screens. Each step still gets its own registered route here (rather
    // than only step1's) so RegistrationNavigator can send the member to a
    // route that actually exists no matter which step the backend's
    // memberDetailStatusName names; MemberRegistrationScreen then reads the
    // `initialStep` argument RegistrationNavigator attaches to jump its
    // PageView straight to the matching page — see
    // _MemberRegistrationScreenState._applyResumeStepFromArguments.
    GetPage(name: AppRoutes.memberRegistrationStep1, page: () => const MemberRegistrationScreen()),
    GetPage(name: AppRoutes.memberRegistrationStep2, page: () => const MemberRegistrationScreen()),
    GetPage(name: AppRoutes.memberRegistrationStep3, page: () => const MemberRegistrationScreen()),
    GetPage(name: AppRoutes.memberRegistrationStep4, page: () => const MemberRegistrationScreen()),
    GetPage(name: AppRoutes.registrationPreview, page: () => const RegistrationPreviewScreen()),
    // Reached two ways: RegistrationPreviewScreen._completeRegistration
    // navigates here right after submission, and — on a later app launch,
    // before approval — RegistrationNavigator routes a returning member
    // straight back here via GetSingleMemberByRegistredStatus's returned
    // screen name (see RegistrationNavigator.mapScreenNameToRoute's
    // '/registration-pending' case).
    GetPage(name: AppRoutes.registrationPending, page: () => const RegistrationPendingScreen()),
    // The bottom-navigation shell (Home / Loans / Profile tabs) — see
    // MainNavigationBinding for why every tab's dependencies are wired
    // together here instead of each tab (or sub-page) declaring its own
    // binding.
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavigationScreen(),
      binding: MainNavigationBinding(),
    ),

    // ------------------------------------------------------------
    // Profile — sub-pages pushed from the Profile tab. No binding: they
    // reuse the controllers MainNavigationBinding already registered.
    // ------------------------------------------------------------

    GetPage(name: AppRoutes.membershipCard, page: () => const MembershipCardPage()),
    GetPage(name: AppRoutes.passbook, page: () => const PassbookPage()),
    GetPage(name: AppRoutes.aboutUs, page: () => const AboutUsPage()),
    GetPage(name: AppRoutes.termsAndConditions, page: () => const TermsConditionsPage()),
    GetPage(name: AppRoutes.privacyPolicy, page: () => const PrivacyPolicyPage()),
    GetPage(name: AppRoutes.contactUs, page: () => const ContactUsPage()),
    GetPage(name: AppRoutes.deleteAccount, page: () => const DeleteAccountPage()),

    // ------------------------------------------------------------
    // Loans — sub-page pushed from the Loans tab.
    // ------------------------------------------------------------

    GetPage(name: AppRoutes.loans, page: () => const LoansScreen()),
    GetPage(name: AppRoutes.loanInstallments, page: () => const InstallmentDetailsScreen()),
  ];
}
