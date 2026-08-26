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
}