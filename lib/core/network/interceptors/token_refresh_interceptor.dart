import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/network/auth/token_manager.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

/// The ONE place session-expiry is handled for every API call in the app.
/// No feature/repository/controller needs to know an access token can
/// expire — a request made with an expired token gets a 401, this
/// interceptor transparently refreshes the token and retries it, and the
/// original caller just sees its normal successful response (or, if the
/// refresh itself fails, a normal error — see [_forceLogout]).
///
/// Registered once, in `DioClient.create`, ahead of `ErrorInterceptor` —
/// so a 401 that gets fixed here never reaches `ErrorInterceptor` as a
/// user-facing "session expired" toast at all; only a 401 that survives a
/// refresh attempt (or a refresh-token that has itself expired) does.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(this._dio);

  /// The exact Dio instance this interceptor is attached to — reused to
  /// retry the failed request (via [Dio.fetch]) so the retry goes through
  /// every other interceptor exactly like a normal request (picking up
  /// the freshly-refreshed Authorization header from `AuthInterceptor`).
  final Dio _dio;

  /// Coordinates concurrent 401s (e.g. three widgets each firing an API
  /// call the moment a token expires): only the FIRST one triggers a real
  /// `RefreshToken` call; every other 401 that arrives while that call is
  /// still in flight just awaits this same future instead of firing its
  /// own duplicate refresh request.
  static Future<String?>? _refreshFuture;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = requestOptions.extra['isTokenRetry'] == true;
    final isRefreshCall = requestOptions.path == ApiEndPoints.refreshToken;

    if (!isUnauthorized || alreadyRetried || isRefreshCall) {
      handler.next(err);
      return;
    }

    final newAccessToken = await _refreshAccessToken();

    if (newAccessToken == null) {
      await _forceLogout();
      handler.next(err);
      return;
    }

    try {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['isTokenRetry'] = true;

      final retriedResponse = await _dio.fetch(requestOptions);
      handler.resolve(retriedResponse);
    } catch (_) {
      // The retry itself failed (still unauthorized, or a fresh network
      // error) — fall through to the normal error path instead of
      // silently swallowing it.
      handler.next(err);
    }
  }

  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = TokenManager.instance.refreshToken;

    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    try {
      // A bare Dio with no interceptors — reusing `_dio` here would run
      // this very interceptor again, and a 401 on the refresh call itself
      // would recurse straight back into this method.
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

      final body = response.data;
      if (body is! Map || body['status'] != true) return null;

      final data = body['data'];
      if (data is! Map) return null;

      final newAccessToken = data['accessToken']?.toString();
      final newRefreshToken = data['refreshToken']?.toString();

      if (newAccessToken == null || newAccessToken.isEmpty) return null;

      await TokenManager.instance.setTokens(
        accessToken: newAccessToken,
        refreshToken: (newRefreshToken?.isNotEmpty ?? false)
            ? newRefreshToken!
            : refreshToken,
      );

      return newAccessToken;
    } catch (_) {
      return null;
    }
  }

  /// The refresh token itself is invalid/expired — there is no way to
  /// silently recover, so the session ends: clear everything session-
  /// related and send the member back to sign in, same as
  /// `ProfileController.logout()`.
  Future<void> _forceLogout() async {
    await TokenManager.instance.clear();
    await AppSecureStorage.deleteMemberId();
    await AppSecureStorage.clearLoggedInUser();

    ToastUtil.error('session_expired_message'.tr);
    Get.offAllNamed(AppRoutes.authChoice);
  }
}
