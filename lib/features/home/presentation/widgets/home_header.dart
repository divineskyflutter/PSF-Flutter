import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_header_curve_clipper.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart'
    show AppHeaderIconButton;

/// The Home tab's header — a [SliverAppBar] so it behaves like Nikhil's
/// reference header (wavy gradient, white circular logo with a shadow,
/// two soft decorative glow accents, greeting/name/member-id) when the
/// screen is scrolled to the top, and collapses down to a normal, pinned
/// app-bar-height strip (member name only, solid [AppColors.primary]) as
/// the user scrolls the dashboard content — the standard Material
/// "collapsing toolbar" behaviour via [FlexibleSpaceBar].
///
/// This is the same collapsing mechanism the old, unused
/// `shared/widgets/common/app_home_sliver_header.dart` used (left in
/// place, not deleted) before the header was pulled out into its own
/// home-feature widget file with the reference's visual style. Drop this
/// straight into a [CustomScrollView]'s `slivers` list — this widget
/// **is** the sliver (a [SliverAppBar]), not a plain box, so [HomeScreen]
/// doesn't wrap it in anything.
///
/// Lives in `home/presentation/widgets/` (not `shared/`) because, unlike
/// [AppHeaderCurveClipper] / [AppSubPageHeader], this specific header is
/// only ever used by the Home tab — same "feature owns its own widgets"
/// convention as [MemberSummaryCard] / [PaymentReminderCard] next to it.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.memberName,
    required this.memberIdLabel,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.expandedHeight = 210,
  });

  final String greeting;

  final String memberName;

  final String memberIdLabel;

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
      titleSpacing: 0,
      centerTitle: false,

      // Pinned, not part of the fading flexible-space content — stays in
      // the same top-right spot whether the header is expanded or
      // collapsed, like a normal app bar action.
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
        titlePadding: EdgeInsets.only(
          left: 20.px(context),
          bottom: 16.px(context),
        ),

        // Shown centered-left once the header has collapsed to a normal
        // app-bar height.
        title: Text(
          memberName,
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
            child: Stack(
              children: [
                // Soft decorative glows — purely cosmetic, clipped with
                // the header's own wavy shape.
                Positioned(
                  top: -30,
                  right: -24,
                  child: _Glow(
                    size: 130.px(context),
                    color: Colors.white.withOpacity(.08),
                  ),
                ),
                Positioned(
                  bottom: -6,
                  left: -26,
                  child: _Glow(
                    size: 110.px(context),
                    color: AppColors.primaryLight.withOpacity(.22),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    // Right padding leaves room for the pinned
                    // notification-bell action above so the greeting/
                    // member-id text never runs under it.
                    padding: EdgeInsets.fromLTRB(
                      22.px(context),
                      18.px(context),
                      70.px(context),
                      44.px(context),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 54.px(context),
                          height: 54.px(context),
                          padding: EdgeInsets.all(8.px(context)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
