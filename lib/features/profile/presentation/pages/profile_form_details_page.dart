import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../controllers/profile_controller.dart';
import '../widgets/my_profile_health_tab.dart';
import '../widgets/my_profile_nominee_tab.dart';
import '../widgets/my_profile_personal_tab.dart';
import '../widgets/profile_segmented_tabs.dart';

/// The member's submitted form, shown from the Profile screen's "Form
/// details" options: Personal / Nominee / Health Declaration. Tap a tab or
/// swipe sideways to change it; each tab pulls to refresh on its own and is
/// read-only (refreshed from the server, never edited here). [initialTab] is
/// the option that was tapped on Profile.
class ProfileFormDetailsPage extends StatefulWidget {
  const ProfileFormDetailsPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ProfileFormDetailsPage> createState() => _ProfileFormDetailsPageState();
}

class _ProfileFormDetailsPageState extends State<ProfileFormDetailsPage> {
  late final PageController _pages = PageController(initialPage: widget.initialTab);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppStrings.personalTab.tr,
      AppStrings.nomineeTab.tr,
      AppStrings.healthDeclarationTab.tr,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(
        title: AppStrings.profileFormDetailsTitle.tr,
        onBack: () => Get.back(),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: AppSubPageHeader.totalHeight() + 14.px(context)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.px(context)),
                child: ProfileSegmentedTabs(
                  labels: labels,
                  icons: const [
                    Icons.badge_rounded,
                    Icons.family_restroom_rounded,
                    Icons.health_and_safety_rounded,
                  ],
                  pages: _pages,
                  onTap: (i) => _pages.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              SizedBox(height: 14.px(context)),
              Expanded(
                child: PageView(
                  controller: _pages,
                  children: const [
                    _FormTab(index: 0),
                    _FormTab(index: 1),
                    _FormTab(index: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One swipeable page: its own scroll view + pull-to-refresh.
class _FormTab extends StatelessWidget {
  const _FormTab({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Obx(() {
      final member = controller.memberDetails.value;
      final health = controller.healthDeclaration.value;
      final nominees = controller.nominees.toList();

      // Read so the page rebuilds when the enum bundle arrives (ids turn
      // into their names).
      controller.enumBundle.value;

      final Widget body;
      switch (index) {
        case 0:
          body = member != null
              ? MyProfilePersonalTab(member: member, controller: controller)
              : AppStateView.empty(message: 'no_data_found'.tr);
        case 1:
          body = MyProfileNomineeTab(nominees: nominees, controller: controller);
        default:
          body = health != null
              ? MyProfileHealthTab(health: health)
              : AppStateView.empty(message: 'no_data_found'.tr);
      }

      return AppRefreshIndicator(
        onRefresh: controller.refreshMemberData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            18.px(context),
            4.px(context),
            18.px(context),
            32.px(context) + MediaQuery.of(context).padding.bottom,
          ),
          child: body,
        ),
      );
    });
  }
}
