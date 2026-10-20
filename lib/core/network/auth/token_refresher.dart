import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/notifications/fcm_token_service.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

import 'token_manager.dart';

/// Outcome of one refresh attempt.
class RefreshResult {
  const RefreshResult.success(String this.accessToken) : rejected = false;
  const RefreshResult.rejected() : accessToken = null, rejected = true;
  const RefreshResult.unavailable() : accessToken = null, rejected = false;

  final String? accessToken;

  /// The server said the refresh token is not valid any more.
  final bool rejected;
}

/// The one place the access/refresh token pair is renewed — used both by
/// `AuthInterceptor` (renew BEFORE sending a request whose token is expired
/// or about to be) and `TokenRefreshInterceptor` (renew AFTER a 401).
///
/// Concurrent callers share a single `RefreshToken` request: only the first
/// triggers it, the rest await the same future. The new pair replaces the old
/// one in memory and secure storage.
class TokenRefresher {
  TokenRefresher._();

  static Future<RefreshResult>? _inFlight;

  static bool _endingSession = false;

  /// The refresh token itself is invalid/expired — there is no way to
  /// silently recover, so the session ends: clear everything session-related
  /// and send the member back to sign in, same as `ProfileController.logout()`.
  /// Safe to call from several places at once; it only runs once.
  static Future<void> endSession() async {
    if (_endingSession) return;
    _endingSession = true;

    try {
      await FcmTokenService.instance.onLogout();
      await TokenManager.instance.clear();
      await AppSecureStorage.deleteMemberId();
      await AppSecureStorage.clearLoggedInUser();
      await AppPrefs.setYojnaId(null);
      await AppPrefs.setRegistrationCompleted(false);

      ToastUtil.error('session_expired_message'.tr);
      Get.offAllNamed(AppRoutes.authChoice);
    } finally {
      _endingSession = false;
    }
  }

  static Future<RefreshResult> refresh() {
    return _inFlight ??= _perform().whenComplete(() {
      _inFlight = null;
    });
  }

  /// Seconds until the JWT [token] expires (negative when already expired);
  /// `null` when it can't be read.
  static int? secondsLeft(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final exp = (jsonDecode(payload) as Map)['exp'];
      if (exp is! num) return null;
      return exp.toInt() - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }

  static Future<RefreshResult> _perform() async {
    final refreshToken = TokenManager.instance.refreshToken;

    if (refreshToken == null || refreshToken.isEmpty) {
      return const RefreshResult.rejected();
    }

    try {
      // A bare Dio with no interceptors — reusing the app's Dio here would run
      // the auth interceptors again and could recurse.
      final refreshDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json', 'accept': '*/*'},
        ),
      );

      final response = await refreshDio.post(
        ApiEndPoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final tokens = _extractTokens(response.data);

      // The API answers HTTP 200 with `status:false` ("Un-Authorized") for a
      // refresh token it does not accept.
      if (tokens == null) return const RefreshResult.rejected();

      final newRefresh = tokens.refreshToken;

      await TokenManager.instance.setTokens(
        accessToken: tokens.accessToken,
        refreshToken: (newRefresh != null && newRefresh.isNotEmpty) ? newRefresh : refreshToken,
      );

      return RefreshResult.success(tokens.accessToken);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      // 401/403 from the refresh call itself = refresh token not accepted.
      if (code == 401 || code == 403) return const RefreshResult.rejected();
      return const RefreshResult.unavailable();
    } catch (_) {
      return const RefreshResult.unavailable();
    }
  }

  /// Finds the token pair in whichever place the response carries it: the
  /// envelope's `data`, `data.authorizeToken` (same shape as the login
  /// response), or the top level.
  static ({String accessToken, String? refreshToken})? _extractTokens(dynamic body) {
    if (body is! Map) return null;

    final data = body['data'];
    final candidates = <Map>[
      if (data is Map && data['authorizeToken'] is Map) data['authorizeToken'] as Map,
      if (data is Map) data,
      body,
    ];

    for (final map in candidates) {
      final access = map['accessToken']?.toString();
      if (access != null && access.isNotEmpty) {
        return (accessToken: access, refreshToken: map['refreshToken']?.toString());
      }
    }
    return null;
  }
}
