// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'auth/auth_token_provider.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

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
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true), // remove/guard for release builds
    ]);

    return dio;
  }
}