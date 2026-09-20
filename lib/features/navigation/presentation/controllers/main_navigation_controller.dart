import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Owns which bottom-nav tab (Profile / Home / Card) is showing inside
/// [MainNavigationScreen], plus the shell's [Scaffold] key so any tab (e.g.
/// the Home header's menu button) can open the side drawer.
///
/// Deliberately just an index + a key — each tab's own screen keeps its own
/// state alive via the `IndexedStack` in `main_navigation_screen.dart`, so
/// switching tabs never re-fetches data. There is deliberately NO
/// data/domain layer here: which tab is selected is pure UI state, never
/// fetched from or sent to any API.
class MainNavigationController extends GetxController {
  /// Tab order: 0 Profile, 1 Home (center, opens first), 2 Card.
  static const int profileTab = 0;
  static const int homeTab = 1;
  static const int cardTab = 2;

  final RxInt currentIndex = homeTab.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void changeTab(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();

  void closeDrawer() => scaffoldKey.currentState?.closeDrawer();
}
