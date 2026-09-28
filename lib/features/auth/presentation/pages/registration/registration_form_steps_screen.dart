import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/core/localization/registration_strings.dart';
import 'package:psf_application/features/auth/data/models/member_model.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/features/profile/presentation/widgets/language_settings_sheet.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/signature/app_signature_bottom_sheet.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/enum_option_translator.dart';
import 'package:psf_application/shared/utils/script_detector.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/images/common_image_view.dart';
import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';
import 'package:psf_application/shared/widgets/upload/app_upload_container.dart';

/// Keeps a nominee-share text field honest as the member types: only
/// digits + a single decimal point (max 2 decimal places, same as before),
/// AND the resulting number can never exceed 100 — since share is a
/// percentage and the three nominee slots together can't add up to more
/// than 100% anyway (see RegistrationController.shareExceedsLimit). This
/// replaces the old formatter that only capped decimal places and let the
/// member type arbitrarily large whole numbers (e.g. "9999").
class _ShareInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    if (!RegExp(r'^\d{0,3}(\.\d{0,2})?$').hasMatch(text)) {
      return oldValue;
    }

    final parsed = double.tryParse(text);

    // A bare "100." or similar partial entry parses fine and is <= 100,
    // so it's only actually-over-100 numeric values that get rejected.
    if (parsed != null && parsed > 100) {
      return oldValue;
    }

    return newValue;
  }
}

/// Groups an Aadhaar number into 4-4-4 blocks as the member types — e.g.
/// "123456789012" reads as "1234 5678 9012" — capped at 12 digits, purely
/// as a display aid (see AppValidators.formatAadhar/stripAadharFormatting
/// for the shared grouping logic, also used to keep a resumed/prefilled
/// Aadhaar number grouped the same way instead of showing as one long
/// unbroken string — see RegistrationController.getMemberStatus/
/// loadExistingNominees). AppValidators.aadhar/aadharOptional strip the
/// spaces back out before validating, and saveMemberPersonalDetail/
/// saveNomineeSlot strip them before sending to the API — the space
/// characters never leave this field.
///
/// Cursor position is re-derived from how many digits sit before it in
/// the raw input, then re-located in the freshly-formatted string, so
/// typing/deleting in the middle of the number doesn't jump the cursor to
/// the end every keystroke.
class _AadharInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cappedDigits =
        rawDigits.length > 12 ? rawDigits.substring(0, 12) : rawDigits;

    final cursorOffset = newValue.selection.end < 0
        ? newValue.text.length
        : newValue.selection.end.clamp(0, newValue.text.length);

    final digitsBeforeCursor = newValue.text
        .substring(0, cursorOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, cappedDigits.length);

    final formatted = AppValidators.formatAadhar(cappedDigits);

    var digitsSeen = 0;
    var cursorIndex = formatted.length;

    for (var i = 0; i < formatted.length; i++) {
      if (digitsSeen >= digitsBeforeCursor) {
        cursorIndex = i;
        break;
      }
      if (formatted[i] != ' ') digitsSeen++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorIndex),
    );
  }
}

/// Which soft keyboard PAN's field should show for a given CURSOR
/// POSITION (not text length — the member can move the cursor to any
/// position and edit there, so the keyboard has to match whatever slot the
/// cursor currently sits in, not just wherever typing last stopped) —
/// visiblePassword (plain Latin letters, no Hindi/Gujarati IME — see
/// TextInputType.visiblePassword's own doc comment for why this is the
/// standard trick for that) for the first 5 characters and the last one,
/// number pad for the 4 digits in between. See _PanInputFormatter below
/// for the matching character-type enforcement, and _PanInputFormatter's
/// own cursor tracking for why the ValueListenableBuilder's
/// value.selection is always accurate here even after typing, deleting,
/// or tapping to a new position mid-string.
TextInputType _panKeyboardTypeFor(int cursorPosition) {
  final slot = cursorPosition.clamp(0, 9);
  // .phone (not .number) for the digit zone — same reason as the date
  // picker's day/month/year segments and the mobile-number field: under
  // .number, a Hindi/Gujarati keyboard's native-script numeral keys type
  // non-ASCII digits that FilteringTextInputFormatter/this formatter's
  // own digit regex then silently strip, so digits the member typed
  // never actually appear. .phone reliably gets ASCII 0-9.
  return _PanInputFormatter._letterSlots.contains(slot)
      ? TextInputType.visiblePassword
      : TextInputType.phone;
}

/// Enforces the PAN format's fixed letter/digit layout as the member
/// types — 5 letters, 4 digits, 1 letter (e.g. "ABCDE1234F") — instead of
/// only catching a wrong character after the fact via AppValidators.pan.
/// A character that doesn't match its position's expected type is simply
/// not inserted, same idea as an OTP field. Also uppercases every letter,
/// since textCapitalization only affects the on-screen keyboard's shift
/// state, not what's actually inserted.
///
/// Cursor handling mirrors [_MobileInputFormatter]/[_AadharInputFormatter]
/// above rather than always collapsing to the end: the number of ACCEPTED
/// characters before the original cursor position is preserved as the new
/// cursor position (this format has no separator characters, so — unlike
/// Aadhaar/mobile — 1 accepted character always maps to exactly 1
/// formatted character). That's what makes typing, deleting, or tapping
/// to any position in the middle of the number all land the cursor back
/// where the member actually put it, instead of always jumping to the
/// end — which is also what makes _panKeyboardTypeFor's cursor-based
/// keyboard switch actually track the right slot. See _panKeyboardTypeFor
/// above for the matching keyboard auto-switch (point 8's other half).
class _PanInputFormatter extends TextInputFormatter {
  static const _letterSlots = {0, 1, 2, 3, 4, 9};

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursorOffset = newValue.selection.end < 0
        ? newValue.text.length
        : newValue.selection.end.clamp(0, newValue.text.length);

    // A pure deletion (backspace/cut, nothing typed) must only ever
    // remove the character(s) that were actually removed — it must NOT
    // re-run the slot-type check below on what's left. That check keys
    // each character to its POSITION IN THE OUTPUT BUFFER as it's
    // rebuilt, and deleting a character from the middle shifts every
    // character after it back by one slot. E.g. "ABCDE1234F" with the
    // '2' deleted mid-string becomes "ABCDE134F" — the trailing 'F' has
    // now shifted into what the buffer counts as a digit slot, so the
    // old code silently dropped it too, making one backspace appear to
    // delete two characters (the intended one AND the last one). A
    // deletion just shortens the string; nothing needs re-validating.
    if (newValue.text.length < oldValue.text.length) {
      final capped = newValue.text.toUpperCase();
      final result = capped.length > 10 ? capped.substring(0, 10) : capped;
      return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(
          offset: cursorOffset.clamp(0, result.length),
        ),
      );
    }

    final raw = newValue.text.toUpperCase();

    final buffer = StringBuffer();
    var cursorIndex = 0;
    var located = cursorOffset == 0;

    for (var i = 0; i < raw.length && buffer.length < 10; i++) {
      final char = raw[i];
      final isLetterSlot = _letterSlots.contains(buffer.length);
      final matches = isLetterSlot
          ? RegExp(r'[A-Z]').hasMatch(char)
          : RegExp(r'[0-9]').hasMatch(char);

      if (matches) buffer.write(char);

      if (!located && i == cursorOffset - 1) {
        cursorIndex = buffer.length;
        located = true;
      }
    }

    // Cursor was past whatever got capped/consumed (e.g. pasting more
    // than 10 characters) — land it at the end of what's actually there.
    if (!located) cursorIndex = buffer.length;

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorIndex.clamp(0, formatted.length),
      ),
    );
  }
}

/// Groups a mobile number into the Indian 5+5 blocks as the member
/// types — e.g. "9876543210" reads as "98765 43210" — capped at 10
/// digits, purely as a display aid (see AppValidators.formatMobile/
/// stripMobileFormatting for the shared grouping logic). Same
/// cursor-preserving approach as [_AadharInputFormatter] above.
class _MobileInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final cappedDigits =
        rawDigits.length > 10 ? rawDigits.substring(0, 10) : rawDigits;

    final cursorOffset = newValue.selection.end < 0
        ? newValue.text.length
        : newValue.selection.end.clamp(0, newValue.text.length);

    final digitsBeforeCursor = newValue.text
        .substring(0, cursorOffset)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, cappedDigits.length);

    final formatted = AppValidators.formatMobile(cappedDigits);

    var digitsSeen = 0;
    var cursorIndex = formatted.length;

    for (var i = 0; i < formatted.length; i++) {
      if (digitsSeen >= digitsBeforeCursor) {
        cursorIndex = i;
        break;
      }
      if (formatted[i] != ' ') digitsSeen++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorIndex),
    );
  }
}

