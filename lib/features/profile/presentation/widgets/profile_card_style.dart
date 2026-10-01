import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/loaders/app_shimmer.dart';

/// One shared card look for every card on the My Profile tabs: a soft
/// theme-tinted border plus a two-layer shadow, so cards read as raised
/// panels instead of flat boxes.
BoxDecoration profileCardDecoration(BuildContext context) {
  return BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(18.px(context)),
    border: Border.all(color: AppColors.primary.withOpacity(.16), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(.10),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
      const BoxShadow(
        color: AppColors.shadow,
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
}

/// A network image inside a light gradient frame with a soft shadow —
/// used for every photo on My Profile (avatar, nominee photo, document
/// thumbnails) so they all share the same "framed picture" look. Shows a
/// spinner while loading and [fallbackIcon] when there is no image or it
/// fails to load.
class FramedImage extends StatelessWidget {
  const FramedImage({
    super.key,
    required this.url,
    required this.size,
    this.circle = false,
    this.fallbackIcon = Icons.image_not_supported_outlined,
  });

  final String? url;

  final double size;

  final bool circle;

  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final hasImage = url?.isNotEmpty ?? false;
    final radius = BorderRadius.circular(14.px(context));
    final innerRadius = BorderRadius.circular(11.px(context));

    Widget content = hasImage
        ? Image.network(
            url!,
            // Decode near display size — the uploads are full-resolution
            // photos, and decoding them whole made opening Profile hitch.
            cacheWidth: (size * 3).round(),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              // A shimmering placeholder the size of the frame itself, not
              // a spinner — same loading language the banner carousels
              // already use (see NetworkBanner), instead of a different
              // "normal loader" look just for this one widget.
              return AppShimmer(
                child: Container(color: Colors.white),
              );
            },
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : _fallback();

    content = circle
        ? ClipOval(child: content)
        : ClipRRect(borderRadius: innerRadius, child: content);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(2.5.px(context)),
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(1.5.px(context)),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : innerRadius,
        ),
        child: content,
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.textSecondary.withOpacity(.6),
          size: size * .38,
        ),
      ),
    );
  }
}
