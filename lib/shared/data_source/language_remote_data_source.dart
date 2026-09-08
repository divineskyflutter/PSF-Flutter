import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/network_caller.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/models/transliteration_request_model.dart';
import 'package:psf_application/shared/models/transliteration_response_model.dart';

class LanguageRemoteDataSource {
  final NetworkCaller _networkCaller;

  LanguageRemoteDataSource(
      this._networkCaller,
      );

  /// Calls the `/api/Transliteration/{Language}` endpoint matching
  /// [targetLanguage] and converts [text] into that script.
  ///
  /// Uses [NetworkCaller.postRequestRaw] because this API's response body
  /// (`{status, language, input, transliteratedText}`) does not match the
  /// app's common `{status, message, data, id}` envelope.
  Future<TransliterationResponseModel> transliterate({
    required String text,
    required AppLanguage targetLanguage,
  }) async {
    final request = TransliterationRequestModel(text: text);

    final raw = await _networkCaller.postRequestRaw(
      _endpointFor(targetLanguage),
      body: request.toJson(),
      requireToken: false,
    );

    if (raw is! Map<String, dynamic>) {
      throw Exception('Unexpected transliteration response format.');
    }

    return TransliterationResponseModel.fromJson(raw);
  }

  String _endpointFor(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return ApiEndPoints.transliterateToHindi;
      case AppLanguage.gujarati:
        return ApiEndPoints.transliterateToGujarati;
      case AppLanguage.english:
        return ApiEndPoints.transliterateToEnglish;
    }
  }
}
