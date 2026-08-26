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
          ClipOval(
            child: Container(
              width: widgetWidth,
              height: widgetHeight,
              color: Colors.white,
              child: content,
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

    return Column(
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
  }
}