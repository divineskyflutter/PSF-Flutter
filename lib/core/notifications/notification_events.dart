import 'package:flutter/foundation.dart';

/// Tells the rest of the app that a push notification just arrived while the
/// app is open, so the notification list can refresh itself. The value only
/// counts up; listen to it and reload when it changes.
class NotificationEvents {
  NotificationEvents._();

  static final ValueNotifier<int> received = ValueNotifier<int>(0);

  static void push() => received.value++;
}
