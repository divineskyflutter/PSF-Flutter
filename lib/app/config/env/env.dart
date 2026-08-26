import '../app_flavor.dart';
import 'env_dev.dart';
import 'env_prod.dart';

class Env {
  static late EnvConfig config;

  static void load(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        config = EnvConfig(
          baseUrl: EnvDev.baseUrl,
          showDebugBanner: true,
        );
        break;

      case Flavor.prod:
        config = EnvConfig(
          baseUrl: EnvProd.baseUrl,
          showDebugBanner: false,
        );
        break;
    }
  }
}

class EnvConfig {
  final String baseUrl;
  final bool showDebugBanner;


  EnvConfig({
    required this.baseUrl,
    required this.showDebugBanner,
  });
}
