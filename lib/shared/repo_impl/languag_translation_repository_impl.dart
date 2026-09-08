import 'package:psf_application/core/network/exceptions/api_exceptions.dart';
import 'package:psf_application/shared/data_source/language_remote_data_source.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/repo/language_translation_repository.dart';
import 'package:psf_application/shared/utils/script_detector_util.dart';

class LanguageTranslationRepositoryImpl
    implements LanguageTranslationRepository {
  final LanguageRemoteDataSource _remoteDataSource;

  LanguageTranslationRepositoryImpl(
      this._remoteDataSource,
      );

  @override
  Future<String> transliterate({
    required String text,
    required AppLanguage to,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    final response = await _remoteDataSource.transliterate(
      text: trimmed,
      targetLanguage: to,
    );

    if (response.status != true || response.transliteratedText.isEmpty) {
      throw TranslationException(
        'Could not convert "$trimmed" to ${to.displayName}. '
            'Please try again.',
      );
    }

    return response.transliteratedText;
  }

  @override
  Future<LocalizedTextModel> translateAllScripts({
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return LocalizedTextModel.empty();
    }

    final inputLanguage = _languageOf(
      ScriptDetector.detectScript(trimmedText),
    );

    String english =
    inputLanguage == AppLanguage.english ? trimmedText : '';
    String hindi =
    inputLanguage == AppLanguage.hindi ? trimmedText : '';
    String gujarati =
    inputLanguage == AppLanguage.gujarati ? trimmedText : '';

    // Only call the API for the scripts that aren't already known — the
    // script the user actually typed in needs no round trip.
    final pending = <AppLanguage>[
      if (english.isEmpty) AppLanguage.english,
      if (hindi.isEmpty) AppLanguage.hindi,
      if (gujarati.isEmpty) AppLanguage.gujarati,
    ];

    final results = await Future.wait(
      pending.map(
            (language) => transliterate(
          text: trimmedText,
          to: language,
        ),
      ),
    );

    for (var i = 0; i < pending.length; i++) {
      switch (pending[i]) {
        case AppLanguage.english:
          english = results[i];
          break;
        case AppLanguage.hindi:
          hindi = results[i];
          break;
        case AppLanguage.gujarati:
          gujarati = results[i];
          break;
      }
    }

    return LocalizedTextModel(
      original: trimmedText,
      english: english,
      hindi: hindi,
      gujarati: gujarati,
    );
  }

  /// Treats undetectable script (numbers, punctuation-only input, etc.) as
  /// English, matching the previous behaviour.
  AppLanguage _languageOf(DetectedScript script) {
    switch (script) {
      case DetectedScript.hindi:
        return AppLanguage.hindi;
      case DetectedScript.gujarati:
        return AppLanguage.gujarati;
      case DetectedScript.english:
      case DetectedScript.unknown:
        return AppLanguage.english;
    }
  }
}
