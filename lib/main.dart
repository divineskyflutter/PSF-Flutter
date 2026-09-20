import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'core/network/auth/token_manager.dart';
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

    // Loads month/day names for every locale so dates can be shown in the
    // selected app language (see AppDateFormat).
    await initializeDateFormatting();

    // Seeds TokenManager's in-memory access/refresh token from secure
    // storage before any request goes out — AuthTokenProvider.getToken()
    // is synchronous, so this can't happen lazily on first use. See
    // TokenManager's doc comment.
    await TokenManager.instance.loadFromStorage();

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
