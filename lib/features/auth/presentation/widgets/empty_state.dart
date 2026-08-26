import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

class PlaceholderBanner extends StatelessWidget {
  final int index;

  const PlaceholderBanner({
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(
          22.px(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -35,
            top: -35,
            child: Container(
              width: 130.px(context),
              height: 130.px(context),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(.08),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: -45,
            bottom: -45,
            child: Container(
              width: 150.px(context),
              height: 150.px(context),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Placeholder content
          Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Container(
                  width: 62.px(context),
                  height: 62.px(context),
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.white
                        .withOpacity(.85),
                    size: 32.px(context),
                  ),
                ),

                SizedBox(
                  height: 12.px(context),
                ),

                Text(
                  AppStrings.bannerPlaceholder.tr,
                  style: TextStyle(
                    color: Colors.white
                        .withOpacity(.9),
                    fontSize: 14.px(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}