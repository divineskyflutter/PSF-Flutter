import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppLoaderController extends GetxController {
  final RxBool isLoading = false.obs;

  /// Optional custom loader
  final Rx<Widget?> customLoader = Rx<Widget?>(null);

  /// Show global overlay loader
  void show({
    Widget? loader,
  }) {
    customLoader.value = loader;
    isLoading.value = true;
  }

  /// Hide global overlay loader
  void hide() {
    isLoading.value = false;
    customLoader.value = null;
  }
}