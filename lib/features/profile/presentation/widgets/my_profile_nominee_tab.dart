import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/auth/data/models/nominee_model.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import '../controllers/profile_controller.dart';
import 'document_thumbnail.dart';
import 'profile_card_style.dart';

/// "Nominee" tab of [MyProfilePage] — one card per nominee (photo, name,
/// relation resolved via [ProfileController]'s enum-bundle lookup, share,
/// Aadhaar) with that nominee's own document photos, each tappable to a
/// zoomable full-screen preview.
class MyProfileNomineeTab extends StatelessWidget {
  const MyProfileNomineeTab({
    super.key,
    required this.nominees,
    required this.controller,
  });

  final List<NomineeModel> nominees;

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    if (nominees.isEmpty) {
      return AppStateView.empty(
        message: AppStrings.noNomineeFound.tr,
        icon: Icons.people_outline_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < nominees.length; i++) ...[
          _NomineeCard(nominee: nominees[i], controller: controller),
          if (i != nominees.length - 1) SizedBox(height: 14.px(context)),
        ],
      ],
    );
  }
}

class _NomineeCard extends StatelessWidget {
  const _NomineeCard({required this.nominee, required this.controller});

  final NomineeModel nominee;

  final ProfileController controller;

  String _notEmpty(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value : 'not_provided'.tr;

  String _formattedShare(double share) {
    return share == share.roundToDouble()
        ? share.toInt().toString()
        : share.toString();
  }

  String _formattedDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'not_provided'.tr;
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return 'not_provided'.tr;
    return AppDateFormat.medium(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final language = Get.find<LanguageController>().currentAppLanguage;
    final displayName = localizedField(
      language,
      plain: nominee.name,
      hindi: nominee.hName,
      gujarati: nominee.gName,
    );

    final documents = <MapEntry<String, String?>>[
      MapEntry(AppStrings.aadharFrontPhotoLabel.tr, nominee.aadharFrontImageUrl),
      MapEntry(AppStrings.aadharBackPhotoLabel.tr, nominee.aadharBackImageUrl),
      MapEntry('nominee_passbook_cheque_label'.tr, nominee.passBookChequeUrl),
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

    final photoUrl = nominee.photoUrl;

    return Container(
      padding: EdgeInsets.all(16.px(context)),
      decoration: profileCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: (photoUrl?.isNotEmpty ?? false)
                    ? () => CommonImagePreview.show(
                          context: context,
                          images: [PreviewImageItem(imagePath: photoUrl!)],
                          mode: ImagePreviewMode.fullScreen,
                        )
                    : null,
                child: FramedImage(
                  url: photoUrl,
                  size: 60.px(context),
                  circle: true,
                  fallbackIcon: Icons.person_rounded,
                ),
              ),
              SizedBox(width: 14.px(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.isNotEmpty ? displayName : 'not_provided'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.px(context),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.px(context)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.px(context),
                        vertical: 3.px(context),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(.10),
                        borderRadius: BorderRadius.circular(20.px(context)),
                      ),
                      child: Text(
                        controller.relationName(nominee.relation),
                        style: TextStyle(
                          fontSize: 11.5.px(context),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.px(context)),
            child: const Divider(height: 1, color: AppColors.border),
          ),
          InfoListTile(
            label: AppStrings.dateOfBirth.tr,
            value: _formattedDate(nominee.dateOfBirth),
          ),
          InfoListTile(
            label: 'nominee_share_percent'.tr,
            value: nominee.share != null ? _formattedShare(nominee.share!) : 'not_provided'.tr,
          ),
          InfoListTile(
            label: 'aadhaar_number'.tr,
            value: _notEmpty(nominee.aadharNo),
            showDivider: availableImages.isNotEmpty,
          ),
          if (availableImages.isNotEmpty) ...[
            SizedBox(height: 12.px(context)),
            Wrap(
              spacing: 8.px(context),
              runSpacing: 12.px(context),
              children: [
                for (final entry in documents)
                  DocumentThumbnail(
                    label: entry.key,
                    imageUrl: entry.value,
                    onTap: () => openPreview(entry.value),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
