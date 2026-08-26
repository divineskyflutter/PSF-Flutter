import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../app/constants/app_assets.dart';
import '../../../app/constants/app_colors.dart';
import '../../../shared/extensions/new_responsive_extensions.dart';
import 'app_loader_controller.dart';

class AppLoader extends StatelessWidget {
  final Widget? child;
  final Widget? customLoader;

  final bool overlay;

  const AppLoader({
    super.key,
    this.child,
    this.customLoader,
    this.overlay = false,
  });

  /// ------------------------------------------------------------
  /// GLOBAL OVERLAY ROOT
  /// ------------------------------------------------------------

  static Widget overlayRoot({
    required Widget child,
  }) {
    return _GlobalLoaderOverlay(
      child: child,
    );
  }

  /// ------------------------------------------------------------
  /// DEFAULT INLINE LOADER
  /// ------------------------------------------------------------

  factory AppLoader.inline({
    Key? key,
    Widget? customLoader,
  }) {
    return AppLoader(
      key: key,
      customLoader: customLoader,
    );
  }

  /// ------------------------------------------------------------
  /// DEFAULT OVERLAY LOADER
  /// ------------------------------------------------------------

  factory AppLoader.overlay({
    Key? key,
    Widget? customLoader,
  }) {
    return AppLoader(
      key: key,
      customLoader: customLoader,
      overlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loader = customLoader ?? _DefaultLoader();

    if (!overlay) {
      return Center(child: loader);
    }

    return Stack(
      children: [
        if (child != null) child!,

        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.25),
            alignment: Alignment.center,
            child: loader,
          ),
        ),
      ],
    );
  }
}

class _DefaultLoader extends StatefulWidget {
  @override
  State<_DefaultLoader> createState() =>
      _DefaultLoaderState();
}

class _DefaultLoaderState extends State<_DefaultLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.88,
        end: 1.05,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      ),
      child: SvgPicture.asset(
        width: 92.px(context),
        height: 92.px(context),
        AppAssets.logo,
      ),
    );
  }
}

class _GlobalLoaderOverlay extends StatelessWidget {
  final Widget child;

  const _GlobalLoaderOverlay({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final loaderController =
    Get.find<AppLoaderController>();

    return Stack(
      children: [
        child,

        Obx(() {
          if (!loaderController.isLoading.value) {
            return const SizedBox.shrink();
          }

          return Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withOpacity(0.25),
                alignment: Alignment.center,
                child:
                loaderController.customLoader.value ??
                    _DefaultLoader(),
              ),
            ),
          );
        }),
      ],
    );
  }
}