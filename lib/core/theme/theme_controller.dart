import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/app_prefs.dart';

class ThemeController extends GetxController {

  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() async {
    _isDarkMode.value = AppPrefs.isDarkMode ?? false;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    await AppPrefs.setDarkMode(
      _isDarkMode.value,
    );
  }
}
