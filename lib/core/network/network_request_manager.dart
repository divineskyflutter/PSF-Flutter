import 'package:dio/dio.dart';

class NetworkRequestManager {
  NetworkRequestManager._();

  static final NetworkRequestManager instance =
  NetworkRequestManager._();

  final List<CancelToken> _activeTokens = [];

  CancelToken createToken() {
    final token = CancelToken();

    _activeTokens.add(token);

    return token;
  }

  void removeToken(CancelToken token) {
    _activeTokens.remove(token);
  }

  void cancelAllRequests([String reason = 'No internet connection']) {
    for (final token in List<CancelToken>.from(_activeTokens)) {
      if (!token.isCancelled) {
        token.cancel(reason);
      }
    }

    _activeTokens.clear();
  }
}