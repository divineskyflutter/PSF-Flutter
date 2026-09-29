import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../../../app/routes/app_routes.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/widgets/common/ornamental_divider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 7), _routeNext);

    // There used to be an `AppPrefs.setOnboardingCompleted(false)` call
    // here — it force-reset the "has the member finished onboarding" flag
    // back to false on every single app launch, right before
    // LanguageSelectionController checks that same flag to decide whether
    // to show onboarding again. That's why onboarding kept showing every
    // time instead of only on first install. OnboardingScreen already
    // sets this to true once, when the member finishes onboarding (see
    // its _goToAuthSelection) — nothing here should ever undo that.
  }

  // ============================================================
  // ROUTING
  //
  // Was previously unconditional -> AppRoutes.language on every launch,
  // then briefly skipped straight to auth-choice once a language had ever
  // been picked (since that preference is saved permanently) — which
  // meant language selection only ever showed once, on the very first
  // install. That's not what's wanted: the language screen should show on
  // every single launch — right up until the member has actually
  // completed registration and reached Home — and should start showing
  // again after logout, same as a fresh install.
  //
  // So the ONLY way to skip the language screen now is the fully-done
  // case:
  //   • Registration fully completed (see
  //     RegistrationPreviewScreen._completeRegistration -> AppPrefs
  //     .setRegistrationCompleted) AND a member session is still active
  //     (AppSecureStorage's memberId — cleared on logout, see
  //     ProfileController.logout) -> straight to Home.
  //   • Anything else (brand-new install, mid-registration, or logged
  //     out) -> language screen, every time.
  // ============================================================

  Future<void> _routeNext() async {
    if (!mounted) return;

    final memberId = await AppSecureStorage.getMemberId();
    final hasActiveSession = memberId != null && memberId > 0;

    if (AppPrefs.isRegistrationCompleted && hasActiveSession) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    Get.offAllNamed(AppRoutes.language);
  }


  @override
  Widget build(BuildContext context) {
    // We use context.theme.colorScheme to automatically adapt to dark/light mode
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // A plain fill in the same cream tone the rest of the app uses,
          // instead of the marble/paper texture image this used to show.
          const Positioned.fill(
            child: ColoredBox(color: AppColors.background),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  SizedBox(
                    width: 320.px(context),
                    height: 400.px(context),
                    child: Image.asset(
                      "assets/images/logo/logo.gif",
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "PARIVAR SURKSHA",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "FOUNDATION",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 16),

                  OrnamentalDivider(
                    color: colorScheme.primary,
                  ),

                  const SizedBox(height: 16),

                  // Registration/legal identifiers — same values printed on
                  // every page of the registration PDF (see
                  // RegistrationPreviewScreen's fixed footer text), reused
                  // here rather than re-typed so the two stay in sync.
                  const _SplashRegistrationInfo(
                    cin: 'U94990GJ2025NPL167764',
                    pan: 'AAQCP1978H',
                    licenseNo: '173515',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon+label rows for the foundation's registration identifiers,
/// shown below the logo/name on the splash screen so a first-time user
/// sees the organization is a registered entity before anything else
/// loads.
class _SplashRegistrationInfo extends StatelessWidget {
  const _SplashRegistrationInfo({
    required this.cin,
    required this.pan,
    required this.licenseNo,
  });

  final String cin;
  final String pan;
  final String licenseNo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SplashInfoRow(
          icon: Icons.apartment_outlined,
          label: 'CIN',
          value: cin,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 8),
        _SplashInfoRow(
          icon: Icons.badge_outlined,
          label: 'PAN',
          value: pan,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 8),
        _SplashInfoRow(
          icon: Icons.verified_outlined,
          label: 'License No.',
          value: licenseNo,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _SplashInfoRow extends StatelessWidget {
  const _SplashInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 13,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              TextSpan(
                text: value,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
