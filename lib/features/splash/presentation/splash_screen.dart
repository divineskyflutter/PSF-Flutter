import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../../../app/routes/app_routes.dart';
import 'package:psf_application/core/storage/app_prefs.dart';

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
      Future.delayed(const Duration(seconds: 7), () {
        // final isPending = AppPrefs.registrationStatus == 'pending';
        Get.offAllNamed(
            // isPending ? AppRoutes.registrationPending :
            AppRoutes.language);
      }
      );
  }


  @override
  Widget build(BuildContext context) {
    // We use context.theme.colorScheme to automatically adapt to dark/light mode
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(AppAssets.paperTexture, fit: BoxFit.cover),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
