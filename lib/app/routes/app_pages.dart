import 'package:get/get.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/auth/bindings/auth_binding.dart';
import 'package:psf_application/features/auth/presentation/pages/auth_choice_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/login_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/register_screen.dart';
import 'package:psf_application/features/auth/presentation/pages/legal_rules.dart';
import 'package:psf_application/features/auth/presentation/pages/registration/registration_form_steps_screen.dart';
// import 'package:psf_application/features/registration/presentation/pages/registration_form_steps_screen.dart';
// import 'package:psf_application/features/registration/presentation/pages/registration_preview_screen.dart';
// import 'package:psf_application/features/registration/presentation/pages/registration_pending_screen.dart';
import 'package:psf_application/features/home/bindings/home_binding.dart';
import 'package:psf_application/features/home/presentation/pages/home_screen.dart';
import 'package:psf_application/features/language/bindings/language_binding.dart';
import 'package:psf_application/features/language/presentation/pages/language_selection_screen.dart';
import 'package:psf_application/features/onboarding/presentation/pages/onboarding_screen.dart';
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
    GetPage(name: AppRoutes.memberRegistrationStep1, page: () => const MemberRegistrationScreen()),
    // GetPage(name: AppRoutes.memberRegistrationStep2, page: () => const MemberRegistrationScreen()),
    // GetPage(name: AppRoutes.memberRegistrationStep3, page: () => const MemberRegistrationScreen()),
    // GetPage(name: AppRoutes.registrationPreview, page: () => const RegistrationPreviewScreen()),
    // GetPage(name: AppRoutes.registrationPending, page: () => const RegistrationPendingScreen()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
  ];
}
