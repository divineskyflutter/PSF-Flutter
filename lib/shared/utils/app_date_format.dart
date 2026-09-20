import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Date display in the member's selected app language (month names in
/// Hindi/Gujarati, etc.). Needs `initializeDateFormatting()` to have run
/// at startup (see `main.dart`). Pass `localized: false` for plain
/// English (PDF export, whose standard fonts are Latin-only).
class AppDateFormat {
  AppDateFormat._();

  static String medium(DateTime date, {bool localized = true}) {
    final locale = localized ? (Get.locale?.toString() ?? 'en_US') : 'en_US';

    try {
      return DateFormat('dd MMM yyyy', locale).format(date);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  /// `16 / 09 / 2026` — digits only, so it reads the same in every language
  /// (used on the printed-style member card).
  static String numeric(DateTime date) => DateFormat('dd / MM / yyyy').format(date);
}
