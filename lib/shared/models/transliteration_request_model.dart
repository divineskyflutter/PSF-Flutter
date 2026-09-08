/// Request body for the `/api/Transliteration/{Language}` endpoints.
class TransliterationRequestModel {
  final String text;

  /// Number of alternate candidates to ask the service for. The API's own
  /// documented example uses `0` and still returns a single best result in
  /// [TransliterationResponseModel.transliteratedText], so `0` is the safe
  /// default here too.
  final int numSuggestions;

  const TransliterationRequestModel({
    required this.text,
    this.numSuggestions = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'numSuggestions': numSuggestions,
    };
  }
}
