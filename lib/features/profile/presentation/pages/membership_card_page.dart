import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../../domain/entities/member_profile_entity.dart';
import '../controllers/profile_controller.dart';

/// A physical-card-style rendering of the member's own profile data
/// (already fetched by [ProfileController] — no separate API call).
class MembershipCardPage extends StatelessWidget {
  const MembershipCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.membershipCard.tr),
      body: Obx(() {
        final profile = controller.profile.value;

        if (controller.isProfileLoading.value && profile == null) {
          return const AppStateView.loading();
        }

        if (controller.hasProfileError.value && profile == null) {
          return AppStateView.error(
            message: controller.profileErrorMessage.value.isEmpty
                ? AppStrings.somethingWentWrong.tr
                : controller.profileErrorMessage.value,
            onRetry: controller.fetchProfile,
          );
        }

        if (profile == null) {
          return AppStateView.empty(message: AppStrings.noDataFound.tr);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(20.px(context)),
          child: _MembershipCard(profile: profile),
        );
      }),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.profile});

  final MemberProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.58,
      child: Container(
        padding: EdgeInsets.all(20.px(context)),
        decoration: BoxDecoration(
          gradient: AppColors.headerGradient,
          borderRadius: BorderRadius.circular(22.px(context)),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.px(context),
                  height: 40.px(context),
                  padding: EdgeInsets.all(6.px(context)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(AppAssets.logo, fit: BoxFit.contain),
                ),
                SizedBox(width: 10.px(context)),
                Expanded(
                  child: Text(
                    AppStrings.appName.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.px(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.px(context),
                    vertical: 4.px(context),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppStrings.validMember.tr,
                    style: TextStyle(color: Colors.white, fontSize: 9.5.px(context)),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              profile.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19.px(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.px(context)),
            if ((profile.schemeName ?? '').isNotEmpty)
              Text(
                profile.schemeName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 12.px(context),
                ),
              ),
            SizedBox(height: 16.px(context)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.memberId.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.7),
                          fontSize: 10.px(context),
                        ),
                      ),
                      SizedBox(height: 3.px(context)),
                      Text(
                        profile.memberIdLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.px(context),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profile.joiningDate != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppStrings.joiningDate.tr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.7),
                          fontSize: 10.px(context),
                        ),
                      ),
                      SizedBox(height: 3.px(context)),
                      Text(
                        DateFormat('dd MMM yyyy').format(profile.joiningDate!),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5.px(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
