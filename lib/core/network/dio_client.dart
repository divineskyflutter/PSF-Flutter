// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      // Debug builds only: this prints every request/response body and
      // header (login password, access tokens, Aadhaar/PAN numbers, health
      // details) to the device log, which anyone with the phone attached
      // can read — never acceptable in a release build.
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}