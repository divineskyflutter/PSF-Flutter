import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/core/network/network_caller.dart';
import 'package:psf_application/shared/models/translate_text_request_model.dart';

class LanguageRemoteDataSource {
  final NetworkCaller _networkCaller;

  LanguageRemoteDataSource(
      this._networkCaller,
      );

  Future<ApiResponseModel> translateEnglishToHindi(
      TranslateTextRequestModel request,
      ) {
    return _networkCaller.postRequest(
      ApiEndPoints.englishToHindi,
      body: request.toJson(),
      requireToken: false,
    );
  }

  Future<ApiResponseModel> translateEnglishToGujarati(
      TranslateTextRequestModel request,
      ) {
    return _networkCaller.postRequest(
      ApiEndPoints.englishToGujarati,
      body: request.toJson(),
      requireToken: false,
    );
  }

  Future<ApiResponseModel> translateHindiToEnglish(
      TranslateTextRequestModel request,
      ) {
    return _networkCaller.postRequest(
      ApiEndPoints.hindiToEnglish,
      body: request.toJson(),
      requireToken: false,
    );
  }

  Future<ApiResponseModel> translateHindiToGujarati(
      TranslateTextRequestModel request,
      ) {
    return _networkCaller.postRequest(
      ApiEndPoints.hindiToGujarati,
      body: request.toJson(),
      requireToken: false,
    );
  }

  Future<ApiResponseModel> translateGujaratiToEnglish(
      TranslateTextRequestModel request,
      ) {
    return _networkCaller.postRequest(
      ApiEndPoints.gujaratiToEnglish,
      body: request.toJson(),
      requireToken: false,
    );
  }

  Future<ApiResponseModel> translateGujaratiToHindi(
      TranslateTextRequestModel request,
      ) {
    return _networkCaller.postRequest(
      ApiEndPoints.gujaratiToHindi,
      body: request.toJson(),
      requireToken: false,
    );
  }

  /// Dynamic translation endpoint for future additional languages
  Future<ApiResponseModel> translateDynamic({
    required TranslateTextRequestModel request,
    required String fromCode,
    required String toCode,
  }) {
    return _networkCaller.postRequest(
      ApiEndPoints.translateEndpoint(fromCode, toCode),
      body: request.toJson(),
      requireToken: false,
    );
  }
}