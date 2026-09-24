import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';

/// Wraps a screen that can be reached directly from the side drawer (About
/// Us, Contact Us — pushed with `arguments: {'viaDrawer': true}`).
///
/// When reached that way, the header's back arrow (via the [onBack] handed
/// to [builder]) and the system back gesture (via the [PopScope] below) both
/// pop the screen and then reopen the drawer, instead of just landing on
/// whatever tab sits underneath — so the two ways of going back behave
/// identically.
///
/// When NOT reached via the drawer (e.g. a screen pushed from inside one of
/// these pages, like About Us's own "Contact us" button), [builder] gets a
/// `null` onBack — the header falls back to its own default plain pop — and
/// no PopScope is applied, so both back paths unwind one level normally.
class DrawerBackScope extends StatelessWidget {
  const DrawerBackScope({super.key, required this.builder});

  final Widget Function(BuildContext context, VoidCallback? onBack) builder;

  bool get _viaDrawer {
    final arguments = Get.arguments;
    return arguments is Map && arguments['viaDrawer'] == true;
  }

  void _backToDrawer() {
    Get.back();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MainNavigationController>().openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_viaDrawer) return builder(context, null);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _backToDrawer();
      },
      child: builder(context, _backToDrawer),
    );
  }
}
