import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// A small labelled image tile (profile photo / Aadhaar / PAN / nominee
/// document / ...) used on the My Profile tabs — tapping it opens the
/// full-screen zoomable preview (see [CommonImagePreview]) via [onTap].
/// Shows a neutral placeholder icon instead of being tappable when
/// [imageUrl] is empty, so a member who never uploaded a given document
/// doesn't see a broken-image tile.
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
      onTap: hasImage ? onTap : null,
      child: SizedBox(
        width: 78.px(context),
        child: Column(
          children: [
            Container(
              width: 72.px(context),
              height: 72.px(context),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14.px(context)),
                border: Border.all(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                        size: 24.px(context),
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textSecondary.withOpacity(.6),
                      size: 24.px(context),
                    ),
            ),
            SizedBox(height: 6.px(context)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5.px(context),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
