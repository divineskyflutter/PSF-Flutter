import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:psf_application/core/storage/app_secure_storage.dart';

import 'fcm_token_service.dart';
import 'notification_display.dart';
import 'notification_navigator.dart';

/// Runs when a push arrives while the app is in the BACKGROUND or KILLED
/// (a separate isolate, so it must be a top-level function).
///
/// A message with a `notification` block is already drawn by Android itself
/// in this state (with the channel/sound/icon named in AndroidManifest.xml) —
/// drawing it again would show two notifications, so it is skipped. Only a
/// data-only message (nothing for Android to draw) is drawn here.
@pragma('vm:entry-point')
Future<void> psfFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (_) {
    return; // Firebase not configured: nothing to do
  }

  if (message.notification != null) return; // Android already drew it

  await NotificationDisplay.show(message);
}

/// Push notifications, end to end — ONE notification per message in every app
/// state:
///
/// | app state  | message has `notification` | data-only                        |
/// |------------|----------------------------|----------------------------------|
/// | open       | drawn here (onMessage)     | drawn here (onMessage)           |
/// | background | drawn by Android           | drawn by the background handler  |
/// | killed     | drawn by Android           | drawn by the background handler  |
///
/// A tap opens the screen named in `data.route` ([NotificationNavigator]).
/// Sound, icon and channel are ours ([NotificationDisplay]); the backend needs
/// to send no channel id.
///
/// Safe without a Firebase project: when `google-services.json` isn't in the
/// build, [init] just logs that push is off and the app runs as normal.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _firebaseReady = false;

  /// Whether this build has a working Firebase config (push can work).
  bool get isFirebaseReady => _firebaseReady;

  bool _initialised = false;

  /// Call once at start-up, after the core services exist. Never throws and
  /// never delays start-up by more than a few seconds.
  Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    try {
      // 1. Local notifications + our channel — no Firebase needed.
      await NotificationDisplay.initialize(onTap: _onLocalNotificationTap);

      // App was launched from killed by tapping a notification we drew.
      final launch = await NotificationDisplay.launchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        NotificationNavigator.instance.handleTap(
          NotificationDisplay.parsePayload(launch!.notificationResponse?.payload),
        );
      }

      // Test aid: `--dart-define=PSF_NOTIF_TEST=true` draws a sample notification
      // a few seconds after start-up (works without Firebase) to check the
      // channel, chime, icon and tap.
      if (const bool.fromEnvironment('PSF_NOTIF_TEST')) {
        Future.delayed(const Duration(seconds: 10), () => showTestNotification());
      }

      // 2. Firebase (push). No google-services.json -> skip, quietly.
      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp().timeout(const Duration(seconds: 6));
        }
        _firebaseReady = true;
      } catch (e) {
        debugPrint('Notifications: push is off - Firebase is not configured ($e)');
        return;
      }

      final messaging = FirebaseMessaging.instance;

      FirebaseMessaging.onBackgroundMessage(psfFirebaseMessagingBackgroundHandler);

      // We draw foreground notifications ourselves; keep the system from
      // drawing a second copy where it would (iOS).
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpened);
      messaging.onTokenRefresh.listen(FcmTokenService.instance.onTokenRefreshed);

      // App was launched from killed by tapping a notification Android drew.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        NotificationNavigator.instance.handleTap(initial.data, messageId: initial.messageId);
      }

      // Keep the server's copy of this phone's token current.
      unawaited(FcmTokenService.instance.syncIfNeeded());

      // Test aid: `--dart-define=PSF_NOTIF_PUSH_TEST=true` re-sends this phone's
      // token a few seconds after start-up. The backend answers every token
      // upload with a push, so this makes a REAL push arrive on demand — to
      // test it with the app open, in the background (press Home right after
      // launching) and so on.
      if (const bool.fromEnvironment('PSF_NOTIF_PUSH_TEST')) {
        Future.delayed(const Duration(seconds: 7), () async {
          final memberId = await AppSecureStorage.getMemberId();
          if (memberId != null && memberId > 0) {
            await FcmTokenService.instance.syncAfterLogin(memberId);
          }
        });
      }
    } catch (e, stack) {
      debugPrint('Notifications: setup failed ($e)\n$stack');
    }
  }

  /// Asks for the notification permission (Android 13+ shows a system dialog)
  /// — once, while it hasn't been decided. Call it when the member is inside
  /// the app (not at start-up), so the request makes sense to them.
  Future<void> requestPermissionIfNeeded() async {
    if (!_firebaseReady) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('Notifications: permission request failed ($e)');
    }
  }

  /// Draws a sample notification (sound / icon / tap check). For testing.
  Future<void> showTestNotification({String route = '/notifications'}) =>
      NotificationDisplay.showTest(route: route);

  // ----------------------------------------------------------------- handlers

  /// A push arrived with the app OPEN: Android doesn't draw it, we do.
  void _onForegroundMessage(RemoteMessage message) {
    NotificationDisplay.show(message);
  }

  /// Tap on a notification Android drew while the app was in the background.
  void _onNotificationOpened(RemoteMessage message) {
    NotificationNavigator.instance.handleTap(message.data, messageId: message.messageId);
  }

  /// Tap on a notification we drew ourselves.
  void _onLocalNotificationTap(NotificationResponse response) {
    NotificationNavigator.instance.handleTap(
      NotificationDisplay.parsePayload(response.payload),
    );
  }
}
