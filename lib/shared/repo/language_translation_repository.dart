import '../enums/app_language.dart';
import '../models/localized_text_model.dart';

abstract class LanguageTranslationRepository {
  /// Converts [text] into the script used by [to] (e.g. typed "Hetal" ->
  /// "હેતલ" for [AppLanguage.gujarati]). Only the target script matters —
  /// the transliteration API accepts input in any script and renders it in
  /// the requested one, so callers don't need to know the source script.
  ///
  /// Throws an [Exception] (a [TranslationException] for a business-logic
  /// failure, or the usual typed network exceptions) instead of silently
  /// returning the original text — callers decide how to surface that.
  Future<String> transliterate({
    required String text,
    required AppLanguage to,
  });

  /// Fills in all three script variants of [text] at once, skipping the
  /// network call for whichever script [text] is already written in.
  Future<LocalizedTextModel> translateAllScripts({
    required String text,
  });
}
