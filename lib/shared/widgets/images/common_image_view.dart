import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:psf_application/features/auth/presentation/widgets/empty_state.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/loaders/app_shimmer.dart';

enum CommonImageType {
  network,
  asset,
}

class CommonImageView extends StatelessWidget {
  const CommonImageView({
    super.key,
    required this.image,
    required this.type,
    this.index = 0,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.showShimmer = true,
    this.showPlaceholder = true,
    this.placeholder,
  });

  final String image;

  final CommonImageType type;

  final int index;

  final BoxFit fit;

  final BorderRadius? borderRadius;

  final double? width;

  final double? height;

  /// Show shimmer while network image is downloading.
  final bool showShimmer;

  /// Show PlaceholderBanner when image fails.
  final bool showPlaceholder;

  /// Optional custom placeholder.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ??
        BorderRadius.circular(
          22.px(context),
        );

    Widget imageWidget;

    switch (type) {
    // ==========================================================
    // NETWORK
    // ==========================================================

      case CommonImageType.network:
        imageWidget = CachedNetworkImage(
          imageUrl: image,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          fit: fit,

          // ------------------------------------------------------
          // NETWORK IMAGE LOADING
          // ------------------------------------------------------

          placeholder: (_, __) {
            if (!showShimmer) {
              return placeholder ??
                  const SizedBox.shrink();
            }

            return AppShimmer(
              child: Container(
                width: width ?? double.infinity,
                height: height ?? double.infinity,
                color: Colors.white,
              ),
            );
          },

          // ------------------------------------------------------
          // NETWORK IMAGE ERROR
          // ------------------------------------------------------

          errorWidget: (_, __, ___) {
            if (!showPlaceholder) {
              return const SizedBox.shrink();
            }

            return placeholder ??
                PlaceholderBanner(
                  index: index,
                );
          },
        );
        break;

    // ==========================================================
    // ASSET
    // ==========================================================

      case CommonImageType.asset:
        imageWidget = Image.asset(
          image,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          fit: fit,

          errorBuilder: (_, __, ___) {
            if (!showPlaceholder) {
              return const SizedBox.shrink();
            }

            return placeholder ??
                PlaceholderBanner(
                  index: index,
                );
          },
        );
        break;
    }

    return ClipRRect(
      borderRadius: radius,
      child: imageWidget,
    );
  }
}