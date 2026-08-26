import '../enums/app_language.dart';
import '../models/localized_text_model.dart';

abstract class LanguageTranslationRepository {
  Future<String> translate({
    required String text,
    required AppLanguage from,
    required AppLanguage to,
  });

  Future<LocalizedTextModel> translateAllScripts({
    required String text,
  });
}