import 'package:psf_application/core/network/models/api_response_model.dart';
import 'package:psf_application/shared/data_source/language_remote_data_source.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/models/translate_text_request_model.dart';
import 'package:psf_application/shared/repo/language_translation_repository.dart';
import 'package:psf_application/shared/utils/script_detector_util.dart';

class LanguageTranslationRepositoryImpl
    implements LanguageTranslationRepository {
  final LanguageRemoteDataSource _remoteDataSource;

  LanguageTranslationRepositoryImpl(
      this._remoteDataSource,
      );

  @override
  Future<String> translate({
    required String text,
    required AppLanguage from,
    required AppLanguage to,
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    if (from == to) {
      return text;
    }

    final request = TranslateTextRequestModel(
      text: text.trim(),
    );

    late final ApiResponseModel response;

    try {
      if (from == AppLanguage.english && to == AppLanguage.hindi) {
        response = await _remoteDataSource.translateEnglishToHindi(request);
      } else if (from == AppLanguage.english && to == AppLanguage.gujarati) {
        response = await _remoteDataSource.translateEnglishToGujarati(request);
      } else if (from == AppLanguage.hindi && to == AppLanguage.english) {
        response = await _remoteDataSource.translateHindiToEnglish(request);
      } else if (from == AppLanguage.hindi && to == AppLanguage.gujarati) {
        response = await _remoteDataSource.translateHindiToGujarati(request);
      } else if (from == AppLanguage.gujarati && to == AppLanguage.english) {
        response = await _remoteDataSource.translateGujaratiToEnglish(request);
      } else if (from == AppLanguage.gujarati && to == AppLanguage.hindi) {
        response = await _remoteDataSource.translateGujaratiToHindi(request);
      } else {
        response = await _remoteDataSource.translateDynamic(
          request: request,
          fromCode: from.code,
          toCode: to.code,
        );
      }

      if (response.data == null) return text;
      if (response.data is Map) {
        return response.data['data']?.toString() ??
            response.data['translatedText']?.toString() ??
            response.data['result']?.toString() ??
            text;
      }
      return response.data.toString();
    } catch (e) {
      // Return original text on API failure to prevent UI crash or data corruption
      return text;
    }
  }

  @override
  Future<LocalizedTextModel> translateAllScripts({
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return LocalizedTextModel.empty();
    }

    final script = ScriptDetector.detectScript(trimmedText);

    String english = '';
    String hindi = '';
    String gujarati = '';

    switch (script) {
      case DetectedScript.hindi:
        hindi = trimmedText;
        final results = await Future.wait([
          translate(text: trimmedText, from: AppLanguage.hindi, to: AppLanguage.english),
          translate(text: trimmedText, from: AppLanguage.hindi, to: AppLanguage.gujarati),
        ]);
        english = results[0];
        gujarati = results[1];
        break;

      case DetectedScript.gujarati:
        gujarati = trimmedText;
        final results = await Future.wait([
          translate(text: trimmedText, from: AppLanguage.gujarati, to: AppLanguage.english),
          translate(text: trimmedText, from: AppLanguage.gujarati, to: AppLanguage.hindi),
        ]);
        english = results[0];
        hindi = results[1];
        break;

      case DetectedScript.english:
      case DetectedScript.unknown:
      default:
        english = trimmedText;
        final results = await Future.wait([
          translate(text: trimmedText, from: AppLanguage.english, to: AppLanguage.hindi),
          translate(text: trimmedText, from: AppLanguage.english, to: AppLanguage.gujarati),
        ]);
        hindi = results[0];
        gujarati = results[1];
        break;
    }

    return LocalizedTextModel(
      original: trimmedText,
      english: english,
      hindi: hindi,
      gujarati: gujarati,
    );
  }
}