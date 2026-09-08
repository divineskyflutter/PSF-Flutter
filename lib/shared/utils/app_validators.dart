import 'package:get/get.dart';

/// All default messages below are short, single-line and pulled from the
/// localized `registration_strings.dart` maps (via `.tr`) so every message
/// exists in en/hi/gu — instead of the old hardcoded-English-only defaults,
/// which meant a validator message never respected the selected app
/// language. Callers can still override with their own `message`.
class AppValidators {
  AppValidators._();

  // ============================================================
  // REQUIRED
  // ============================================================

  static String? requiredField(
      String? value, {
        String? message,
      }) {
    if (value == null || value.trim().isEmpty) {
      return message ?? 'field_required'.tr;
    }

    return null;
  }

  // ============================================================
  // NAME
  // ============================================================

  // Devanagari (Hindi) and Gujarati Unicode letter/matra blocks, appended
  // to every "letters only" pattern below alongside plain a-zA-Z — the
  // member can type a name/place in whichever of the app's 3 languages
  // they prefer (this wizard already transliterates a typed value into
  // the other two in the background — see translateNameFieldOnUnfocus),
  // so the field itself must not silently reject or block Hindi/Gujarati
  // script to begin with.
  static const String _scriptLetters = r'a-zA-Zऀ-ॿ઀-૿';

  static String? name(
      String? value, {
        String? message,
      }) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr;
    }

    final regex =
    RegExp('^[$_scriptLetters\\s]+\$');

    if (!regex.hasMatch(value.trim())) {
      return message ?? 'invalid_name'.tr;
    }

    return null;
  }

  // ============================================================
  // PLACE NAME (village / taluka / district / state style fields —
  // same as [name] but also allows digits, comma and hyphen, since
  // real place names can include them, e.g. "Sector-5" or "Rajkot-2").
  // ============================================================

  static String? placeName(
      String? value, {
        String? message,
      }) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr;
    }

    final regex = RegExp('^[$_scriptLetters' r'0-9\s,\-]+$');

    if (!regex.hasMatch(value.trim())) {
      return message ?? 'invalid_village_format'.tr;
    }

    return null;
  }

  // ============================================================
  // FULL NAME (combined "First [Middle] Surname" field)
  // ============================================================

  /// Validates the combined full-name field on the registration wizard's
  /// Member step: at least two space-separated word parts (first +
  /// surname, middle optional), each made only of letters, with no
  /// leading/trailing space and no run of 2+ spaces. That last check is
  /// the important one for an EDITED value specifically — deleting one
  /// word out of an existing "First Middle Surname" but leaving its
  /// separating space behind produces exactly a double space or a
  /// trailing space, which this flags instead of silently accepting an
  /// incomplete name.
  static String? fullName(
      String? value, {
        String? message,
      }) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr;
    }

    final effectiveMessage = message ?? 'full_name_format_error'.tr;

    if (value != value.trim() || value.contains(RegExp(r'\s{2,}'))) {
      return effectiveMessage;
    }

    final words = value.trim().split(RegExp(r'\s+'));

    if (words.length < 2) {
      return effectiveMessage;
    }

    final wordRegex = RegExp('^[$_scriptLetters]+\$');

    if (!words.every((word) => wordRegex.hasMatch(word))) {
      return effectiveMessage;
    }

    return null;
  }

  // ============================================================
  // MOBILE
  // ============================================================

  // Length only — no restriction on the leading digit. This used to
  // require the number start with 6-9 (India's mobile-prefix convention),
  // but that rejected otherwise-valid numbers the backend itself doesn't
  // constrain, so it's just a 10-digit count now.
  static String? mobile(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'mobile_number_field_required'.tr;
    }

    if (!RegExp(
      r'^\d{10}$',
    ).hasMatch(value.trim())) {
      return 'invalid_mobile_number'.tr;
    }

    return null;
  }

  /// Same 10-digit-length check as [mobile] (no leading-digit
  /// restriction), but for a genuinely optional second number (e.g.
  /// "Mobile Number 2") that the API doesn't always return and the user
  /// isn't required to fill in: an empty value is valid here, so the
  /// field never shows an error just for being blank — only a non-empty
  /// value that doesn't match the expected format is flagged.
  static String? mobileOptional(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!RegExp(
      r'^\d{10}$',
    ).hasMatch(value.trim())) {
      return 'invalid_mobile_number'.tr;
    }

    return null;
  }

  // ============================================================
  // AADHAR
  // ============================================================

  static String? aadhar(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'enter_aadhaar_number'.tr;
    }

    // The field displays this grouped into 4-4-4 blocks with spaces (see
    // formatAadhar / _AadharInputFormatter on the registration wizard) —
    // strip those back out before checking the actual 12-digit value.
    if (!RegExp(
      r'^\d{12}$',
    ).hasMatch(stripAadharFormatting(value))) {
      return 'invalid_aadhaar_number'.tr;
    }

    return null;
  }

  /// Same 12-digit format check as [aadhar], but never required — for the
  /// Nominee step's Aadhaar number field, which the API defines as an
  /// optional string (see NomineeModel.aadharNo's doc comment). Empty is
  /// valid; anything typed still has to be a real 12-digit number.
  static String? aadharOptional(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!RegExp(
      r'^\d{12}$',
    ).hasMatch(stripAadharFormatting(value))) {
      return 'invalid_aadhaar_number'.tr;
    }

    return null;
  }

  /// Groups a (possibly partial) Aadhaar number into 4-4-4 blocks for
  /// display — "123456789012" -> "1234 5678 9012" — capped at 12 digits.
  /// Non-digit characters (including spaces already in [value], so this
  /// is safe to call again on an already-formatted value) are stripped
  /// first. Purely a display aid; see [stripAadharFormatting] for the
  /// reverse, which is what's actually sent to the API.
  static String formatAadhar(String value) {
    final digits = stripAadharFormatting(value);
    final capped = digits.length > 12 ? digits.substring(0, 12) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(capped[i]);
    }

    return buffer.toString();
  }

  /// The reverse of [formatAadhar] — strips everything but digits, so the
  /// grouped on-screen "1234 5678 9012" becomes the plain "123456789012"
  /// the API actually expects.
  static String stripAadharFormatting(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  // ============================================================
  // PAN
  // ============================================================

  static String? pan(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'enter_pan_number'.tr;
    }

    if (!RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
    ).hasMatch(value.trim().toUpperCase())) {
      return 'invalid_pan_number'.tr;
    }

    return null;
  }

  // ============================================================
  // DATE
  // ============================================================

  static String? date(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'select_date'.tr;
    }

    return null;
  }
}