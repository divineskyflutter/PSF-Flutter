import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import 'package:psf_application/features/navigation/presentation/controllers/main_navigation_controller.dart';
import 'package:psf_application/features/navigation/presentation/widgets/app_bottom_nav_bar.dart';

import '../../data/models/scheme_reference_model.dart';
import '../controllers/profile_controller.dart';
import '../widgets/download_documents_sheet.dart';
import '../widgets/profile_overview_cards.dart';
import '../widgets/reference_mismatch_notifier.dart';

int? _ageFrom(String? dateOfBirth) {
  final dob = DateTime.tryParse(dateOfBirth ?? '');
  if (dob == null) return null;
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
  return age < 0 ? null : age;
}

/// The Profile tab — an at-a-glance overview of the member: a hero card (photo,
/// name, member number, status, mobile, scheme), the membership fee (total /
/// paid / pending with progress), the payment-history table, and the "Form
/// details" options. Tapping an option opens the submitted form (Personal /
/// Nominee / Health Declaration) on its own page, where the tabs can be
/// swiped — see [ProfileFormDetailsPage]. Pull down to refresh.
///
/// Whatever the backend has not sent yet reads "-" (or shows an empty state)
/// instead of being hidden, so the layout stays the same as data arrives.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

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
        actions: [_DownloadPdfButton(controller: controller)],
      ),
      // Whatever card happens to be scrolled to the very bottom edge gets
      // faded to transparent there instead of ending in a hard, square-cut
      // edge sitting right against the floating bottom bar.
      body: Stack(
        children: [
          ShaderMask(
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
                final member = controller.memberDetails.value;
                final profile = controller.profile.value;
                final scheme = controller.scheme.value ?? const MembershipSchemeInfo();
                final language = Get.find<LanguageController>().currentAppLanguage;

                // Read so the page rebuilds the moment the enum bundle
                // arrives — member status then switches from a raw id to its
                // real name.
                controller.enumBundle.value;

                if (member == null && profile == null) {
                  return Padding(
                    padding: EdgeInsets.only(top: AppSubPageHeader.totalHeight()),
                    child: AppStateView.empty(message: 'no_data_found'.tr),
                  );
                }

                final photoUrl = member?.imageUrl ?? profile?.photoUrl;
                final displayName = (member?.fullName.isNotEmpty ?? false)
                    ? member!.localizedFullName(language)
                    : (profile?.fullName ?? '');

                // Joining date and the fee's last date (joining + 365 days).
                final joinedOn = profile?.joiningDate;
                final lastDate = joinedOn?.add(const Duration(days: 365));

                // Status in the app language only.
                final status = (member != null && member.status != null)
                    ? controller.memberStatusName(member.status)
                    : null;

                final age = _ageFrom(member?.dateOfBirth);

                final gap = SizedBox(height: 16.px(context));

                return AppRefreshIndicator(
                  onRefresh: controller.refreshMemberData,
                  edgeOffset: AppSubPageHeader.totalHeight(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      18.px(context),
                      AppSubPageHeader.totalHeight() + 12.px(context),
                      18.px(context),
                      // Clear the bottom bar, which floats over the page —
                      // same clearance as Home.
                      32.px(context) + AppBottomNavBar.occupiedHeight(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileHeroCard(
                          photoUrl: photoUrl,
                          memberNo: member?.memberNo,
                          name: displayName,
                          joinedOn: joinedOn,
                          age: age,
                          status: status,
                        ),
                        gap,
                        ProfileFeeCard(scheme: scheme, lastDate: lastDate),
                        gap,
                        ProfilePaymentSection(controller: controller),
                        gap,
                        const ProfileFeeInfoBar(),
                        gap,
                        // Only drawn when the login response flags it (it
                        // brings its own bottom gap).
                        ProfileSangyogNitiCard(scheme: scheme),
                        ProfileSupportingAccountCard(controller: controller, age: age),
                        gap,
                        const ProfileFormDetailsOptions(),
                        gap,
                        const ProfileImportantNotes(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const ReferenceMismatchNotifier(tabIndex: MainNavigationController.profileTab),
        ],
      ),
    );
  }
}

/// Header action that opens the download sheet (application form, ID card,
/// receipt, certificate, agreement — see [DownloadDocumentsSheet]) — same translucent-circle
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
          onTap: busy ? null : () => DownloadDocumentsSheet.show(controller),
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
