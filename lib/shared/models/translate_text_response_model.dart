import 'localized_text_model.dart';

class TranslateTextResponseModel {
  final String english;
  final String hindi;
  final String gujarati;

  const TranslateTextResponseModel({
    required this.english,
    required this.hindi,
    required this.gujarati,
  });

  factory TranslateTextResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return TranslateTextResponseModel(
      english: json['english']?.toString() ?? '',
      hindi: json['hindi']?.toString() ?? '',
      gujarati: json['gujarati']?.toString() ?? '',
    );
  }

  LocalizedTextModel toEntity({
    required String original,
  }) {
    return LocalizedTextModel(
      original: original,
      english: english,
      hindi: hindi,
      gujarati: gujarati,
    );
  }
}