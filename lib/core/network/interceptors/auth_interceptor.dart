// lib/core/network/interceptors/auth_interceptor.dart
import 'package:dio/dio.dart';
import '../auth/auth_token_provider.dart';

class AuthInterceptor extends Interceptor {
  final AuthTokenProvider tokenProvider;
  AuthInterceptor(this.tokenProvider);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requireToken = options.extra['requireToken'] ?? true;
    if (requireToken == true) {
      final token = tokenProvider.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}