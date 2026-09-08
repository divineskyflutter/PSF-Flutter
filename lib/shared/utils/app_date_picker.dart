import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/constants/app_colors.dart';

class AppDatePicker {
  AppDatePicker._();

  static Future<DateTime?> pickDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return showDatePicker(
      context: context,

      initialDate:
      initialDate ?? DateTime.now(),

      firstDate:
      firstDate ?? DateTime(1900),

      lastDate:
      lastDate ?? DateTime.now(),

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.background,
              onSurface: AppColors.primaryDark,
            ),
          ),

          child: child!,
        );
      },
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
}