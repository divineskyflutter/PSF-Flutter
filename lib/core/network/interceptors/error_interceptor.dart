// lib/core/network/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import '../exceptions/api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Your API always returns 200 with {status, message, data} even on business-logic errors.
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final status = body['status'] ?? false;
      final message = body['message']?.toString() ?? '';
      final showSuccessToast = response.requestOptions.extra['showSuccessToast'] ?? false;

      if (status == true) {
        if (showSuccessToast) ToastUtil.success(message);
      } else {
        ToastUtil.error(message);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapDioException(err);
    ToastUtil.error(appException.message);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection.');
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        final serverMsg = (err.response?.data is Map)
            ? err.response?.data['message']?.toString()
            : null;
        if (code == 401 || code == 403) {
          return UnauthorizedException(serverMsg ?? 'Session expired. Please login again.');
        } else if (code >= 400 && code < 500) {
          return BadRequestException(serverMsg ?? 'Invalid request.');
        } else {
          return ServerException(serverMsg ?? 'Server error. Please try again later.');
        }
      case DioExceptionType.cancel:
        return UnknownException('Request cancelled.');
      default:
        return UnknownException('Something went wrong.');
    }
  }
}