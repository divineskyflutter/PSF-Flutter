import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/routes/app_routes.dart';

class RegistrationNavigator {
  RegistrationNavigator._();

  /// One list, in step order (index 0 = step1 ... index 3 = step4) — the
  /// single place that ties a wizard step number to its registered route.
  /// Every method below reads from this instead of repeating the mapping,
  /// so adding/renaming a step's route only ever needs a change here.
  static const List<String> _stepRoutes = [
    AppRoutes.memberRegistrationStep1,
    AppRoutes.memberRegistrationStep2,
    AppRoutes.memberRegistrationStep3,
    AppRoutes.memberRegistrationStep4,
  ];

  /// Matches a trailing step number in whatever casing/separator style the
  /// backend actually uses — "/member-registration-step2",
  /// "MemberRegistrationStep2", "step_2", "Step 2", etc. — since the exact
  /// literal format of `memberDetailStatusName` isn't nailed down by a
  /// documented contract, only by whatever a real response has shown so
  /// far. Falls back to this instead of requiring an exact string match, so
  /// a small formatting difference from the backend doesn't silently strand
  /// the member on step 1.
  static final RegExp _stepNumberPattern = RegExp(r'step[_\s-]?([1-4])');

  static int? _extractStepNumber(String normalized) {
    final match = _stepNumberPattern.firstMatch(normalized);
    if (match == null) return null;

    final stepNumber = int.tryParse(match.group(1)!);
    return stepNumber;
  }

  /// Maps a backend screen name / status to a registered GetX route. Every
  /// one of the four wizard steps now has its OWN entry in app_pages.dart
  /// (all four pointing at the same MemberRegistrationScreen widget — see
  /// that file's comment), so this returns the actual matching route
  /// instead of funneling every step through step1's route and relying
  /// solely on the `initialStep` argument to correct it after the fact.
  static String mapScreenNameToRoute(String? screenName) {
    if (screenName == null || screenName.trim().isEmpty) {
      return AppRoutes.registerScreen;
    }

    final normalized = screenName.trim().toLowerCase().replaceAll(' ', '_');

    switch (normalized) {
      case '/register-screen':
        return AppRoutes.registerScreen;

      case '/legal-rules':
        return AppRoutes.legalRules;

      case '/member-registration-step1':
        return AppRoutes.memberRegistrationStep1;
      case '/member-registration-step2':
        return AppRoutes.memberRegistrationStep2;
      case '/member-registration-step3':
        return AppRoutes.memberRegistrationStep3;
      case '/member-registration-step4':
        return AppRoutes.memberRegistrationStep4;

      // Pending approval. The real backend value (confirmed from a live
      // GetSingleMemberByRegistredStatus response) is
      // "/member-registration-pending" — it follows the SAME
      // "/member-registration-stepN" convention as the four wizard steps
      // above, not the "/registration-preview" convention this was
      // originally guessed from. A returning member whose application is
      // still awaiting admin approval gets sent straight back to
      // RegistrationPendingScreen instead of re-showing the wizard or
      // falling through to signup (which was re-triggering SaveMemberStep1
      // and failing with "Member Already Exists"). The other variants are
      // kept too, harmlessly, in case the backend ever sends a differently
      // shaped status string.
      case '/member-registration-pending':
      case '/registration-pending':
      case 'pending':
      case 'registration_pending':
      case 'under_review':
        return AppRoutes.registrationPending;

      case '/member-registration-preview':
        return AppRoutes.registrationPreview;

      // // case 'home':
      // case 'dashboard':
      //   return AppRoutes.home;

      default:
        final stepNumber = _extractStepNumber(normalized);

        if (stepNumber != null) {
          return _stepRoutes[stepNumber - 1];
        }

        debugPrint('Unknown screenName: "$screenName". Defaulting to signup.');
        return AppRoutes.registerScreen;
    }
  }

  /// Resolves [screenName] to the internal page index (0-3) that
  /// MemberRegistrationScreen's PageView should open on — Member (0) /
  /// Nominee (1) / Health (2) / Rules (3), matching
  /// RegistrationController.currentStep. `null` means [screenName] isn't
  /// one of the four wizard steps (e.g. it's '/register-screen' or
  /// '/legal-rules'), so there's no step to resume into.
  ///
  /// Kept even though each step now has its own route (mapScreenNameToRoute
  /// above): GetX doesn't hand MemberRegistrationScreen the route name it
  /// was opened on in a form this widget can read directly without extra
  /// wiring, so the resolved index still travels as a route argument — see
  /// navigateToScreen and _MemberRegistrationScreenState.initState.
  static int? initialStepFor(String? screenName) {
    if (screenName == null || screenName.trim().isEmpty) return null;

    final normalized = screenName.trim().toLowerCase().replaceAll(' ', '_');

    switch (normalized) {
      case '/member-registration-step1':
        return 0;
      case '/member-registration-step2':
        return 1;
      case '/member-registration-step3':
        return 2;
      case '/member-registration-step4':
        return 3;
      default:
        final stepNumber = _extractStepNumber(normalized);
        return stepNumber != null ? stepNumber - 1 : null;
    }
  }

  /// Navigates user to the route matching the backend [screenName]. When
  /// [screenName] names one of the wizard's four internal steps, the
  /// resolved step index travels along as a route argument
  /// (`{'initialStep': int}`) so MemberRegistrationScreen can jump
  /// straight to it instead of always showing step 1 — see
  /// _MemberRegistrationScreenState.initState.
  static Future<void> navigateToScreen(
    String? screenName, {
    bool offAll = false,
  }) async {
    final route = mapScreenNameToRoute(screenName);
    final initialStep = initialStepFor(screenName);

    final arguments = initialStep != null
        ? {'initialStep': initialStep}
        : null;

    if (offAll) {
      Get.offAllNamed(route, arguments: arguments);
    } else {
      Get.toNamed(route, arguments: arguments);
    }
  }
}
