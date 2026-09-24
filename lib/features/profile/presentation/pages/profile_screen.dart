import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/features/navigation/presentation/widgets/app_bottom_nav_bar.dart';

import '../controllers/profile_controller.dart';
import '../widgets/my_profile_health_tab.dart';
import '../widgets/my_profile_nominee_tab.dart';
import '../widgets/my_profile_personal_tab.dart';
import '../widgets/profile_card_style.dart';

/// The Profile tab — the member's full profile shown directly (no menu in
/// between). Member photo centered up top (tap to preview), then a shadowed
/// segmented control switching between three read-only tabs — Personal /
/// Nominee / Health Declaration — each showing the matching slice of
/// whatever the member's last login response returned (see
/// `ProfileController.loadProfileFromLocalLogin`). The Personal and Nominee
/// tabs keep their document photos in a collapsible Documents section.
/// All data here is display-only: it's refreshed by logging in again, not
/// edited on this screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = Get.find<ProfileController>();

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // The header stays fixed and the page scrolls UNDER it, so the wavy
      // edge overlays the content (same look as the Home screen) instead of
      // the content being cut off by a straight line beneath the header.
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(
        title: AppStrings.myProfile.tr,
        // A tab of the bottom bar, not a pushed page — the back arrow
        // switches to the Home tab instead of popping a route (there is
        // none to pop); the system back gesture does the same, handled
        // once for every tab by MainNavigationScreen's own PopScope.
        onBack: () => Get.find<MainNavigationController>()
            .changeTab(MainNavigationController.homeTab),
        actions: [_DownloadPdfButton(controller: _controller)],
      ),
      // Whatever card happens to be scrolled to the very bottom edge gets
      // faded to transparent there instead of ending in a hard, square-cut
      // edge sitting right against the floating bottom bar — a soft blend
      // into the page background (matching where the bar floats) rather
      // than a box-looking cutoff, regardless of scroll position.
      body: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, .9, 1],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: SafeArea(
          top: false,
          child: Obx(() {
            final member = _controller.memberDetails.value;
            final profile = _controller.profile.value;
            final health = _controller.healthDeclaration.value;
            final nominees = _controller.nominees.toList();

            // Read here (not just inside the tab widgets) so the whole page
            // rebuilds the moment the enum bundle arrives — gender / marital
            // status / relation / member status then switch from raw numeric
            // ids to their real names.
            _controller.enumBundle.value;

            if (member == null && profile == null) {
              return Padding(
                padding: EdgeInsets.only(top: AppSubPageHeader.totalHeight()),
                child: AppStateView.empty(message: 'no_data_found'.tr),
              );
            }

            final photoUrl = member?.imageUrl ?? profile?.photoUrl;
            final displayName = (member?.fullName.isNotEmpty ?? false)
                ? member!.fullName
                : (profile?.fullName ?? '');

            final Widget tabBody;
            switch (_selectedTab) {
              case 0:
                tabBody = member != null
                    ? MyProfilePersonalTab(
                        member: member, controller: _controller)
                    : AppStateView.empty(message: 'no_data_found'.tr);
              case 1:
                tabBody = MyProfileNomineeTab(
                  nominees: nominees,
                  controller: _controller,
                );
              default:
                tabBody = health != null
                    ? MyProfileHealthTab(health: health)
                    : AppStateView.empty(message: 'no_data_found'.tr);
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18.px(context),
                AppSubPageHeader.totalHeight() + 12.px(context),
                18.px(context),
                // Clear the bottom bar, which floats over the page — same
                // clearance as Home, so both tabs leave an identical gap.
                32.px(context) + AppBottomNavBar.occupiedHeight(context),
              ),
              child: Column(
                children: [
                  _ProfileAvatar(photoUrl: photoUrl, name: displayName),
                  SizedBox(height: 22.px(context)),
                  _TabSelector(
                    selectedIndex: _selectedTab,
                    onChanged: (index) => setState(() => _selectedTab = index),
                  ),
                  SizedBox(height: 18.px(context)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .04),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: tabBody,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.name});

  final String? photoUrl;

  final String name;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl?.isNotEmpty ?? false;

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasPhoto
              ? () => CommonImagePreview.show(
                    context: context,
                    images: [PreviewImageItem(imagePath: photoUrl!)],
                    mode: ImagePreviewMode.dialog,
                  )
              : null,
          child: FramedImage(
            url: photoUrl,
            size: 104.px(context),
            circle: true,
            fallbackIcon: Icons.person_rounded,
          ),
        ),
        if (name.isNotEmpty) ...[
          SizedBox(height: 12.px(context)),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.px(context),
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

/// Three-tab segmented control with a gradient "pill" that slides under the
/// selected tab. Labels get the full width of their tab with no extra
/// padding and wrap onto a second centered line instead of overflowing.
class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;

  final ValueChanged<int> onChanged;

  static const _icons = [
    Icons.badge_rounded,
    Icons.family_restroom_rounded,
    Icons.health_and_safety_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppStrings.personalTab.tr,
      AppStrings.nomineeTab.tr,
      AppStrings.healthDeclarationTab.tr,
    ];

    return Container(
      padding: EdgeInsets.all(4.px(context)),
      decoration: profileCardDecoration(context).copyWith(
        borderRadius: BorderRadius.circular(20.px(context)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutBack,
              alignment: Alignment(-1 + selectedIndex * 1.0, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(16.px(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.38),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.px(context),
                        vertical: 10.px(context),
                      ),
                      child: _TabLabel(
                        icon: _icons[i],
                        label: labels[i],
                        selected: selectedIndex == i,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;

  final String label;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: selected ? 1.15 : 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: Icon(
            icon,
            size: 20.px(context),
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.px(context)),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5.px(context),
            height: 1.2,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

/// Header action that downloads the member's application PDF
/// (`ProfileController.downloadApplicationPdf`) — same translucent-circle
/// look as [AppHeaderIconButton], swapping the icon for a small spinner
/// while the request is in flight so it never looks unresponsive.
class _DownloadPdfButton extends StatelessWidget {
  const _DownloadPdfButton({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isDownloadingPdf.value;
      final size = 40.px(context);

      return Material(
        color: Colors.white.withOpacity(.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: busy ? null : controller.downloadApplicationPdf,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18.px(context),
                      height: 18.px(context),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 20.px(context),
                    ),
            ),
          ),
        ),
      );
    });
  }
}
