import 'package:get/get.dart';

/// Owns which bottom-nav tab (Home / Loans / Profile) is showing inside
/// [MainNavigationScreen]. Deliberately just an index — each tab's own
/// screen keeps its own state alive via the `IndexedStack` in
/// `main_navigation_screen.dart`, so switching tabs never re-fetches data.
///
/// This is the "navigation" feature's own controller — it now also has
/// its own page (`main_navigation_screen.dart`), bindings
/// (`main_navigation_binding.dart`) and widgets
/// (`presentation/widgets/app_bottom_nav_bar.dart`), matching every other
/// feature's folder shape. There is deliberately NO data/domain layer
/// (no repository/datasource/model) here: which tab is selected is pure
/// UI state, never fetched from or sent to any API, so a repository would
/// have nothing real to call. If that ever changes — e.g. persisting the
/// last-opened tab, or per-tab badge counts coming from the backend —
/// that's the point to add one.
class MainNavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
  }
}
