import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/constants/app_colors.dart';

class AppDatePicker {
  AppDatePicker._();

  /// A fully custom date-picker dialog (calendar grid + a manual
  /// dd/mm/yyyy entry mode toggled by the pencil icon), replacing
  /// Flutter's own [showDatePicker]/[InputDatePickerFormField].
  ///
  /// That built-in manual-entry mode turned out to always use the
  /// mm/dd/yyyy order and plain English error text no matter what locale
  /// was passed to it via Localizations.override — Flutter's generated
  /// Material localizations don't actually vary the date order by
  /// country for English, only by language, so `en_GB` behaved exactly
  /// like `en_US` there. This custom dialog gives full control instead:
  /// a permanent dd / mm / yyyy layout with the "/" separators always
  /// visible, single-digit day/month entry auto-padded to two digits,
  /// real calendar-date validation (rejects e.g. 31/04), and an error
  /// message localized to whichever app language is currently selected.
  static Future<DateTime?> pickDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    final resolvedFirstDate = firstDate ?? DateTime(1900);
    final resolvedLastDate = lastDate ?? DateTime.now();
    var resolvedInitialDate = initialDate ?? DateTime.now();

    if (resolvedInitialDate.isBefore(resolvedFirstDate)) {
      resolvedInitialDate = resolvedFirstDate;
    } else if (resolvedInitialDate.isAfter(resolvedLastDate)) {
      resolvedInitialDate = resolvedLastDate;
    }

    return showDialog<DateTime>(
      context: context,
      builder: (context) => _AppDatePickerDialog(
        initialDate: resolvedInitialDate,
        firstDate: resolvedFirstDate,
        lastDate: resolvedLastDate,
      ),
    );
  }

  static String format(
      DateTime date,
      ) {
    return DateFormat(
      'dd/MM/yyyy',
    ).format(date);
  }

  /// Whole years between [dateOfBirth] and today — the common "show age
  /// next to date of birth" calculation, kept in one place instead of
  /// every screen re-deriving it.
  static int calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();

    var age = today.year - dateOfBirth.year;

    final birthdayHasOccurredThisYear =
        today.month > dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day >= dateOfBirth.day);

    if (!birthdayHasOccurredThisYear) {
      age--;
    }

    return age < 0 ? 0 : age;
  }

  /// Same idea as [calculateAge], but also returns the extra whole
  /// months since the last birthday — e.g. born 15 Mar 2000, checked on
  /// 11 Sep 2026, is 26 years and 5 months (the registration form's Step
  /// 1 age box shows both, not just the year count).
  static ({int years, int months}) calculateAgeYearsMonths(
      DateTime dateOfBirth,
      ) {
    final today = DateTime.now();

    var years = today.year - dateOfBirth.year;
    var months = today.month - dateOfBirth.month;

    if (today.day < dateOfBirth.day) {
      months--;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years < 0) {
      years = 0;
      months = 0;
    }

    return (years: years, months: months);
  }
}

class _AppDatePickerDialog extends StatefulWidget {
  const _AppDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

/// The two ways a typed dd/mm/yyyy entry can fail — kept as an enum
/// rather than a pre-translated string so the message is always resolved
/// fresh via .tr() at build time (always the live, currently-selected
/// app language) instead of being frozen into whatever language was
/// active the moment the error was raised.
enum _DateFieldError { invalidFormat, outOfRange }

class _AppDatePickerDialogState extends State<_AppDatePickerDialog> {
  late DateTime _selectedDate;
  bool _manualEntryMode = false;
  _DateFieldError? _error;

  String? get _errorText => switch (_error) {
    _DateFieldError.invalidFormat => 'invalid_date_error'.tr,
    _DateFieldError.outOfRange => 'date_out_of_range_error'.tr,
    null => null,
  };

  late final TextEditingController _dayController;
  late final TextEditingController _monthController;
  late final TextEditingController _yearController;
  late final FocusNode _dayFocus;
  late final FocusNode _monthFocus;
  late final FocusNode _yearFocus;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.initialDate;

    _dayController = TextEditingController(
      text: _selectedDate.day.toString().padLeft(2, '0'),
    );
    _monthController = TextEditingController(
      text: _selectedDate.month.toString().padLeft(2, '0'),
    );
    _yearController = TextEditingController(
      text: _selectedDate.year.toString(),
    );

    _dayFocus = FocusNode();
    _monthFocus = FocusNode();
    _yearFocus = FocusNode();

    // Single-digit day/month entry (e.g. "5") is auto-padded to two
    // digits ("05") as soon as that segment loses focus — matches how a
    // member would naturally expect a dd/mm/yyyy field to behave.
    _dayFocus.addListener(() => _padSegmentOnBlur(_dayController, _dayFocus));
    _monthFocus.addListener(
      () => _padSegmentOnBlur(_monthController, _monthFocus),
    );
  }

