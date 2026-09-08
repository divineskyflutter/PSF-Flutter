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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          InfoListTile(label: AppStrings.fullName.tr, value: profile.fullName),
          InfoListTile(label: AppStrings.mobileNumber.tr, value: profile.mobile ?? '-'),
          InfoListTile(label: AppStrings.fatherName.tr, value: profile.fatherName ?? '-'),
          InfoListTile(label: AppStrings.dateOfBirth.tr, value: profile.dateOfBirth ?? '-'),
          InfoListTile(label: AppStrings.gender.tr, value: profile.gender ?? '-'),
          InfoListTile(label: AppStrings.maritalStatus.tr, value: profile.maritalStatus ?? '-'),
          InfoListTile(label: AppStrings.occupation.tr, value: profile.occupation ?? '-'),
          InfoListTile(
            label: AppStrings.address.tr,
            value: profile.address ?? '-',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
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
                Expanded(
                  child: AppButton.outlined(
                    label: AppStrings.cancel.tr,
                    onPressed: _controller.isSavingProfile.value
                        ? null
                        : () => setState(() => _isEditing = false),
                  ),
                ),
                SizedBox(width: 14.px(context)),
                Expanded(
                  child: AppButton(
                    label: AppStrings.save.tr,
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
