class LocalizedTextModel {
  final String original;
  final String english;
  final String hindi;
  final String gujarati;

  const LocalizedTextModel({
    required this.original,
    required this.english,
    required this.hindi,
    required this.gujarati,
  });

  factory LocalizedTextModel.empty() {
    return const LocalizedTextModel(
      original: '',
      english: '',
      hindi: '',
      gujarati: '',
    );
  }

  LocalizedTextModel copyWith({
    String? original,
    String? english,
    String? hindi,
    String? gujarati,
  }) {
    return LocalizedTextModel(
      original: original ?? this.original,
      english: english ?? this.english,
      hindi: hindi ?? this.hindi,
      gujarati: gujarati ?? this.gujarati,
    );
  }
}