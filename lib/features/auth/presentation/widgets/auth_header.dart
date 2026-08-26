import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import 'auth_header_clipper.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 190.px(context),
      child: ClipPath(
        clipper: AuthHeaderClipper(),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24.px(context),
            50.px(context),
            20.px(context),
            40.px(context),
          ),
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
          child: Row(
            children: [
              // ======================================================
              // LEFT - WELCOME TEXT
              // ======================================================

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.welcomeToPsf.tr,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25.px(context),
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),

                    SizedBox(
                      height: 10.px(context),
                    ),

                    Text(
                      AppStrings.authHeaderSubtitle.tr,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(.88),
                        fontSize: 13.px(context),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 12.px(context),
              ),

              // ======================================================
              // RIGHT - LOGO
              // ======================================================

              Container(
                width: 75.px(context),
                height: 75.px(context),
                padding: EdgeInsets.all(
                  10.px(context),
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(.25),
                  ),
                ),
                child: SvgPicture.asset(
                  AppAssets.logo,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}