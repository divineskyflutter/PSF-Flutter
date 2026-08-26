import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_colors.dart';

class ToastUtil {
  ToastUtil._();

  static void success(String message, {String title = 'Success'}) {
    if (message.isEmpty) return;
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF2E9D68),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 28),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      boxShadows: [
        const BoxShadow(
          color: Color(0x29000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    );
  }

  static void error(String message, {String title = 'Error'}) {
    if (message.isEmpty) return;
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFFD94B4B),
      colorText: Colors.white,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 28),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      boxShadows: [
        const BoxShadow(
          color: Color(0x29000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    );
  }

  static void info(String message, {String title = 'Information'}) {
    if (message.isEmpty) return;
    Get.snackbar(
      title,
      message,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 28),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      boxShadows: [
        const BoxShadow(
          color: Color(0x29000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ],
    );
  }
}