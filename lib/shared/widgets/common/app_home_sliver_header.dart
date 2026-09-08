import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import 'app_header_curve_clipper.dart';
import 'app_sub_page_header.dart';

/// The Home tab's header, built as a [SliverAppBar] so it behaves exactly
/// as asked: the full curved-gradient header (logo + greeting + member id)
/// shows when the screen first opens / is scrolled to the top, and as the
/// user scrolls it collapses down to a normal, pinned app-bar-sized strip
/// (title only, solid [AppColors.primary]) — the standard Material
/// "collapsing toolbar" behaviour, driven by [FlexibleSpaceBar] rather than
/// a hand-rolled scroll-offset listener.
///
/// The notification bell is passed as a [SliverAppBar] action, so — like a
/// normal app bar — it stays visible and in the same place in both the
/// expanded and collapsed states, instead of fading with the rest of the
/// header content.
class AppHomeSliverHeader extends StatelessWidget {
  const AppHomeSliverHeader({
    super.key,
    required this.greeting,
    required this.memberName,
    required this.memberIdLabel,
    required this.collapsedTitle,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.expandedHeight = 230,
  });

  final String greeting;

  final String memberName;

  final String memberIdLabel;

  /// Shown centered in the app bar once the header has collapsed.
  final String collapsedTitle;

  final int notificationCount;

  final VoidCallback? onNotificationTap;

  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: AppColors.primary,
      expandedHeight: expandedHeight.px(context),
      centerTitle: true,
      titleSpacing: 0,
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 14.px(context)),
          child: AppHeaderIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: notificationCount,
            onTap: onNotificationTap ?? () {},
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 14),
        title: Text(
          collapsedTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.px(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        background: ClipPath(
          clipper: const AppHeaderCurveClipper(),
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22.px(context),
                  18.px(context),
                  70.px(context),
                  46.px(context),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54.px(context),
                      height: 54.px(context),
                      padding: EdgeInsets.all(8.px(context)),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(.25)),
                      ),
                      child: SvgPicture.asset(
                        AppAssets.logo,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 14.px(context)),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.85),
                              fontSize: 12.px(context),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 2.px(context)),
                          Text(
                            memberName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.px(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2.px(context)),
                          Text(
                            memberIdLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(.75),
                              fontSize: 11.5.px(context),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
