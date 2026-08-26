import 'dart:async';

import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/features/auth/presentation/widgets/empty_state.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/images/common_image_view.dart';
import 'package:psf_application/shared/widgets/loaders/app_shimmer.dart';

class AppImageSlider extends StatefulWidget {
  const AppImageSlider({
    super.key,
    required this.images,
    required this.imageType,

    this.isLoading = false,

    this.height = 220,

    this.horizontalPadding = 18,

    this.borderRadius = 18,

    this.autoSlide = true,

    this.autoSlideDuration = const Duration(seconds: 4),

    this.animationDuration = const Duration(
      milliseconds: 600,
    ),

    this.showIndicators = true,

    this.showEmptyPlaceholder = true,

    this.loadingWidget,

    this.emptyWidget,

    this.onPageChanged,
  });

  /// Images used by the slider.
  final List<String> images;

  /// Network or asset.
  final CommonImageType imageType;

  /// API loading state.
  final bool isLoading;

  /// Slider height.
  final double height;

  /// Horizontal space around each image.
  final double horizontalPadding;

  /// Image border radius.
  final double borderRadius;

  /// Automatically move slider.
  final bool autoSlide;

  /// Time between slides.
  final Duration autoSlideDuration;

  /// Animation duration.
  final Duration animationDuration;

  /// Show dots below slider.
  final bool showIndicators;

  /// Show placeholder when API has completed but no images exist.
  final bool showEmptyPlaceholder;

  /// Optional custom loading widget.
  final Widget? loadingWidget;

  /// Optional custom empty widget.
  final Widget? emptyWidget;

  final ValueChanged<int>? onPageChanged;

  @override
  State<AppImageSlider> createState() => _AppImageSliderState();
}

class _AppImageSliderState extends State<AppImageSlider> {
  late final PageController _pageController;

  Timer? _timer;

  /// Logical page.
  ///
  /// This is intentionally not limited to images.length.
  /// It allows the slider to continue infinitely.
  int _currentPage = 0;

  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      initialPage: 0,
    );

    _startAutoSlideIfNeeded();
  }

  // ==========================================================
  // AUTO SLIDER
  // ==========================================================

  void _startAutoSlideIfNeeded() {
    _timer?.cancel();

    if (!widget.autoSlide) return;

    if (widget.images.length <= 1) return;

    _timer = Timer.periodic(
      widget.autoSlideDuration,
          (_) {
        _moveToNext();
      },
    );
  }

  // ==========================================================
  // NEXT
  // ==========================================================

  void _moveToNext() {
    if (!mounted) return;

    if (!_pageController.hasClients) return;

    if (_isUserScrolling) return;

    if (widget.images.length <= 1) return;

    final nextPage = _currentPage + 1;

    _pageController.animateToPage(
      nextPage,
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
    );
  }

  // ==========================================================
  // PAGE CHANGED
  // ==========================================================

  void _onPageChanged(int page) {
    if (!mounted) return;

    setState(() {
      _currentPage = page;
    });

    final actualIndex = _getActualIndex(page);

    widget.onPageChanged?.call(actualIndex);
  }

  // ==========================================================
  // ACTUAL IMAGE INDEX
  // ==========================================================

  int _getActualIndex(int page) {
    if (widget.images.isEmpty) {
      return 0;
    }

    return page % widget.images.length;
  }

  @override
  void didUpdateWidget(
      covariant AppImageSlider oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.images.length != widget.images.length ||
        oldWidget.autoSlide != widget.autoSlide ||
        oldWidget.autoSlideDuration !=
            widget.autoSlideDuration) {
      _startAutoSlideIfNeeded();
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // API LOADING
    // ========================================================

    if (widget.isLoading && widget.images.isEmpty) {
      return _buildLoading(context);
    }

    // ========================================================
    // EMPTY
    // ========================================================

    if (widget.images.isEmpty) {
      if (!widget.showEmptyPlaceholder) {
        return const SizedBox.shrink();
      }

      return _buildEmpty(context);
    }

    // ========================================================
    // SINGLE IMAGE
    // ========================================================

    if (widget.images.length == 1) {
      return _buildSingleImage(context);
    }

    // ========================================================
    // MULTIPLE IMAGES
    // ========================================================

    return _buildMultipleImages(context);
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding.px(context),
      ),
      child: AppShimmer(
        child: Container(
          width: double.infinity,
          height: widget.height.px(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              widget.borderRadius.px(context),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.horizontalPadding.px(context),
      ),
      child: SizedBox(
        height: widget.height.px(context),
        child: widget.emptyWidget ??
            PlaceholderBanner(
              index: 0,
            ),
      ),
    );
  }

  // ==========================================================
  // SINGLE IMAGE
  // ==========================================================

  Widget _buildSingleImage(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: widget.height.px(context),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding.px(context),
            ),
            child: CommonImageView(
              image: widget.images.first,
              type: widget.imageType,
              index: 0,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(
                widget.borderRadius.px(context),
              ),
            ),
          ),
        ),

        if (widget.showIndicators)
          SizedBox(
            height: 16.px(context),
          ),
      ],
    );
  }

  // ==========================================================
  // MULTIPLE IMAGES
  // ==========================================================

  Widget _buildMultipleImages(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: widget.height.px(context),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _isUserScrolling = true;
              }

              if (notification is ScrollEndNotification) {
                _isUserScrolling = false;
              }

              return false;
            },
            child: PageView.builder(
              controller: _pageController,

              // ==================================================
              // INFINITE SLIDER
              // ==================================================
              //
              // We are NOT creating duplicate image data.
              //
              // The index is converted using:
              //
              // page % images.length
              //
              // This allows:
              //
              // 0 → 1 → 2 → 0 → 1 → 2 → ...
              //
              // without copying the actual image list.
              //
              itemCount: null,

              onPageChanged: _onPageChanged,

              itemBuilder: (context, page) {
                final actualIndex =
                _getActualIndex(page);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                    widget.horizontalPadding.px(context),
                  ),
                  child: CommonImageView(
                    image: widget.images[actualIndex],
                    type: widget.imageType,
                    index: actualIndex,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius.px(context),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (widget.showIndicators) ...[
          SizedBox(
            height: 10.px(context),
          ),

          _buildIndicators(context),
        ],
      ],
    );
  }

  // ==========================================================
  // INDICATORS
  // ==========================================================

  Widget _buildIndicators(BuildContext context) {
    final actualIndex =
    _getActualIndex(_currentPage);

    return SizedBox(
      height: 8.px(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.images.length,
              (index) {
            final selected =
                index == actualIndex;

            return AnimatedContainer(
              duration: const Duration(
                milliseconds: 250,
              ),
              curve: Curves.easeInOut,

              margin: EdgeInsets.symmetric(
                horizontal: 3.px(context),
              ),

              width: selected
                  ? 20.px(context)
                  : 7.px(context),

              height: 7.px(context),

              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(
                  0.25,
                ),
                borderRadius: BorderRadius.circular(
                  10.px(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}