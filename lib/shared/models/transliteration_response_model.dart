/// Response body for the `/api/Transliteration/{Language}` endpoints.
///
/// This is a deliberately separate model from [ApiResponseModel]
/// (core/network/models/api_response_model.dart): the transliteration
/// service does not use the app's common `{status, message, data, id}`
/// envelope, it returns `{status, language, input, transliteratedText}`
/// directly. Parsing it with the common model silently produced an empty
/// `data`, which is why name translation used to always fall back to the
/// untranslated original text.
class TransliterationResponseModel {
  final bool status;
  final String language;
  final String input;
  final String transliteratedText;

  const TransliterationResponseModel({
    required this.status,
    required this.language,
    required this.input,
    required this.transliteratedText,
  });

  factory TransliterationResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return TransliterationResponseModel(
      status: json['status'] == true,
      language: json['language']?.toString() ?? '',
      input: json['input']?.toString() ?? '',
      transliteratedText:
      json['transliteratedText']?.toString() ?? '',
    );
  }
}
