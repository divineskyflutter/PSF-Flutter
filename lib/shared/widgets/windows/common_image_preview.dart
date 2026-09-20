import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

// ==========================================================
// IMAGE PREVIEW MODE
// ==========================================================

enum ImagePreviewMode {
  dialog,
  fullScreen,
}

// ==========================================================
// IMAGE TYPE
// ==========================================================

enum PreviewImageType {
  network,
  asset,
}

// ==========================================================
// IMAGE ITEM
// ==========================================================

class PreviewImageItem {
  final String imagePath;
  final PreviewImageType type;

  const PreviewImageItem({
    required this.imagePath,
    this.type = PreviewImageType.network,
  });
}

// ==========================================================
// COMMON IMAGE PREVIEW
// ==========================================================

class CommonImagePreview {
  CommonImagePreview._();

  static Future<void> show({
    required BuildContext context,
    required List<PreviewImageItem> images,
    int initialIndex = 0,
    ImagePreviewMode mode = ImagePreviewMode.dialog,
  }) async {
    if (images.isEmpty) return;

    // Prevent invalid index.
    final safeInitialIndex =
    initialIndex.clamp(0, images.length - 1);

    // ========================================================
    // FULL SCREEN
    // ========================================================

    if (mode == ImagePreviewMode.fullScreen) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (
              context,
              animation,
              secondaryAnimation,
              ) {
            return ImagePreviewScreen(
              images: images,
              initialIndex: safeInitialIndex,
              mode: mode,
            );
          },
          transitionDuration:
          const Duration(milliseconds: 180),
          reverseTransitionDuration:
          const Duration(milliseconds: 150),
          transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
              ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );

      return;
    }

    // ========================================================
    // DIALOG (ANIMATED POPUP WITH BLUR BACKDROP)
    // ========================================================

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Image Preview',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 4.px(dialogContext),
              vertical: 20.px(dialogContext),
            ),
            child: ImagePreviewScreen(
              images: images,
              initialIndex: safeInitialIndex,
              mode: mode,
            ),
          ),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

// ==========================================================
// IMAGE PREVIEW SCREEN
// ==========================================================

class ImagePreviewScreen extends StatefulWidget {
  final List<PreviewImageItem> images;
  final int initialIndex;
  final ImagePreviewMode mode;

  const ImagePreviewScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.mode,
  });

  @override
  State<ImagePreviewScreen> createState() =>
      _ImagePreviewScreenState();
}