class MemberRegistrationScreen
    extends StatefulWidget {
  const MemberRegistrationScreen({
    super.key,
  });

  @override
  State<MemberRegistrationScreen> createState() =>
      _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState
    extends State<MemberRegistrationScreen> {
  final controller =
  Get.find<RegistrationController>();

  final PageController pageController =
  PageController();

  final GlobalKey<FormState>
  memberFormKey =
  GlobalKey<FormState>();

  /// One Form key per nominee slot (RegistrationController.nomineeSlots is
  /// fixed-length, so this is too) — each slot validates independently,
  /// since slots are revealed/saved one at a time rather than all at once.
  final List<GlobalKey<FormState>> nomineeSlotFormKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey<FormState>(),
  );

  // ============================================================
  // SCROLL-TO-FIRST-ERROR
  //
  // One GlobalKey per checkpoint, kept in the same top-to-bottom order the
  // fields actually appear on screen. _scrollToFirstError walks a
  // checkpoint list (built by _step0Checkpoints/_nomineeCheckpoints below)
  // after a failed Next and jumps to the first one still in error — every
  // one of these already gets its own inline/Form error text the moment
  // _showStep1Errors (step 0) or a slot's showErrors (step 1) flips true,
  // this only adds the scroll so that text is actually seen instead of
  // sitting off-screen while just a toast (or nothing) appears.
  // ============================================================

  final GlobalKey _profileImageKey = GlobalKey();
  final GlobalKey _fullNameKey = GlobalKey();
  final GlobalKey _fatherNameKey = GlobalKey();
  final GlobalKey _dobKey = GlobalKey();
  final GlobalKey _genderKey = GlobalKey();
  final GlobalKey _maritalStatusKey = GlobalKey();
  final GlobalKey _addressKey = GlobalKey();
  final GlobalKey _villageKey = GlobalKey();
  final GlobalKey _talukaKey = GlobalKey();
  final GlobalKey _districtKey = GlobalKey();
  final GlobalKey _stateKey = GlobalKey();
  final GlobalKey _aadharNumberKey = GlobalKey();
  final GlobalKey _aadharFrontKey = GlobalKey();
  final GlobalKey _aadharBackKey = GlobalKey();
  final GlobalKey _panNumberKey = GlobalKey();
  final GlobalKey _panImageKey = GlobalKey();
  final GlobalKey _occupationKey = GlobalKey();
  final GlobalKey _mobile2Key = GlobalKey();
  final GlobalKey _signatureKey = GlobalKey();

  /// Kept alive across every letters<->digits keyboard-zone switch on the
  /// PAN field (see the ValueKey remount trick at that field's callsite)
  /// so focus survives the remount instead of the field silently losing
  /// it. A plain change to TextField.keyboardType while already focused
  /// doesn't reliably make Android's on-screen keyboard actually redraw
  /// with the new layout — remounting the field with a fresh element is
  /// what forces that, but only works if the SAME FocusNode carries over
  /// (a brand new FocusNode on remount would read as "nothing focused",
  /// closing the keyboard instead of reopening it with the right type).
  final FocusNode _panFocusNode = FocusNode();

  /// Tracks which keyboard zone (letters vs digits — see
  /// _PanInputFormatter._letterSlots) the PAN cursor was in as of the last
  /// check, so _handlePanKeyboardSwitch only acts on an actual zone
  /// CROSSING instead of re-running on every keystroke within the same
  /// zone. Starts null so the very first check never counts as a
  /// crossing.
  bool? _panLastZoneWasLetters;

  /// Nominee checkpoints are per-slot (each slot is its own Form, same
  /// reasoning as [nomineeSlotFormKeys]) — only the last visible slot is
  /// ever validated on Next, but every slot gets its own key set so an
  /// earlier slot re-opened for editing still scrolls correctly too.
  final List<GlobalKey> _nomineePhotoKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineeNameKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineeDobKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineeRelationKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineeAadharFrontKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineeAadharBackKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineePassbookKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );
  final List<GlobalKey> _nomineeShareKeys = List.generate(
    RegistrationController.maxNominees,
    (_) => GlobalKey(),
  );

  /// Health Declaration step (step 2) checkpoint keys — see
  /// _healthCheckpoints below.
  final GlobalKey _healthCurrentIllnessKey = GlobalKey();
  final GlobalKey _healthCurrentIllnessDetailKey = GlobalKey();
  final GlobalKey _healthHereditaryDetailKey = GlobalKey();
  final GlobalKey _healthSurgeryKey = GlobalKey();
  final GlobalKey _healthSurgeryDetailKey = GlobalKey();
  final GlobalKey _healthSurgeryDateKey = GlobalKey();
  final GlobalKey _healthMedicationKey = GlobalKey();
  final GlobalKey _healthMedicationDetailKey = GlobalKey();
  final GlobalKey _healthAllergyKey = GlobalKey();
  final GlobalKey _healthAllergyDetailKey = GlobalKey();
  final GlobalKey _healthTobaccoKey = GlobalKey();
  final GlobalKey _healthAlcoholKey = GlobalKey();
  final GlobalKey _healthDrugsKey = GlobalKey();
  final GlobalKey _healthOtherDetailsKey = GlobalKey();
  final GlobalKey _healthDiseaseChipsKey = GlobalKey();

  /// Ordered top-to-bottom checkpoint list for Step 0 (Member) — each
  /// entry pairs a field's GlobalKey with a fresh re-check of the exact
  /// same condition its own validator/_inlineError already uses.
  List<MapEntry<GlobalKey, bool Function()>> _step0Checkpoints() => [
        MapEntry(
          _profileImageKey,
          () =>
              controller.profileImage.value == null &&
              controller.profileImageId.value == null,
        ),
        MapEntry(
          _fullNameKey,
          () => AppValidators.fullName(fullNameController.text) != null,
        ),
        MapEntry(
          _fatherNameKey,
          () => AppValidators.fatherName(
                controller.fatherNameController.text,
              ) !=
              null,
        ),
        MapEntry(
          _dobKey,
          () => AppValidators.date(controller.dateOfBirthController.text) !=
              null,
        ),
        MapEntry(
          _genderKey,
          () => controller.selectedGenderId.value == null,
        ),
        MapEntry(
          _maritalStatusKey,
          () => controller.selectedMaritalStatusId.value == null,
        ),
        MapEntry(
          _addressKey,
          () =>
              AppValidators.requiredField(controller.addressController.text) !=
              null,
        ),
        MapEntry(
          _villageKey,
          () =>
              AppValidators.placeName(controller.villageController.text) !=
              null,
        ),
        MapEntry(
          _talukaKey,
          () =>
              AppValidators.placeName(controller.talukaController.text) !=
              null,
        ),
        MapEntry(
          _districtKey,
          () =>
              AppValidators.placeName(controller.districtController.text) !=
              null,
        ),
        MapEntry(
          _stateKey,
          () =>
              AppValidators.placeName(controller.stateController.text) !=
              null,
        ),
        MapEntry(
          _aadharNumberKey,
          () =>
              AppValidators.aadhar(controller.aadharNumberController.text) !=
              null,
        ),
        MapEntry(
          _aadharFrontKey,
          () =>
              controller.aadharImage.value == null &&
              controller.aadharImageId.value == null,
        ),
        MapEntry(
          _aadharBackKey,
          () =>
              controller.aadharBackImage.value == null &&
              controller.aadharBackImageId.value == null,
        ),
        MapEntry(
          _panNumberKey,
          () => AppValidators.pan(controller.panNumberController.text) !=
              null,
        ),
        MapEntry(
          _panImageKey,
          () =>
              controller.panImage.value == null &&
              controller.panImageId.value == null,
        ),
        MapEntry(
          _occupationKey,
          () =>
              AppValidators.name(controller.occupationController.text) !=
              null,
        ),
        MapEntry(
          _signatureKey,
          () =>
              controller.signatureFile.value == null &&
              controller.signatureFileId.value == null,
        ),
      ];

  /// Same idea for Step 1 (Nominee), for a single slot — [_next] only ever
  /// re-validates the last visible slot, so it always passes index
  /// `visibleNomineeSlots.value - 1` here.
  List<MapEntry<GlobalKey, bool Function()>> _nomineeCheckpoints(int index) {
    final slot = controller.nomineeSlots[index];

    return [
      MapEntry(
        _nomineePhotoKeys[index],
        () =>
            slot.photo.value == null && slot.photoDocumentId.value == null,
      ),
      MapEntry(
        _nomineeRelationKeys[index],
        () => slot.relationId.value == null,
      ),
      MapEntry(
        _nomineeAadharFrontKeys[index],
        () =>
            slot.aadharFrontImage.value == null &&
            slot.aadharFrontImageDocumentId.value == null,
      ),
      MapEntry(
        _nomineeAadharBackKeys[index],
        () =>
            slot.aadharBackImage.value == null &&
            slot.aadharBackImageDocumentId.value == null,
      ),
      MapEntry(
        _nomineePassbookKeys[index],
        () =>
            slot.passbookChequeImage.value == null &&
            slot.passbookChequeImageDocumentId.value == null,
      ),
      MapEntry(
        _nomineeShareKeys[index],
        () => (controller.totalShareEntered.value - 100).abs() > 0.01,
      ),
    ];
  }

  /// Ordered top-to-bottom checkpoint list for the Health Declaration step
  /// — same top-to-bottom order (and the exact same conditions) as
  /// RegistrationController.firstMissingHealthDetail, which is what
  /// saveHealthDeclaration itself uses to decide whether to block Next.
  List<MapEntry<GlobalKey, bool Function()>> _healthCheckpoints() => [
        MapEntry(
          _healthCurrentIllnessKey,
          () => controller.hasCurrentIllness.value == null,
        ),
        MapEntry(
          _healthCurrentIllnessDetailKey,
          () =>
              controller.hasCurrentIllness.value == true &&
              controller.seriousIllnessDetailController.text.trim().isEmpty,
        ),
        MapEntry(
          _healthHereditaryDetailKey,
          () =>
              controller.selectedDiseaseKeys.contains('disease_hereditary') &&
              controller.otherHereditaryDetailController.text.trim().isEmpty,
        ),
        MapEntry(
          _healthSurgeryKey,
          () => controller.hadSurgery.value == null,
        ),
        MapEntry(
          _healthSurgeryDetailKey,
          () =>
              controller.hadSurgery.value == true &&
              controller.surgeryDetailController.text.trim().isEmpty,
        ),
        MapEntry(
          _healthSurgeryDateKey,
          () =>
              controller.hadSurgery.value == true &&
              controller.surgeryDate.value == null,
        ),
        MapEntry(
          _healthMedicationKey,
          () => controller.onRegularMedication.value == null,
        ),
        MapEntry(
          _healthMedicationDetailKey,
          () =>
              controller.onRegularMedication.value == true &&
              controller.medicationDetailController.text.trim().isEmpty,
        ),
        MapEntry(
          _healthAllergyKey,
          () => controller.hasAllergies.value == null,
        ),
        MapEntry(
          _healthAllergyDetailKey,
          () =>
              controller.hasAllergies.value == true &&
              controller.allergyDetailController.text.trim().isEmpty,
        ),
        MapEntry(
          _healthTobaccoKey,
          () => controller.usesTobacco.value == null,
        ),
        MapEntry(
          _healthAlcoholKey,
          () => controller.consumesAlcohol.value == null,
        ),
        MapEntry(
          _healthDrugsKey,
          () => controller.usesDrugs.value == null,
        ),
      ];

  /// Scrolls to the first checkpoint (in the list's own order) whose
  /// condition is still true. No-op if every checkpoint currently passes,
  /// or if the failing one's key has no attached context yet (shouldn't
  /// normally happen — every checkpoint's widget is already on screen by
  /// the time Next can be tapped).
  /// Maps a `tblMemberField` id (any of a field's base/H/G variants) to
  /// the one physical widget's `GlobalKey` — used by
  /// [_scrollToActiveStep1QueryField] to jump straight to whichever field
  /// the current pass just unlocked, instead of leaving the member to
  /// hunt for it down a long form.
  GlobalKey? _step1KeyForFieldId(int fieldId) {
    const fatherIds = {12, 13, 14};
    const addressIds = {21, 22, 23};
    const villageIds = {24, 25, 26};
    const talukaIds = {27, 28, 29};
    const districtIds = {30, 31, 32};
    const stateIds = {33, 34, 35};
    const occupationIds = {38, 39, 40};
    if (fatherIds.contains(fieldId)) return _fatherNameKey;
    if (addressIds.contains(fieldId)) return _addressKey;
    if (villageIds.contains(fieldId)) return _villageKey;
    if (talukaIds.contains(fieldId)) return _talukaKey;
    if (districtIds.contains(fieldId)) return _districtKey;
    if (stateIds.contains(fieldId)) return _stateKey;
    if (occupationIds.contains(fieldId)) return _occupationKey;
    if (fieldId == 41) return _aadharNumberKey;
    if (fieldId == 43) return _panNumberKey;
    // Name parts (Surname/FirstName/LastName and their G/H versions) all
    // live in the one Full Name box.
    const nameIds = {2, 3, 4, 6, 7, 8, 9, 10, 11};
    if (nameIds.contains(fieldId)) return _fullNameKey;
    if (fieldId == 18) return _dobKey;
    if (fieldId == 19) return _genderKey;
    if (fieldId == 20) return _maritalStatusKey;
    if (fieldId == 37) return _mobile2Key;
    return null;
  }

  /// Same mapping as [_step1KeyForFieldId], but to the field's own
  /// (FocusNode, TextEditingController) pair instead of its GlobalKey —
  /// used by [_scrollToActiveStep1QueryField] to actually focus the field
  /// and place the cursor, not just scroll it into view.
  (FocusNode, TextEditingController)? _step1FocusTargetForFieldId(
    int fieldId,
  ) {
    const fatherIds = {12, 13, 14};
    const addressIds = {21, 22, 23};
    const villageIds = {24, 25, 26};
    const talukaIds = {27, 28, 29};
    const districtIds = {30, 31, 32};
    const stateIds = {33, 34, 35};
    const occupationIds = {38, 39, 40};
    if (fatherIds.contains(fieldId)) {
      return (fatherNameFocusNode, controller.fatherNameController);
    }
    if (addressIds.contains(fieldId)) {
      return (addressFocusNode, controller.addressController);
    }
    if (villageIds.contains(fieldId)) {
      return (villageFocusNode, controller.villageController);
    }
    if (talukaIds.contains(fieldId)) {
      return (talukaFocusNode, controller.talukaController);
    }
    if (districtIds.contains(fieldId)) {
      return (districtFocusNode, controller.districtController);
    }
    if (stateIds.contains(fieldId)) {
      return (stateFocusNode, controller.stateController);
    }
    if (occupationIds.contains(fieldId)) {
      return (occupationFocusNode, controller.occupationController);
    }
    if (fieldId == 41) {
      return (_aadharNumberFocusNode, controller.aadharNumberController);
    }
    if (fieldId == 43) {
      return (_panFocusNode, controller.panNumberController);
    }
    const nameIds = {2, 3, 4, 6, 7, 8, 9, 10, 11};
    if (nameIds.contains(fieldId)) {
      return (fullNameFocusNode, controller.queryFullNameController);
    }
    return null;
  }

  /// Scrolls to the first currently-unlocked query field on Step 1 — call
  /// whenever the screen first opens in query-resolution mode, and again
  /// each time a pass advances (so the member isn't left staring at a
  /// field that just got locked again with no idea where the next one
  /// is). Scrolling alone leaves the member to tap the field themselves
  /// before they can type — this also requests focus and places the
  /// cursor at the end of whatever's already there (these are prefilled
  /// values being corrected, not started from blank), so they can start
  /// typing immediately.
  void _scrollToActiveStep1QueryField() {
    final fieldId = controller.queryState.firstEditableFieldId(1);
    if (fieldId == null) return;
    final key = _step1KeyForFieldId(fieldId);
    if (key == null) return;
    final focusTarget = _step1FocusTargetForFieldId(fieldId);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final targetContext = key.currentContext;
      if (targetContext == null) return;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );

      if (focusTarget == null) return;
      final (focusNode, textController) = focusTarget;
      focusNode.requestFocus();
      textController.selection = TextSelection.collapsed(
        offset: textController.text.length,
      );
    });
  }

  /// Maps a `tblNomineeField` id to nominee [itemNumber]'s own GlobalKey —
  /// mirrors [_step1KeyForFieldId] for the Nominee table.
  GlobalKey? _nomineeKeyForFieldId(int itemNumber, int fieldId) {
    final index = itemNumber - 1;
    if (index < 0 || index >= _nomineePhotoKeys.length) return null;
    return switch (fieldId) {
      6 => _nomineePhotoKeys[index],
      2 || 8 || 9 => _nomineeNameKeys[index],
      4 => _nomineeRelationKeys[index],
      3 => _nomineeDobKeys[index],
      5 => _nomineeShareKeys[index],
      10 => _nomineeAadharFrontKeys[index],
      11 => _nomineeAadharBackKeys[index],
      12 => _nomineePassbookKeys[index],
      _ => null,
    };
  }

  /// Same idea as [_scrollToActiveStep1QueryField], for the Nominee
  /// table's currently-active nominee [itemNumber] — call whenever this
  /// nominee's slot first becomes the "current" one and again each time
  /// its own pass advances or Next is blocked mid-pass. Only Name has a
  /// FocusNode worth requesting (Relation/DateOfBirth/photos aren't typed
  /// into directly — DateOfBirth opens a picker, Aadhaar/Share still
  /// scroll into view but don't get an artificial focus request).
  void _scrollToActiveNomineeQueryField(int itemNumber) {
    final fieldId = controller.queryState.firstEditableFieldId(
      2,
      itemNumber: itemNumber,
    );
    if (fieldId == null) return;
    final key = _nomineeKeyForFieldId(itemNumber, fieldId);
    if (key == null) return;
    final slotIndex = itemNumber - 1;
    final isNameField = fieldId == 2 || fieldId == 8 || fieldId == 9;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final targetContext = key.currentContext;
      if (targetContext == null) return;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );

      if (!isNameField) return;
      final slot = controller.nomineeSlots[slotIndex];
      slot.nameFocusNode.requestFocus();
      slot.nameController.selection = TextSelection.collapsed(
        offset: slot.nameController.text.length,
      );
    });
  }

  /// Maps a `tblHealthDeclarationFields` id to its own GlobalKey — mirrors
  /// [_step1KeyForFieldId]/[_nomineeKeyForFieldId] for Health Declaration.
  /// Only the fields this flow can actually unlock are listed (see
  /// RegistrationController's Health Declaration doc comment for why the
  /// other ~33 fields aren't wired) — a query against anything else has
  /// nowhere on screen to scroll to.
  GlobalKey? _healthKeyForFieldId(int fieldId) {
    if (fieldId >= 5 && fieldId <= 17) return _healthDiseaseChipsKey;
    return switch (fieldId) {
      3 => _healthCurrentIllnessKey,
      4 || 30 || 31 => _healthCurrentIllnessDetailKey,
      18 || 32 || 33 => _healthHereditaryDetailKey,
      19 => _healthSurgeryKey,
      20 || 34 || 35 => _healthSurgeryDetailKey,
      21 => _healthSurgeryDateKey,
      22 => _healthMedicationKey,
      23 => _healthMedicationDetailKey,
      24 => _healthAllergyKey,
      25 || 36 || 37 => _healthAllergyDetailKey,
      26 => _healthTobaccoKey,
      27 => _healthAlcoholKey,
      28 => _healthDrugsKey,
      29 || 38 || 39 => _healthOtherDetailsKey,
      _ => null,
    };
  }

  /// `true` when any of these Health Declaration field ids has an active
  /// query — used to keep a detail box visible (even while its yes/no
  /// answer is "no") so a flagged field can never be hidden and unfixable.
  bool _healthQueried(List<int> ids) =>
      controller.queryState.isActive &&
      ids.any((id) => controller.queryState.hasQueryFor(3, id));

  /// Same idea as [_scrollToActiveStep1QueryField], for Health
  /// Declaration (table 3, no itemNumber). Only the 2 triple-language
  /// text fields (Other/otherDetails) get an actual focus request — the
  /// yes/no toggles just scroll into view, same as Nominee's
  /// non-Name fields.
  void _scrollToActiveHealthQueryField() {
    final fieldId = controller.queryState.firstEditableFieldId(3);
    if (fieldId == null) return;
    final key = _healthKeyForFieldId(fieldId);
    if (key == null) return;
    final isHereditary = fieldId == 18 || fieldId == 32 || fieldId == 33;
    final isOtherDetails = fieldId == 29 || fieldId == 38 || fieldId == 39;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final targetContext = key.currentContext;
      if (targetContext == null) return;
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );

      // Other detail boxes: focus + cursor at the end, same as below.
      final detailTargets = <List<int>, (FocusNode, TextEditingController)>{
        const [4, 30, 31]: (
          seriousIllnessDetailFocusNode,
          controller.seriousIllnessDetailController,
        ),
        const [20, 34, 35]: (
          surgeryDetailFocusNode,
          controller.surgeryDetailController,
        ),
        const [25, 36, 37]: (
          allergyDetailFocusNode,
          controller.allergyDetailController,
        ),
      };
      for (final entry in detailTargets.entries) {
        if (entry.key.contains(fieldId)) {
          final (node, textController) = entry.value;
          node.requestFocus();
          textController.selection = TextSelection.collapsed(
            offset: textController.text.length,
          );
          return;
        }
      }

      if (isHereditary) {
        otherHereditaryDetailFocusNode.requestFocus();
        controller.otherHereditaryDetailController.selection =
            TextSelection.collapsed(
          offset: controller.otherHereditaryDetailController.text.length,
        );
      } else if (isOtherDetails) {
        otherHealthDetailFocusNode.requestFocus();
        controller.otherHealthDetailController.selection =
            TextSelection.collapsed(
          offset: controller.otherHealthDetailController.text.length,
        );
      }
    });
  }

  void _scrollToFirstError(
    List<MapEntry<GlobalKey, bool Function()>> checkpoints,
  ) {
    for (final checkpoint in checkpoints) {
      if (!checkpoint.value()) continue;

      // Runs after this frame so the inline/Form error text that just
      // turned on above (via _showStep1Errors / showErrors / validate())
      // has already changed that field's height before we scroll to it —
      // scrolling first would undershoot by that text's height.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final targetContext = checkpoint.key.currentContext;
        if (targetContext == null) return;

        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      });
      return;
    }
  }

  // ============================================================
  // BACKGROUND-TRANSLATION FOCUS NODES
  //
  // Same pattern as register_screen.dart: fire the translate-on-blur call
  // the moment the user leaves a field, so its hi/gu variants are usually
  // already ready by the time Next is pressed.
  // ============================================================

  late final FocusNode fatherNameFocusNode;
  late final FocusNode addressFocusNode;
  late final FocusNode villageFocusNode;
  late final FocusNode talukaFocusNode;
  late final FocusNode districtFocusNode;
  late final FocusNode stateFocusNode;
  late final FocusNode occupationFocusNode;

  /// Query-resolution mode's Aadhaar number field has no FocusNode of its
  /// own elsewhere (unlike the 7 triple-language fields above, or PAN's
  /// `_panFocusNode`) — added so [_scrollToActiveStep1QueryField] can
  /// focus it too.
  final FocusNode _aadharNumberFocusNode = FocusNode();

  // Health step's own translated free-text detail fields — same
  // translate-on-blur pattern as the focus nodes above.
  // medicationDetailController has no focus node here: the swagger
  // schema's `medicationRegularly` has no hi/gu pair, so nothing needs to
  // fire on its unfocus (see RegistrationController's doc comment).
  late final FocusNode seriousIllnessDetailFocusNode;
  late final FocusNode otherHereditaryDetailFocusNode;
  late final FocusNode surgeryDetailFocusNode;
  late final FocusNode allergyDetailFocusNode;
  late final FocusNode otherHealthDetailFocusNode;

  // Editable combined first+middle+surname field. Seeded from whatever's
  // already saved (or prefilled via GetMemberStatus) by an `ever()`
  // worker (see initState) rather than being written directly inside
  // build — writing to a TextFormField's controller from inside an Obx
  // builder synchronously notifies that field's listener, which walks up
  // to the ancestor Form and calls setState() on it mid-build. Flutter
  // only allows marking a DESCENDANT dirty during a widget's build, not
  // an ancestor (the enclosing Form, in this case), so that crashed with
  // "setState() or markNeedsBuild() called during build." Updating the
  // controller from a worker callback — which runs outside of any build
  // phase — avoids the whole problem. In practice this worker only ever
  // fires before the user reaches this screen (member.value is set by
  // earlier GetMemberStatus/prefill flows, not while this field is being
  // edited), so it doesn't fight with the user's own edits below.
  late final TextEditingController fullNameController;

  late final FocusNode fullNameFocusNode;

  Worker? _fullNameWorker;

  // Re-groups controller.mobileController's text into the Indian 5+5
  // display format ("98765 43210") whenever it changes — needed because
  // that field is read-only (see below), so _MobileInputFormatter's
  // inputFormatters never actually run on it (those only fire on live
  // user typing, and the raw 10-digit value is instead set directly from
  // RegistrationController — see saveMemberStep1/getMemberStatus). The
  // equality guard stops this from looping: setting .text inside this
  // same listener re-notifies it once, but the second call is a no-op
  // since the text already matches its formatted form by then.
  void _formatMobileDisplay() {
    final formatted =
        AppValidators.formatMobile(controller.mobileController.text);
    if (controller.mobileController.text != formatted) {
      controller.mobileController.text = formatted;
    }
  }

  /// Forces Android to actually redraw the PAN field's on-screen keyboard
  /// when the cursor crosses between the letters zone and the digits zone
  /// (see _panKeyboardTypeFor/_PanInputFormatter._letterSlots). Just
  /// changing TextField.keyboardType on an already-focused field — even
  /// through a full element remount via a changing ValueKey, which was
  /// tried before this — doesn't reliably make every device's IME
  /// re-render an already-open keyboard; some stock keyboards (reported
  /// on this Motorola device) keep showing whatever layout is already up
  /// regardless. Dropping focus and picking it back up on the NEXT frame
  /// is the same trick segmented OTP fields use elsewhere: unfocus tears
  /// the platform text-input connection all the way down, and refocusing
  /// opens a brand new one with whatever TextInputType the field wants by
  /// then — that round trip is what actually makes the OS redraw it.
  void _handlePanKeyboardSwitch() {
    final value = controller.panNumberController.value;
    final cursorOffset = value.selection.end < 0
        ? value.text.length
        : value.selection.end.clamp(0, value.text.length);
    final isLetterZone =
        _PanInputFormatter._letterSlots.contains(cursorOffset.clamp(0, 9));

    if (_panLastZoneWasLetters == isLetterZone) return;
    _panLastZoneWasLetters = isLetterZone;

    // Nothing to redraw if the field isn't even focused right now (e.g.
    // this fired from a programmatic text change, not the member typing)
    // — the next time it IS focused, _panKeyboardTypeFor already picks
    // the right keyboard for wherever the cursor lands.
    if (!_panFocusNode.hasFocus) return;

    final selectionToRestore = value.selection;
    _panFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _panFocusNode.requestFocus();
      // unfocus/refocus alone would otherwise leave the cursor jumped to
      // the end instead of wherever the member actually left it.
      controller.panNumberController.selection = selectionToRestore;
    });
  }

  // Devanagari (Hindi) and Gujarati Unicode letter/matra blocks, alongside
  // plain a-zA-Z — matches AppValidators._scriptLetters so a name field's
  // live typing never blocks a script its own validator would accept.
  final _nameInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Zऀ-ॿ઀-૿\s]'),
  );

  // Same script ranges as above, plus digits/comma/hyphen — for place-name
  // style fields (village/taluka/district/state) whose validator is
  // AppValidators.placeName rather than AppValidators.name.
  final _placeNameInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9ऀ-ॿ઀-૿\s,\-]'),
  );

  // ============================================================
  // INLINE ERROR TEXT (Step 1 — gender/marital status/upload cards)
  //
  // These aren't TextFormFields, so Form.validate() never gave them their
  // own error text the way every text field gets one automatically —
  // they only ever surfaced through a toast. Flips true the first time
  // the member taps Next on step 1; each field's own _inlineError() Obx
  // below then shows/hides itself reactively, so it disappears the
  // moment the member fixes that one field — no manual per-field
  // clearing needed.
  // ============================================================

  final RxBool _showStep1Errors = false.obs;

  Widget _inlineError(
    bool Function() hasError,
    String message, {
    RxBool? showFlag,
  }) {
    final effectiveShowFlag = showFlag ?? _showStep1Errors;

    return Obx(() {
      if (!effectiveShowFlag.value || !hasError()) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: EdgeInsets.only(
          top: 6.px(context),
          left: 6.px(context),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: AppColors.danger,
            fontSize: 12.px(context),
          ),
        ),
      );
    });
  }

  Worker? _languageMirrorWorker;

  @override
  void initState() {
    super.initState();

    // Query-resolution mode: the top-right language icon opens the same
    // sheet as the drawer and really changes the app language, so this
    // flow's own labels/toasts simply mirror whatever that currently is.
    if (controller.queryState.isActive) {
      final languageController = Get.find<LanguageController>();
      controller.queryState.localLanguage.value =
          languageController.currentAppLanguage;
      _languageMirrorWorker = ever(languageController.locale, (_) {
        controller.queryState.localLanguage.value =
            languageController.currentAppLanguage;

        // The saved values (name, address, village, nominee names, health
        // details...) already exist in all three languages — show the
        // ones matching the newly selected language, not just new labels.
        controller.refreshLocalizedDisplay();
        final fullName = controller.localizedFullNameText();
        if (fullName != null && fullNameController.text != fullName) {
          fullNameController.text = fullName;
        }
      });
    }

    // localizedFullName (not the plain fullName getter) so a resumed
    // member who picked Hindi/Gujarati sees their own already-saved
    // translation here too, not just the plain/English text — same fix as
    // RegistrationController.getMemberStatus's other resumed fields (see
    // MemberModel.localizedFullName's doc comment).
    fullNameController = TextEditingController(
      text: controller.member.value?.localizedFullName(
            Get.find<LanguageController>().currentAppLanguage,
          ) ??
          '',
    );

    // `ever` fires only on SUBSEQUENT changes to controller.member, so the
    // constructor above still needs to seed the initial value itself.
    _fullNameWorker = ever<MemberModel?>(controller.member, (member) {
      fullNameController.text = member?.localizedFullName(
            Get.find<LanguageController>().currentAppLanguage,
          ) ??
          '';
    });

    fullNameFocusNode = FocusNode()..addListener(_onFullNameFocusChange);

    controller.mobileController.addListener(_formatMobileDisplay);
    _formatMobileDisplay();

    controller.panNumberController.addListener(_handlePanKeyboardSwitch);

    fatherNameFocusNode = FocusNode()..addListener(_onFatherNameFocusChange);
    addressFocusNode = FocusNode()..addListener(_onAddressFocusChange);
    villageFocusNode = FocusNode()..addListener(_onVillageFocusChange);
    talukaFocusNode = FocusNode()..addListener(_onTalukaFocusChange);
    districtFocusNode = FocusNode()..addListener(_onDistrictFocusChange);
    stateFocusNode = FocusNode()..addListener(_onStateFocusChange);
    occupationFocusNode = FocusNode()..addListener(_onOccupationFocusChange);

    seriousIllnessDetailFocusNode = FocusNode()
      ..addListener(_onSeriousIllnessDetailFocusChange);
    otherHereditaryDetailFocusNode = FocusNode()
      ..addListener(_onOtherHereditaryDetailFocusChange);
    surgeryDetailFocusNode = FocusNode()
      ..addListener(_onSurgeryDetailFocusChange);
    allergyDetailFocusNode = FocusNode()
      ..addListener(_onAllergyDetailFocusChange);
    otherHealthDetailFocusNode = FocusNode()
      ..addListener(_onOtherHealthDetailFocusChange);

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadMember();

      // Prefill the Nominee step from whatever was already saved for this
      // member, if any — e.g. the member saved one nominee, closed the
      // app, and reopened it later; GetMemberStatus/legal-rules will have
      // routed straight back to this screen with memberId already known.
      // Runs regardless of which step is currently showing since all four
      // steps share this one screen/controller.
      controller.loadExistingNominees();

      // Same "prefill from whatever's already saved" reasoning, for the
      // Health step.
      controller.loadExistingHealthDeclaration();

      // Resume on the correct internal step (Member/Nominee/Health/Rules)
      // instead of always opening on step 1 — see
      // RegistrationNavigator.navigateToScreen, which is the only caller
      // that ever sets this argument.
      _applyResumeStepFromArguments();

      // Query-resolution mode: jump straight to the correct STEP first —
      // login always opens this screen on Step 1 regardless of which
      // table actually has queries, so a member whose only flagged
      // fields are on Nominee/Health used to have to look at a fully
      // locked Personal Details screen and tap Next once before landing
      // anywhere useful. queryModeNextPage(-1) is the same "skip any
      // table with nothing queried" walk Next already does, just started
      // one step before the beginning. Then jump straight to whichever
      // field actually needs fixing — query state (unlike the prefilled
      // values above) is already set by the time this screen opens, so
      // this doesn't need to wait on _loadMember's own async work.
      if (controller.queryState.isActive) {
        final initialStep = controller.queryModeNextPage(-1);
        if (initialStep != controller.currentStep.value) {
          controller.currentStep.value = initialStep;
          pageController.jumpToPage(initialStep);
        }

        switch (initialStep) {
          case 0:
            _scrollToActiveStep1QueryField();
          case 1:
            final currentNominee =
                controller.queryModeCurrentNomineeItemNumber();
            if (currentNominee != null) {
              _scrollToActiveNomineeQueryField(currentNominee);
            }
          case 2:
            _scrollToActiveHealthQueryField();
        }
      }
    });
  }

  /// Reads the `initialStep` route argument RegistrationNavigator attaches
  /// when resuming mid-registration (e.g. the member re-entered their name
  /// on the Register screen and GetSingleMemberByRegistredStatus returned
  /// "/member-registration-step3") and jumps straight there — both the
  /// controller's own step counter (drives _StepIndicator/back-button
  /// logic) and the PageView itself. A no-op on a fresh registration,
  /// where no such argument is passed.
  void _applyResumeStepFromArguments() {
    final arguments = Get.arguments;

    if (arguments is! Map || arguments['initialStep'] is! int) return;

    final requestedStep = arguments['initialStep'] as int;
    final step = requestedStep < 0
        ? 0
        : (requestedStep > RegistrationController.totalSteps - 1
            ? RegistrationController.totalSteps - 1
            : requestedStep);

    controller.currentStep.value = step;

    if (pageController.hasClients) {
      pageController.jumpToPage(step);
    }
  }

  Future<void> _loadMember() async {
    final currentMember =
        controller.member.value;

    if (currentMember == null) {
      return;
    }

    await controller.getMemberStatus(
      isRegistered: true,
      firstName:
      currentMember.firstName ?? '',
      middleName:
      currentMember.lastName ?? '',
      surname:
      currentMember.surname ?? '',
      mobile:
      currentMember.mobile ?? '',
    );
  }

  // ============================================================
  // FOCUS-CHANGE TRANSLATION LISTENERS
  // ============================================================

  void _onFullNameFocusChange() {
    if (fullNameFocusNode.hasFocus || controller.queryState.isActive) return;
    controller.splitAndTranslateFullName(fullNameController.text);
  }

  // Query-resolution mode never calls the transliteration API — the
  // member types each queried field's required script themselves (see
  // QueryResolutionState's doc comment) — so every one of these on-unfocus
  // handlers below skips its translate call while that mode is active,
  // the same way _next() already skips splitAndTranslateFullName/
  // translateAllStep1Fields for the same reason. Gated on
  // `queryState.isActive` (the whole flow, not just Step 1) so a Health
  // Declaration field queried in the future is covered too, without
  // needing a second fix when that table gets wired up.
  bool get _skipTranslateOnUnfocus => controller.queryState.isActive;

  void _onFatherNameFocusChange() {
    if (fatherNameFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.fatherNameController.text,
      targetModel: controller.fatherNameLanguages,
      isDirty: controller.isFatherNameDirty,
    );
  }

  void _onAddressFocusChange() {
    if (addressFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.addressController.text,
      targetModel: controller.addressLanguages,
      isDirty: controller.isAddressDirty,
    );
  }

  void _onSeriousIllnessDetailFocusChange() {
    if (seriousIllnessDetailFocusNode.hasFocus || _skipTranslateOnUnfocus) {
      return;
    }
    controller.translateNameFieldOnUnfocus(
      text: controller.seriousIllnessDetailController.text,
      targetModel: controller.seriousIllnessLanguages,
      isDirty: controller.isSeriousIllnessDirty,
    );
  }

  void _onOtherHereditaryDetailFocusChange() {
    if (otherHereditaryDetailFocusNode.hasFocus || _skipTranslateOnUnfocus) {
      return;
    }
    controller.translateNameFieldOnUnfocus(
      text: controller.otherHereditaryDetailController.text,
      targetModel: controller.otherHereditaryLanguages,
      isDirty: controller.isOtherHereditaryDirty,
    );
  }

  void _onSurgeryDetailFocusChange() {
    if (surgeryDetailFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.surgeryDetailController.text,
      targetModel: controller.surgeryLanguages,
      isDirty: controller.isSurgeryDirty,
    );
  }

  void _onAllergyDetailFocusChange() {
    if (allergyDetailFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.allergyDetailController.text,
      targetModel: controller.allergyLanguages,
      isDirty: controller.isAllergyDirty,
    );
  }

  void _onOtherHealthDetailFocusChange() {
    if (otherHealthDetailFocusNode.hasFocus || _skipTranslateOnUnfocus) {
      return;
    }
    controller.translateNameFieldOnUnfocus(
      text: controller.otherHealthDetailController.text,
      targetModel: controller.otherHealthDetailLanguages,
      isDirty: controller.isOtherHealthDetailDirty,
    );
  }

  void _onVillageFocusChange() {
    if (villageFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.villageController.text,
      targetModel: controller.villageLanguages,
      isDirty: controller.isVillageDirty,
    );
  }

  void _onTalukaFocusChange() {
    if (talukaFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.talukaController.text,
      targetModel: controller.talukaLanguages,
      isDirty: controller.isTalukaDirty,
    );
  }

  void _onDistrictFocusChange() {
    if (districtFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.districtController.text,
      targetModel: controller.districtLanguages,
      isDirty: controller.isDistrictDirty,
    );
  }

  void _onStateFocusChange() {
    if (stateFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.stateController.text,
      targetModel: controller.stateLanguages,
      isDirty: controller.isStateDirty,
    );
  }

  void _onOccupationFocusChange() {
    if (occupationFocusNode.hasFocus || _skipTranslateOnUnfocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.occupationController.text,
      targetModel: controller.occupationLanguages,
      isDirty: controller.isOccupationDirty,
    );
  }

  // ============================================================
  // NEXT
  // ============================================================

  Future<void> _next() async {
    final step =
        controller.currentStep.value;

    if (step == 0) {
      // Turns on every inline error below (each one only actually shows
      // if its own field is still invalid) instead of a toast — see
      // _inlineError's doc comment.
      _showStep1Errors.value = true;

      final formValid =
          memberFormKey.currentState!.validate();

      // Covers every custom (non-TextFormField) check — profile image,
      // gender, marital status, aadhaar front/back photo, pan photo,
      // signature — plus a fresh re-check of every text field's own
      // validator (so this list alone always knows the true first error
      // in top-to-bottom order, whether Form.validate() or a custom check
      // is what actually caught it). Also passes a document check when
      // its id already exists (from an earlier session's upload, prefilled
      // by getMemberStatus) — a returning member isn't forced to re-pick a
      // photo that already uploaded successfully. See
      // uploadStep1Documents' matching check.
      final step0Checkpoints = _step0Checkpoints();
      final hasCheckpointError =
          step0Checkpoints.any((checkpoint) => checkpoint.value());

      if (!formValid || hasCheckpointError) {
        _scrollToFirstError(step0Checkpoints);
        return;
      }

      final inQueryMode = controller.queryState.isActive;

      if (inQueryMode && !controller.queryModeStep1Resolved()) {
        ToastUtil.error(
          _flowLocalized(
            controller.queryState.localLanguage.value,
            'query_resolve_all_fields_error',
          ),
        );
        // More than one field can share the same pass (e.g. two Gujarati
        // fields queried together) — fixing one and tapping Next without
        // fixing the other used to just toast with no way to tell WHICH
        // field still needed attention. Jump straight to it, same as the
        // pass-advance and initial-open cases already do.
        _scrollToActiveStep1QueryField();
        return;
      }

      // Dismiss keyboard so no focus events fire during the async work.
      FocusScope.of(context).unfocus();

      // Query-resolution mode never calls the transliteration API — the
      // member types the required script themselves (see
      // QueryResolutionState's doc comment) — so both the full-name
      // split/translate safety net and the dirty-field sweep below are
      // skipped entirely in that mode.
      if (!inQueryMode) {
        // Safety net for the full-name split/translate: normally already
        // done by _onFullNameFocusChange when the field loses focus, this
        // just guarantees it's finished (and re-attempts it if the previous
        // attempt failed) even if that never fired in time — same reasoning
        // as translateAllStep1Fields below. The Form validation above has
        // already confirmed the text is a validly-formatted full name.
        await controller.splitAndTranslateFullName(fullNameController.text);

        // Translate every dirty/incomplete field before saving.
        await controller.translateAllStep1Fields();

        final incompleteField =
            controller.firstIncompleteStep1Field();

        if (incompleteField != null) {
          ToastUtil.error(
            'field_translation_failed'.trParams({'label': incompleteField.tr}),
          );
          return;
        }
      }

      // Upload documents, then save the personal-detail step. The loader
      // is shown internally for the whole sequence.
      final saved = await controller.saveMemberPersonalDetail();

      if (!saved) {
        return;
      }

      if (inQueryMode) {
        await controller.resolveStep1Queries();

        // More passes remain on this same screen (e.g. Gujarati fields
        // just resolved, Hindi fields still pending) — stay put, switch
        // the screen's local language to the next pass, tell the member
        // why via toast, and scroll to the newly-unlocked field, instead
        // of advancing to the next step.
        if (!controller.queryModeStep1FullyResolved()) {
          final prevLanguage = controller.queryState.passLanguageFor(1);
          controller.queryState.primeLocalLanguageForScreen(1);
          // Show the saved value of the language now being fixed, instead
          // of the previous pass's leftover text in the shared box.
          controller.seedQueryModeStep1Fields();
          controller.recheckStep1ScriptMismatches();
          _toastPassAdvanced(
            prevLanguage,
            controller.queryState.passLanguageFor(1),
          );

          _scrollToActiveStep1QueryField();
          return;
        }
      }

      ToastUtil.success('information_saved_successfully'.tr);

      final nextPage = inQueryMode ? controller.queryModeNextPage(0) : 1;

      // Query mode never shows the Rules step (registration-only) — once
      // nothing else is left to fix, go straight to Preview.
      if (inQueryMode && nextPage >= 3) {
        Get.toNamed(AppRoutes.registrationPreview);
        return;
      }

      controller.currentStep.value = nextPage;

      await pageController.animateToPage(
        nextPage,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Landed on Nominee with queries of its own waiting — jump straight
      // to the first one, same as Step 1's own initial auto-scroll.
      if (inQueryMode && nextPage == 1) {
        final currentNominee = controller.queryModeCurrentNomineeItemNumber();
        if (currentNominee != null) {
          _scrollToActiveNomineeQueryField(currentNominee);
        }
      } else if (inQueryMode && nextPage == 2) {
        // Nominee had nothing queried — queryModeNextPage skipped straight
        // to Health Declaration.
        _scrollToActiveHealthQueryField();
      }

      return;
    }

    if (step == 1) {
      if (controller.queryState.isActive) {
        await _nextQueryModeNominee();
        return;
      }

      // Only the currently-last-visible nominee slot can still be
      // unsaved here — every earlier slot was already validated + saved
      // via SaveNominee the moment "Add another nominee" revealed the
      // next one (see _saveNomineeSlotAndReveal). Re-validating/re-saving
      // that last slot on Next covers the case where the member filled it
      // in and tapped Next directly, without ever tapping "Add another".
      final lastNomineeIndex =
          controller.visibleNomineeSlots.value - 1;

      final lastSlot =
          controller.nomineeSlots[lastNomineeIndex];

      // Same as _saveNomineeSlotAndReveal — reveal this slot's inline
      // error state before validating.
      lastSlot.showErrors.value = true;

      // Recomputed up-front (not just right before the share check below)
      // so the share checkpoint's condition is already accurate by the
      // time _scrollToFirstError reads it, same reasoning as
      // _step0Checkpoints being a fresh re-check of every field.
      controller.recomputeTotalShare();

      _scrollToFirstError(_nomineeCheckpoints(lastNomineeIndex));

      if (!nomineeSlotFormKeys[lastNomineeIndex]
          .currentState!
          .validate()) {
        return;
      }

      if (lastSlot.photo.value == null &&
          lastSlot.photoDocumentId.value == null) {
        _showError(
          'please_upload_nominee_photo'.tr,
        );
        return;
      }

      if (lastSlot.relationId.value == null) {
        _showError(
          'please_select_option'.trParams({'label': 'relationship'.tr}),
        );
        return;
      }

      if (lastSlot.aadharFrontImage.value == null &&
          lastSlot.aadharFrontImageDocumentId.value == null) {
        _showError('please_upload_nominee_aadhaar_front_photo'.tr);
        return;
      }

      if (lastSlot.aadharBackImage.value == null &&
          lastSlot.aadharBackImageDocumentId.value == null) {
        _showError('please_upload_nominee_aadhaar_back_photo'.tr);
        return;
      }

      if (lastSlot.passbookChequeImage.value == null &&
          lastSlot.passbookChequeImageDocumentId.value == null) {
        _showError('please_upload_nominee_passbook_cheque_photo'.tr);
        return;
      }

      controller.recomputeTotalShare();

      // The combined nominee share must hit exactly 100% before the
      // member can leave this step — unlike saveNomineeSlot's own check
      // (used on "Add another nominee" too), which only ever blocks
      // going OVER 100%, since under 100% is expected while the member
      // is still in the middle of adding more nominees.
      if ((controller.totalShareEntered.value - 100).abs() > 0.01) {
        _showError(
          'nominee_share_must_be_100'.trParams({
            'total': _formatShareForDisplay(controller.totalShareEntered.value),
          }),
        );
        return;
      }

      FocusScope.of(context).unfocus();

      final nomineeSaved =
          await controller.saveNomineeSlot(lastNomineeIndex);

      if (!nomineeSaved) {
        return;
      }

      final nomineeScreenSaved =
          await controller.saveNomineeScreen();

      if (!nomineeScreenSaved) {
        return;
      }

      controller.nextStep();

      await pageController.animateToPage(
        2,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      return;
    }

    if (step == 2) {
      // Health Declaration — the yes/no questions are required (their
      // attached detail field too, once answered "yes" — see
      // firstMissingHealthDetail), and SaveMemberHealthDeclaration is
      // always called here (create on the first Next, update on every one
      // after).
      //
      // Dismiss the keyboard/unfocus whatever detail field was still
      // being typed in BEFORE calling saveHealthDeclaration — the same
      // "tap Next without ever tapping away from the field first" case
      // the Member step's full-name/other text fields guard against.
      // saveHealthDeclaration() itself awaits each visible detail field's
      // hi/gu translation (re-reading the controller's current text, not
      // whatever was last translated) before building the save request,
      // so the just-typed value's translated languages are always what
      // gets saved, never a stale/empty one — and only then is the save
      // API itself called, also awaited.
      final inHealthQueryMode = controller.queryState.isActive;

      if (inHealthQueryMode && !controller.queryModeHealthResolved()) {
        ToastUtil.error(
          _flowLocalized(
            controller.queryState.localLanguage.value,
            'query_resolve_all_fields_error',
          ),
        );
        _scrollToActiveHealthQueryField();
        return;
      }

      FocusScope.of(context).unfocus();

      final healthDeclarationSaved =
          await controller.saveHealthDeclaration();

      if (!healthDeclarationSaved) {
        // Only scroll when the failure was a missing/invalid field —
        // firstMissingHealthDetail() is exactly what saveHealthDeclaration
        // itself checked first. A null here means the false came from a
        // real save/API error instead (see saveHealthDeclaration), which
        // has nothing on screen to scroll to.
        if (!inHealthQueryMode && controller.firstMissingHealthDetail() != null) {
          _scrollToFirstError(_healthCheckpoints());
        }
        return;
      }

      if (inHealthQueryMode) {
        await controller.resolveHealthQueries();

        if (!controller.queryModeHealthFullyResolved()) {
          final prevLanguage = controller.queryState.passLanguageFor(3);
          controller.queryState.primeLocalLanguageForScreen(3);
          controller.seedQueryModeHealthFields();
          controller.recheckHealthScriptMismatches();
          _toastPassAdvanced(
            prevLanguage,
            controller.queryState.passLanguageFor(3),
          );
          _scrollToActiveHealthQueryField();
          return;
        }
      }

      // Query mode skips the Rules step (registration-only) — straight to
      // Preview once Health is saved and resolved.
      if (inHealthQueryMode) {
        Get.toNamed(AppRoutes.registrationPreview);
        return;
      }

      controller.nextStep();

      await pageController.animateToPage(
        3,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      return;
    }

    await _finishRegistration();
  }

  /// Toast shown when a pass finishes but the same screen still has
  /// another language to fill: names the language JUST completed and the
  /// one that comes next (Gujarati > Hindi > English), written in the
  /// member's selected app language.
  void _toastPassAdvanced(AppLanguage completed, AppLanguage next) {
    ToastUtil.info(
      _flowLocalized(
        controller.queryState.localLanguage.value,
        'query_pass_advanced_toast',
        params: {
          'prevLanguage': completed.displayName,
          'nextLanguage': next.displayName,
        },
      ),
    );
  }

  /// Query-resolution mode's Next handling for the Nominee step. Every
  /// nominee with a pending query is editable at once; on Next, in order:
  /// validate that each one's current pass is fixed, SAVE each queried
  /// nominee with its new data (SaveNominee, one nominee at a time), then
  /// call QueryResolve for each nominee's resolved query ids one by one.
  /// If some nominee still has another language pass left, stay on this
  /// screen for it; otherwise finalize the screen and move on.
  Future<void> _nextQueryModeNominee() async {
    final queriedNominees = controller.queryModeUnresolvedNominees();

    if (queriedNominees.isEmpty) {
      // Nothing queried on this table (or everything already resolved) —
      // just move on to wherever query mode's forward-skip logic sends us.
      final nextPage = controller.queryModeNextPage(1);
      if (nextPage >= 3) {
        Get.toNamed(AppRoutes.registrationPreview);
        return;
      }
      controller.currentStep.value = nextPage;
      await pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      if (nextPage == 2) _scrollToActiveHealthQueryField();
      return;
    }

    for (final itemNumber in queriedNominees) {
      if (!controller.queryModeNomineeCurrentPassResolved(itemNumber)) {
        ToastUtil.error(
          _flowLocalized(
            controller.queryState.localLanguage.value,
            'query_resolve_all_fields_error',
          ),
        );
        _scrollToActiveNomineeQueryField(itemNumber);
        return;
      }
    }

    FocusScope.of(context).unfocus();

    // 1. Save every queried nominee with the new data, one by one.
    for (final itemNumber in queriedNominees) {
      final saved = await controller.saveNomineeSlot(itemNumber - 1);
      if (!saved) {
        _scrollToActiveNomineeQueryField(itemNumber);
        return;
      }
    }

    // 2. Then resolve each nominee's queries, one query id at a time.
    for (final itemNumber in queriedNominees) {
      await controller.resolveNomineeQueries(itemNumber);
    }

    // 3. Another language pass left on some nominee — stay for it.
    final remaining = controller.queryModeUnresolvedNominees();
    if (remaining.isNotEmpty) {
      final firstRemaining = remaining.first;
      final prevLanguage = controller.queryState.passLanguageFor(
        2,
        itemNumber: firstRemaining,
      );
      controller.primeAllQueriedNominees();
      _toastPassAdvanced(
        prevLanguage,
        controller.queryState.passLanguageFor(2, itemNumber: firstRemaining),
      );
      _scrollToActiveNomineeQueryField(firstRemaining);
      return;
    }

    // 4. Every queried nominee is saved + resolved — the one "finalize
    // this screen" call the normal flow also makes, then move on.
    final nomineeScreenSaved = await controller.saveNomineeScreen();
    if (!nomineeScreenSaved) {
      return;
    }

    ToastUtil.success(
      _flowLocalized(
        controller.queryState.localLanguage.value,
        'information_saved_successfully',
      ),
    );

    final nextPage = controller.queryModeNextPage(1);

    if (nextPage >= 3) {
      Get.toNamed(AppRoutes.registrationPreview);
      return;
    }

    controller.currentStep.value = nextPage;
    await pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (nextPage == 2) {
      _scrollToActiveHealthQueryField();
    }
  }

  // ============================================================
  // BACK
  // ============================================================

  Future<void> _back() async {
    if (controller.currentStep.value == 0) {
      Get.back();
      return;
    }

    controller.previousStep();

    await pageController.animateToPage(
      controller.currentStep.value,
      duration:
      const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ============================================================
  // FINISH
  //
  // No SaveNominee/finish endpoint was provided for this last step —
  // nominee details currently have nowhere on the backend to be
  // submitted. "Finish" here just means the user is done editing, so
  // this hands off to the Application Preview screen (a review + PDF
  // download step) instead of completing registration outright — the
  // actual "registration_completed_successfully" + navigate-home now
  // happens from that screen's own "Complete Registration" button.
  // ============================================================

  Future<void> _finishRegistration() async {
    if (!controller.acceptedRules.value) {
      _showError(
        'accept_terms_error'.tr,
      );
      return;
    }

    // SaveRulesRegulationAcceptScreen — this step's own accept-checkbox
    // save, distinct from SaveRulesRegulationScreen (already called much
    // earlier, from the Legal Rules screen). Only navigate to Preview once
    // it succeeds.
    final accepted = await controller.saveRulesRegulationAcceptScreen();

    if (!accepted) {
      return;
    }

    Get.toNamed(
      AppRoutes.registrationPreview,
    );
  }

  void _showError(String message) {
    ToastUtil.error(message, title: 'required'.tr);
  }

  Future<void> _openSignature() async {
    final File? signature =
    await Get.bottomSheet<File>(
      const AppSignatureBottomSheet(),
      isScrollControlled: true,
    );

    if (signature != null) {
      controller.setSignature(
        signature,
      );
    }
  }

  @override
  void dispose() {
    _languageMirrorWorker?.dispose();
    controller.mobileController.removeListener(_formatMobileDisplay);
    controller.panNumberController.removeListener(_handlePanKeyboardSwitch);
    _panFocusNode.dispose();
    _aadharNumberFocusNode.dispose();
    fatherNameFocusNode
      ..removeListener(_onFatherNameFocusChange)
      ..dispose();
    addressFocusNode
      ..removeListener(_onAddressFocusChange)
      ..dispose();
    villageFocusNode
      ..removeListener(_onVillageFocusChange)
      ..dispose();
    talukaFocusNode
      ..removeListener(_onTalukaFocusChange)
      ..dispose();
    districtFocusNode
      ..removeListener(_onDistrictFocusChange)
      ..dispose();
    stateFocusNode
      ..removeListener(_onStateFocusChange)
      ..dispose();
    occupationFocusNode
      ..removeListener(_onOccupationFocusChange)
      ..dispose();
    seriousIllnessDetailFocusNode
      ..removeListener(_onSeriousIllnessDetailFocusChange)
      ..dispose();
    otherHereditaryDetailFocusNode
      ..removeListener(_onOtherHereditaryDetailFocusChange)
      ..dispose();
    surgeryDetailFocusNode
      ..removeListener(_onSurgeryDetailFocusChange)
      ..dispose();
    allergyDetailFocusNode
      ..removeListener(_onAllergyDetailFocusChange)
      ..dispose();
    otherHealthDetailFocusNode
      ..removeListener(_onOtherHealthDetailFocusChange)
      ..dispose();

    fullNameController.dispose();
    fullNameFocusNode
      ..removeListener(_onFullNameFocusChange)
      ..dispose();
    _fullNameWorker?.dispose();

    pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        title: Text(
          'member_registration'.tr,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor:
        AppColors.background,
        elevation: 0,
        // The app's default AppBarTheme is styled for a dark/primary-color
        // bar (white title + white icons — see AppTheme.lightTheme), but
        // this screen overrides backgroundColor to the same light cream
        // used everywhere else in the wizard, without also overriding
        // foregroundColor. That left the title AND the automatic back
        // arrow rendering white text/icon on a near-white background —
        // technically there, but unreadable. The title above now gets an
        // explicit dark color, and the leading back arrow below is
        // rebuilt manually (dark too) instead of relying on the theme's
        // default.
        automaticallyImplyLeading: false,
        leading: Obx(
              () => controller.currentStep.value == 0
              // Step 1 is the only step where "back" genuinely means
              // "leave this screen" (see _back(): step 0 -> Get.back()).
              // From step 2 onward, going back means "previous step
              // within this same screen", which the dedicated Back
              // button in _buildBottomButtons already handles — showing
              // this same-looking arrow here too, on every step, was
              // redundant at best and confusing at worst (it popped the
              // whole registration screen instead of stepping back one
              // page). So it's only shown on step 1 now.
              ? IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
            ),
            onPressed: _back,
          )
              : const SizedBox.shrink(),
        ),
        // Query-resolution mode's OWN language toggle — manually
        // previewing labels/toasts in a different language than the
        // active pass, never the app's real locale (see
        // QueryResolutionState.localLanguage's doc comment). Hidden
        // entirely outside this flow. NOT wrapped in Obx: `isActive` is
        // a plain (non-Rx) getter that's decided once at login and never
        // changes for the rest of this screen's lifetime — wrapping it
        // in Obx anyway is exactly the "never reads a real observable"
        // case that throws GetX's own "improper use of Obx" check (same
        // bug already fixed on _queryAwareField/_querySimpleField/
        // _queryLockableImage — this one just needs no Obx at all rather
        // than an unconditional Rx read, since it truly never changes).
        actions: [
          if (controller.queryState.isActive)
            IconButton(
              icon: const Icon(
                Icons.translate,
                color: AppColors.primary,
              ),
              onPressed: LanguageSettingsSheet.show,
            ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Obx(
                  () => _StepIndicator(
                currentStep:
                controller.currentStep.value,
              ),
            ),

            SizedBox(
              height: 16.px(context),
            ),

            Expanded(
              child: PageView(
                controller:
                pageController,
                physics:
                const NeverScrollableScrollPhysics(),
                children: [
                  _buildMemberStep(
                    context,
                  ),
                  _buildNomineeStep(
                    context,
                  ),
                  _buildHealthStep(
                    context,
                  ),
                  _buildRulesStep(
                    context,
                  ),
                ],
              ),
            ),

            _buildBottomButtons(
              context,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a network-loaded preview (with a small edit badge) when nothing
  /// was picked THIS session but [networkUrl] is already available for a
  /// previously-uploaded document — resumed registration, prefilled by
  /// RegistrationController.getMemberStatus/loadExistingNominees — falling
  /// back to the normal [AppUploadContainer] "tap to upload" tile
  /// otherwise. Generalizes the Stack+CommonImageView pattern
  /// [_nomineeSlotCard] already uses for the nominee photo so every
  /// resumable document tile on this wizard (profile, Aadhaar front/back,
  /// PAN, signature, and the nominee's own new document tiles) shows the
  /// same way.
  Widget _uploadOrNetworkImage({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    File? file,
    String? networkUrl,
    VoidCallback? onRemove,
    bool isCircle = false,
    double? width,
    double? height,
  }) {
    if (file == null && networkUrl != null) {
      final tileWidth = width ?? double.infinity;
      final tileHeight = height ?? 160.px(context);

      final image = SizedBox(
        width: tileWidth,
        height: tileHeight,
        child: CommonImageView(
          image: networkUrl,
          type: CommonImageType.network,
          fit: BoxFit.cover,
          showPlaceholder: false,
        ),
      );

      return GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            isCircle
                ? Container(
              width: tileWidth,
              height: tileHeight,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              child: ClipOval(child: image),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(16.px(context)),
              child: image,
            ),
            Positioned(
              right: isCircle ? 0 : 8.px(context),
              bottom: isCircle ? 0 : 8.px(context),
              child: Container(
                padding: EdgeInsets.all(6.px(context)),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 14.px(context),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppUploadContainer(
      title: title,
      subtitle: subtitle,
      isCircle: isCircle,
      width: width,
      height: height,
      file: file,
      onTap: onTap,
      onRemove: onRemove,
    );
  }

  /// Query-resolution mode's lock/unlock treatment for an already-built
  /// widget that isn't a plain text field — a photo/signature tile, a
  /// dropdown, a date-picker trigger — same "every non-queried field is
  /// fully locked, a queried one starts red and turns green once touched"
  /// idea as [_queryAwareField]/[_querySimpleField]. [tableId] defaults to
  /// 1 (Step 1's 5 image/signature fields: Image=17, AadharImage=42,
  /// AadharBackImage=61, PanImage=44, DigitalSign=45); pass `tableId: 2`
  /// with [itemNumber] for a Nominee-table field (e.g. Relation=4,
  /// ProfilePhoto=6, the 3 document photos) on a specific nominee slot.
  /// Checked outside any Obx first for the same reason as those two: Obx
  /// requires a branch to always read a real observable, so "not in this
  /// flow" is handled before ever entering one. "Touched" is set by the
  /// picker/setSignature methods themselves (registration_controller.dart)
  /// the moment a new file is actually chosen, or by the dropdown/date
  /// field's own onChanged — not on tap alone, since tapping a photo just
  /// opens the source-picker sheet and the member may cancel it.
  Widget _queryLockableImage({
    required int fieldId,
    required Widget child,
    bool isCircle = false,
    int tableId = 1,
    int? itemNumber,
  }) {
    if (!controller.queryState.isActive) return child;

    return Obx(() {
      final queryState = controller.queryState;
      // Always read a real observable up front, regardless of which
      // branch this build takes below — Obx requires an actual `.value`
      // read on every build, and `isFieldEditable` returns early WITHOUT
      // touching any Rx at all when this field has no active query (the
      // common case: an account's queries usually target text fields
      // only, not every photo/signature slot), which throws GetX's
      // "improper use of Obx" check otherwise.
      final resolvedValue = queryState
          .isFieldResolved(tableId, fieldId, itemNumber: itemNumber)
          .value;
      final editable = queryState.isFieldEditable(
        tableId,
        fieldId,
        itemNumber: itemNumber,
      );
      final resolved = editable && resolvedValue;

      final locked = IgnorePointer(
        ignoring: !editable,
        child: Opacity(
          opacity: editable ? 1 : 0.45,
          child: child,
        ),
      );

      if (!editable) return locked;

      return Container(
        padding: EdgeInsets.all(3.px(context)),
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle
              ? null
              : BorderRadius.circular(18.px(context)),
          border: Border.all(
            color: resolved ? AppColors.success : AppColors.danger,
            width: 2,
          ),
        ),
        child: locked,
      );
    });
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _buildMemberStep(
      BuildContext context,
      ) {
    return Form(
      key: memberFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 20.px(context),
          vertical: 10.px(context),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              context,
              'personal_information'.tr,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryFlaggedBanner(1),

            Center(
              key: _profileImageKey,
              child: _queryLockableImage(
                fieldId: 17,
                isCircle: true,
                child: Obx(
                      () => _uploadOrNetworkImage(
                    context: context,
                    title: 'profile_photo'.tr,
                    subtitle:
                    'tap_to_upload'.tr,
                    isCircle: true,
                    width:
                    130.px(context),
                    height:
                    130.px(context),
                    file: controller
                        .profileImage.value,
                    networkUrl: controller
                        .profileImageUrl.value,
                    onTap: () {
                      controller
                          .showImageSourceSheet(
                        onSelected:
                        controller
                            .pickProfileImage,
                      );
                    },
                    onRemove: controller
                        .profileImage
                        .value !=
                        null
                        ? () {
                      controller
                          .profileImage
                          .value = null;
                    }
                        : null,
                  ),
                ),
              ),
            ),

            Center(
              child: _inlineError(
                () => controller.profileImage.value == null &&
                    controller.profileImageId.value == null,
                'please_upload_profile_photo'.tr,
              ),
            ),

            SizedBox(
              height: 24.px(context),
            ),

            // Editable combined first + middle + surname field. Format is
            // validated (EXACTLY "First Middle Surname" — 3 words, none
            // optional, each part letters-only, no leftover double/
            // leading/trailing space from deleting a word) by
            // AppValidators.fullName; on unfocus (and again right before
            // Save) the value is split back into parts and each one
            // re-translated — see splitAndTranslateFullName.
            _queryFullNameField(),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _fatherNameKey,
              // "Father's / Husband's Name" — same field either way (a
              // married woman may fill in her husband's name here), see
              // the printed scheme-benefit form's "પિતા / પતિનું નામ" /
              // "पिता / पति का नाम" label. RegistrationPreviewScreen
              // already shows it this way; this is the one other place
              // ('father_name' alone) that hadn't caught up.
              label: 'father_husband_name'.tr,
              labelKey: 'father_husband_name',
              hintText: 'father_name_hint'.tr,
              textController: controller.fatherNameController,
              focusNode: fatherNameFocusNode,
              validator: (value) => AppValidators.fatherName(
                value,
                message: 'father_name_format_error'.tr,
              ),
              inputFormatters: [
                _nameInputFormatter,
              ],
              baseFieldId: 12,
              hFieldId: 13,
              gFieldId: 14,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            // Read-only, same reasoning as Full Name above: this is the
            // number the member already submitted and confirmed back on
            // the Register screen (seeded into mobileController.text by
            // saveMemberStep1, then re-confirmed by getMemberStatus for a
            // resumed member or saveRulesAcceptance for a brand-new one —
            // see RegistrationController), so it's a summary field here,
            // never editable — a correction means going back to Register,
            // not overwriting the confirmed number in the middle of the
            // wizard.
            AppTextField.form(
              label: 'mobile_number'.tr,
              controller:
              controller.mobileController,
              readOnly: true,
              enabled: false,
              keyboardType:
              TextInputType.phone,
              maxLength: 11,
              validator:
              AppValidators.mobile,
              inputFormatters: [
                _MobileInputFormatter(),
              ],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            // Second/alternate number — optional, per the client's
            // requirements doc: AppValidators.mobileOptional never shows
            // an error just for being left blank, only if a non-empty
            // value doesn't match the expected 10-digit format.
            _querySimpleField(
              fieldKey: _mobile2Key,
              label: 'mobile_number_2'.tr,
              textController:
              controller.mobile2Controller,
              keyboardType:
              TextInputType.phone,
              maxLength: 11,
              validator:
              AppValidators.mobileOptional,
              inputFormatters: [
                _MobileInputFormatter(),
              ],
              tableId: 1,
              fieldId: 37,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _queryLockableImage(
                    fieldId: 18,
                    child: AppTextField.form(
                      key: _dobKey,
                      label: 'date_of_birth'.tr,
                      controller:
                      controller.dateOfBirthController,
                      readOnly: true,
                      validator:
                      AppValidators.date,
                      suffixIcon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                      onTap: () {
                        controller.pickDateOfBirth(
                          context,
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(width: 12.px(context)),

                // Age, derived automatically from the selected date of
                // birth — nothing for the user to enter.
                Expanded(
                  child: Obx(() {
                    final selectedDateOfBirth =
                        controller.dateOfBirth.value;

                    final ageText = selectedDateOfBirth != null
                        ? (() {
                            final age = AppDatePicker.calculateAgeYearsMonths(
                              selectedDateOfBirth,
                            );
                            return 'age_years_months'.trParams({
                              'years': '${age.years}',
                              'months': '${age.months}',
                            });
                          })()
                        : '';

                    return Container(
                      height: 56,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.px(context),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFD5D5D5),
                        ),
                      ),
                      child: Text(
                        ageText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.px(context),
                          color: AppColors.primaryDark,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            SizedBox(
              height: 20.px(context),
            ),

            _sectionTitle(context, 'gender'.tr),

            SizedBox(height: 10.px(context)),

            _queryLockableImage(
              fieldId: 19,
              child: Container(
                key: _genderKey,
                child: Obx(() => _genderRadioGroup(context)),
              ),
            ),

            _inlineError(
              () => controller.selectedGenderId.value == null,
              'please_select_gender'.tr,
            ),

            SizedBox(
              height: 20.px(context),
            ),

            _queryLockableImage(
              fieldId: 20,
              child: Container(
                key: _maritalStatusKey,
                child: Obx(
                      () => _enumDropdown(
                  context: context,
                  label: 'marital_status'.tr,
                  value: controller
                      .selectedMaritalStatusId
                      .value,
                  items: controller
                      .maritalStatusOptions
                      .value,
                  onChanged: (value) {
                    controller
                        .selectedMaritalStatusId
                        .value = value;
                    if (controller.queryState.isActive) {
                      controller.queryState.markTouched(1, 20);
                    }
                  },
                  hasError: _showStep1Errors.value &&
                      controller.selectedMaritalStatusId.value == null,
                ),
                ),
              ),
            ),

            _inlineError(
              () => controller.selectedMaritalStatusId.value == null,
              'please_select_marital_status'.tr,
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'address_details'.tr,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _addressKey,
              label: 'address'.tr,
              labelKey: 'address',
              textController: controller.addressController,
              focusNode: addressFocusNode,
              maxLines: 3,
              validator: AppValidators.requiredField,
              baseFieldId: 21,
              hFieldId: 22,
              gFieldId: 23,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _villageKey,
              label: 'village'.tr,
              labelKey: 'village',
              textController: controller.villageController,
              focusNode: villageFocusNode,
              validator: AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
              baseFieldId: 24,
              hFieldId: 25,
              gFieldId: 26,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _talukaKey,
              label: 'taluka'.tr,
              labelKey: 'taluka',
              textController: controller.talukaController,
              focusNode: talukaFocusNode,
              validator: AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
              baseFieldId: 27,
              hFieldId: 28,
              gFieldId: 29,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _districtKey,
              label: 'district'.tr,
              labelKey: 'district',
              textController: controller.districtController,
              focusNode: districtFocusNode,
              validator: AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
              baseFieldId: 30,
              hFieldId: 31,
              gFieldId: 32,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _stateKey,
              label: 'state'.tr,
              labelKey: 'state',
              textController: controller.stateController,
              focusNode: stateFocusNode,
              validator: AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
              baseFieldId: 33,
              hFieldId: 34,
              gFieldId: 35,
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'identity_documents'.tr,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _querySimpleField(
              fieldKey: _aadharNumberKey,
              label: 'aadhaar_number'.tr,
              labelKey: 'aadhaar_number',
              textController: controller.aadharNumberController,
              focusNode: _aadharNumberFocusNode,
              keyboardType: TextInputType.number,
              // 12 digits + 2 grouping spaces ("1234 5678 9012") — see
              // _AadharInputFormatter.
              maxLength: 14,
              validator: AppValidators.aadhar,
              inputFormatters: [
                _AadharInputFormatter(),
              ],
              tableId: 1,
              fieldId: 41,
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Container(
              key: _aadharFrontKey,
              child: _queryLockableImage(
                fieldId: 42,
                child: Obx(
                      () => _uploadOrNetworkImage(
                  context: context,
                  title:
                  'aadhaar_photo'.tr,
                  subtitle:
                  'tap_to_upload_image'.tr,
                  height:
                  180.px(context),
                  file: controller
                      .aadharImage.value,
                  networkUrl: controller
                      .aadharImageUrl.value,
                  onTap: () {
                    controller
                        .showImageSourceSheet(
                      onSelected:
                      controller
                          .pickAadharImage,
                    );
                  },
                  onRemove: controller
                      .aadharImage
                      .value !=
                      null
                      ? () {
                    controller
                        .aadharImage
                        .value = null;
                  }
                      : null,
                ),
                ),
              ),
            ),

            _inlineError(
              () => controller.aadharImage.value == null &&
                  controller.aadharImageId.value == null,
              'please_upload_aadhaar_photo'.tr,
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Container(
              key: _aadharBackKey,
              child: _queryLockableImage(
                fieldId: 61,
                child: Obx(
                      () => _uploadOrNetworkImage(
                  context: context,
                  title:
                  'aadhaar_back_photo'.tr,
                  subtitle:
                  'tap_to_upload_image'.tr,
                  height:
                  180.px(context),
                  file: controller
                      .aadharBackImage.value,
                  networkUrl: controller
                      .aadharBackImageUrl.value,
                  onTap: () {
                    controller
                        .showImageSourceSheet(
                      onSelected:
                      controller
                          .pickAadharBackImage,
                    );
                  },
                  onRemove: controller
                      .aadharBackImage
                      .value !=
                      null
                      ? () {
                    controller
                        .aadharBackImage
                        .value = null;
                  }
                      : null,
                ),
                ),
              ),
            ),

            _inlineError(
              () => controller.aadharBackImage.value == null &&
                  controller.aadharBackImageId.value == null,
              'please_upload_aadhaar_back_photo'.tr,
            ),

            SizedBox(
              height: 20.px(context),
            ),

            // Keyboard type follows the CURSOR through PAN's fixed
            // 5-letters / 4-digits / 1-letter layout — plain Latin
            // (visiblePassword — no Hindi/Gujarati IME) for the first 5
            // characters and the last one, phone-style number pad for the
            // 4 digits in between — instead of making the member manually
            // flip the keyboard themselves. ValueListenableBuilder (a
            // TextEditingController is a ValueListenable<TextEditingValue>)
            // rebuilds this field whenever its text OR its selection
            // changes — the selection change is what makes tapping to a
            // new position (with nothing actually typed) update the
            // keyboard too, not just typing/deleting. See
            // _panKeyboardTypeFor/_PanInputFormatter above for why
            // value.selection is always the member's real cursor position,
            // not just wherever typing last stopped.
            //
            // Just handing TextField a new `keyboardType` on rebuild isn't
            // enough by itself to make an already-open Android keyboard
            // redraw — a full element remount (previously tried here via a
            // ValueKey keyed to the zone) didn't reliably fix that either
            // on this device. See _handlePanKeyboardSwitch (listening on
            // controller.panNumberController, added in initState) for what
            // actually forces the redraw: an explicit unfocus-then-refocus
            // across a frame boundary whenever the cursor crosses zones.
            // _panFocusNode itself just stays put here — the switch is
            // handled entirely by that listener now.
            Container(
              key: _panNumberKey,
              // Query-resolution mode wraps the same cursor-tracking
              // ValueListenableBuilder in an outer Obx for the lock/
              // resolved/mismatch state — checked outside any Obx first,
              // same reasoning as _queryAwareField/_querySimpleField
              // above (Obx requires a branch to always read a real
              // observable, so the "not in this flow" case is handled
              // before ever entering one).
              child: !controller.queryState.isActive
                  ? ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.panNumberController,
                      builder: (context, value, _) {
                        final cursorOffset = value.selection.end < 0
                            ? value.text.length
                            : value.selection.end.clamp(0, value.text.length);

                        return AppTextField.form(
                          focusNode: _panFocusNode,
                          label: 'pan_number'.tr,
                          controller:
                          controller.panNumberController,
                          keyboardType: _panKeyboardTypeFor(cursorOffset),
                          textCapitalization:
                          TextCapitalization.characters,
                          validator:
                          AppValidators.pan,
                          inputFormatters: [
                            _PanInputFormatter(),
                          ],
                          onChanged: (text) {
                            // "Close the keyboard after completion" — PAN
                            // is always exactly 10 characters, so once the
                            // last one is entered there's nothing left to
                            // type.
                            if (text.length == 10) {
                              FocusScope.of(context).unfocus();
                            }
                          },
                        );
                      },
                    )
                  : Obx(() {
                      final queryState = controller.queryState;
                      // Always read real observables up front, regardless
                      // of which branch this build takes below — same fix
                      // as _queryAwareField/_querySimpleField/
                      // _queryLockableImage: isFieldEditable returns early
                      // WITHOUT touching any Rx at all when PAN has no
                      // active query this session, which would otherwise
                      // throw GetX's "improper use of Obx" check.
                      final resolvedValue =
                          queryState.isFieldResolved(1, 43).value;
                      final mismatchValue =
                          queryState.scriptMismatch(1, 43).value;
                      final editable = queryState.isFieldEditable(1, 43);
                      final resolved = editable && resolvedValue;
                      final mismatch = editable && mismatchValue;

                      String wrongScriptMessage() => _flowLocalized(
                            queryState.localLanguage.value,
                            'query_field_wrong_script',
                            params: {
                              'language': AppLanguage.english.displayName,
                            },
                          );

                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller.panNumberController,
                        builder: (context, value, _) {
                          final cursorOffset = value.selection.end < 0
                              ? value.text.length
                              : value.selection.end
                              .clamp(0, value.text.length);

                          return AppTextField.form(
                            focusNode: editable ? _panFocusNode : null,
                            label: _flowLocalized(
                              queryState.localLanguage.value,
                              'pan_number',
                            ),
                            controller: controller.panNumberController,
                            keyboardType: _panKeyboardTypeFor(cursorOffset),
                            textCapitalization:
                            TextCapitalization.characters,
                            validator: editable ? AppValidators.pan : null,
                            inputFormatters:
                            editable ? [_PanInputFormatter()] : null,
                            enabled: editable,
                            readOnly: !editable,
                            errorText: (mismatch || (editable && !resolved))
                ? wrongScriptMessage()
                : null,
                            enabledBorderColor: !editable
                                ? null
                                : (resolved
                                ? AppColors.success
                                : AppColors.danger),
                            // Without this, the red/green above is only
                            // ever visible while the field is NOT focused
                            // — auto-scroll immediately focuses a newly
                            // unlocked field, and AppTextField.form's
                            // focused border defaults to the app's plain
                            // teal theme color when this isn't set,
                            // masking the red/green entirely the instant
                            // focus lands (errorText's OWN built-in red
                            // still shows through regardless, which is
                            // why an ACTIVE mismatch was visible but a
                            // simply-unresolved-and-not-yet-touched field
                            // wasn't).
                            focusedBorderColor: !editable
                                ? null
                                : (resolved
                                ? AppColors.success
                                : AppColors.danger),
                            onChanged: !editable
                                ? null
                                : (text) {
                              if (text.length == 10) {
                                FocusScope.of(context).unfocus();
                              }
                              controller.queryModeTouchSimpleField(
                                1,
                                43,
                                text,
                              );
                              final isMismatched =
                                  queryState.scriptMismatch(1, 43).value;
                              if (queryState.shouldToastMismatch(
                                1,
                                43,
                                isMismatched,
                              )) {
                                ToastUtil.error(wrongScriptMessage());
                              }
                            },
                          );
                        },
                      );
                    }),
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Container(
              key: _panImageKey,
              child: _queryLockableImage(
                fieldId: 44,
                child: Obx(
                      () => _uploadOrNetworkImage(
                  context: context,
                  title: 'upload_pan_card'.tr,
                  subtitle:
                  'tap_to_upload_image'.tr,
                  height:
                  180.px(context),
                  file: controller
                      .panImage.value,
                  networkUrl: controller
                      .panImageUrl.value,
                  onTap: () {
                    controller
                        .showImageSourceSheet(
                      onSelected:
                      controller
                          .pickPanImage,
                    );
                  },
                  onRemove: controller
                      .panImage
                      .value !=
                      null
                      ? () {
                    controller
                        .panImage
                        .value = null;
                  }
                      : null,
                ),
                ),
              ),
            ),

            _inlineError(
              () => controller.panImage.value == null &&
                  controller.panImageId.value == null,
              'please_upload_pan_photo'.tr,
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'occupation'.tr,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            _queryAwareField(
              fieldKey: _occupationKey,
              label: 'occupation'.tr,
              labelKey: 'occupation',
              textController: controller.occupationController,
              focusNode: occupationFocusNode,
              validator: AppValidators.name,
              baseFieldId: 38,
              hFieldId: 39,
              gFieldId: 40,
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'signature'.tr,
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Container(
              key: _signatureKey,
              child: _queryLockableImage(
                fieldId: 45,
                child: Obx(
                      () => _uploadOrNetworkImage(
                  context: context,
                  title: 'your_signature'.tr,
                  subtitle:
                  'tap_to_enter_signature'.tr,
                  height:
                  160.px(context),
                  file: controller
                      .signatureFile.value,
                  networkUrl: controller
                      .signatureFileUrl.value,
                  onTap: _openSignature,
                  onRemove: controller
                      .signatureFile.value !=
                      null
                      ? controller.clearSignature
                      : null,
                ),
                ),
              ),
            ),

            _inlineError(
              () => controller.signatureFile.value == null &&
                  controller.signatureFileId.value == null,
              'please_enter_your_signature'.tr,
            ),

            SizedBox(
              height: 30.px(context),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2 — NOMINEE (up to RegistrationController.maxNominees slots)
  // ============================================================

  Widget _buildNomineeStep(
      BuildContext context,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 20.px(context),
        vertical: 10.px(context),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'nominee_details'.tr,
          ),

          SizedBox(
            height: 8.px(context),
          ),

          Text(
            'please_provide_nominee_information'.tr,
            style: TextStyle(
              fontSize: 14.px(context),
              color: AppColors.primaryDark
                  .withOpacity(0.65),
            ),
          ),

          SizedBox(
            height: 24.px(context),
          ),

          _queryFlaggedBanner(2),

          Obx(() {
            final visibleCount =
                controller.visibleNomineeSlots.value;

            return Column(
              children: [
                for (var index = 0; index < visibleCount; index++) ...[
                  _nomineeSlotCard(context, index),
                  SizedBox(height: 20.px(context)),
                ],

                if (visibleCount < RegistrationController.maxNominees)
                  _addAnotherNomineeButton(context, visibleCount - 1),
              ],
            );
          }),

          SizedBox(height: 12.px(context)),

          _nomineeShareTotal(context),

          SizedBox(
            height: 30.px(context),
          ),
        ],
      ),
    );
  }

  /// One nominee's card — photo, name, relationship (dropdown, live from
  /// GetEnumBundle's Relation list), date of birth, and share. Wrapped in
  /// its own Form (nomineeSlotFormKeys[index]) so slots can be validated
  /// and saved independently as they're revealed one at a time.
  Widget _nomineeSlotCard(
      BuildContext context,
      int index,
      ) {
    final slot = controller.nomineeSlots[index];

    return Container(
      padding: EdgeInsets.all(16.px(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.px(context)),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: nomineeSlotFormKeys[index],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'nominee_number'.trParams({'n': '${index + 1}'}),
                    style: TextStyle(
                      fontSize: 16.px(context),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Obx(
                      () => slot.isSaved.value
                      ? Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18.px(context),
                  )
                      : const SizedBox.shrink(),
                ),

                // Lets the member undo an accidental "Add another nominee"
                // tap. Only ever shown for the LAST visible card (removing
                // a middle one would leave a gap) and only while it has
                // never gone through SaveNominee — the mandatory first
                // nominee (index 0) never gets this button either way. See
                // RegistrationController.removeLastNomineeSlot for the
                // exact rule, including why a prefilled-from-server or
                // previously-saved-then-cleared card can only be edited,
                // never removed.
                Obx(() {
                  // Read every observable unconditionally, before any
                  // branching — `index` is a plain int, so a short-circuit
                  // like `index > 0 && controller.visibleNomineeSlots.value
                  // == ...` would skip the `.value` reads entirely for the
                  // first card (index 0), leaving this Obx subscribed to
                  // nothing. GetX then has no dependency to track, which is
                  // exactly what threw "the improper use of a GetX has been
                  // detected" and cascaded into the RenderFlex overflow on
                  // this Row. Always touching both `.value`s first keeps the
                  // subscription registered on every build, index 0 included.
                  final visibleSlots = controller.visibleNomineeSlots.value;
                  final isSaved = slot.isSaved.value;
                  final canRemove =
                      index > 0 && index == visibleSlots - 1 && !isSaved;

                  if (!canRemove) return const SizedBox.shrink();

                  return Padding(
                    padding: EdgeInsets.only(left: 8.px(context)),
                    child: SizedBox(
                      // Explicit bounds so this InkWell can never be handed
                      // unbounded constraints as a direct Row child — the
                      // other likely contributor to the reported overflow.
                      height: 22.px(context),
                      width: 22.px(context),
                      child: InkWell(
                        onTap: controller.removeLastNomineeSlot,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: EdgeInsets.all(2.px(context)),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 18.px(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),

            SizedBox(height: 16.px(context)),

            _nomineeSlotBody(context, index),
          ],
        ),
      ),
    );
  }

  /// Everything in a nominee card except its header row (number/saved-
  /// check/remove button, always shown regardless of query mode) — split
  /// out so query-resolution mode can wrap the WHOLE thing in one blanket
  /// lock when this slot isn't the "current" nominee (see
  /// RegistrationController.queryModeCurrentNomineeItemNumber: only the
  /// lowest itemNumber with any unresolved query is ever unlocked at a
  /// time — "Complete Nominee 1's relevant queries before moving to
  /// Nominee 2", never mixing fields from different nominee items).
  /// Outside query mode, or for the one current nominee, renders exactly
  /// as before; per-field lock/pass/resolve treatment (mirroring Step 1's
  /// _queryAwareField/_querySimpleField/_queryLockableImage) only matters
  /// for that one slot, since every other slot is already fully
  /// non-interactive here regardless of what any individual field's own
  /// query state says.
  Widget _nomineeSlotBody(BuildContext context, int index) {
    final slot = controller.nomineeSlots[index];
    final itemNumber = index + 1;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            _queryLockableImage(
              tableId: 2,
              fieldId: 6,
              itemNumber: itemNumber,
              isCircle: true,
              child: Center(
              key: _nomineePhotoKeys[index],
              child: Obx(() {
                final pickPhoto = () => controller.showImageSourceSheet(
                      onSelected: (source) =>
                          controller.pickNomineeSlotImage(index, source),
                    );

                // Nothing picked THIS session, but the nominee already has
                // a photo on the server (resumed registration) AND the
                // response happened to carry a loadable URL for it (see
                // NomineeModel.photoUrl — not guaranteed) — show that
                // instead of the "tap to upload" placeholder.
                //
                // AppUploadContainer itself only knows how to display a
                // local File (see its own doc comment), so this is a
                // separate small tile rather than a change to that shared
                // widget, which every other photo on this wizard also
                // uses.
                if (slot.photo.value == null && slot.photoUrl.value != null) {
                  return GestureDetector(
                    onTap: pickPhoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 110.px(context),
                          height: 110.px(context),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: CommonImageView(
                              image: slot.photoUrl.value!,
                              type: CommonImageType.network,
                              fit: BoxFit.cover,
                              showPlaceholder: false,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(6.px(context)),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14.px(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return AppUploadContainer(
                  title: 'nominee_photo'.tr,
                  subtitle: slot.photo.value == null &&
                      slot.photoDocumentId.value != null
                      ? 'file_selected'.tr
                      : 'tap_to_upload'.tr,
                  isCircle: true,
                  width: 110.px(context),
                  height: 110.px(context),
                  file: slot.photo.value,
                  onTap: pickPhoto,
                  onRemove: slot.photo.value != null
                      ? () => slot.photo.value = null
                      : null,
                );
              }),
            ),
            ),

            Center(
              child: _inlineError(
                () =>
                    slot.photo.value == null && slot.photoDocumentId.value == null,
                'please_upload_nominee_photo'.tr,
                showFlag: slot.showErrors,
              ),
            ),

            SizedBox(height: 20.px(context)),

            // Same EXACTLY-3-words format as the member's own Full Name
            // field (First Middle Surname) — see AppValidators.fullName —
            // instead of the old letters-only-with-no-word-count check.
            _queryAwareField(
              fieldKey: _nomineeNameKeys[index],
              label: 'nominee_name'.tr,
              labelKey: 'nominee_name',
              hintText: 'full_name_hint'.tr,
              textController: slot.nameController,
              // Leaving this field is what fires the same background
              // Hindi/Gujarati transliteration every other name field on
              // this wizard uses (see RegistrationController.onInit,
              // where this focus node's listener is wired) — sent to
              // SaveNominee as hName/gName.
              focusNode: slot.nameFocusNode,
              validator: (value) => AppValidators.fullName(
                value,
                message: 'full_name_format_error'.tr,
              ),
              inputFormatters: [
                _nameInputFormatter,
              ],
              baseFieldId: 2,
              hFieldId: 8,
              gFieldId: 9,
              tableId: 2,
              itemNumber: itemNumber,
              onUpdate: (fieldId, text) => controller
                  .queryModeUpdateNomineeNameField(itemNumber, fieldId, text),
            ),

            SizedBox(height: 16.px(context)),

            _queryLockableImage(
              tableId: 2,
              fieldId: 4,
              itemNumber: itemNumber,
              child: Container(
              key: _nomineeRelationKeys[index],
              child: Obx(
                    () => _enumDropdown(
                context: context,
                label: 'relationship'.tr,
                value: slot.relationId.value,
                items: controller.relationOptions.value,
                onChanged: (value) {
                  slot.relationId.value = value;
                  if (controller.queryState.isActive) {
                    controller.queryState.markTouched(
                      2,
                      4,
                      itemNumber: itemNumber,
                    );
                  }
                },
                hasError:
                    slot.showErrors.value && slot.relationId.value == null,
              ),
              ),
            ),
            ),

            _inlineError(
              () => slot.relationId.value == null,
              'please_select_option'.trParams({'label': 'relationship'.tr}),
              showFlag: slot.showErrors,
            ),

            SizedBox(height: 16.px(context)),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  key: _nomineeDobKeys[index],
                  child: _queryLockableImage(
                    tableId: 2,
                    fieldId: 3,
                    itemNumber: itemNumber,
                    child: AppTextField.form(
                    label: 'date_of_birth'.tr,
                    controller: slot.dateOfBirthController,
                    readOnly: true,
                    validator: AppValidators.date,
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                    ),
                    onTap: () {
                      controller.pickNomineeSlotDateOfBirth(
                        context,
                        index,
                      );
                    },
                  ),
                  ),
                ),

                SizedBox(width: 12.px(context)),

                // What "share" means exactly isn't specified by the API
                // beyond it being a plain nullable number — this app treats
                // it as each nominee's percentage of the payout, so it's a
                // free-form numeric field with no per-field range, but see
                // _nomineeShareTotal / saveNomineeSlot's shareExceedsLimit
                // check for the one rule enforced today: the running total
                // across all visible nominees can't exceed 100%.
                Expanded(
                  key: _nomineeShareKeys[index],
                  child: _queryLockableImage(
                    tableId: 2,
                    fieldId: 5,
                    itemNumber: itemNumber,
                    child: Obx(() {
                    // Once the running total across all visible nominees
                    // goes over 100%, every share field's border turns
                    // red — not just the one the member is currently
                    // typing in — so it's clear at a glance that the
                    // split needs adjusting.
                    final exceeds = controller.shareExceedsLimit;

                    return AppTextField.form(
                      label: 'nominee_share'.tr,
                      controller: slot.shareController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => AppValidators.requiredField(
                        value,
                        message: 'please_enter_nominee_share'.tr,
                      ),
                      inputFormatters: [
                        _ShareInputFormatter(),
                      ],
                      onChanged: controller.queryState.isActive
                          ? (text) => controller.queryModeTouchSimpleField(
                                2,
                                5,
                                text,
                                itemNumber: itemNumber,
                              )
                          : null,
                      enabledBorderColor:
                          exceeds ? AppColors.danger : null,
                      focusedBorderColor:
                          exceeds ? AppColors.danger : null,
                    );
                  }),
                  ),
                ),
              ],
            ),

            // Same instant (not gated behind showErrors/Next) reactive
            // warning as the share field's own red border above — shows
            // the running total right under the field the moment it goes
            // over 100%, not just via the summary banner further down
            // (_nomineeShareTotal), since that banner sits below every
            // visible nominee card and can be scrolled far out of view.
            Align(
              alignment: Alignment.centerRight,
              child: Obx(() {
                if (!controller.shareExceedsLimit) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: EdgeInsets.only(top: 6.px(context)),
                  child: Text(
                    'nominee_share_exceeds_limit'.trParams({
                      'total': _formatShareForDisplay(
                        controller.totalShareEntered.value,
                      ),
                    }),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12.px(context),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 16.px(context)),

            // Aadhaar number + front/back photo + passbook/cheque photo —
            // all added to SaveNominee's schema after this card was first
            // built. The API itself defines aadharNo as optional (see
            // NomineeModel's doc comment), but the member now wants every
            // nominee field required on this screen, so this is validated
            // with AppValidators.aadhar (required) instead of the
            // aadharOptional variant used before.
            _querySimpleField(
              label: 'nominee_aadhaar_number'.tr,
              labelKey: 'nominee_aadhaar_number',
              textController: slot.aadharNoController,
              keyboardType: TextInputType.number,
              // 12 digits + 2 grouping spaces ("1234 5678 9012") — see
              // _AadharInputFormatter.
              maxLength: 14,
              validator: AppValidators.aadhar,
              inputFormatters: [
                _AadharInputFormatter(),
              ],
              tableId: 2,
              fieldId: 13,
              itemNumber: itemNumber,
            ),

            SizedBox(height: 12.px(context)),

            _queryLockableImage(
              tableId: 2,
              fieldId: 10,
              itemNumber: itemNumber,
              child: Container(
              key: _nomineeAadharFrontKeys[index],
              child: Obx(
                    () => _uploadOrNetworkImage(
                context: context,
                title: 'nominee_aadhaar_front_photo'.tr,
                subtitle: 'tap_to_upload_image'.tr,
                height: 160.px(context),
                file: slot.aadharFrontImage.value,
                networkUrl: slot.aadharFrontImageUrl.value,
                onTap: () {
                  controller.showImageSourceSheet(
                    onSelected: (source) => controller
                        .pickNomineeSlotAadharFrontImage(index, source),
                  );
                },
                onRemove: slot.aadharFrontImage.value != null
                    ? () => slot.aadharFrontImage.value = null
                    : null,
              ),
              ),
            ),
            ),

            _inlineError(
              () => slot.aadharFrontImage.value == null &&
                  slot.aadharFrontImageDocumentId.value == null,
              'please_upload_nominee_aadhaar_front_photo'.tr,
              showFlag: slot.showErrors,
            ),

            SizedBox(height: 12.px(context)),

            _queryLockableImage(
              tableId: 2,
              fieldId: 11,
              itemNumber: itemNumber,
              child: Container(
              key: _nomineeAadharBackKeys[index],
              child: Obx(
                    () => _uploadOrNetworkImage(
                context: context,
                title: 'nominee_aadhaar_back_photo'.tr,
                subtitle: 'tap_to_upload_image'.tr,
                height: 160.px(context),
                file: slot.aadharBackImage.value,
                networkUrl: slot.aadharBackImageUrl.value,
                onTap: () {
                  controller.showImageSourceSheet(
                    onSelected: (source) => controller
                        .pickNomineeSlotAadharBackImage(index, source),
                  );
                },
                onRemove: slot.aadharBackImage.value != null
                    ? () => slot.aadharBackImage.value = null
                    : null,
              ),
              ),
            ),
            ),

            _inlineError(
              () => slot.aadharBackImage.value == null &&
                  slot.aadharBackImageDocumentId.value == null,
              'please_upload_nominee_aadhaar_back_photo'.tr,
              showFlag: slot.showErrors,
            ),

            SizedBox(height: 12.px(context)),

            _queryLockableImage(
              tableId: 2,
              fieldId: 12,
              itemNumber: itemNumber,
              child: Container(
              key: _nomineePassbookKeys[index],
              child: Obx(
                    () => _uploadOrNetworkImage(
                context: context,
                title: 'nominee_passbook_cheque_photo'.tr,
                subtitle: 'tap_to_upload_image'.tr,
                height: 160.px(context),
                file: slot.passbookChequeImage.value,
                networkUrl: slot.passbookChequeImageUrl.value,
                onTap: () {
                  controller.showImageSourceSheet(
                    onSelected: (source) => controller
                        .pickNomineeSlotPassbookChequeImage(index, source),
                  );
                },
                onRemove: slot.passbookChequeImage.value != null
                    ? () => slot.passbookChequeImage.value = null
                    : null,
              ),
              ),
            ),
            ),

            _inlineError(
              () => slot.passbookChequeImage.value == null &&
                  slot.passbookChequeImageDocumentId.value == null,
              'please_upload_nominee_passbook_cheque_photo'.tr,
              showFlag: slot.showErrors,
            ),
      ],
    );

    if (!controller.queryState.isActive) return body;

    return Obx(() {
      // Always read a real observable (GetX throws otherwise when no
      // nominee has any query, so nothing below would read one).
      controller.queryState.localLanguage.value;

      // Every nominee with something still to fix is editable at once —
      // one Next saves each of them in turn, then resolves its queries.
      // Nominees with no (or only already-resolved) queries stay fully
      // locked.
      final isActive =
          controller.queryModeUnresolvedNominees().contains(itemNumber);

      if (isActive) return body;

      return IgnorePointer(
        child: Opacity(opacity: 0.45, child: body),
      );
    });
  }

  /// "Add another nominee" — validates + saves [lastVisibleIndex] (via
  /// SaveNominee) and, only on success, reveals the next slot. Hidden once
  /// all `RegistrationController.maxNominees` slots are visible; Next on
  /// the last slot is what proceeds from there (see _next()'s step==1
  /// branch).
  Widget _addAnotherNomineeButton(
      BuildContext context,
      int lastVisibleIndex,
      ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _saveNomineeSlotAndReveal(
          context,
          lastVisibleIndex,
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: Text('add_another_nominee'.tr),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: 14.px(context),
          ),
          side: const BorderSide(color: AppColors.primary),
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  /// Running total across every visible nominee's share field — recomputed
  /// live as the member types (see the shareController listeners wired in
  /// RegistrationController.onInit). Members aren't required to reach
  /// exactly 100% today (see RegistrationController.shareExceedsLimit's
  /// doc comment), only warned when they go over it, so this is styled as
  /// a quiet hint rather than a hard error — the actual block-and-toast
  /// happens inside saveNomineeSlot, on Add Another / Next.
  Widget _nomineeShareTotal(BuildContext context) {
    return Obx(() {
      final total = controller.totalShareEntered.value;
      final exceeds = controller.shareExceedsLimit;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: 14.px(context),
          vertical: 10.px(context),
        ),
        decoration: BoxDecoration(
          color: exceeds
              ? AppColors.danger.withOpacity(0.08)
              : AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12.px(context)),
          border: Border.all(
            color: exceeds
                ? AppColors.danger.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              exceeds ? Icons.error_outline : Icons.pie_chart_outline,
              size: 18.px(context),
              color: exceeds ? AppColors.danger : AppColors.primary,
            ),
            SizedBox(width: 8.px(context)),
            Expanded(
              child: Text(
                exceeds
                    ? 'nominee_share_exceeds_limit'.trParams({
                        'total': _formatShareForDisplay(total),
                      })
                    : 'nominee_total_share'.trParams({
                        'total': _formatShareForDisplay(total),
                      }),
                style: TextStyle(
                  fontSize: 12.5.px(context),
                  fontWeight: FontWeight.w600,
                  color: exceeds ? AppColors.danger : AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatShareForDisplay(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  Future<void> _saveNomineeSlotAndReveal(
      BuildContext context,
      int index,
      ) async {
    final slot = controller.nomineeSlots[index];

    // Reveal this slot's own inline error state (relationship dropdown)
    // before validating, same as _showStep1Errors on step 1 — so a first
    // Add More/Save/Next tap already shows every error at once instead of
    // needing a second tap.
    slot.showErrors.value = true;

    if (!nomineeSlotFormKeys[index].currentState!.validate()) {
      return;
    }

    if (slot.photo.value == null && slot.photoDocumentId.value == null) {
      _showError('please_upload_nominee_photo'.tr);
      return;
    }

    if (slot.relationId.value == null) {
      _showError(
        'please_select_option'.trParams({'label': 'relationship'.tr}),
      );
      return;
    }

    if (slot.aadharFrontImage.value == null &&
        slot.aadharFrontImageDocumentId.value == null) {
      _showError('please_upload_nominee_aadhaar_front_photo'.tr);
      return;
    }

    if (slot.aadharBackImage.value == null &&
        slot.aadharBackImageDocumentId.value == null) {
      _showError('please_upload_nominee_aadhaar_back_photo'.tr);
      return;
    }

    if (slot.passbookChequeImage.value == null &&
        slot.passbookChequeImageDocumentId.value == null) {
      _showError('please_upload_nominee_passbook_cheque_photo'.tr);
      return;
    }

    FocusScope.of(context).unfocus();

    final saved = await controller.saveNomineeSlot(index);

    if (!saved) {
      return;
    }

    ToastUtil.success('nominee_saved_successfully'.tr);

    controller.revealNextNomineeSlot();
  }


  // ============================================================
  // STEP 3 — HEALTH DECLARATION (SaveMemberHealthDeclaration /
  // GetHealthDeclarationByMemberId)
  //
  // Mirrors the Preview screen's / downloaded PDF's health-declaration
  // page (see registration_preview_screen.dart's _healthDeclarationPage
  // and registration_pdf_builder.dart's PAGE 3), but interactive instead
  // of a static read-only render. Every yes/no question's detail field is
  // shown only once answered "yes" — matches the swagger schema exactly,
  // see RegistrationController's HEALTH DECLARATION section doc comment
  // for the full field mapping. Every yes/no question here must be
  // answered (and its detail field filled in, once answered "yes") to
  // Continue — see RegistrationController.firstMissingHealthDetail,
  // called from saveHealthDeclaration() before it will save. Only the
  // standalone "any other details" field and the 13 fixed disease
  // checkboxes stay optional.
  // ============================================================

  Widget _buildHealthStep(
      BuildContext context,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 20.px(context),
        vertical: 10.px(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'health_declaration_title'.tr),

          SizedBox(height: 8.px(context)),

          Text(
            'health_declaration_intro'.tr,
            style: TextStyle(
              fontSize: 12.5.px(context),
              fontStyle: FontStyle.italic,
              color: AppColors.primaryDark.withOpacity(0.65),
            ),
          ),

          SizedBox(height: 22.px(context)),

          _queryFlaggedBanner(3),

          // isSeriousIllness -> seriousIllness (translated)
          Obx(() {
            final hasIllness = controller.hasCurrentIllness.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _queryLockableImage(
                  tableId: 3,
                  fieldId: 3,
                  child: Container(
                  key: _healthCurrentIllnessKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_current_illness'.tr,
                    value: hasIllness,
                    onChanged: (value) {
                      controller.setHasCurrentIllness(value);
                      if (controller.queryState.isActive) {
                        controller.queryModeTouchSimpleField(
                          3,
                          3,
                          '$value',
                        );
                      }
                    },
                  ),
                ),
                ),
                if (hasIllness == true ||
                    _healthQueried(const [4, 30, 31])) ...[
                  SizedBox(height: 12.px(context)),
                  _queryAwareField(
                    fieldKey: _healthCurrentIllnessDetailKey,
                    label: 'health_q_current_illness_detail'.tr,
                    labelKey: 'health_q_current_illness_detail',
                    textController: controller.seriousIllnessDetailController,
                    focusNode: seriousIllnessDetailFocusNode,
                    maxLines: 2,
                    baseFieldId: 4,
                    hFieldId: 30,
                    gFieldId: 31,
                    tableId: 3,
                    onUpdate: (fieldId, text) =>
                        controller.queryModeUpdateHealthField(fieldId, text),
                  ),
                ],
              ],
            );
          }),

          SizedBox(height: 22.px(context)),

          Text(
            'health_q_past_diseases'.tr,
            style: TextStyle(
              fontSize: 14.px(context),
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),

          SizedBox(height: 10.px(context)),

          Container(
            key: _healthDiseaseChipsKey,
            child: Obx(
                () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final key in RegistrationController.diseaseKeys)
                  _diseaseChip(context, key),
              ],
            ),
            ),
          ),

          // anyHerediatry -> other (translated) — the 'disease_hereditary'
          // chip's own "please specify" detail. Also forced visible
          // whenever THIS field itself (base/H/G, id 18/32/33) has an
          // active query — otherwise a query targeting it could never be
          // reached at all on an account where the hereditary checkbox
          // isn't ticked, permanently blocking Next with no way to even
          // see the field that needs fixing.
          Obx(() {
            final isHereditary =
                controller.selectedDiseaseKeys.contains('disease_hereditary');
            final isQueried = controller.queryState.hasQueryFor(3, 18) ||
                controller.queryState.hasQueryFor(3, 32) ||
                controller.queryState.hasQueryFor(3, 33);

            if (!isHereditary && !isQueried) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(top: 12.px(context)),
              child: _queryAwareField(
                fieldKey: _healthHereditaryDetailKey,
                label: 'health_hereditary_detail'.tr,
                labelKey: 'health_hereditary_detail',
                textController: controller.otherHereditaryDetailController,
                focusNode: otherHereditaryDetailFocusNode,
                maxLines: 2,
                baseFieldId: 18,
                hFieldId: 32,
                gFieldId: 33,
                tableId: 3,
                onUpdate: (fieldId, text) =>
                    controller.queryModeUpdateHealthField(fieldId, text),
              ),
            );
          }),

          SizedBox(height: 22.px(context)),

          // isSurgery -> surgery + surgeryDate (translated)
          Obx(() {
            final hadSurgery = controller.hadSurgery.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _queryLockableImage(
                  tableId: 3,
                  fieldId: 19,
                  child: Container(
                  key: _healthSurgeryKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_surgery'.tr,
                    value: hadSurgery,
                    onChanged: (value) {
                      controller.setHadSurgery(value);
                      if (controller.queryState.isActive) {
                        controller.queryModeTouchSimpleField(3, 19, '$value');
                      }
                    },
                  ),
                ),
                ),
                if (hadSurgery == true ||
                    _healthQueried(const [20, 34, 35, 21])) ...[
                  SizedBox(height: 12.px(context)),
                  _queryAwareField(
                    fieldKey: _healthSurgeryDetailKey,
                    label: 'health_q_surgery_detail'.tr,
                    labelKey: 'health_q_surgery_detail',
                    textController: controller.surgeryDetailController,
                    focusNode: surgeryDetailFocusNode,
                    maxLines: 2,
                    baseFieldId: 20,
                    hFieldId: 34,
                    gFieldId: 35,
                    tableId: 3,
                    onUpdate: (fieldId, text) =>
                        controller.queryModeUpdateHealthField(fieldId, text),
                  ),
                  SizedBox(height: 12.px(context)),
                  _queryLockableImage(
                    tableId: 3,
                    fieldId: 21,
                    child: AppTextField.form(
                      key: _healthSurgeryDateKey,
                      label: 'health_q_surgery_date'.tr,
                      controller: controller.surgeryDateController,
                      readOnly: true,
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      onTap: () => controller.pickSurgeryDate(context),
                    ),
                  ),
                ],
              ],
            );
          }),

          SizedBox(height: 22.px(context)),

          // ismedicationRegularly -> medicationRegularly (NOT translated —
          // the swagger schema has no h/g pair for this field).
          Obx(() {
            final onMedication = controller.onRegularMedication.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _queryLockableImage(
                  tableId: 3,
                  fieldId: 22,
                  child: Container(
                  key: _healthMedicationKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_medication'.tr,
                    value: onMedication,
                    onChanged: (value) {
                      controller.setOnRegularMedication(value);
                      if (controller.queryState.isActive) {
                        controller.queryModeTouchSimpleField(3, 22, '$value');
                      }
                    },
                  ),
                ),
                ),
                if (onMedication == true || _healthQueried(const [23])) ...[
                  SizedBox(height: 12.px(context)),
                  _queryAwareField(
                    fieldKey: _healthMedicationDetailKey,
                    label: 'health_q_medication_detail'.tr,
                    labelKey: 'health_q_medication_detail',
                    textController: controller.medicationDetailController,
                    maxLines: 2,
                    // No Hindi/Gujarati version of this one — 23 only.
                    baseFieldId: 23,
                    hFieldId: -1,
                    gFieldId: -1,
                    tableId: 3,
                    onUpdate: (fieldId, text) => controller
                        .queryModeTouchSimpleField(3, fieldId, text),
                  ),
                ],
              ],
            );
          }),

          SizedBox(height: 22.px(context)),

          // anyAllergies -> allergies (translated)
          Obx(() {
            final hasAllergies = controller.hasAllergies.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _queryLockableImage(
                  tableId: 3,
                  fieldId: 24,
                  child: Container(
                    key: _healthAllergyKey,
                    child: _yesNoField(
                      context,
                      question: 'health_q_allergy'.tr,
                      value: hasAllergies,
                      onChanged: (value) {
                        controller.setHasAllergies(value);
                        if (controller.queryState.isActive) {
                          controller.queryModeTouchSimpleField(
                            3,
                            24,
                            '$value',
                          );
                        }
                      },
                    ),
                  ),
                ),
                if (hasAllergies == true ||
                    _healthQueried(const [25, 36, 37])) ...[
                  SizedBox(height: 12.px(context)),
                  _queryAwareField(
                    fieldKey: _healthAllergyDetailKey,
                    label: 'health_q_allergy_detail'.tr,
                    labelKey: 'health_q_allergy_detail',
                    textController: controller.allergyDetailController,
                    focusNode: allergyDetailFocusNode,
                    maxLines: 2,
                    baseFieldId: 25,
                    hFieldId: 36,
                    gFieldId: 37,
                    tableId: 3,
                    onUpdate: (fieldId, text) =>
                        controller.queryModeUpdateHealthField(fieldId, text),
                  ),
                ],
              ],
            );
          }),

          SizedBox(height: 22.px(context)),

          _queryLockableImage(
            tableId: 3,
            fieldId: 26,
            child: Container(
              key: _healthTobaccoKey,
              child: Obx(
                    () => _yesNoField(
                  context,
                  question: 'health_q_tobacco'.tr,
                  value: controller.usesTobacco.value,
                  onChanged: (value) {
                    controller.usesTobacco.value = value;
                    if (controller.queryState.isActive) {
                      controller.queryModeTouchSimpleField(3, 26, '$value');
                    }
                  },
                ),
              ),
            ),
          ),

          SizedBox(height: 16.px(context)),

          _queryLockableImage(
            tableId: 3,
            fieldId: 27,
            child: Container(
            key: _healthAlcoholKey,
            child: Obx(
                  () => _yesNoField(
                context,
                question: 'health_q_alcohol'.tr,
                value: controller.consumesAlcohol.value,
                onChanged: (value) {
                  controller.consumesAlcohol.value = value;
                  if (controller.queryState.isActive) {
                    controller.queryModeTouchSimpleField(3, 27, '$value');
                  }
                },
              ),
            ),
            ),
          ),

          SizedBox(height: 16.px(context)),

          _queryLockableImage(
            tableId: 3,
            fieldId: 28,
            child: Container(
            key: _healthDrugsKey,
            child: Obx(
                  () => _yesNoField(
                context,
                question: 'health_q_drugs'.tr,
                value: controller.usesDrugs.value,
                onChanged: (value) {
                  controller.usesDrugs.value = value;
                  if (controller.queryState.isActive) {
                    controller.queryModeTouchSimpleField(3, 28, '$value');
                  }
                },
              ),
            ),
            ),
          ),

          SizedBox(height: 22.px(context)),

          // otherDetails (translated) — standalone, always optional, no
          // yes/no gate (the swagger schema has no boolean flag for it).
          _queryAwareField(
            fieldKey: _healthOtherDetailsKey,
            label: 'health_q_other'.tr,
            labelKey: 'health_q_other',
            textController: controller.otherHealthDetailController,
            focusNode: otherHealthDetailFocusNode,
            maxLines: 2,
            baseFieldId: 29,
            hFieldId: 38,
            gFieldId: 39,
            tableId: 3,
            onUpdate: (fieldId, text) =>
                controller.queryModeUpdateHealthField(fieldId, text),
          ),

          SizedBox(height: 30.px(context)),
        ],
      ),
    );
  }

  Widget _yesNoField(
      BuildContext context, {
        required String question,
        required bool? value,
        required ValueChanged<bool?> onChanged,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(fontSize: 14.px(context)),
        ),
        SizedBox(height: 8.px(context)),
        Row(
          children: [
            _yesNoChip(
              context,
              label: 'yes'.tr,
              selected: value == true,
              onTap: () => onChanged(true),
            ),
            SizedBox(width: 12.px(context)),
            _yesNoChip(
              context,
              label: 'no'.tr,
              selected: value == false,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _yesNoChip(
      BuildContext context, {
        required String label,
        required bool selected,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 22.px(context),
          vertical: 10.px(context),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primaryDark,
            fontWeight: FontWeight.w600,
            fontSize: 13.px(context),
          ),
        ),
      ),
    );
  }

  Widget _diseaseChip(BuildContext context, String key) {
    final selected = controller.selectedDiseaseKeys.contains(key);
    // tblHealthDeclarationFields ids 5-17 map 1:1 onto diseaseKeys' own
    // order (HeartDisease=5 ... anyHerediatry=17) — see
    // RegistrationController.diseaseKeys' declaration order.
    final fieldId = RegistrationController.diseaseKeys.indexOf(key) + 5;

    return _queryLockableImage(
      tableId: 3,
      fieldId: fieldId,
      child: InkWell(
      onTap: () {
        controller.toggleDiseaseKey(key);
        if (controller.queryState.isActive) {
          controller.queryModeTouchSimpleField(3, fieldId, '${!selected}');
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.px(context),
          vertical: 9.px(context),
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 6.px(context)),
            Text(
              key.tr,
              style: TextStyle(
                fontSize: 12.5.px(context),
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // STEP 4 — RULES & DECLARATION
  // ============================================================

  Widget _buildRulesStep(
      BuildContext context,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        20.px(context),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'rules_and_declaration'.tr,
          ),

          SizedBox(
            height: 16.px(context),
          ),

          Container(
            padding:
            EdgeInsets.all(
              18.px(context),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                16.px(context),
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _rule(
                  'rule_info_correct'.tr,
                ),
                _rule(
                  'rule_info_rejection'.tr,
                ),
                _rule(
                  'rule_provide_documents'.tr,
                ),
                _rule(
                  'rule_agree_foundation_terms'.tr,
                ),
              ],
            ),
          ),

          SizedBox(
            height: 20.px(context),
          ),

          Obx(
                () => CheckboxListTile(
              value: controller
                  .acceptedRules.value,
              onChanged: (value) {
                controller
                    .acceptedRules
                    .value = value ?? false;
              },
              contentPadding:
              EdgeInsets.zero,
              controlAffinity:
              ListTileControlAffinity.leading,
              title: Text(
                'agree_terms'.tr,
              ),
            ),
          ),

          SizedBox(
            height: 30.px(context),
          ),
        ],
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons(
      BuildContext context,
      ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.px(context),
        12.px(context),
        20.px(context),
        20.px(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color:
            Colors.black.withOpacity(0.08),
            offset:
            const Offset(0, -3),
          ),
        ],
      ),
      child: Obx(
            () {
          final step =
              controller.currentStep.value;

          final isFinish =
              step == 3;

          return Row(
            children: [
              if (step > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 48.px(context),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        // Without this, OutlinedButton's own default
                        // vertical padding stacks on top of the fixed
                        // 48px height above and can leave too little
                        // room for the label — see the matching
                        // ElevatedButton comment below, where the app's
                        // global button theme made that combination
                        // actually clip the text.
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      onPressed: _back,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'back'.tr,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 12.px(context),
                ),
              ],

              Expanded(
                child: SizedBox(
                  height: 48.px(context),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // AppTheme's global ElevatedButtonThemeData sets
                      // padding: EdgeInsets.symmetric(vertical: 16) (meant
                      // for buttons that size themselves around their
                      // content) — style.styleFrom here only overrides
                      // shape, so that 16+16=32px of forced vertical
                      // padding was still being squeezed into this
                      // button's own fixed 48px height, leaving too
                      // little room for the label and clipping it off at
                      // the bottom. Zeroing it out here lets the label
                      // actually center in the full 48px instead.
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    onPressed: isFinish &&
                        !controller.acceptedRules.value
                        ? null
                        : _next,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isFinish ? 'finish'.tr : 'next'.tr,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // GENDER — RADIO GROUP (live from GetEnumBundle)
  // ============================================================

  Widget _genderRadioGroup(BuildContext context) {
    if (controller.isLoadingEnumOptions.value &&
        controller.genderOptions.value.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (controller.genderOptions.value.isEmpty) {
      return Row(
        children: [
          Text(
            'could_not_load_options'.trParams({'label': 'gender'.tr}),
            style: TextStyle(
              fontSize: 13.px(context),
              color: AppColors.primaryDark.withOpacity(0.6),
            ),
          ),
          TextButton(
            onPressed: controller.loadEnumOptions,
            child: Text('retry'.tr),
          ),
        ],
      );
    }

    // Column, not Row — stays readable regardless of how many options the
    // backend returns or how long their labels are. Wrapped in a bordered
    // container matching AppTextField's default enabled border so this
    // reads as one field of the form instead of a set of loose rows, and
    // each option gets real horizontal padding (was EdgeInsets.zero,
    // which crammed the radio dot against the left edge).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD5D5D5),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 4.px(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: controller.genderOptions.value.map((option) {
          return RadioListTile<int>(
            value: option.id,
            groupValue: controller.selectedGenderId.value,
            onChanged: (value) {
              controller.selectedGenderId.value = value;
              if (controller.queryState.isActive) {
                controller.queryState.markTouched(1, 19);
              }
            },
            title: Text(
              EnumOptionTranslator.translate(option.name),
              style: TextStyle(fontSize: 14.px(context)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.px(context),
            ),
            visualDensity: VisualDensity.compact,
            activeColor: AppColors.primary,
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // ENUM-BACKED DROPDOWN (Marital Status)
  // ============================================================

  Widget _enumDropdown({
    required BuildContext context,
    required String label,
    required int? value,
    required List<EnumItem> items,
    required ValueChanged<int?> onChanged,
    bool hasError = false,
  }) {
    if (controller.isLoadingEnumOptions.value && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (items.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'could_not_load_options'.trParams({'label': label}),
              style: TextStyle(
                fontSize: 13.px(context),
                color: AppColors.primaryDark.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: controller.loadEnumOptions,
            child: Text('retry'.tr),
          ),
        ],
      );
    }

    // items contains the currently selected value (or it's null) — a
    // resumed prefill or an in-progress edit could point at an id that
    // isn't (yet, or any longer) in `items`, so this only ever shows a
    // value that's actually selectable.
    final validValue =
        items.any((item) => item.id == value) ? value : null;

    // _OverlaySelectField (below) replaces what used to be a
    // DropdownButtonFormField here. That widget's menu always opens
    // aligned so the currently-selected item sits where the field itself
    // is — by design, per Material spec — which is exactly what read as
    // "the menu opens on top of/overlapping the field, hiding the
    // selected value" rather than appearing cleanly below it. There's no
    // public option on DropdownButtonFormField to change that alignment,
    // so this custom widget (CompositedTransformTarget/Follower +
    // OverlayEntry) opens its menu at a fixed offset directly under the
    // field instead, matches the field's exact width, and keeps the
    // rounded corners — see _OverlaySelectField's own doc comment.
    //
    // It also has no Form-level validator of its own — [hasError] (driven
    // by the same controller state the caller's _inlineError text below
    // it already reads) is what turns the border red, so there is only
    // ever ONE error source for this field, not two.
    return _OverlaySelectField(
      label: label,
      value: validValue,
      items: items,
      onChanged: onChanged,
      hasError: hasError,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  /// Wraps a Step 1 free-text field (father's name, address, village,
  /// taluka, district, state, occupation) with query-resolution-mode
  /// behavior: outside that mode, behaves exactly like a plain
  /// `AppTextField.form` (all the existing params pass straight through,
  /// unchanged). While query-resolution mode is active, this same field
  /// is locked unless one of its base/H/G variants ([baseFieldId]/
  /// [hFieldId]/[gFieldId], from `tblMemberField`) is queried — when it
  /// is, the field shows/edits that specific language slot directly (see
  /// `RegistrationController.queryModeUpdateStep1Field`), turns green once
  /// edited, and rejects (red + toast) text not written in the script
  /// that slot requires.
  Widget _queryAwareField({
    Key? fieldKey,
    required String label,
    String? hintText,
    required TextEditingController textController,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    required int baseFieldId,
    required int hFieldId,
    required int gFieldId,
    int tableId = 1,
    int? itemNumber,
    // Step 1's 7 triple fields write through queryModeUpdateStep1Field by
    // default; Nominee's one triple field (Name/HName/GName) passes this
    // to route the write into the right nominee slot instead.
    void Function(int fieldId, String text)? onUpdate,
    // The raw registration_strings.dart key `label` was already run
    // through .tr() with (the real app locale) — passing the key too
    // lets this field re-render its own label in the flow's own local
    // language while editable, instead of showing the label in whatever
    // language the rest of the app happens to be in.
    String? labelKey,
  }) {
    // Checked OUTSIDE any Obx on purpose: this never changes once the
    // screen is showing (the flow either started before Step 1 opened or
    // didn't), and Obx requires reading an actual observable on every
    // build — a branch that returns without touching one throws GetX's
    // own "improper use of Obx" check.
    if (!controller.queryState.isActive) {
      return AppTextField.form(
        key: fieldKey,
        label: label,
        hintText: hintText,
        controller: textController,
        focusNode: focusNode,
        validator: validator,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
      );
    }

    return Obx(() {
      final queryState = controller.queryState;

      final variantId = controller.queryModeVariantFor(
        baseFieldId,
        hFieldId,
        gFieldId,
        tableId: tableId,
        itemNumber: itemNumber,
      );
      final editable = variantId != null;
      // Always read a real RxBool's .value below, even when this field
      // isn't editable (falling back to baseFieldId's, whose value is
      // simply unused then) — same Obx-tracking reason as above: a build
      // that never reads an observable is invalid, and `editable && ...`
      // would short-circuit past the read entirely whenever `editable` is
      // false, which is most fields most of the time.
      final trackedId = variantId ?? baseFieldId;
      final resolvedValue = queryState
          .isFieldResolved(tableId, trackedId, itemNumber: itemNumber)
          .value;
      final mismatchValue = queryState
          .scriptMismatch(tableId, trackedId, itemNumber: itemNumber)
          .value;
      final resolved = editable && resolvedValue;
      final mismatch = editable && mismatchValue;

      String wrongScriptMessage() {
        final requiredScript = ScriptDetector.requiredScriptFor(
          queryState.fieldNameFor(tableId, variantId!),
        );
        final languageName = switch (requiredScript) {
          ScriptType.gujarati => AppLanguage.gujarati.displayName,
          ScriptType.devanagari => AppLanguage.hindi.displayName,
          ScriptType.latin => AppLanguage.english.displayName,
        };
        return _flowLocalized(
          queryState.localLanguage.value,
          'query_field_wrong_script',
          params: {'language': languageName},
        );
      }

      return AppTextField.form(
        key: fieldKey,
        label: labelKey != null
            ? _flowLocalized(queryState.localLanguage.value, labelKey)
            : label,
        hintText: hintText,
        controller: textController,
        focusNode: editable ? focusNode : null,
        // Locked fields keep whatever value they already have — no reason
        // to re-validate a field the member can't touch here.
        validator: editable ? validator : null,
        inputFormatters: editable ? inputFormatters : null,
        maxLines: maxLines,
        enabled: editable,
        readOnly: !editable,
        errorText: (mismatch || (editable && !resolved))
                ? wrongScriptMessage()
                : null,
        enabledBorderColor:
            !editable ? null : (resolved ? AppColors.success : AppColors.danger),
        // Without this, red/green is only visible while NOT focused —
        // auto-scroll focuses the field immediately, and the focused
        // border otherwise defaults to the app's plain teal theme color,
        // masking it (errorText's own built-in red still overrides
        // regardless, which is why an ACTIVE mismatch stayed visible but
        // a simply-unresolved-not-yet-touched field didn't).
        focusedBorderColor:
            !editable ? null : (resolved ? AppColors.success : AppColors.danger),
        onChanged: !editable
            ? null
            : (text) {
                if (onUpdate != null) {
                  onUpdate(variantId, text);
                } else {
                  controller.queryModeUpdateStep1Field(variantId, text);
                }
                final isMismatched = queryState
                    .scriptMismatch(tableId, variantId, itemNumber: itemNumber)
                    .value;
                if (queryState.shouldToastMismatch(
                  tableId,
                  variantId,
                  isMismatched,
                  itemNumber: itemNumber,
                )) {
                  ToastUtil.error(wrongScriptMessage());
                }
              },
      );
    });
  }

  /// Short note at the top of a step naming the fields the admin flagged
  /// there (and not yet fixed) — only in query mode, and only while some
  /// are still pending. A safety net: whatever gets flagged in future is at
  /// least listed here, even if it ever had no highlighted box of its own.
  Widget _queryFlaggedBanner(int tableId) {
    if (!controller.queryState.isActive ||
        !controller.queryState.hasQueriesForTable(tableId)) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final queryState = controller.queryState;
      final language = queryState.localLanguage.value;
      final labels = queryState.flaggedFieldLabels(tableId);

      if (labels.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16.px(context)),
        padding: EdgeInsets.all(12.px(context)),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.px(context)),
          border: Border.all(color: AppColors.danger.withOpacity(0.5)),
        ),
        child: Text(
          '${_flowLocalized(language, 'query_flagged_banner')}: '
          '${labels.join(', ')}',
          style: TextStyle(
            fontSize: 13.px(context),
            color: AppColors.primaryDark,
          ),
        ),
      );
    });
  }

  /// The Full Name box. Outside query mode it is exactly the normal
  /// editable field. In query mode it is locked unless the admin flagged
  /// one of the name parts (first / middle / surname, in any language) for
  /// the language being fixed right now — then it shows that language's
  /// name, is red until edited, and turns green once edited.
  Widget _queryFullNameField() {
    final plainField = AppTextField.form(
      key: _fullNameKey,
      label: 'full_name'.tr,
      hintText: 'full_name_hint'.tr,
      controller: fullNameController,
      focusNode: fullNameFocusNode,
      inputFormatters: [_nameInputFormatter],
      validator: (value) =>
          AppValidators.fullName(value, message: 'full_name_format_error'.tr),
    );

    if (!controller.queryState.isActive) return plainField;

    return Obx(() {
      final queryState = controller.queryState;
      // Real observable read on every build (see _queryAwareField).
      final language = queryState.localLanguage.value;

      final script = controller.queryModeNameScript();

      if (script == null) {
        // Nothing to fix in the name right now — same box, locked.
        return AppTextField.form(
          key: _fullNameKey,
          label: 'full_name'.tr,
          controller: fullNameController,
          enabled: false,
          readOnly: true,
        );
      }

      final ids = controller.queryModeQueriedNameIds(script);
      final resolved = ids.every(
        (id) => queryState.isFieldResolved(1, id).value,
      );
      final mismatch = ids.any(
        (id) => queryState.scriptMismatch(1, id).value,
      );

      String wrongScriptMessage() {
        final languageName = switch (script) {
          ScriptType.gujarati => AppLanguage.gujarati.displayName,
          ScriptType.devanagari => AppLanguage.hindi.displayName,
          ScriptType.latin => AppLanguage.english.displayName,
        };
        return _flowLocalized(
          language,
          'query_field_wrong_script',
          params: {'language': languageName},
        );
      }

      return AppTextField.form(
        key: _fullNameKey,
        label: _flowLocalized(language, 'full_name'),
        hintText: 'full_name_hint'.tr,
        controller: controller.queryFullNameController,
        focusNode: fullNameFocusNode,
        inputFormatters: [_nameInputFormatter],
        validator: (value) =>
            AppValidators.fullName(value, message: 'full_name_format_error'.tr),
        errorText: (mismatch || !resolved) ? wrongScriptMessage() : null,
        enabledBorderColor: resolved ? AppColors.success : AppColors.danger,
        focusedBorderColor: resolved ? AppColors.success : AppColors.danger,
        onChanged: (text) {
          controller.queryModeUpdateFullName(text);
          final firstQueried = ids.first;
          final isMismatched =
              queryState.scriptMismatch(1, firstQueried).value;
          if (queryState.shouldToastMismatch(1, firstQueried, isMismatched)) {
            ToastUtil.error(wrongScriptMessage());
          }
        },
      );
    });
  }

  /// Same idea as [_queryAwareField], for a plain field with no language
  /// variants at all (Aadhaar/PAN numbers) — [tableId]/[fieldId] name the
  /// one query that can unlock it, no base/H/G priority needed.
  Widget _querySimpleField({
    Key? fieldKey,
    required String label,
    required TextEditingController textController,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    int? maxLength,
    required int tableId,
    required int fieldId,
    int? itemNumber,
    // See _queryAwareField's identical param for why this is separate
    // from the already-.tr()'d `label`.
    String? labelKey,
  }) {
    if (!controller.queryState.isActive) {
      return AppTextField.form(
        key: fieldKey,
        label: label,
        controller: textController,
        focusNode: focusNode,
        validator: validator,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
        maxLength: maxLength,
      );
    }

    return Obx(() {
      final queryState = controller.queryState;
      final editable = queryState.isFieldEditable(
        tableId,
        fieldId,
        itemNumber: itemNumber,
      );
      final resolvedValue = queryState
          .isFieldResolved(tableId, fieldId, itemNumber: itemNumber)
          .value;
      final mismatchValue = queryState
          .scriptMismatch(tableId, fieldId, itemNumber: itemNumber)
          .value;
      final resolved = editable && resolvedValue;
      final mismatch = editable && mismatchValue;

      String wrongScriptMessage() {
        final requiredScript =
            ScriptDetector.requiredScriptFor(queryState.fieldNameFor(tableId, fieldId));
        final languageName = switch (requiredScript) {
          ScriptType.gujarati => AppLanguage.gujarati.displayName,
          ScriptType.devanagari => AppLanguage.hindi.displayName,
          ScriptType.latin => AppLanguage.english.displayName,
        };
        return _flowLocalized(
          queryState.localLanguage.value,
          'query_field_wrong_script',
          params: {'language': languageName},
        );
      }

      return AppTextField.form(
        key: fieldKey,
        label: labelKey != null
            ? _flowLocalized(queryState.localLanguage.value, labelKey)
            : label,
        controller: textController,
        focusNode: editable ? focusNode : null,
        validator: editable ? validator : null,
        inputFormatters: editable ? inputFormatters : null,
        keyboardType: keyboardType,
        maxLength: maxLength,
        enabled: editable,
        readOnly: !editable,
        errorText: (mismatch || (editable && !resolved))
                ? wrongScriptMessage()
                : null,
        enabledBorderColor:
            !editable ? null : (resolved ? AppColors.success : AppColors.danger),
        focusedBorderColor:
            !editable ? null : (resolved ? AppColors.success : AppColors.danger),
        onChanged: !editable
            ? null
            : (text) {
                controller.queryModeTouchSimpleField(
                  tableId,
                  fieldId,
                  text,
                  itemNumber: itemNumber,
                );
                final isMismatched = queryState
                    .scriptMismatch(tableId, fieldId, itemNumber: itemNumber)
                    .value;
                if (queryState.shouldToastMismatch(
                  tableId,
                  fieldId,
                  isMismatched,
                  itemNumber: itemNumber,
                )) {
                  ToastUtil.error(wrongScriptMessage());
                }
              },
      );
    });
  }

  /// Looks up [key] in the raw translation maps directly for [language].
  /// The flow keeps `queryState.localLanguage` mirroring the app's real
  /// language (see initState), so this matches what `.tr` shows — it just
  /// stays reactive inside Obx and lets callers name any language.
  String _flowLocalized(
    AppLanguage language,
    String key, {
    Map<String, String>? params,
  }) {
    final map = switch (language) {
      AppLanguage.english => registrationEn,
      AppLanguage.hindi => registrationHi,
      AppLanguage.gujarati => registrationGu,
    };
    var text = map[key] ?? key;
    params?.forEach((paramKey, value) {
      text = text.replaceAll('@$paramKey', value);
    });
    return text;
  }

  Widget _sectionTitle(
      BuildContext context,
      String title,
      ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.px(context),
        fontWeight:
        FontWeight.w700,
        color:
        AppColors.primaryDark,
      ),
    );
  }
}

// ============================================================================
// STEP INDICATOR
// ============================================================================

class _StepIndicator
    extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({
    required this.currentStep,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final titles = [
      'step_member'.tr,
      'step_nominee'.tr,
      'step_health'.tr,
      'finish'.tr,
    ];

    // Each step's circle+label is its own fixed-size widget (NOT wrapped
    // in an equal-width Expanded segment). Only the connector lines
    // between them are Expanded, so they soak up exactly the leftover
    // space. This is what makes the first circle sit flush at the left
    // edge and the LAST circle sit flush at the right edge, with the
    // steps spread evenly across the full width in between.
    //
    // The previous version wrapped every step — including the last one —
    // in its own equal 1/3-width Expanded segment, with the connector
    // line only ever trailing after a circle. Since the last step had no
    // trailing connector to fill its segment, that whole final third of
    // the row sat empty, and the entire indicator visually read as
    // pushed toward the left with unused space on the right.
    final children = <Widget>[];

    for (var index = 0; index < titles.length; index++) {
      final completed = index < currentStep;
      final active = index == currentStep;

      children.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 250,
              ),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed || active
                    ? AppColors.primary
                    : Colors.white,
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: completed
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                )
                    : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              titles[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: active
                    ? AppColors.primaryDark
                    : Colors.grey,
              ),
            ),
          ],
        ),
      );

      if (index < titles.length - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(
                bottom: 22,
              ),
              color: index < currentStep
                  ? AppColors.primary
                  : Colors.grey.shade300,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20.px(context),
        vertical: 8.px(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ================================================================
// OVERLAY-BASED SELECT FIELD (replaces DropdownButtonFormField for the
// Marital Status and nominee Relationship fields)
// ================================================================

/// A dropdown-style field whose popup menu is guaranteed to open directly
/// BELOW the field, matching the field's own width, with rounded corners —
/// unlike Flutter's built-in DropdownButton/DropdownButtonFormField, whose
/// menu is deliberately positioned so the currently-selected item lines up
/// with the field (per Material spec), which reads as the menu opening on
/// top of / overlapping the field and hiding the value that was showing.
///
/// Positioning uses a CompositedTransformTarget/CompositedTransformFollower
/// pair (a LayerLink) plus an OverlayEntry — the field measures its own
/// rendered size via a GlobalKey the moment it's tapped open, and the menu
/// is inserted into the app's Overlay at that exact width, anchored to just
/// under the field. A full-screen transparent barrier behind the menu closes
/// it on any outside tap.
///
/// This widget has no Form-level validator of its own — [hasError] (passed
/// in by the caller, driven by the same reactive controller state the
/// caller's own inline error text below the field already reads) is the
/// only thing that turns the border red, so there's exactly one error
/// source for the field, never two.
class _OverlaySelectField extends StatefulWidget {
  const _OverlaySelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hasError = false,
  });

  final String label;
  final int? value;
  final List<EnumItem> items;
  final ValueChanged<int?> onChanged;
  final bool hasError;

  @override
  State<_OverlaySelectField> createState() => _OverlaySelectFieldState();
}

class _OverlaySelectFieldState extends State<_OverlaySelectField> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void didUpdateWidget(covariant _OverlaySelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The options list or selected value can change (e.g. a resumed
    // prefill arriving late) while the menu happens to be open — closing
    // it rather than showing a now-stale list is simpler and safer than
    // trying to rebuild the open OverlayEntry in place.
    if (_isOpen &&
        (oldWidget.items != widget.items || oldWidget.value != widget.value)) {
      _removeOverlay();
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    } else {
      _isOpen = false;
    }
  }

  void _toggleMenu() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.hasSize) return;

    final fieldWidth = renderBox.size.width;
    final fieldHeight = renderBox.size.height;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            // Tapping anywhere else closes the menu — inserted first so it
            // sits BEHIND the menu itself and never intercepts taps on it.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, fieldHeight + 6),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: fieldWidth,
                      maxWidth: fieldWidth,
                      maxHeight: 260,
                    ),
                    child: widget.items.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (itemContext, index) {
                              final item = widget.items[index];
                              final selected = item.id == widget.value;

                              return InkWell(
                                onTap: () {
                                  widget.onChanged(item.id);
                                  _removeOverlay();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  color: selected
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                                  child: Text(
                                    EnumOptionTranslator.translate(item.name),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? AppColors.primary
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final selectedName = hasValue
        ? EnumOptionTranslator.translate(
            widget.items
                .firstWhere(
                  (item) => item.id == widget.value,
                  orElse: () => widget.items.first,
                )
                .name,
          )
        : null;

    final borderColor = widget.hasError
        ? AppColors.danger
        : (_isOpen ? AppColors.primary : const Color(0xFFD5D5D5));

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleMenu,
        behavior: HitTestBehavior.opaque,
        child: Container(
          key: _fieldKey,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: hasValue ? 10 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.hasError || _isOpen ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: hasValue
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedName ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.primaryDark.withOpacity(0.6),
                        ),
                      ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.primaryDark.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
