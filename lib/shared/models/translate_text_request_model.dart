class TranslateTextRequestModel {
  final String text;

  const TranslateTextRequestModel({
    required this.text,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
} 