class _ImagePreviewScreenState
    extends State<ImagePreviewScreen> {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final PageController _pageController;

  // ==========================================================
  // STATE
  // ==========================================================

  late int _currentIndex;

  bool _isChangingPage = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  // ==========================================================
  // PREVIOUS
  // ==========================================================

  void _previousImage() {
    if (_isChangingPage) return;

    if (_currentIndex <= 0) return;

    _isChangingPage = true;

    _pageController
        .previousPage(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOut,
    )
        .whenComplete(() {
      _isChangingPage = false;
    });
  }

  // ==========================================================
  // NEXT
  // ==========================================================

  void _nextImage() {
    if (_isChangingPage) return;

    if (_currentIndex >=
        widget.images.length - 1) {
      return;
    }

    _isChangingPage = true;

    _pageController
        .nextPage(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOut,
    )
        .whenComplete(() {
      _isChangingPage = false;
    });
  }

  // ==========================================================
  // PAGE CHANGED
  // ==========================================================

  void _onPageChanged(int index) {
    if (!mounted) return;

    setState(() {
      _currentIndex = index;
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final isFullScreen =
        widget.mode ==
            ImagePreviewMode.fullScreen;

    final borderRadius =
    isFullScreen ? 0.0 : 14.px(context);

    // Full-screen mode draws edge to edge, so its top controls (back
    // button, "1 / 3" counter) and bottom indicators must sit inside the
    // safe area — otherwise they end up under the camera cutout / status
    // bar. The dialog mode is already inset by the Dialog itself.
    final insets = isFullScreen
        ? MediaQuery.paddingOf(context)
        : EdgeInsets.zero;

    return Material(
      color: Colors.transparent,

      child: Container(
        width: isFullScreen ? double.infinity : 360.px(context),
        height: isFullScreen ? double.infinity : 600.px(context),

        decoration: BoxDecoration(
          // Soft transparent background.
          color: AppColors.primary,

          borderRadius:
          BorderRadius.circular(
            borderRadius,
          ),
        ),

        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(
            borderRadius,
          ),

          child: Stack(
            children: [

              // ==================================================
              // IMAGE GALLERY
              // ==================================================

              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 55.px(context) + insets.top,
                    bottom: 30.px(context) + insets.bottom,
                  ),

                  child: PhotoViewGallery.builder(
                    itemCount:
                    widget.images.length,

                    pageController:
                    _pageController,

                    backgroundDecoration:
                    const BoxDecoration(
                      color: Colors.transparent,
                    ),

                    // Smooth page movement.
                    scrollPhysics:
                    const ClampingScrollPhysics(),

                    // Initial image.
                    pageSnapping: true,

                    // Keep page movement smooth.
                    onPageChanged:
                    _onPageChanged,

                    // ------------------------------------------------
                    // IMAGE BUILDER
                    // ------------------------------------------------

                    builder: (
                        context,
                        index,
                        ) {
                      final image =
                      widget.images[index];

                      return PhotoViewGalleryPageOptions(
                        imageProvider: _imageProvider(image),

                        minScale:
                        PhotoViewComputedScale.contained * 0.95,

                        initialScale:
                        PhotoViewComputedScale.contained * 1.0,

                        maxScale:
                        PhotoViewComputedScale.covered * 3.0,

                        gestureDetectorBehavior:
                        HitTestBehavior.opaque,

                        filterQuality:
                        FilterQuality.medium,

                        errorBuilder: (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return _errorWidget(context);
                        },
                      );
                    },
                  ),
                ),
              ),

              // ==================================================
              // CLOSE / BACK BUTTON
              // ==================================================

              Positioned(
                top: 12.px(context) + insets.top,
                left: isFullScreen ? 10.px(context) + insets.left : null,
                // Only ONE horizontal edge is pinned: with both left and
                // right set the button was stretched across the whole width
                // and its icon ended up centered, on top of the "1 / 4"
                // counter.
                right: isFullScreen ? null : 10.px(context) + insets.right,

                child: _buildTopButton(
                  context: context,

                  icon: isFullScreen
                      ? Icons.arrow_back_rounded
                      : Icons.close_rounded,

                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // ==================================================
              // IMAGE COUNT
              // ==================================================

              if (widget.images.length > 1)
                Positioned(
                  top: 15.px(context) + insets.top,
                  left: 0,
                  right: 0,

                  child: Center(
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(
                        horizontal:
                        12.px(context),
                        vertical:
                        6.px(context),
                      ),

                      decoration:
                      BoxDecoration(
                        color: AppColors.background
                            .withOpacity(0.10),

                        borderRadius:
                        BorderRadius.circular(
                          20.px(context),
                        ),

                        border: Border.all(
                          color: AppColors.background
                              .withOpacity(0.18),
                        ),
                      ),

                      child: Text(
                        '${_currentIndex + 1} / '
                            '${widget.images.length}',

                        style: TextStyle(
                          color:
                          AppColors.background,
                          fontSize:
                          12.px(context),
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              // ==================================================
              // LEFT BUTTON
              // ==================================================

              if (_currentIndex > 0)
                Positioned(
                  left: 5.px(context),
                  top: 0,
                  bottom: 0,

                  child: Center(
                    child:
                    _buildNavigationButton(
                      context: context,

                      icon:
                      Icons.chevron_left_rounded,

                      onTap:
                      _previousImage,
                    ),
                  ),
                ),

              // ==================================================
              // RIGHT BUTTON
              // ==================================================

              if (_currentIndex <
                  widget.images.length - 1)
                Positioned(
                  right: 5.px(context),
                  top: 0,
                  bottom: 0,

                  child: Center(
                    child:
                    _buildNavigationButton(
                      context: context,

                      icon:
                      Icons.chevron_right_rounded,

                      onTap:
                      _nextImage,
                    ),
                  ),
                ),

              // ==================================================
              // BOTTOM INDICATORS
              // ==================================================

              if (widget.images.length > 1)
                Positioned(
                  bottom: 14.px(context) + insets.bottom,
                  left: 0,
                  right: 0,

                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,

                      children: List.generate(
                        widget.images.length,
                            (index) {
                          final isSelected =
                              index ==
                                  _currentIndex;

                          return AnimatedContainer(
                            duration:
                            const Duration(
                              milliseconds: 160,
                            ),

                            curve:
                            Curves.easeOut,

                            margin:
                            EdgeInsets.symmetric(
                              horizontal:
                              3.px(context),
                            ),

                            width: isSelected
                                ? 20.px(context)
                                : 6.px(context),

                            height:
                            6.px(context),

                            decoration:
                            BoxDecoration(
                              color: isSelected
                                  ? AppColors.background
                                  : AppColors.background
                                  .withOpacity(
                                0.25,
                              ),

                              borderRadius:
                              BorderRadius
                                  .circular(
                                20.px(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // IMAGE PROVIDER
  // ==========================================================

  ImageProvider _imageProvider(
      PreviewImageItem image,
      ) {
    if (image.type ==
        PreviewImageType.asset) {
      return AssetImage(
        image.imagePath,
      );
    }

    return NetworkImage(
      image.imagePath,
    );
  }

  // ==========================================================
  // LOADING WIDGET
  // ==========================================================

  Widget _loadingWidget(
      BuildContext context,
      ) {
    return Center(
      child: Container(
        width: 48.px(context),
        height: 48.px(context),

        padding: EdgeInsets.all(
          10.px(context),
        ),

        decoration: BoxDecoration(
          color: AppColors.background
              .withOpacity(0.75),

          shape: BoxShape.circle,
        ),

        child:
        const CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ==========================================================
  // ERROR WIDGET
  // ==========================================================

  Widget _errorWidget(
      BuildContext context,
      ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            Icons.broken_image_outlined,

            color: AppColors.primary
                .withOpacity(0.55),

            size: 50.px(context),
          ),

          SizedBox(
            height: 10.px(context),
          ),

          Text(
            'Unable to load image',

            style: TextStyle(
              color: AppColors.primaryDark
                  .withOpacity(0.70),

              fontSize:
              14.px(context),

              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOP BUTTON
  // ==========================================================

  Widget _buildTopButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparent,


      borderRadius:
      BorderRadius.circular(
        30.px(context),
      ),

      child: InkWell(
        onTap: onTap,

        borderRadius:
        BorderRadius.circular(
          30.px(context),
        ),

        child: SizedBox(
          width: 35.px(context),
          height: 35.px(context),

          child: Icon(
            icon,

            color:
            AppColors.background,

            size: 24.px(context),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NAVIGATION BUTTON
  // ==========================================================

  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background
          .withOpacity(0.18),

      shape: const CircleBorder(),


      child: InkWell(
        onTap: onTap,

        customBorder:
        const CircleBorder(),

        child: SizedBox(
          width: 35.px(context),
          height: 35.px(context),

          child: Icon(
            icon,

            color:
            AppColors.primaryDark,

            size: 32.px(context),
          ),
        ),
      ),
    );
  }
}