// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'auth/auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';

class DioClient {
  static Dio create(AuthTokenProvider tokenProvider) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json', 'accept': '*/*'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(tokenProvider),
      // Ahead of ErrorInterceptor on purpose — a 401 it manages to fix by
      // silently refreshing the token and retrying never reaches
      // ErrorInterceptor as a user-facing error at all. See its own doc
      // comment for the full flow.
      TokenRefreshInterceptor(dio),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true), // remove/guard for release builds
    ]);

    return dio;
  }
}