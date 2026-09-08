import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// Shared "intro banner" used at the top of About Us / Privacy Policy —
/// a solid primary-colored block with the opening paragraph.
class ContentIntroBanner extends StatelessWidget {
  const ContentIntroBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18.px(context)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13.5.px(context),
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A bordered content block with a small colored section-title pill —
/// used to lay out About Us' Mission/Vision/Values and Privacy Policy's
/// numbered sections without every page redeclaring the same container.
class ContentSectionCard extends StatelessWidget {
  const ContentSectionCard({
    super.key,
    required this.title,
    this.body,
    this.child,
  }) : assert(body != null || child != null, 'Provide body text or a child widget.');

  final String title;

  final String? body;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.px(context)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.px(context), vertical: 6.px(context)),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10.px(context)),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5.px(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 12.px(context)),
          if (body != null)
            Text(
              body!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.px(context),
                height: 1.5,
              ),
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
