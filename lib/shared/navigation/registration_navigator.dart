import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/routes/app_routes.dart';

class RegistrationNavigator {
  RegistrationNavigator._();

  /// Maps backend screen names or member detail statuses to GetX routes.
  static String   mapScreenNameToRoute(String? screenName) {
    if (screenName == null || screenName.trim().isEmpty) {
      return AppRoutes.registerScreen;
    }

    final normalized = screenName.trim().toLowerCase().replaceAll(' ', '_');

    switch (normalized) {
      // Registration
      case '/register-screen':
        return AppRoutes.registerScreen;

      // Legal / Rules
      case '/legal-rules':
        return AppRoutes.legalRules;

    // Step 1 / Member registration
      case '/member-registration-step1':
        return AppRoutes.memberRegistrationStep1;

    // Step 2 / Member registration
      case '/member-registration-step2':
        return AppRoutes.memberRegistrationStep2;

    // Step 3 / Member registration
      case '/member-registration-step3':
        return AppRoutes.memberRegistrationStep3;

      // // Pending approval / completed
      // case 'pending':
      // case 'registration_pending':
      // case 'under_review':
      //   return AppRoutes.registrationPending;
      //
      // case 'home':
      // case 'dashboard':
      //   return AppRoutes.home;

      default:
        debugPrint('Unknown screenName: "$screenName". Defaulting to signup.');
        return AppRoutes.registerScreen;
    }
  }

  /// Navigates user to the route matching the backend [screenName].
  static Future<void> navigateToScreen(
    String? screenName, {
    bool offAll = false,
  }) async {
    final route = mapScreenNameToRoute(screenName);
    if (offAll) {
      Get.offAllNamed(route);
    } else {
      Get.toNamed(route);
    }
  }
}
