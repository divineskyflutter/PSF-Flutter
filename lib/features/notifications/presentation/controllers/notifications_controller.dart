import 'package:get/get.dart';

/// State of the Notifications screen (opened from the bell on Home, or by a
/// push notification whose `data.route` is `/notifications`).
///
/// The notification-list API doesn't exist yet, so there is nothing to load:
/// [refresh] is the one place to call it when it does (and to fill the list
/// the screen then shows, with read / unread handled by that API). Until then
/// the screen shows its empty state and pull-to-refresh simply completes.
class NotificationsController extends GetxController {
  final RxBool isLoading = false.obs;

  /// Pull-to-refresh. TODO(notifications-api): fetch the member's list here.
  Future<void> refresh() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      // No API yet.
    } finally {
      isLoading.value = false;
    }
  }
}
