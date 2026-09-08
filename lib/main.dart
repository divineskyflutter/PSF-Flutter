import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/config/app_flavor.dart';
import 'package:psf_application/app/config/env/env.dart';
import 'package:psf_application/core/theme/app_theme.dart';
import 'package:psf_application/core/theme/theme_controller.dart';
import 'package:psf_application/app/routes/app_pages.dart';
import 'package:psf_application/shared/widgets/loaders/app_loader.dart';
import 'package:psf_application/shared/widgets/loaders/app_loader_controller.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

import 'core/localization/app_translation.dart';
import 'core/localization/language_controller.dart';
import 'core/storage/app_prefs.dart';

void startApp(/*FirebaseOptions firebaseOptions*/) async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // ============================================================
    // Load Environment
    // ============================================================

    Env.load(AppFlavor.flavor);

    // ============================================================
    // Initialize Local Storage
    // ============================================================

    await AppPrefs.init();

    // ============================================================
    // Lock Orientation
    // ============================================================

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    // ============================================================
    // Firebase
    // ============================================================

    // await Firebase.initializeApp(options: firebaseOptions);

    // ============================================================
    // Core Controllers
    // ============================================================
    Get.put(
      ThemeController(),
      permanent: true,
    );

    Get.put(
      LanguageController(),
      permanent: true,
    );

    Get.put(
      AppLoaderController(),
      permanent: true,
    );

    // ConnectivityService hides the global loader when a connection is lost,
    // so the loader must be registered before this service starts listening.
    Get.put(
      ConnectivityService(),
      permanent: true,
    );
    // Initialize Core Services
    // await Get.putAsync(() => DeepLinkService().init());
    // await Get.putAsync(() => NotificationService().init());
    runApp(const MyApp());
  }, (error, stack) {
    // Was just `debugPrint('App Error: $error')` — logging only the
    // message and dropping the stack trace made every zone error
    // (like the "Null check operator used on a null value" during the
    // resume-registration flow) unfindable: no file, no line, nothing
    // to grep for. Print the stack too so the next occurrence points at
    // the actual call site.
    debugPrint('App Error: $error\n$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() => GetMaterialApp(
          translations: AppTranslation(),
          locale: Get.find<LanguageController>().locale.value,

          fallbackLocale: const Locale('en', 'US'),
          title: AppFlavor.isDev ? 'PSF Foundation Dev' : 'PSF Foundation',
          debugShowCheckedModeBanner: Env.config.showDebugBanner,

          // Theme Setup
          themeMode:
              themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          // Routes Setup
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          builder: (context, child) {
            return AppLoader.overlayRoot(
              child: child ?? const SizedBox.shrink(),
            );
          },
        ));
  }
}
