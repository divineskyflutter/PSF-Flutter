import 'package:get/get.dart';

/// Owns which bottom-nav tab (Home / Loans / Profile) is showing inside
/// [MainNavigationScreen]. Deliberately just an index — each tab's own
/// screen keeps its own state alive via the `IndexedStack` in
/// `main_navigation_screen.dart`, so switching tabs never re-fetches data.
class MainNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
  }
}
