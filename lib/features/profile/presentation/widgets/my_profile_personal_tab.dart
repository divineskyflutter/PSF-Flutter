import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/auth/data/models/member_model.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';

import '../controllers/profile_controller.dart';
import 'documents_section.dart';
import 'profile_card_style.dart';

/// "Personal" tab of [MyProfilePage] — every field `MemberModel` carries
/// (father name, DOB, gender/marital status resolved via
/// [ProfileController]'s enum-bundle lookup, address, occupation,
/// Aadhaar/PAN, ...), grouped into a few smaller cards (not one long block)
/// so the page keeps the same alternating card/background rhythm as Home
/// all the way down — then a collapsible Documents section holding the
/// uploaded document photos (each tappable to a zoomable popup preview).
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
    return AppDateFormat.medium(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final language = Get.find<LanguageController>().currentAppLanguage;

    String localized(String? plain, String? hindi, String? gujarati) {
      final value =
          localizedField(language, plain: plain, hindi: hindi, gujarati: gujarati);
      return value.isNotEmpty ? value : 'not_provided'.tr;
    }

    // The profile photo is left out on purpose — it is already shown at the
    // top of the page.
    final documents = <DocumentItem>[
      DocumentItem(label: AppStrings.aadharFrontPhotoLabel.tr, url: member.aadharImageUrl),
      DocumentItem(label: AppStrings.aadharBackPhotoLabel.tr, url: member.aadharBackImageUrl),
      DocumentItem(label: AppStrings.panCardPhotoLabel.tr, url: member.panImageUrl),
    ];

    final gap = SizedBox(height: 14.px(context));

    Widget card(List<Widget> rows) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.px(context)),
        decoration: profileCardDecoration(context),
        child: Column(children: rows),
      );
    }

    final hasMobile2 = member.mobile2?.trim().isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==================================================
        // PERSONAL
        // ==================================================
        card([
          InfoListTile(
            label: AppStrings.memberStatus.tr,
            value: controller.memberStatusName(member.status),
          ),
          InfoListTile(
            label: AppStrings.fatherName.tr,
            value: localized(member.fatherName, member.hFatherName, member.gFatherName),
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
            showDivider: false,
          ),
        ]),

        gap,

        // ==================================================
        // CONTACT & ADDRESS
        // ==================================================
        card([
          if (hasMobile2)
            InfoListTile(label: 'mobile_number_2'.tr, value: member.mobile2!),
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
            showDivider: false,
          ),
        ]),

        gap,

        // ==================================================
        // IDENTITY
        // ==================================================
        card([
          InfoListTile(label: 'aadhaar_number'.tr, value: _notEmpty(member.aadharNo)),
          InfoListTile(
            label: 'pan_number'.tr,
            value: _notEmpty(member.panNo),
            showDivider: false,
          ),
        ]),

        gap,

        // ==================================================
        // DOCUMENTS (open / close)
        // ==================================================
        DocumentsSection(documents: documents),
      ],
    );
  }
}
