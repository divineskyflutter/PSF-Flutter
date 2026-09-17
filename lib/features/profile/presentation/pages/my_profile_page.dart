import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import '../controllers/profile_controller.dart';
import '../widgets/my_profile_health_tab.dart';
import '../widgets/my_profile_nominee_tab.dart';
import '../widgets/my_profile_personal_tab.dart';

/// Full member profile — the "My Profile" row inside the Profile tab's
/// menu. Member photo centered up top (tap to preview), then a shadowed
/// segmented control switching between three read-only tabs — Personal /
/// Nominee / Health Declaration — each showing the matching slice of
/// whatever the member's last login response returned (see
/// `ProfileController.loadProfileFromLocalLogin`). All data here is
/// display-only: it's refreshed by logging in again, not edited on this
/// screen.
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final ProfileController _controller = Get.find<ProfileController>();

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.myProfile.tr),
      body: Obx(() {
        final member = _controller.memberDetails.value;
        final profile = _controller.profile.value;

        if (member == null && profile == null) {
          return AppStateView.empty(message: 'no_data_found'.tr);
        }

        final photoUrl = member?.imageUrl ?? profile?.photoUrl;
        final displayName =
            (member?.fullName.isNotEmpty ?? false) ? member!.fullName : (profile?.fullName ?? '');

        return SingleChildScrollView(
          padding: EdgeInsets.all(18.px(context)),
          child: Column(
            children: [
              _ProfileAvatar(photoUrl: photoUrl, name: displayName),
              SizedBox(height: 20.px(context)),
              _TabSelector(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
              SizedBox(height: 18.px(context)),
              if (_selectedTab == 0)
                member != null
                    ? MyProfilePersonalTab(member: member, controller: _controller)
                    : AppStateView.empty(message: 'no_data_found'.tr)
              else if (_selectedTab == 1)
                MyProfileNomineeTab(
                  nominees: _controller.nominees,
                  controller: _controller,
                )
              else
                _controller.healthDeclaration.value != null
                    ? MyProfileHealthTab(health: _controller.healthDeclaration.value!)
                    : AppStateView.empty(message: 'no_data_found'.tr),
            ],
          ),
        );
      }),
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
          onTap: hasPhoto
              ? () => CommonImagePreview.show(
                    context: context,
                    images: [PreviewImageItem(imagePath: photoUrl!)],
                    mode: ImagePreviewMode.fullScreen,
                  )
              : null,
          child: Container(
            width: 96.px(context),
            height: 96.px(context),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(.25), width: 2),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(context),
                  )
                : _fallbackIcon(context),
          ),
        ),
        if (name.isNotEmpty) ...[
          SizedBox(height: 12.px(context)),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17.px(context),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      color: AppColors.primary,
      size: 44.px(context),
    );
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppStrings.personalTab.tr,
      AppStrings.nomineeTab.tr,
      AppStrings.healthDeclarationTab.tr,
    ];

    return Container(
      padding: EdgeInsets.all(5.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(vertical: 11.px(context)),
                  decoration: BoxDecoration(
                    color: selectedIndex == i ? AppColors.primary : AppColors.transparent,
                    borderRadius: BorderRadius.circular(12.px(context)),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5.px(context),
                      fontWeight: FontWeight.w700,
                      color: selectedIndex == i ? AppColors.background : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
