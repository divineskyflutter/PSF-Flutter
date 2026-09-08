// lib/shared/widgets/network/network_controller.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  final RxBool showNoInternet = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        show();
      } else {
        hide();
      }
    });
  }

  /// Call this from anywhere — connectivity listener OR Dio interceptor
  void show() => showNoInternet.value = true;

  void hide() => showNoInternet.value = false;

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}