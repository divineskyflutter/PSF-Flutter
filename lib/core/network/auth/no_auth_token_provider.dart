import 'auth_token_provider.dart';
import 'token_manager.dart';

/// Shared [AuthTokenProvider] used by every `DioClient.create(...)` call
/// site — reads whatever access token [TokenManager] currently holds
/// (`null` before a member has logged in, kept fresh across login and
/// silent token-refresh by `TokenRefreshInterceptor`).
///
/// Despite the name (kept to avoid a rename sweep across every feature
/// binding that already imports it), this is no longer a "no-op" stub —
/// before a real login/session existed, [TokenManager] always held `null`
/// here, which is still exactly what an unauthenticated request needs.
class NoAuthTokenProvider implements AuthTokenProvider {
  const NoAuthTokenProvider();

  @override
  String? getToken() => TokenManager.instance.accessToken;
}
