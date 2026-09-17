import 'package:psf_application/core/storage/app_secure_storage.dart';

/// Single in-memory source of truth for the current access/refresh token
/// pair, backing [SessionTokenProvider] (used by every `AuthInterceptor`)
/// and consulted/updated by `TokenRefreshInterceptor` — kept as one
/// singleton so the token used to sign outgoing requests, the token
/// refreshed on a 401, and the token persisted to secure storage can never
/// drift out of sync with each other.
///
/// `AuthTokenProvider.getToken()` is synchronous (Dio needs the header
/// value at request-build time), but `AppSecureStorage` is async — so the
/// token also lives here, in memory, and [loadFromStorage] must run once
/// at app startup (see `main.dart`) to seed it before the first
/// authenticated request goes out.
class TokenManager {
  TokenManager._();

  static final TokenManager instance = TokenManager._();

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  String? get refreshToken => _refreshToken;

  Future<void> loadFromStorage() async {
    _accessToken = await AppSecureStorage.getAccessToken();
    _refreshToken = await AppSecureStorage.getRefreshToken();
  }

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await AppSecureStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await AppSecureStorage.clearTokens();
  }
}
