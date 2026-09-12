import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/auth/data/models/member_model.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/signature/app_signature_bottom_sheet.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/enum_option_translator.dart';
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

  @override
  void initState() {
    super.initState();

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
    if (fullNameFocusNode.hasFocus) return;
    controller.splitAndTranslateFullName(fullNameController.text);
  }

  void _onFatherNameFocusChange() {
    if (fatherNameFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.fatherNameController.text,
      targetModel: controller.fatherNameLanguages,
      isDirty: controller.isFatherNameDirty,
    );
  }

  void _onAddressFocusChange() {
    if (addressFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.addressController.text,
      targetModel: controller.addressLanguages,
      isDirty: controller.isAddressDirty,
    );
  }

  void _onSeriousIllnessDetailFocusChange() {
    if (seriousIllnessDetailFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.seriousIllnessDetailController.text,
      targetModel: controller.seriousIllnessLanguages,
      isDirty: controller.isSeriousIllnessDirty,
    );
  }

  void _onOtherHereditaryDetailFocusChange() {
    if (otherHereditaryDetailFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.otherHereditaryDetailController.text,
      targetModel: controller.otherHereditaryLanguages,
      isDirty: controller.isOtherHereditaryDirty,
    );
  }

  void _onSurgeryDetailFocusChange() {
    if (surgeryDetailFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.surgeryDetailController.text,
      targetModel: controller.surgeryLanguages,
      isDirty: controller.isSurgeryDirty,
    );
  }

  void _onAllergyDetailFocusChange() {
    if (allergyDetailFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.allergyDetailController.text,
      targetModel: controller.allergyLanguages,
      isDirty: controller.isAllergyDirty,
    );
  }

  void _onOtherHealthDetailFocusChange() {
    if (otherHealthDetailFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.otherHealthDetailController.text,
      targetModel: controller.otherHealthDetailLanguages,
      isDirty: controller.isOtherHealthDetailDirty,
    );
  }

  void _onVillageFocusChange() {
    if (villageFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.villageController.text,
      targetModel: controller.villageLanguages,
      isDirty: controller.isVillageDirty,
    );
  }

  void _onTalukaFocusChange() {
    if (talukaFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.talukaController.text,
      targetModel: controller.talukaLanguages,
      isDirty: controller.isTalukaDirty,
    );
  }

  void _onDistrictFocusChange() {
    if (districtFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.districtController.text,
      targetModel: controller.districtLanguages,
      isDirty: controller.isDistrictDirty,
    );
  }

  void _onStateFocusChange() {
    if (stateFocusNode.hasFocus) return;
    controller.translateNameFieldOnUnfocus(
      text: controller.stateController.text,
      targetModel: controller.stateLanguages,
      isDirty: controller.isStateDirty,
    );
  }

  void _onOccupationFocusChange() {
    if (occupationFocusNode.hasFocus) return;
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

      // Dismiss keyboard so no focus events fire during the async work.
      FocusScope.of(context).unfocus();

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

      // Upload documents, then save the personal-detail step. The loader
      // is shown internally for the whole sequence.
      final saved = await controller.saveMemberPersonalDetail();

      if (!saved) {
        return;
      }

      ToastUtil.success('information_saved_successfully'.tr);

      controller.nextStep();

      await pageController.animateToPage(
        1,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      return;
    }

    if (step == 1) {
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
      FocusScope.of(context).unfocus();

      final healthDeclarationSaved =
          await controller.saveHealthDeclaration();

      if (!healthDeclarationSaved) {
        // Only scroll when the failure was a missing/invalid field —
        // firstMissingHealthDetail() is exactly what saveHealthDeclaration
        // itself checked first. A null here means the false came from a
        // real save/API error instead (see saveHealthDeclaration), which
        // has nothing on screen to scroll to.
        if (controller.firstMissingHealthDetail() != null) {
          _scrollToFirstError(_healthCheckpoints());
        }
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
    controller.mobileController.removeListener(_formatMobileDisplay);
    controller.panNumberController.removeListener(_handlePanKeyboardSwitch);
    _panFocusNode.dispose();
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

            Center(
              key: _profileImageKey,
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
            AppTextField.form(
              key: _fullNameKey,
              label: 'full_name'.tr,
              hintText: 'full_name_hint'.tr,
              controller: fullNameController,
              focusNode: fullNameFocusNode,
              inputFormatters: [_nameInputFormatter],
              validator: (value) =>
                  AppValidators.fullName(value, message: 'full_name_format_error'.tr),
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              key: _fatherNameKey,
              label: 'father_name'.tr,
              hintText: 'father_name_hint'.tr,
              controller:
              controller.fatherNameController,
              focusNode: fatherNameFocusNode,
              validator: (value) => AppValidators.fatherName(
                value,
                message: 'father_name_format_error'.tr,
              ),
              inputFormatters: [
                _nameInputFormatter,
              ],
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
            AppTextField.form(
              label: 'mobile_number_2'.tr,
              controller:
              controller.mobile2Controller,
              keyboardType:
              TextInputType.phone,
              maxLength: 11,
              validator:
              AppValidators.mobileOptional,
              inputFormatters: [
                _MobileInputFormatter(),
              ],
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

            Container(
              key: _genderKey,
              child: Obx(() => _genderRadioGroup(context)),
            ),

            _inlineError(
              () => controller.selectedGenderId.value == null,
              'please_select_gender'.tr,
            ),

            SizedBox(
              height: 20.px(context),
            ),

            Container(
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
                },
                hasError: _showStep1Errors.value &&
                    controller.selectedMaritalStatusId.value == null,
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

            AppTextField.form(
              key: _addressKey,
              label: 'address'.tr,
              controller:
              controller.addressController,
              focusNode: addressFocusNode,
              maxLines: 3,
              validator:
              AppValidators.requiredField,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              key: _villageKey,
              label: 'village'.tr,
              controller:
              controller.villageController,
              focusNode: villageFocusNode,
              validator:
              AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              key: _talukaKey,
              label: 'taluka'.tr,
              controller:
              controller.talukaController,
              focusNode: talukaFocusNode,
              validator:
              AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              key: _districtKey,
              label: 'district'.tr,
              controller:
              controller.districtController,
              focusNode: districtFocusNode,
              validator:
              AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              key: _stateKey,
              label: 'state'.tr,
              controller:
              controller.stateController,
              focusNode: stateFocusNode,
              validator:
              AppValidators.placeName,
              inputFormatters: [_placeNameInputFormatter],
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

            AppTextField.form(
              key: _aadharNumberKey,
              label: 'aadhaar_number'.tr,
              controller:
              controller
                  .aadharNumberController,
              keyboardType:
              TextInputType.number,
              // 12 digits + 2 grouping spaces ("1234 5678 9012") — see
              // _AadharInputFormatter.
              maxLength: 14,
              validator:
              AppValidators.aadhar,
              inputFormatters: [
                _AadharInputFormatter(),
              ],
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Container(
              key: _aadharFrontKey,
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
              child: ValueListenableBuilder<TextEditingValue>(
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
                      // "Close the keyboard after completion" — PAN is
                      // always exactly 10 characters, so once the last one
                      // is entered there's nothing left to type.
                      if (text.length == 10) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                  );
                },
              ),
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Container(
              key: _panImageKey,
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

            AppTextField.form(
              key: _occupationKey,
              label: 'occupation'.tr,
              controller:
              controller.occupationController,
              focusNode: occupationFocusNode,
              validator:
              AppValidators.name,
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

            Center(
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
            AppTextField.form(
              label: 'nominee_name'.tr,
              hintText: 'full_name_hint'.tr,
              controller: slot.nameController,
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
            ),

            SizedBox(height: 16.px(context)),

            Container(
              key: _nomineeRelationKeys[index],
              child: Obx(
                    () => _enumDropdown(
                context: context,
                label: 'relationship'.tr,
                value: slot.relationId.value,
                items: controller.relationOptions.value,
                onChanged: (value) {
                  slot.relationId.value = value;
                },
                hasError:
                    slot.showErrors.value && slot.relationId.value == null,
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
                      enabledBorderColor:
                          exceeds ? AppColors.danger : null,
                      focusedBorderColor:
                          exceeds ? AppColors.danger : null,
                    );
                  }),
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
            AppTextField.form(
              label: 'nominee_aadhaar_number'.tr,
              controller: slot.aadharNoController,
              keyboardType: TextInputType.number,
              // 12 digits + 2 grouping spaces ("1234 5678 9012") — see
              // _AadharInputFormatter.
              maxLength: 14,
              validator: AppValidators.aadhar,
              inputFormatters: [
                _AadharInputFormatter(),
              ],
            ),

            SizedBox(height: 12.px(context)),

            Container(
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

            _inlineError(
              () => slot.aadharFrontImage.value == null &&
                  slot.aadharFrontImageDocumentId.value == null,
              'please_upload_nominee_aadhaar_front_photo'.tr,
              showFlag: slot.showErrors,
            ),

            SizedBox(height: 12.px(context)),

            Container(
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

            _inlineError(
              () => slot.aadharBackImage.value == null &&
                  slot.aadharBackImageDocumentId.value == null,
              'please_upload_nominee_aadhaar_back_photo'.tr,
              showFlag: slot.showErrors,
            ),

            SizedBox(height: 12.px(context)),

            Container(
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

            _inlineError(
              () => slot.passbookChequeImage.value == null &&
                  slot.passbookChequeImageDocumentId.value == null,
              'please_upload_nominee_passbook_cheque_photo'.tr,
              showFlag: slot.showErrors,
            ),
          ],
        ),
      ),
    );
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

          // isSeriousIllness -> seriousIllness (translated)
          Obx(() {
            final hasIllness = controller.hasCurrentIllness.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  key: _healthCurrentIllnessKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_current_illness'.tr,
                    value: hasIllness,
                    onChanged: (value) =>
                    controller.setHasCurrentIllness(value),
                  ),
                ),
                if (hasIllness == true) ...[
                  SizedBox(height: 12.px(context)),
                  AppTextField.form(
                    key: _healthCurrentIllnessDetailKey,
                    label: 'health_q_current_illness_detail'.tr,
                    controller: controller.seriousIllnessDetailController,
                    focusNode: seriousIllnessDetailFocusNode,
                    maxLines: 2,
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

          Obx(
                () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final key in RegistrationController.diseaseKeys)
                  _diseaseChip(context, key),
              ],
            ),
          ),

          // anyHerediatry -> other (translated) — the 'disease_hereditary'
          // chip's own "please specify" detail.
          Obx(() {
            final isHereditary =
                controller.selectedDiseaseKeys.contains('disease_hereditary');

            if (!isHereditary) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(top: 12.px(context)),
              child: AppTextField.form(
                key: _healthHereditaryDetailKey,
                label: 'health_hereditary_detail'.tr,
                controller: controller.otherHereditaryDetailController,
                focusNode: otherHereditaryDetailFocusNode,
                maxLines: 2,
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
                Container(
                  key: _healthSurgeryKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_surgery'.tr,
                    value: hadSurgery,
                    onChanged: (value) => controller.setHadSurgery(value),
                  ),
                ),
                if (hadSurgery == true) ...[
                  SizedBox(height: 12.px(context)),
                  AppTextField.form(
                    key: _healthSurgeryDetailKey,
                    label: 'health_q_surgery_detail'.tr,
                    controller: controller.surgeryDetailController,
                    focusNode: surgeryDetailFocusNode,
                    maxLines: 2,
                  ),
                  SizedBox(height: 12.px(context)),
                  AppTextField.form(
                    key: _healthSurgeryDateKey,
                    label: 'health_q_surgery_date'.tr,
                    controller: controller.surgeryDateController,
                    readOnly: true,
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                    onTap: () => controller.pickSurgeryDate(context),
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
                Container(
                  key: _healthMedicationKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_medication'.tr,
                    value: onMedication,
                    onChanged: (value) =>
                    controller.setOnRegularMedication(value),
                  ),
                ),
                if (onMedication == true) ...[
                  SizedBox(height: 12.px(context)),
                  AppTextField.form(
                    key: _healthMedicationDetailKey,
                    label: 'health_q_medication_detail'.tr,
                    controller: controller.medicationDetailController,
                    maxLines: 2,
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
                Container(
                  key: _healthAllergyKey,
                  child: _yesNoField(
                    context,
                    question: 'health_q_allergy'.tr,
                    value: hasAllergies,
                    onChanged: (value) =>
                    controller.setHasAllergies(value),
                  ),
                ),
                if (hasAllergies == true) ...[
                  SizedBox(height: 12.px(context)),
                  AppTextField.form(
                    key: _healthAllergyDetailKey,
                    label: 'health_q_allergy_detail'.tr,
                    controller: controller.allergyDetailController,
                    focusNode: allergyDetailFocusNode,
                    maxLines: 2,
                  ),
                ],
              ],
            );
          }),

          SizedBox(height: 22.px(context)),

          Container(
            key: _healthTobaccoKey,
            child: Obx(
                  () => _yesNoField(
                context,
                question: 'health_q_tobacco'.tr,
                value: controller.usesTobacco.value,
                onChanged: (value) => controller.usesTobacco.value = value,
              ),
            ),
          ),

          SizedBox(height: 16.px(context)),

          Container(
            key: _healthAlcoholKey,
            child: Obx(
                  () => _yesNoField(
                context,
                question: 'health_q_alcohol'.tr,
                value: controller.consumesAlcohol.value,
                onChanged: (value) => controller.consumesAlcohol.value = value,
              ),
            ),
          ),

          SizedBox(height: 16.px(context)),

          Container(
            key: _healthDrugsKey,
            child: Obx(
                  () => _yesNoField(
                context,
                question: 'health_q_drugs'.tr,
                value: controller.usesDrugs.value,
                onChanged: (value) => controller.usesDrugs.value = value,
              ),
            ),
          ),

          SizedBox(height: 22.px(context)),

          // otherDetails (translated) — standalone, always optional, no
          // yes/no gate (the swagger schema has no boolean flag for it).
          AppTextField.form(
            label: 'health_q_other'.tr,
            controller: controller.otherHealthDetailController,
            focusNode: otherHealthDetailFocusNode,
            maxLines: 2,
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

    return InkWell(
      onTap: () => controller.toggleDiseaseKey(key),
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
