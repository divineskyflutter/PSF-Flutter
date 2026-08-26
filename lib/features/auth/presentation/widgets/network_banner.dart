import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:psf_application/features/auth/presentation/widgets/empty_state.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/loaders/app_shimmer.dart';

class NetworkBanner extends StatelessWidget {
  const NetworkBanner({
    required this.imageUrl,
    required this.index,
    super.key,
  });

  final String imageUrl;
  final int index;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      22.px(context),
    );

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,

        /// IMAGE LOADING
        placeholder: (_, __) {
          return AppShimmer(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),
          );
        },

        /// IMAGE ERROR
        errorWidget: (_, __, ___) {
          return PlaceholderBanner(
            index: index,
          );
        },
      ),
    );
  }
}