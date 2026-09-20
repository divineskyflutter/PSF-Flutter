import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';

import 'exceptions/api_exceptions.dart';
import 'models/api_response_model.dart';
import 'network_request_manager.dart';
import '../../shared/widgets/network/ConnectivityService.dart';

class NetworkCaller {
  final Dio _dio;

  NetworkCaller(this._dio);

  Future<ApiResponseModel> getRequest(
      String url, {
        Map<String, dynamic>? queryParams,
        bool requireToken = true,
      }) {
    return _execute(
          (cancelToken) => _dio.get(
        url,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            'requireToken': requireToken,
          },
        ),
      ),
      (data) => ApiResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponseModel> postRequest(
      String url, {
        Map<String, dynamic>? body,
        bool requireToken = true,
        bool showSuccessToast = false,
        // Opt-out for endpoints whose own repository already treats a
        // status:false response as a normal, expected outcome rather than
        // a real error (e.g. "no record yet for this member" on a
        // best-effort prefill call) — see ErrorInterceptor.onResponse,
        // which otherwise auto-toasts the raw `message` on every
        // status:false response regardless of what it actually means.
        bool suppressErrorToast = false,
      }) {
    return _execute(
          (cancelToken) => _dio.post(
        url,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            'requireToken': requireToken,
            'showSuccessToast': showSuccessToast,
            'suppressErrorToast': suppressErrorToast,
          },
        ),
      ),
      (data) => ApiResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST for endpoints whose response is a file/image rather than the
  /// common JSON envelope (e.g. `GetMemberQrCode`). Sends [queryParams] on
  /// the URL, returns the raw response bytes, and — unless
  /// [suppressErrorToast] is false — fails quietly (no global error toast),
  /// since callers show their own inline "unavailable / retry" state.
  Future<Uint8List> postRequestBytes(
      String url, {
        Map<String, dynamic>? queryParams,
        bool requireToken = true,
        bool suppressErrorToast = true,
      }) {
    return _execute<Uint8List>(
          (cancelToken) => _dio.post<List<int>>(
        url,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.bytes,
          extra: {
            'requireToken': requireToken,
            'suppressErrorToast': suppressErrorToast,
          },
        ),
      ),
      (data) => Uint8List.fromList((data as List).cast<int>()),
    );
  }

  Future<ApiResponseModel> patchRequest(
      String url, {
        Map<String, dynamic>? body,
        bool requireToken = true,
        bool showSuccessToast = false,
      }) {
    return _execute(
          (cancelToken) => _dio.patch(
        url,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            'requireToken': requireToken,
            'showSuccessToast': showSuccessToast,
          },
        ),
      ),
      (data) => ApiResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Same request/error/connectivity handling as [postRequest], but for
  /// endpoints that do NOT use the app's common `{status, message, data,
  /// id}` envelope (e.g. the Transliteration APIs, which return
  /// `{status, language, input, transliteratedText}` directly). Returns the
  /// decoded response body as-is so the caller can parse it with its own
  /// model instead of the common [ApiResponseModel].
  Future<dynamic> postRequestRaw(
      String url, {
        Map<String, dynamic>? body,
        bool requireToken = true,
      }) {
    return _execute<dynamic>(
          (cancelToken) => _dio.post(
        url,
        data: body,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            'requireToken': requireToken,
          },
        ),
      ),
          (data) => data,
    );
  }

  /// Multipart upload (e.g. `SaveDocument`). [fields] are sent as plain
  /// form fields alongside the file — field names must match the API
  /// exactly (it is case-sensitive: `Createdby`, `Module`, `Platform`).
  /// Uses the common `{status, message, data, id}` envelope, same as every
  /// other `Save*` endpoint on this API.
  Future<ApiResponseModel> postMultipart(
      String url, {
        required String filePath,
        required String fileFieldName,
        required Map<String, dynamic> fields,
        bool requireToken = true,
      }) {
    return _execute(
          (cancelToken) async {
        final formData = FormData.fromMap({
          ...fields,
          fileFieldName: await MultipartFile.fromFile(filePath),
        });

        return _dio.post(
          url,
          data: formData,
          cancelToken: cancelToken,
          options: Options(
            contentType: 'multipart/form-data',
            extra: {
              'requireToken': requireToken,
            },
          ),
        );
      },
      (data) => ApiResponseModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<T> _execute<T>(
      Future<Response> Function(CancelToken cancelToken) request,
      T Function(dynamic responseData) parseResponse,
      ) async {
    // Do not start a new request while the app is already handling a loss of
    // connectivity. This also prevents chained API calls from continuing.
    final connectivity = Get.find<ConnectivityService>();
    if (!connectivity.hasInternet) {
      connectivity.handleNetworkFailure();
      throw RequestCancelledException(
        'Request cancelled because internet connection was lost.',
      );
    }

    final cancelToken =
    NetworkRequestManager.instance.createToken();

    try {
      final response = await request(cancelToken);

      // Proof positive that the network works right now, regardless of
      // what the ambient connectivity probe last reported — see
      // ConnectivityService's class doc (3). Without this, a probe that
      // disagreed with reality (blocked/slow/wrong target) could leave
      // hasInternet stuck at false forever, and every retry would then be
      // rejected by the guard above before it even reached the network.
      connectivity.markInternetVerified();

      return parseResponse(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw RequestCancelledException(
          'Request cancelled because internet connection was lost.',
        );
      }

      if (e.error is AppException) {
        throw e.error as AppException;
      }

      throw UnknownException(
        'Something went wrong.',
      );
    } finally {
      NetworkRequestManager.instance
          .removeToken(cancelToken);
    }
  }
}
