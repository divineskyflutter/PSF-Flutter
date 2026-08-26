class AppValidators {
  AppValidators._();

  // ============================================================
  // REQUIRED
  // ============================================================

  static String? requiredField(
      String? value, {
        String message = 'This field is required',
      }) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  // ============================================================
  // NAME
  // ============================================================

  static String? name(
      String? value, {
        String message = 'Please enter a valid name',
      }) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final regex =
    RegExp(r'^[a-zA-Z\s]+$');

    if (!regex.hasMatch(value.trim())) {
      return message;
    }

    return null;
  }

  // ============================================================
  // MOBILE
  // ============================================================

  static String? mobile(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter mobile number';
    }

    if (!RegExp(
      r'^[6-9]\d{9}$',
    ).hasMatch(value.trim())) {
      return 'Please enter valid mobile number';
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
      return 'Please enter Aadhaar number';
    }

    if (!RegExp(
      r'^\d{12}$',
    ).hasMatch(value.trim())) {
      return 'Aadhaar number must be 12 digits';
    }

    return null;
  }

  // ============================================================
  // PAN
  // ============================================================

  static String? pan(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter PAN number';
    }

    if (!RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$',
    ).hasMatch(value.trim().toUpperCase())) {
      return 'Please enter valid PAN number';
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
      return 'Please select date';
    }

    return null;
  }
}