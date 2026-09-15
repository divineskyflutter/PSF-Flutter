import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';
import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';

import '../../domain/entities/member_profile_entity.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar_block.dart';

/// Full member profile — the "Profile" row inside the Profile tab's menu.
/// Read-only by default; the header's edit icon switches a small set of
/// contact fields (name / mobile / address) into an editable form that
/// saves via [ProfileController.updateProfile].
class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  final ProfileController _controller = Get.find<ProfileController>();

  bool _isEditing = false;

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _startEditing(MemberProfileEntity profile) {
    _fullNameController.text = profile.fullName;
    _mobileController.text = profile.mobile ?? '';
    _addressController.text = profile.address ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _save() async {
    final success = await _controller.updateProfile({
      'fullName': _fullNameController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'address': _addressController.text.trim(),
    });

    if (success && mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(
        title: AppStrings.myProfile.tr,
        actions: [
          Obx(() {
            final profile = _controller.profile.value;
            if (profile == null || _isEditing) return const SizedBox.shrink();

            return AppHeaderIconButton(
              icon: Icons.edit_outlined,
              onTap: () => _startEditing(profile),
            );
          }),
        ],
      ),
      body: Obx(() {
        final profile = _controller.profile.value;

        if (_controller.isProfileLoading.value && profile == null) {
          return const AppStateView.loading();
        }

        if (_controller.hasProfileError.value && profile == null) {
          return AppStateView.error(
            message: _controller.profileErrorMessage.value.isEmpty
                ? AppStrings.somethingWentWrong.tr
                : _controller.profileErrorMessage.value,
            onRetry: _controller.fetchProfile,
          );
        }

        if (profile == null) {
          return AppStateView.empty(message: AppStrings.noDataFound.tr);
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(18.px(context)),
          child: _isEditing ? _buildEditForm(context) : _buildReadOnly(context, profile),
        );
      }),
    );
  }

  Widget _buildReadOnly(BuildContext context, MemberProfileEntity profile) {
    // Same dark card + ProfileAvatarBlock as ProfileScreen's summary card
    // (Nikhil asked for "the same card", just full-size here so every
    // field fits) — labelColor/dividerColor are passed explicitly on each
    // InfoListTile since its defaults assume a light card.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileAvatarBlock(
            name: profile.fullName,
            mobile: profile.mobile ?? '-',
            photoUrl: profile.photoUrl,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.px(context)),
            child: const Divider(height: 1, color: Colors.white24),
          ),
          InfoListTile(
            label: AppStrings.fatherName.tr,
            value: profile.fatherName ?? '-',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            dividerColor: Colors.white24,
          ),
          InfoListTile(
            label: AppStrings.dateOfBirth.tr,
            value: profile.dateOfBirth ?? '-',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            dividerColor: Colors.white24,
          ),
          InfoListTile(
            label: AppStrings.gender.tr,
            value: profile.gender ?? '-',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            dividerColor: Colors.white24,
          ),
          InfoListTile(
            label: AppStrings.maritalStatus.tr,
            value: profile.maritalStatus ?? '-',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            dividerColor: Colors.white24,
          ),
          InfoListTile(
            label: AppStrings.occupation.tr,
            value: profile.occupation ?? '-',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            dividerColor: Colors.white24,
          ),
          InfoListTile(
            label: AppStrings.address.tr,
            value: profile.address ?? '-',
            labelColor: Colors.white70,
            valueColor: Colors.white,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    // Same dark card as _buildReadOnly — only fullName / mobile / address
    // are editable (see class doc comment), everything else stays out of
    // this form entirely rather than being shown disabled.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _fullNameController,
            label: AppStrings.fullName.tr,
          ),
          SizedBox(height: 16.px(context)),
          AppTextField(
            controller: _mobileController,
            label: AppStrings.mobileNumber.tr,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16.px(context)),
          AppTextField(
            controller: _addressController,
            label: AppStrings.address.tr,
            maxLines: 3,
          ),
          SizedBox(height: 22.px(context)),
          Obx(
            () => Row(
              children: [
                // Same size (both Expanded), both a plain white
                // background with dark text so they stay readable
                // against the dark card — Save uses the app's primary
                // color instead of white to still read as the primary
                // action.
                Expanded(
                  child: AppButton.rectangular(
                    label: AppStrings.cancel.tr,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    height: 50,
                    onPressed: _controller.isSavingProfile.value
                        ? null
                        : () => setState(() => _isEditing = false),
                  ),
                ),
                SizedBox(width: 14.px(context)),
                Expanded(
                  child: AppButton.rectangular(
                    label: AppStrings.save.tr,
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: AppColors.primaryDark,
                    height: 50,
                    onPressed: _controller.isSavingProfile.value ? null : _save,
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
