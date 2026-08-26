import 'package:get/get.dart';
import 'package:psf_application/features/language/presentation/controllers/language_selection_controller.dart';

class LanguageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LanguageSelectionController>(LanguageSelectionController.new);
  }
}