  void _padSegmentOnBlur(TextEditingController controller, FocusNode node) {
    if (!node.hasFocus && controller.text.length == 1) {
      controller.text = controller.text.padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _dayFocus.dispose();
    _monthFocus.dispose();
    _yearFocus.dispose();
    super.dispose();
  }

  /// The typed day/month/year as a real, valid DateTime — or null if any
  /// segment is missing/incomplete, or the combination isn't a real
  /// calendar date (Dart's DateTime constructor silently rolls invalid
  /// values like 31/04 over into the next month instead of throwing, so
  /// the roll-over is detected by comparing the parsed fields back
  /// against what was actually typed).
  DateTime? _parseTypedDate() {
    if (_dayController.text.isEmpty ||
        _monthController.text.isEmpty ||
        _yearController.text.length != 4) {
      return null;
    }

    final day = int.tryParse(_dayController.text.padLeft(2, '0'));
    final month = int.tryParse(_monthController.text.padLeft(2, '0'));
    final year = int.tryParse(_yearController.text);

    if (day == null || month == null || year == null) return null;

    final parsed = DateTime(year, month, day);

    final isRealCalendarDate = parsed.year == year &&
        parsed.month == month &&
        parsed.day == day;

    return isRealCalendarDate ? parsed : null;
  }

  void _toggleMode() {
    setState(() {
      if (_manualEntryMode) {
        // Leaving manual entry — if what was typed is a valid, in-range
        // date, carry it over so the calendar reopens on that date too.
        final typedDate = _parseTypedDate();
        if (typedDate != null &&
            !typedDate.isBefore(widget.firstDate) &&
            !typedDate.isAfter(widget.lastDate)) {
          _selectedDate = typedDate;
        }
      }

      _manualEntryMode = !_manualEntryMode;
      _error = null;

      if (_manualEntryMode) {
        _dayController.text = _selectedDate.day.toString().padLeft(2, '0');
        _monthController.text = _selectedDate.month.toString().padLeft(2, '0');
        _yearController.text = _selectedDate.year.toString();
      }
    });
  }

  void _handleOk() {
    if (!_manualEntryMode) {
      Navigator.of(context).pop(_selectedDate);
      return;
    }

    final typedDate = _parseTypedDate();

    if (typedDate == null) {
      setState(() => _error = _DateFieldError.invalidFormat);
      return;
    }

    if (typedDate.isBefore(widget.firstDate) ||
        typedDate.isAfter(widget.lastDate)) {
      setState(() => _error = _DateFieldError.outOfRange);
      return;
    }

    Navigator.of(context).pop(typedDate);
  }

  @override
  Widget build(BuildContext context) {
    final headerDateText = DateFormat('EEE, d MMM').format(_selectedDate);

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'select_date'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          headerDateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _manualEntryMode
                              ? Icons.calendar_today_outlined
                              : Icons.edit_outlined,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                        onPressed: _toggleMode,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: _manualEntryMode ? _buildManualEntry() : _buildCalendar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _handleOk,
                    child: Text('ok'.tr),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return SizedBox(
      width: 280,
      height: 340,
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.background,
            onSurface: AppColors.primaryDark,
          ),
        ),
        child: CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDateChanged: (date) => setState(() => _selectedDate = date),
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateSegmentField(
              controller: _dayController,
              focusNode: _dayFocus,
              previousFocus: null,
              nextFocus: _monthFocus,
              maxLength: 2,
              hint: 'dd',
              width: 54,
            ),
            _segmentSeparator(),
            _dateSegmentField(
              controller: _monthController,
              focusNode: _monthFocus,
              previousFocus: _dayFocus,
              nextFocus: _yearFocus,
              maxLength: 2,
              hint: 'mm',
              width: 54,
            ),
            _segmentSeparator(),
            _dateSegmentField(
              controller: _yearController,
              focusNode: _yearFocus,
              previousFocus: _monthFocus,
              nextFocus: null,
              maxLength: 4,
              hint: 'yyyy',
              width: 92,
            ),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorText!,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _segmentSeparator() {
    return const Padding(
      padding: EdgeInsets.only(top: 14),
      child: Text(
        '/',
        style: TextStyle(
          fontSize: 20,
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateSegmentField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? previousFocus,
    required FocusNode? nextFocus,
    required int maxLength,
    required String hint,
    required double width,
  }) {
    // A fixed, generous width instead of splitting the row by flex —
    // flex ratios left the 2-digit day/month boxes so narrow (once the
    // "/" separators and the row's own side padding were accounted for)
    // that the field's own internal horizontal scrolling kicked in,
    // clipping both the "mm" hint and typed digits until the member
    // scrolled sideways inside the box to see the rest. A wide fixed box
    // with the decoration's default content padding removed gives the
    // full width straight to the two/four characters actually shown.
    return SizedBox(
      width: width,
      child: Focus(
        // Backspacing on an already-empty segment jumps back to (and
        // selects) the previous one, instead of doing nothing — the same
        // "delete within the right section" behaviour an OTP-style
        // segmented field gives.
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty &&
              previousFocus != null) {
            previousFocus.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          // TextInputType.number can surface native Devanagari/Gujarati
          // numeral keys on a phone whose keyboard language is set to
          // Hindi/Gujarati — those get typed, then silently stripped by
          // the digitsOnly formatter below (which only matches ASCII
          // 0-9), leaving the segment looking blank even though the
          // member did type something. TextInputType.phone is the same
          // fix already used for the mobile-number field elsewhere in
          // this wizard — it reliably keeps the keyboard on plain ASCII
          // digits regardless of the device's language.
          keyboardType: TextInputType.phone,
          textAlign: TextAlign.center,
          maxLength: maxLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 20,
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            isDense: true,
            // No horizontal inset at all — with the box already sized
            // to fit its digits exactly, any left/right content padding
            // here just eats back into that same width.
            contentPadding: const EdgeInsets.only(bottom: 6),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (value) {
            if (_error != null) setState(() => _error = null);
            if (value.length == maxLength && nextFocus != null) {
              nextFocus.requestFocus();
            }
          },
        ),
      ),
    );
  }
}
