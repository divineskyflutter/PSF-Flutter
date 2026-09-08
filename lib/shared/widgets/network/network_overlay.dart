// lib/shared/widgets/network/network_overlay.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'network_controller.dart';

class NetworkOverlay {
  /// Wrap this around your app's child, same as AppLoader.overlayRoot
  static Widget overlayRoot({required Widget child}) {
    final controller = Get.find<NetworkController>();

    return Stack(
      children: [
        child,
        Obx(() {
          if (!controller.showNoInternet.value) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onTap: controller.hide, // tap outside box -> dismiss
            child: Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {}, // absorb tap so box itself doesn't dismiss
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 42, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      const Text(
                        'No Internet Connection',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please connect to a proper internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}