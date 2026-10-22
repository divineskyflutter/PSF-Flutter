import 'dart:convert';
import 'dart:ui' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_constants.dart';

/// Draws notifications ourselves, with the PSF channel, sound and icon.
///
/// Used in two places: while the app is OPEN (Android doesn't draw FCM
/// messages then) and — for data-only messages — while it is in the
/// background or killed, from the background isolate. Everything here only
/// touches `flutter_local_notifications`, so it works in any isolate and needs
/// no Firebase project.
///
/// One notification, never two: each message gets a stable id (from its FCM
/// message id), and an id already drawn in this isolate is not drawn again.
class NotificationDisplay {
  NotificationDisplay._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool _initialised = false;

  /// Message ids drawn recently in this isolate (newest last).
  static final List<int> _recent = [];

  /// Sets the plugin up and creates the channel. [onTap] is only given by the
  /// main isolate (it opens the tapped notification's screen); the background
  /// isolate passes nothing.
  static Future<void> initialize({DidReceiveNotificationResponseCallback? onTap}) async {
    if (_initialised && onTap == null) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(NotificationConstants.smallIcon),
      ),
      onDidReceiveNotificationResponse: onTap,
    );

    // Android 8+: sound, vibration and importance live on the channel. Created
    // here (not in the payload) so even notifications Android draws by itself
    // use it — see default_notification_channel_id in AndroidManifest.xml.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            NotificationConstants.channelId,
            NotificationConstants.channelName,
            description: NotificationConstants.channelDescription,
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound(NotificationConstants.soundResource),
            enableVibration: true,
          ),
        );

    _initialised = true;
  }

  /// The notification (if any) that launched the app from killed.
  static Future<NotificationAppLaunchDetails?> launchDetails() =>
      _plugin.getNotificationAppLaunchDetails();

  /// Draws [message]. Title/body come from its `notification` block, or from
  /// `data.title` / `data.body` for a data-only message. The whole `data` map
  /// travels as the payload, so a tap knows which screen to open.
  static Future<void> show(RemoteMessage message) async {
    await initialize();

    final title = _first(message.notification?.title, NotificationConstants.titleFrom(message.data)) ?? 'PSF';
    final body = _first(message.notification?.body, NotificationConstants.bodyFrom(message.data)) ?? '';

    final id = (message.messageId ?? '$title|$body|${message.data}').hashCode & 0x7fffffff;
    if (_recent.contains(id)) return; // already drawn
    _recent.add(id);
    if (_recent.length > 30) _recent.removeAt(0);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(title, body),
      payload: jsonEncode(message.data),
    );
  }

  /// Draws a sample notification — to check sound, icon and tap without
  /// waiting for the backend.
  static Future<void> showTest({String route = '/notifications'}) async {
    await initialize();
    // Android 13+ needs the notification permission before anything is drawn.
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final data = {NotificationConstants.routeKey: route};
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      title: 'PSF test notification',
      body: 'If you can hear the chime and see this, notifications work. Tap to open $route.',
      notificationDetails: _details(
        'PSF test notification',
        'If you can hear the chime and see this, notifications work. Tap to open $route.',
      ),
      payload: jsonEncode(data),
    );
  }

  static NotificationDetails _details(String title, String body) {
    // Plain big-text style, no large icon: it looks the same as a notification
    // Android draws itself (the messaging style we used before showed only the
    // small app icon on Samsung One UI).
    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        channelDescription: NotificationConstants.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(NotificationConstants.soundResource),
        icon: NotificationConstants.smallIcon,
        color: const Color(0xFF258077),
        styleInformation: BigTextStyleInformation(body, contentTitle: title),
      ),
    );
  }

  static String? _first(String? a, dynamic b) {
    if (a != null && a.trim().isNotEmpty) return a;
    final text = b?.toString();
    return (text != null && text.trim().isNotEmpty) ? text : null;
  }

  /// Payload (JSON text) of a tapped local notification -> its `data` map.
  static Map<String, dynamic> parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return const {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('Notification: bad payload ($e)');
    }
    return const {};
  }
}
