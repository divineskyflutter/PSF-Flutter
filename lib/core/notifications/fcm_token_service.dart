import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/auth/no_auth_token_provider.dart';
import 'package:psf_application/core/network/dio_client.dart';
import 'package:psf_application/core/network/network_caller.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

import 'notification_service.dart';

/// Keeps the server's copy of this phone's FCM device token up to date, so the
/// backend can push to the signed-in member. Everything about the token lives
/// here — use it from anywhere:
///
/// * [syncAfterLogin] — right after a successful login (the access token is
///   needed by the API, so it must run after login; it runs inside the login
///   loader and never makes login fail).
/// * [onTokenRefreshed] — FCM rotated the token; wired up in
///   [NotificationService.init].
/// * [syncIfNeeded] — at app start, for a member who is already logged in.
/// * [onLogout] — forget this phone's token when the session ends.
///
/// The API (`POST /api/Member/UpdateDevicetoken {memberId, deviceToken}`)
/// needs the Bearer access token; the app's network layer adds it and renews
/// it when expired. The last token sent is remembered, so an unchanged token
/// is not uploaded again.
class FcmTokenService {
  FcmTokenService._();

  static final FcmTokenService instance = FcmTokenService._();

  NetworkCaller? _caller;

  /// `memberId:token` of an upload that is running right now. The start-up
  /// sync and FCM's own "new token" event can both fire within milliseconds of
  /// each other; without this the same token would be uploaded twice (and the
  /// backend, which pushes on every upload, would send two notifications).
  String? _uploading;

  NetworkCaller get _network =>
      _caller ??= NetworkCaller(DioClient.create(const NoAuthTokenProvider()));

  /// Current device token, or `null` when push isn't set up on this build.
  Future<String?> currentToken() async {
    if (!NotificationService.instance.isFirebaseReady) return null;
    try {
      final token = await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 8));
      debugPrint('FCM: device token ${token == null ? 'not available' : 'obtained'}');
      return token;
    } catch (e) {
      debugPrint('FCM: could not get a device token ($e)');
      return null;
    }
  }

  /// After a successful login: always upload (the member may have changed on
  /// this phone). Never throws; gives up after a few seconds so login is not
  /// held up.
  Future<void> syncAfterLogin(int memberId) async {
    try {
      await _sync(memberId, force: true).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('FCM: token upload after login skipped ($e)');
    }
  }

  /// At app start: upload only if the token differs from what was last sent
  /// for the logged-in member.
  Future<void> syncIfNeeded() async {
    final memberId = await AppSecureStorage.getMemberId();
    if (memberId == null || memberId <= 0) return;
    try {
      await _sync(memberId, force: false);
    } catch (e) {
      debugPrint('FCM: background token sync skipped ($e)');
    }
  }

  /// FCM issued a new token.
  Future<void> onTokenRefreshed(String token) async {
    final memberId = await AppSecureStorage.getMemberId();
    if (memberId == null || memberId <= 0) return; // not logged in: sent at next login
    if (AppPrefs.fcmSentToken == token && AppPrefs.fcmSentMemberId == memberId) return;
    try {
      await _upload(memberId, token);
    } catch (e) {
      debugPrint('FCM: refreshed token upload skipped ($e)');
    }
  }

  /// The session ended (logout, delete account, expired session). Invalidates
  /// this phone's token so it stops receiving the previous member's pushes,
  /// and forgets what was sent; a fresh token is made at the next login.
  Future<void> onLogout() async {
    try {
      await AppPrefs.setFcmSent(token: null, memberId: null);
      if (NotificationService.instance.isFirebaseReady) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (e) {
      debugPrint('FCM: clean-up on logout skipped ($e)');
    }
  }

  // --------------------------------------------------------------------------

  Future<void> _sync(int memberId, {required bool force}) async {
    final token = await currentToken();
    if (token == null || token.isEmpty) return;

    if (!force && AppPrefs.fcmSentToken == token && AppPrefs.fcmSentMemberId == memberId) {
      return; // server already has it
    }

    await _upload(memberId, token);
  }

  Future<void> _upload(int memberId, String token) async {
    final key = '$memberId:$token';
    if (_uploading == key) return; // this exact upload is already running
    _uploading = key;
    try {
      await _doUpload(memberId, token);
    } finally {
      _uploading = null;
    }
  }

  Future<void> _doUpload(int memberId, String token) async {
    // Offline: skip quietly (the next sync retries) instead of raising the
    // app-wide "No internet" dialog for a background upload.
    if (Get.isRegistered<ConnectivityService>() &&
        !Get.find<ConnectivityService>().hasInternet) {
      return;
    }

    final response = await _network.postRequest(
      ApiEndPoints.updateDeviceToken,
      body: {'memberId': memberId, 'deviceToken': token},
      suppressErrorToast: true,
      suppressNetworkDialog: true,
    );

    // The token itself is never logged.
    debugPrint(
      'FCM: device token upload for member $memberId ${response.status ? 'ok' : 'rejected (${response.message})'}',
    );

    if (response.status) {
      await AppPrefs.setFcmSent(token: token, memberId: memberId);
    }
  }
}
