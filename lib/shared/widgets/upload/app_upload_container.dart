import 'dart:io';

import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../extensions/new_responsive_extensions.dart';

class AppUploadContainer extends StatelessWidget {
  final File? file;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  final VoidCallback? onRemove;

  final bool isCircle;

  final double? width;

  final double? height;

  const AppUploadContainer({
    super.key,
    required this.title,
    required this.onTap,
    this.file,
    this.subtitle = 'Tap to upload',
    this.onRemove,
    this.isCircle = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final widgetWidth =
        width ?? double.infinity;

    final widgetHeight =
        height ?? 160.px(context);

    final content = GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: widgetWidth,
        height: widgetHeight,
        child: _content(context),
      ),
    );

    if (isCircle) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widgetWidth,
            height: widgetHeight,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: Colors.white,
                child: content,
              ),
            ),
          ),

          if (file != null && onRemove != null)
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: EdgeInsets.all(
                    5.px(context),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16.px(context),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            16.px(context),
          ),
          child: Container(
            width: widgetWidth,
            height: widgetHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                16.px(context),
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: _content(context),
          ),
        ),

        if (file != null && onRemove != null)
          Positioned(
            right: -5.px(context),
            top: -5.px(context),
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(
                  5.px(context),
                ),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16.px(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    if (file != null) {
      return Image.file(
        file!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final inner = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [
        Icon(
          isCircle
              ? Icons.person_outline
              : Icons.cloud_upload_outlined,
          size: 34.px(context),
          color: AppColors.primary,
        ),

        SizedBox(
          height: 10.px(context),
        ),

        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.px(context),
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),

        SizedBox(
          height: 4.px(context),
        ),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.px(context),
            color: AppColors.primaryDark
                .withOpacity(0.6),
          ),
        ),
      ],
    );

    if (!isCircle) {
      return inner;
    }

    // A circle has less usable width near its top/bottom than a rectangle
    // of the same size, and the translated title/subtitle (Hindi/Gujarati
    // routinely run longer than the English original — e.g.
    // registration_strings.dart's profile_photo/tap_to_upload/
    // nominee_photo keys) can wrap onto more lines than a fixed-size
    // circle has room for, overflowing this Column and getting visually
    // cut off (the exact "text not showing properly in native language"
    // report). Instead of letting that overflow, size the text block at a
    // slightly inset width — narrower than the full circle, so wrapped
    // lines don't touch its curved edge — and let FittedBox scale the
    // whole icon+text block down only as much as actually needed to fit.
    // In English this is a no-op (it already fits); in Hindi/Gujarati it
    // shrinks everything uniformly instead of overflowing/cutting text.
    final circleWidth = width ?? 110.px(context);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: circleWidth * 0.8,
        child: inner,
      ),
    );
  }
}