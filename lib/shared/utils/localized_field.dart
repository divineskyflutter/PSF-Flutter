import 'package:psf_application/shared/enums/app_language.dart';

/// Picks the Hindi/Gujarati transliteration of a field when [language]
/// calls for one, falling back to [plain] when no translation was saved
/// for it — the same 3-way fallback `MemberModel.localizedFullName`
/// already uses for the member's name, generalized so every other h/g
/// field pair (address, occupation, nominee name, health-declaration
/// answers, ...) can show data in the member's selected app language too,
/// not just static UI labels via `.tr`.
String localizedField(
  AppLanguage language, {
  required String? plain,
  String? hindi,
  String? gujarati,
}) {
  final translated = switch (language) {
    AppLanguage.hindi => hindi,
    AppLanguage.gujarati => gujarati,
    AppLanguage.english => plain,
  };

  if (translated != null && translated.trim().isNotEmpty) {
    return translated.trim();
  }

  return (plain ?? '').trim();
}
