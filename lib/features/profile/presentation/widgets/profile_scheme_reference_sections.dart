import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';

import '../controllers/profile_controller.dart';
import 'profile_card_style.dart';

String _orDash(String? value) =>
    (value != null && value.trim().isNotEmpty) ? value.trim() : '-';

/// The member's scheme (yojna) name, as one row card at the top of the
/// Personal tab. Reads [ProfileController.scheme] (from the last login).
class ProfileSchemeCard extends StatelessWidget {
  const ProfileSchemeCard({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scheme = controller.scheme.value;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.px(context)),
        decoration: profileCardDecoration(context),
        child: InfoListTile(
          label: AppStrings.yojnaLabel.tr,
          value: _orDash(scheme?.yojnaName),
          multilineValue: true,
          showDivider: false,
        ),
      );
    });
  }
}

/// "References" — shown only when the login says references are needed
/// (`isReferenceNeeded`): how many are required and the people who joined
/// through them, or a "-" placeholder row while none have been added yet.
class ProfileReferencesSection extends StatelessWidget {
  const ProfileReferencesSection({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final info = controller.references.value;
      if (info == null || !info.isReferenceNeeded) return const SizedBox.shrink();

      final language = Get.find<LanguageController>().currentAppLanguage;

      final rows = <Widget>[
        InfoListTile(
          label: AppStrings.referencesRequiredCount.tr,
          value: info.referenceCount?.toString() ?? '-',
          showDivider: true,
        ),
      ];

      if (info.members.isEmpty) {
        rows.add(InfoListTile(
          label: AppStrings.referencesNoneYet.tr,
          value: '-',
          showDivider: false,
        ));
      } else {
        for (var i = 0; i < info.members.length; i++) {
          final m = info.members[i];
          final name = localizedField(
            language,
            plain: m.name,
            hindi: m.hindiName,
            gujarati: m.gujaratiName,
          );
          rows.add(_PersonRow(
            name: name,
            mobile: m.mobile,
            memberNo: m.memberNo,
            showDivider: i != info.members.length - 1,
          ));
        }
      }

      return _Section(title: AppStrings.referencesTitle.tr, rows: rows);
    });
  }
}

/// "You joined through the reference of" — the member who referred THIS
/// member (name in the app language, mobile, member id); "-" for each part
/// that isn't there.
class ProfileReferredBySection extends StatelessWidget {
  const ProfileReferredBySection({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final info = controller.references.value;
      final language = Get.find<LanguageController>().currentAppLanguage;

      final name = localizedField(
        language,
        plain: info?.referredByName,
        hindi: info?.referredByNameHindi,
        gujarati: info?.referredByNameGujarati,
      );

      return _Section(
        title: AppStrings.referenceOfTitle.tr,
        rows: [
          // Left-aligned like the other rows, so a long name wraps from the
          // same starting column instead of sticking to the right edge.
          InfoListTile(
            label: AppStrings.referenceNameLabel.tr,
            value: _orDash(name),
            multilineValue: true,
          ),
          InfoListTile(
            label: AppStrings.mobileNumber.tr,
            value: _orDash(info?.referredByMobile),
          ),
          InfoListTile(
            label: AppStrings.memberNoLabel.tr,
            value: _orDash(info?.referredByMemberNo),
            showDivider: false,
          ),
        ],
      );
    });
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 14.px(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.px(context), bottom: 8.px(context)),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5.px(context),
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.px(context)),
            decoration: profileCardDecoration(context),
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

/// One referenced person: name on top, then mobile · member id.
class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.mobile,
    required this.memberNo,
    required this.showDivider,
  });

  final String name;
  final String? mobile;
  final String? memberNo;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (mobile != null && mobile!.isNotEmpty) mobile!,
      if (memberNo != null && memberNo!.isNotEmpty) '${AppStrings.memberNoLabel.tr}: $memberNo',
    ].join('  ·  ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.px(context)),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _orDash(name),
            style: TextStyle(
              fontSize: 14.px(context),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (details.isNotEmpty) ...[
            SizedBox(height: 3.px(context)),
            Text(
              details,
              style: TextStyle(
                fontSize: 12.5.px(context),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
