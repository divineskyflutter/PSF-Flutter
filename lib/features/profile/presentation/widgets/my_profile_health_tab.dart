import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/auth/data/models/health_declaration_model.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/widgets/common/info_row.dart';

/// "Health Declaration" tab of [MyProfilePage] — reuses the exact
/// question/disease translation keys the registration wizard's Health
/// step already defines (`registration_strings.dart`: `disease_*`,
/// `health_q_*`) so the same questions read identically here as they did
/// when the member first answered them.
class MyProfileHealthTab extends StatelessWidget {
  const MyProfileHealthTab({super.key, required this.health});

  final HealthDeclarationModel health;

  /// Same order as `RegistrationController.diseaseKeys` — kept as a local
  /// literal instead of importing that controller, since only the
  /// translation keys are needed here, not any registration-flow state.
  static const _diseaseKeys = [
    'disease_heart',
    'disease_heart_attack',
    'disease_bp',
    'disease_diabetes',
    'disease_asthma',
    'disease_tb',
    'disease_cancer',
    'disease_liver_kidney',
    'disease_hiv',
    'disease_other_infectious',
    'disease_stroke',
    'disease_mental',
    'disease_hereditary',
  ];

  List<bool> get _diseaseValues => [
        health.heartDisease,
        health.heartAttack,
        health.highBloodPressure,
        health.diabetes,
        health.breathingProblem,
        health.tb,
        health.cancerTumor,
        health.liverDisease,
        health.hiv,
        health.infectiousDiseas,
        health.stroke,
        health.anxiety,
        health.anyHerediatry,
      ];

  @override
  Widget build(BuildContext context) {
    final language = Get.find<LanguageController>().currentAppLanguage;

    String localized(String plain, String hindi, String gujarati) =>
        localizedField(language, plain: plain, hindi: hindi, gujarati: gujarati);

    final diseaseValues = _diseaseValues;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ==================================================
        // CURRENT ILLNESS
        // ==================================================

        _SectionCard(
          children: [
            _YesNoRow(
              question: 'health_q_current_illness'.tr,
              isYes: health.isSeriousIllness,
            ),
            if (health.isSeriousIllness)
              _DetailRow(
                label: 'health_q_current_illness_detail'.tr,
                value: localized(
                  health.seriousIllness,
                  health.hSeriousIllness,
                  health.gSeriousIllness,
                ),
              ),
          ],
        ),

        SizedBox(height: 14.px(context)),

        // ==================================================
        // PAST DISEASES
        // ==================================================

        _SectionCard(
          title: 'health_q_past_diseases'.tr,
          children: [
            for (var i = 0; i < _diseaseKeys.length; i++)
              _YesNoRow(question: _diseaseKeys[i].tr, isYes: diseaseValues[i]),
            if (health.anyHerediatry)
              _DetailRow(
                label: 'health_hereditary_detail'.tr,
                value: localized(health.other, health.hOther, health.gOther),
              ),
          ],
        ),

        SizedBox(height: 14.px(context)),

        // ==================================================
        // SURGERY / MEDICATION / ALLERGIES
        // ==================================================

        _SectionCard(
          children: [
            _YesNoRow(question: 'health_q_surgery'.tr, isYes: health.isSurgery),
            if (health.isSurgery) ...[
              _DetailRow(
                label: 'health_q_surgery_detail'.tr,
                value: localized(health.surgery, health.hSurgery, health.gSurgery),
              ),
              if (health.surgeryDate != null)
                _DetailRow(
                  label: 'health_q_surgery_date'.tr,
                  value: DateFormat('dd MMM yyyy').format(health.surgeryDate!),
                ),
            ],
            _YesNoRow(
              question: 'health_q_medication'.tr,
              isYes: health.ismedicationRegularly,
            ),
            if (health.ismedicationRegularly)
              _DetailRow(
                label: 'health_q_medication_detail'.tr,
                value: health.medicationRegularly,
              ),
            _YesNoRow(question: 'health_q_allergy'.tr, isYes: health.anyAllergies),
            if (health.anyAllergies)
              _DetailRow(
                label: 'health_q_allergy_detail'.tr,
                value: localized(
                  health.allergies,
                  health.hAllergies,
                  health.gAllergies,
                ),
              ),
          ],
        ),

        SizedBox(height: 14.px(context)),

        // ==================================================
        // HABITS
        // ==================================================

        _SectionCard(
          children: [
            _YesNoRow(question: 'health_q_tobacco'.tr, isYes: health.tabaccoBidiCigarates),
            _YesNoRow(question: 'health_q_alcohol'.tr, isYes: health.addictionToAlcohol),
            _YesNoRow(question: 'health_q_drugs'.tr, isYes: health.drugs, showDivider: false),
          ],
        ),

        if (health.otherDetails.trim().isNotEmpty ||
            health.hotherDetails.trim().isNotEmpty ||
            health.gotherDetails.trim().isNotEmpty) ...[
          SizedBox(height: 14.px(context)),
          _SectionCard(
            children: [
              _DetailRow(
                label: 'health_q_other'.tr,
                value: localized(
                  health.otherDetails,
                  health.hotherDetails,
                  health.gotherDetails,
                ),
                showDivider: false,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.children});

  final String? title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.px(context), vertical: 6.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18.px(context)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.only(top: 10.px(context), bottom: 4.px(context)),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 12.5.px(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _YesNoRow extends StatelessWidget {
  const _YesNoRow({
    required this.question,
    required this.isYes,
    this.showDivider = true,
  });

  final String question;

  final bool isYes;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InfoListTile(
      label: question,
      value: isYes ? 'yes'.tr : 'no'.tr,
      valueColor: isYes ? AppColors.warning : AppColors.textPrimary,
      showDivider: showDivider,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;

  final String value;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InfoListTile(
      label: label,
      value: value.trim().isNotEmpty ? value : 'not_provided'.tr,
      showDivider: showDivider,
    );
  }
}
