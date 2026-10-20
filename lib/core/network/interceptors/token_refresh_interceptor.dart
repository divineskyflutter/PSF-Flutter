import 'package:dio/dio.dart';

import 'package:psf_application/app/constants/api_end_points.dart';

import '../auth/token_refresher.dart';

/// Handles a 401 on any API call: transparently refreshes the token pair
/// (see [TokenRefresher]), saves the new pair, and retries the failed
/// request — the original caller just sees its normal successful response.
/// The user sees no error toast; any global loader keeps spinning until the
/// retry returns.
///
/// If the server REJECTS the refresh token (expired / revoked) the session
/// ends: the member is signed out and sent to the login choice with a
/// "session expired" message. A refresh that merely fails because of the
/// network does NOT log anyone out — the original error is passed on and the
/// next call tries again.
///
/// (Tokens that expire are normally renewed even earlier, before the request
/// is sent — see `AuthInterceptor`; this covers a token the server refuses
/// for any other reason.)
///
/// Registered once, in `DioClient.create`, ahead of `ErrorInterceptor` —
/// so a 401 that gets fixed here never reaches `ErrorInterceptor` as a
/// user-facing error at all.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(this._dio);

  /// The exact Dio instance this interceptor is attached to — reused to
  /// retry the failed request (via [Dio.fetch]) so the retry goes through
  /// every other interceptor exactly like a normal request (picking up
  /// the freshly-refreshed Authorization header from `AuthInterceptor`).
  final Dio _dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = requestOptions.extra['isTokenRetry'] == true;
    final isSessionCall = requestOptions.path == ApiEndPoints.refreshToken ||
        requestOptions.path == ApiEndPoints.login;

    if (!isUnauthorized || alreadyRetried || isSessionCall) {
      handler.next(err);
      return;
    }

    final result = await TokenRefresher.refresh();

    if (result.rejected) {
      await TokenRefresher.endSession();
      handler.next(err);
      return;
    }

    final newAccessToken = result.accessToken;

    if (newAccessToken == null) {
      // Refresh couldn't run (no connection, server hiccup): keep the
      // session, let this call fail normally.
      handler.next(err);
      return;
    }

    try {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra['isTokenRetry'] = true;

      final retriedResponse = await _dio.fetch(requestOptions);
      handler.resolve(retriedResponse);
    } on DioException catch (retryError) {
      // The retry itself failed — surface THAT error (not the stale 401).
      // It already went through ErrorInterceptor on its own trip, so it is
      // rejected straight to the caller instead of being toasted twice.
      handler.reject(retryError);
    } catch (_) {
      handler.next(err);
    }
  }
}
