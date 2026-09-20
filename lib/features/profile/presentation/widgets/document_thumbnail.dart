import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import 'profile_card_style.dart';

/// A small labelled, framed image tile (profile photo / Aadhaar / PAN /
/// nominee document / ...) used on the My Profile tabs — tapping it opens
/// the full-screen zoomable preview (see [CommonImagePreview]) via [onTap].
/// Shows a neutral placeholder instead of being tappable when [imageUrl]
/// is empty, so a member who never uploaded a given document doesn't see
/// a broken-image tile.
class DocumentThumbnail extends StatelessWidget {
  const DocumentThumbnail({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;

  final String? imageUrl;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.isNotEmpty ?? false;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasImage ? onTap : null,
      child: SizedBox(
        width: 74.px(context),
        child: Column(
          children: [
            FramedImage(url: imageUrl, size: 72.px(context)),
            SizedBox(height: 6.px(context)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.px(context),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
