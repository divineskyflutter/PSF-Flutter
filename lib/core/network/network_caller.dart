// lib/core/network/network_caller.dart
import 'package:dio/dio.dart';
import 'models/api_response_model.dart';
import 'exceptions/api_exceptions.dart';

class NetworkCaller {
  final Dio _dio;
  NetworkCaller(this._dio);

  Future<ApiResponseModel> getRequest(
      String url, {
        Map<String, dynamic>? queryParams,
        bool requireToken = true,
      }) {
    return _call(() => _dio.get(
      url,
      queryParameters: queryParams,
      options: Options(extra: {'requireToken': requireToken}),
    ));
  }

  Future<ApiResponseModel> postRequest(
      String url, {
        Map<String, dynamic>? body,
        bool requireToken = true,
        bool showSuccessToast = false,
      }) {
    return _call(() => _dio.post(
      url,
      data: body,
      options: Options(extra: {
        'requireToken': requireToken,
        'showSuccessToast': showSuccessToast,
      }),
    ));
  }

  Future<ApiResponseModel> patchRequest(
      String url, {
        Map<String, dynamic>? body,
        bool requireToken = true,
        bool showSuccessToast = false,
      }) {
    return _call(() => _dio.patch(
      url,
      data: body,
      options: Options(extra: {
        'requireToken': requireToken,
        'showSuccessToast': showSuccessToast,
      }),
    ));
  }

  Future<ApiResponseModel> _call(Future<Response> Function() request) async {
    try {
      final response = await request();
      return ApiResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      // ErrorInterceptor already toasted; rethrow the typed AppException so
      // repositories/controllers can still branch on error type if needed.
      if (e.error is AppException) throw e.error as AppException;
      throw UnknownException('Something went wrong.');
    }
  }
}