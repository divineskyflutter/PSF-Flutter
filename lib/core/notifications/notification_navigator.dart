import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';

import 'notification_constants.dart';
import 'notification_routes.dart';

/// Opens the screen a notification names when the member taps it — whether the
/// tap happened with the app open, in the background, or killed.
///
/// A route can only be opened once the signed-in shell (the bottom-bar screen)
/// exists. A tap that arrives earlier — app cold-started by the tap, still on
/// the splash, or the member isn't logged in — is kept as "pending" and opened
/// the moment the shell appears ([flushPending], called when it is ready), so
/// after login the member lands straight on the page. A pending route that
/// nobody reached within [_pendingLifetime] is dropped.
///
/// Opening never blocks normal navigation: tabs just switch, and pages are
/// pushed on top of the current stack, so Back works as usual.
class NotificationNavigator {
  NotificationNavigator._();

  static final NotificationNavigator instance = NotificationNavigator._();

  static const _pendingLifetime = Duration(minutes: 30);

  String? _pendingRoute;
  DateTime? _pendingSince;

  /// Recently handled taps, so one tap reported through two channels (for
  /// example FCM's initial message and the local-notification launch details)
  /// opens the screen only once.
  final List<String> _handled = [];

  /// A notification was tapped. [data] is its `data` map.
  void handleTap(Map<String, dynamic> data, {String? messageId}) {
    final route = (data[NotificationConstants.routeKey] ??
            data[NotificationConstants.routeKeyAlias])
        ?.toString();

    final key = messageId ?? '${route ?? ''}|${DateTime.now().millisecondsSinceEpoch ~/ 2000}';
    if (_handled.contains(key)) return;
    _handled.add(key);
    if (_handled.length > 20) _handled.removeAt(0);

    if (route == null || route.trim().isEmpty) return; // nothing to open: app just opens

    _pendingRoute = route;
    _pendingSince = DateTime.now();
    flushPending();
  }

  /// Opens the pending route if the shell is ready. Safe to call any time.
  void flushPending() {
    final route = _pendingRoute;
    if (route == null) return;

    if (_pendingSince != null &&
        DateTime.now().difference(_pendingSince!) > _pendingLifetime) {
      _clear();
      return;
    }

    if (!Get.isRegistered<MainNavigationController>()) return; // not ready yet

    _clear();

    final target = NotificationRoutes.resolve(route);
    if (target == null) {
      debugPrint('Notification: unsupported route "$route" ignored');
      return;
    }

    // After the current frame, so it never fires in the middle of a build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _open(target));
  }

  void _open(NotificationTarget target) {
    if (!Get.isRegistered<MainNavigationController>()) return;
    final nav = Get.find<MainNavigationController>();

    // Already on the screen the notification names: nothing to do (no flicker,
    // no second copy of the page on the stack).
    final tab = target.tabIndex;
    if (target.page != null && Get.currentRoute == target.page) return;
    if (tab != null &&
        Get.currentRoute == AppRoutes.home &&
        nav.currentIndex.value == tab) {
      return;
    }

    nav.closeDrawer();

    // Back to the shell first (closes any dialog / page above it), so the
    // target opens from a known place and Back returns to the member's tab.
    Get.until((route) => route.settings.name == AppRoutes.home);

    if (tab != null) {
      nav.changeTab(tab);
    } else if (target.page != null) {
      Get.toNamed(target.page!);
    }
  }

  void _clear() {
    _pendingRoute = null;
    _pendingSince = null;
  }
}
