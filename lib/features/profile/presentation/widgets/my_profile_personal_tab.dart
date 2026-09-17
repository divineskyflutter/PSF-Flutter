import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/auth/data/models/member_model.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import '../controllers/profile_controller.dart';
import 'document_thumbnail.dart';

/// "Personal" tab of [MyProfilePage] — every field `MemberModel` carries
/// (father name, DOB, gender/marital status resolved via
/// [ProfileController]'s enum-bundle lookup, address, occupation,
/// Aadhaar/PAN, ...) plus the member's uploaded document photos, each
/// tappable to a zoomable full-screen preview.
class MyProfilePersonalTab extends StatelessWidget {
  const MyProfilePersonalTab({
    super.key,
    required this.member,
    required this.controller,
  });

  final MemberModel member;

  final ProfileController controller;

  String _notEmpty(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value : 'not_provided'.tr;

  String _formattedDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'not_provided'.tr;
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return 'not_provided'.tr;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final language = Get.find<LanguageController>().currentAppLanguage;

    String localized(String? plain, String? hindi, String? gujarati) {
      final value =
          localizedField(language, plain: plain, hindi: hindi, gujarati: gujarati);
      return value.isNotEmpty ? value : 'not_provided'.tr;
    }

    final documents = <MapEntry<String, String?>>[
      MapEntry(AppStrings.profilePhotoLabel.tr, member.imageUrl),
      MapEntry(AppStrings.aadharFrontPhotoLabel.tr, member.aadharImageUrl),
      MapEntry(AppStrings.aadharBackPhotoLabel.tr, member.aadharBackImageUrl),
      MapEntry(AppStrings.panCardPhotoLabel.tr, member.panImageUrl),
    ];

    final availableImages = documents
        .where((entry) => entry.value?.isNotEmpty ?? false)
        .map((entry) => PreviewImageItem(imagePath: entry.value!))
        .toList();

    void openPreview(String? url) {
      if (url == null || url.isEmpty) return;
      final index = availableImages.indexWhere((image) => image.imagePath == url);
      CommonImagePreview.show(
        context: context,
        images: availableImages,
        initialIndex: index < 0 ? 0 : index,
        mode: ImagePreviewMode.fullScreen,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==================================================
        // DOCUMENT PHOTOS
        // ==================================================

        Container(
          padding: EdgeInsets.all(16.px(context)),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18.px(context)),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 12.px(context),
            runSpacing: 14.px(context),
            children: [
              for (final entry in documents)
                DocumentThumbnail(
                  label: entry.key,
                  imageUrl: entry.value,
                  onTap: () => openPreview(entry.value),
                ),
            ],
          ),
        ),

        SizedBox(height: 14.px(context)),

        // ==================================================
        // DETAILS
        // ==================================================

        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.px(context)),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18.px(context)),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              InfoListTile(
                label: AppStrings.memberStatus.tr,
                value: controller.memberStatusName(member.status),
              ),
              InfoListTile(
                label: AppStrings.fatherName.tr,
                value: localized(
                  member.fatherName,
                  member.hFatherName,
                  member.gFatherName,
                ),
              ),
              InfoListTile(
                label: AppStrings.dateOfBirth.tr,
                value: _formattedDate(member.dateOfBirth),
              ),
              InfoListTile(
                label: AppStrings.gender.tr,
                value: controller.genderName(member.gender),
              ),
              InfoListTile(
                label: AppStrings.maritalStatus.tr,
                value: controller.maritalStatusName(member.maritalStatus),
              ),
              if (member.mobile2?.trim().isNotEmpty ?? false)
                InfoListTile(
                  label: 'mobile_number_2'.tr,
                  value: member.mobile2!,
                ),
              InfoListTile(
                label: AppStrings.occupation.tr,
                value: localized(member.occupation, member.hOccupation, member.gOccupation),
              ),
              InfoListTile(
                label: AppStrings.address.tr,
                value: localized(member.address, member.hAddress, member.gAddress),
              ),
              InfoListTile(
                label: 'village'.tr,
                value: localized(member.village, member.hVillage, member.gVillage),
              ),
              InfoListTile(
                label: 'taluka'.tr,
                value: localized(member.taluka, member.hTaluka, member.gTaluka),
              ),
              InfoListTile(
                label: 'district'.tr,
                value: localized(member.district, member.hDistrict, member.gDistrict),
              ),
              InfoListTile(
                label: 'state'.tr,
                value: localized(member.state, member.hState, member.gState),
              ),
              InfoListTile(
                label: 'aadhaar_number'.tr,
                value: _notEmpty(member.aadharNo),
              ),
              InfoListTile(
                label: 'pan_number'.tr,
                value: _notEmpty(member.panNo),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
