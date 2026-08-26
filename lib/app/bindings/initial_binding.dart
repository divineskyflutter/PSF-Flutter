import 'package:get/get.dart';
import 'package:psf_application/core/theme/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ThemeController>(ThemeController(), permanent: true);
    // You can inject other global controllers or repositories here
    // e.g., Get.put<AuthService>(AuthService(), permanent: true);
  }
}
