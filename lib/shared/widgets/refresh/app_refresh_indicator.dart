import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/widgets/loaders/app_loader_controller.dart';

class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    required this.child,
    required this.onRefresh,
    this.refreshColor,
    this.backgroundColor,
    this.displacement = 40,
    this.edgeOffset = 0,

    /// Whether to show global overlay loader
    this.showOverlay = false,

    super.key,
  });

  final Widget child;

  final Future<void> Function() onRefresh;

  final Color? refreshColor;

  final Color? backgroundColor;

  final double displacement;

  final double edgeOffset;

  /// Show global AppLoader while refreshing
  final bool showOverlay;

  @override
  State<AppRefreshIndicator> createState() =>
      _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState
    extends State<AppRefreshIndicator> {
  bool _refreshing = false;

  late final AppLoaderController _loaderController;

  @override
  void initState() {
    super.initState();

    _loaderController =
        Get.find<AppLoaderController>();
  }

  Future<void> _handleRefresh() async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
    });

    /// Only show global overlay if enabled
    if (widget.showOverlay) {
      _loaderController.show();
    }

    try {
      await widget.onRefresh();
    } finally {
      /// Only hide if this widget showed it
      if (widget.showOverlay) {
        _loaderController.hide();
      }

      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,

      color:
      widget.refreshColor ??
          AppColors.primary,

      backgroundColor:
      widget.backgroundColor ??
          Colors.white,

      displacement: widget.displacement,

      edgeOffset: widget.edgeOffset,

      child: widget.child,
    );
  }
}