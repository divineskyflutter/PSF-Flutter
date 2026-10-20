// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';

import 'package:psf_application/app/constants/api_end_points.dart';

import '../auth/auth_token_provider.dart';
import '../auth/token_manager.dart';
import '../auth/token_refresher.dart';

/// Adds `Authorization: Bearer <access token>` to outgoing requests.
///
/// The backend now protects its member APIs, so the token is sent on EVERY
/// request whenever one exists — including calls that were written with
/// `requireToken: false` back when nothing was protected (profile, PDF
/// download, ...). Only the two calls that create/renew the session never
/// carry it: login (no token yet) and token refresh (the old access token is
/// the very thing that expired). Public endpoints (enum bundle, banners)
/// simply ignore the header.
///
/// The token is also renewed BEFORE it is used when it has expired (or is
/// about to): the server does not always answer an expired token with a clean
/// 401 (some endpoints fail with a 500 instead), so waiting for a 401 to
/// trigger the refresh is not enough. See [TokenRefresher].
class AuthInterceptor extends Interceptor {
  final AuthTokenProvider tokenProvider;
  AuthInterceptor(this.tokenProvider);

  /// Renew when fewer than this many seconds are left.
  static const _renewBeforeExpirySeconds = 60;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isSessionCall =
        options.path == ApiEndPoints.login || options.path == ApiEndPoints.refreshToken;

    if (!isSessionCall) {
      var token = tokenProvider.getToken();

      final left = TokenRefresher.secondsLeft(token);
      if (token != null && left != null && left < _renewBeforeExpirySeconds) {
        final result = await TokenRefresher.refresh();

        if (result.rejected) {
          // Refresh token no longer accepted: the session is over.
          await TokenRefresher.endSession();
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              error: 'Session expired',
            ),
          );
          return;
        }

        // On success use the new token; if the refresh was merely unavailable
        // (offline), still send the old one — the normal 401 handling and
        // error paths take over from there.
        token = result.accessToken ?? TokenManager.instance.accessToken ?? token;
      }

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
