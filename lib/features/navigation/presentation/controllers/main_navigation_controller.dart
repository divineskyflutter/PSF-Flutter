import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/core/notifications/notification_navigator.dart';
import 'package:psf_application/core/notifications/notification_service.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';

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
  /// Tab order: 0 Profile, 1 Home (opens first), 2 Card, 3 Passbook.
  static const int profileTab = 0;
  static const int homeTab = 1;
  static const int cardTab = 2;
  static const int passbookTab = 3;

  final RxInt currentIndex = homeTab.obs;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void onReady() {
    super.onReady();
    _syncMemberData();

    // A notification tapped before the signed-in shell existed (app started
    // by the tap, or the member had to log in first) opens now.
    NotificationNavigator.instance.flushPending();

    // Ask for the notification permission once the member is inside the app.
    NotificationService.instance.requestPermissionIfNeeded();
  }

  void changeTab(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index;
    _syncMemberData();
  }

  /// Pulls the member's latest record whenever the signed-in shell opens or
  /// a tab is switched (see `ProfileController.refreshMemberData` — silent
  /// and rate-limited, so quick tab hopping doesn't spam the API).
  void _syncMemberData() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshMemberData(silent: true);
    }
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();

  void closeDrawer() => scaffoldKey.currentState?.closeDrawer();
}
