// lib/core/network/interceptors/error_interceptor.dart
import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';
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
      final suppressErrorToast = response.requestOptions.extra['suppressErrorToast'] ?? false;

      if (status == true) {
        if (showSuccessToast) ToastUtil.success(message);
      } else if (!suppressErrorToast) {
        ToastUtil.error(message);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Request was intentionally cancelled
    if (err.type == DioExceptionType.cancel) {
      handler.next(err);
      return;
    }

    final appException = _mapDioException(err);
    final isNetworkIssue = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isNetworkIssue) {
      // A connectivity error cancels every in-flight request, removes the
      // global loader, and displays the single app-wide dialog. Do not emit a
      // per-request timeout toast.
      Get.find<ConnectivityService>().handleNetworkFailure();
    } else {
      ToastUtil.error(appException.message);
    }
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
