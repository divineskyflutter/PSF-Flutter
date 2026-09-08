// Builds the downloadable "application preview" PDF shown on the
// Registration Preview screen. This intentionally mirrors the layout of
// registration_preview_screen.dart's on-screen pages field-for-field and
// section-for-section — both are built to reproduce the printed "Yojna
// Labharthi Sabhya Form" (member form / nominee table / health
// declaration / undertaking) — so what the user reviews in the app and
// what they download match.
//
// There is currently no backend endpoint that returns a ready-made filled
// PDF (only /api/Document/SaveDocument, for uploading photos/signatures —
// see api_end_points.dart), so this generates the PDF entirely on-device
// from the same data the Preview screen already reads off
// RegistrationController. If a real "get certificate PDF" API is added
// later, only the Preview screen's download handler needs to change to
// call it instead of this builder — this file can stay as a fallback.
//
// The letterhead (organization name, tagline, registration numbers,
// addresses) is reproduced literally, exactly as printed, matching the
// screen's own _letterhead() — see that file for why.
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';

class RegistrationPdfBuilder {
  RegistrationPdfBuilder._();

  static const PdfColor _brandDark = PdfColor.fromInt(0xFF185A55);
  static const PdfColor _brand = PdfColor.fromInt(0xFF258077);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF757575);

  // Cached across calls (fonts are loaded from assets once per app run,
  // not once per download tap).
  static pw.Font? _guRegular;
  static pw.Font? _guBold;
  static pw.Font? _hiRegular;
  static pw.Font? _hiBold;

  static Future<void> _ensureFontsLoaded() async {
    // The pdf package draws its own glyphs and has no access to the
    // device's system font fallback (unlike on-screen Flutter text), so
    // Gujarati/Hindi script needs an explicit Unicode font bundled as an
    // asset — see the "NotoSansGujarati"/"NotoSansDevanagari" font
    // families registered in pubspec.yaml. The letterhead is always
    // Gujarati regardless of the selected language, so the Gujarati font
    // is loaded unconditionally below.
    _guRegular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/noto/NotoSansGujarati-Regular.ttf'),
    );
    _guBold ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/noto/NotoSansGujarati-Bold.ttf'),
    );
    _hiRegular ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/noto/NotoSansDevanagari-Regular.ttf'),
    );
    _hiBold ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/noto/NotoSansDevanagari-Bold.ttf'),
    );
  }

  /// Same "prefer the language-specific translation, fall back to
  /// whatever was originally typed, then to the plain (server-hydrated)
  /// text field" chain the Preview screen itself uses — kept identical so
  /// the PDF never shows a blank value the screen would have shown text
  /// for. See registration_preview_screen.dart's `_localizedValue`.
  static String _localizedValue(
    LocalizedTextModel model,
    String fallback,
    AppLanguage language,
  ) {
    final fromLanguage = switch (language) {
      AppLanguage.hindi => model.hindi,
      AppLanguage.gujarati => model.gujarati,
      AppLanguage.english => model.english,
    };

    if (fromLanguage.trim().isNotEmpty) return fromLanguage;
    if (model.original.trim().isNotEmpty) return model.original;
    return fallback.trim();
  }

  static String _orNotProvided(String value, String notProvidedLabel) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? notProvidedLabel : trimmed;
  }

  /// Builds the full application PDF and returns its bytes, ready to hand
  /// to a file-save call. [notProvidedLabel] and [labels] are passed in
  /// already localized (via `.tr`) rather than read via `.tr` in here,
  /// since this builder has no BuildContext/widget-tree access.
  static Future<Uint8List> build({
    required RegistrationController controller,
    required AppLanguage language,
    required String notProvidedLabel,
    required Map<String, String> labels,
  }) async {
    await _ensureFontsLoaded();

    // The letterhead is always Gujarati text regardless of [language]
    // (see letterhead() below), so the document theme's *base* font must
    // always cover Gujarati glyphs — it can't be swapped per language the
    // way the old (3-page, no fixed letterhead) version of this builder
    // did. Devanagari (for when [language] is Hindi) is supplied as a
    // `fontFallback` instead: the pdf package tries the base font first
    // and only falls through to the fallback list for glyphs the base
    // font doesn't have, so Gujarati (base) and Hindi (fallback) both
    // render correctly no matter which one the applicant's own field
    // values are in. English content renders fine off the Gujarati base
    // font too, since Noto Sans Gujarati includes standard Latin glyphs.
    final theme = pw.ThemeData.withFont(
      base: _guRegular,
      bold: _guBold,
      fontFallback: [
        if (_hiRegular != null) _hiRegular!,
        if (_hiBold != null) _hiBold!,
      ],
    );

    final doc = pw.Document(theme: theme);

    String label(String key) => labels[key] ?? key;
    String value(String raw) => _orNotProvided(raw, notProvidedLabel);
    String localized(LocalizedTextModel model, String fallback) => _orNotProvided(
          _localizedValue(model, fallback, language),
          notProvidedLabel,
        );

    final member = controller.member.value;

    final fullNameParts = [
      _localizedValue(controller.firstNameLanguages.value, member?.firstName ?? '', language),
      _localizedValue(controller.middleNameLanguages.value, member?.lastName ?? '', language),
      _localizedValue(controller.surnameLanguages.value, member?.surname ?? '', language),
    ].where((part) => part.trim().isNotEmpty).join(' ');
    // Same fallback the read-only Full Name field on the previous screen
    // uses (registration_form_steps_screen.dart's `fullNameController`,
    // kept in sync from `controller.member`) — reconstructed here since
    // that TextEditingController lives on the screen's State, not on
    // RegistrationController itself.
    final fullName = value(fullNameParts.isNotEmpty ? fullNameParts : (member?.fullName ?? ''));

    final memberNo = value(member != null && member.memberId > 0 ? '${member.memberId}' : '');
    final today = AppDatePicker.format(DateTime.now());

    final dob = controller.dateOfBirth.value;
    final ageText = dob != null ? '${AppDatePicker.calculateAge(dob)}' : '';

    // Signature image bytes, loaded once and reused on every page (same
    // signature block appears at the bottom of all four pages, matching
    // the printed form).
    final signatureFile = controller.signatureFile.value;
    pw.MemoryImage? signatureImage;
    if (signatureFile != null) {
      try {
        signatureImage = pw.MemoryImage(await signatureFile.readAsBytes());
      } catch (_) {
        // Corrupt/unreadable file — fall through with no signature image
        // rather than failing PDF generation entirely.
        signatureImage = null;
      }
    }

    // ============================================================
    // SHARED WIDGET BUILDERS
    // ============================================================

    pw.Widget letterhead() => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'પરિવાર સુરક્ષા ફાઉન્ડેશન',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _brandDark),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'પરિવારની સુરક્ષાનું સાચું વચન',
              style: pw.TextStyle(fontSize: 11, color: _brand, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Reg.No.(CIN): U94990GJ2025NPL167764, Pan No.: AAQCP1978H, Lic No.: 173515',
              style: const pw.TextStyle(fontSize: 8, color: _textSecondary),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Office Contact : 96646 98982 , Mail : psk4mail@gmail.com',
              style: const pw.TextStyle(fontSize: 8, color: _textSecondary),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1, color: _border),
            pw.Text(
              'રજી. એડ્રેસ : પ૭, ડી.કે. નગર-ર, સંતોષીકૃપા સોસાયટીની બાજુમાં, ડભોલી ચાર રસ્તા, કતારગામ, સુરત ૩૯૫ ૦૦૪',
              style: const pw.TextStyle(fontSize: 7.5, color: _textSecondary),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'ઓફિસ : B/29, બીજો માળ, દાનેવ આશિષ સોસાયટી, ચિકુવાડી રોડ, કતારગામ, સુરત ૩૯૫ ૦૦૪',
              style: const pw.TextStyle(fontSize: 7.5, color: _textSecondary),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 10),
          ],
        );

    pw.Widget formTitle(String text) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _brandDark),
            textAlign: pw.TextAlign.center,
          ),
        );

    pw.Widget boxedCell(String cellLabel, String cellValue) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _border), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(cellLabel, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textSecondary)),
              pw.SizedBox(height: 2),
              pw.Text(cellValue, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );

    pw.Widget dateMemberNoBox() => pw.Row(
          children: [
            pw.Expanded(child: boxedCell(label('form_date'), today)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: boxedCell(label('member_no'), memberNo)),
          ],
        );

    pw.Widget underlineField(String fieldLabel, String fieldValue) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.only(bottom: 3),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _border))),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('$fieldLabel : ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(child: pw.Text(fieldValue, style: const pw.TextStyle(fontSize: 10.5))),
            ],
          ),
        );

    pw.Widget checkChip(String text, bool selected) => pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 10,
              height: 10,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _textSecondary),
                color: selected ? _brand : PdfColors.white,
              ),
              child: selected
                  ? pw.Center(
                      child: pw.Text('X', style: const pw.TextStyle(fontSize: 7, color: PdfColors.white)),
                    )
                  : null,
            ),
            pw.SizedBox(width: 4),
            pw.Text(text, style: const pw.TextStyle(fontSize: 9.5)),
          ],
        );

    pw.Widget choiceRow(String rowLabel, List<EnumItem> options, int? selectedId) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              pw.Text('$rowLabel : ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              if (options.isEmpty)
                pw.Text(notProvidedLabel, style: const pw.TextStyle(fontSize: 9.5, color: _textSecondary))
              else
                for (final option in options) checkChip(option.name, option.id == selectedId),
            ],
          ),
        );

    pw.Widget yesNoQuestion(String question, bool? answer) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Wrap(
            crossAxisAlignment: pw.WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              pw.Text(question, style: const pw.TextStyle(fontSize: 9.5)),
              checkChip(label('yes'), answer == true),
              checkChip(label('no'), answer == false),
            ],
          ),
        );

    pw.Widget blankDetailField(String question, String? value) {
      final displayValue =
          (value != null && value.trim().isNotEmpty) ? value.trim() : notProvidedLabel;

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 9),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(question, style: const pw.TextStyle(fontSize: 9.5)),
            pw.SizedBox(height: 3),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.only(bottom: 2),
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _border))),
              child: pw.Text(displayValue, style: pw.TextStyle(fontSize: 9, color: _textSecondary)),
            ),
          ],
        ),
      );
    }

    pw.Widget signatureBlock() => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label('your_faithfully'), style: const pw.TextStyle(fontSize: 9.5)),
              pw.SizedBox(height: 6),
              if (signatureImage != null)
                pw.Image(signatureImage, height: 34, fit: pw.BoxFit.contain)
              else
                pw.SizedBox(height: 34),
              pw.Container(
                width: 130,
                padding: const pw.EdgeInsets.only(top: 3),
                decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _border))),
                child: pw.Text(label('member_signature'), style: pw.TextStyle(fontSize: 8, color: _textSecondary)),
              ),
              pw.SizedBox(height: 5),
              pw.Text('${label('form_date')} : $today', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        );

    pw.Widget pageFooter(int pageNumber) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            (labels['page_count'] ?? 'Page @page of @total')
                .replaceFirst('@page', '$pageNumber')
                .replaceFirst('@total', '4'),
            style: const pw.TextStyle(fontSize: 8.5, color: _textSecondary),
          ),
        );

    // ============================================================
    // PAGE 1 — MEMBER FORM
    // ============================================================
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          letterhead(),
          formTitle(label('member_form_title')),
          dateMemberNoBox(),
          pw.SizedBox(height: 12),
          underlineField(label('full_name'), fullName),
          underlineField(label('father_husband_name'), value(controller.fatherNameController.text)),
          pw.Row(
            children: [
              pw.Expanded(flex: 3, child: underlineField(label('date_of_birth'), value(controller.dateOfBirthController.text))),
              pw.SizedBox(width: 10),
              pw.Expanded(flex: 2, child: underlineField(label('age_label'), ageText.isEmpty ? notProvidedLabel : ageText)),
            ],
          ),
          choiceRow(label('gender'), controller.genderOptions, controller.selectedGenderId.value),
          choiceRow(label('marital_status'), controller.maritalStatusOptions, controller.selectedMaritalStatusId.value),
          underlineField(label('address'), localized(controller.addressLanguages.value, controller.addressController.text)),
          underlineField(label('native_place'), localized(controller.villageLanguages.value, controller.villageController.text)),
          pw.Row(
            children: [
              pw.Expanded(child: underlineField(label('taluka'), localized(controller.talukaLanguages.value, controller.talukaController.text))),
              pw.SizedBox(width: 10),
              pw.Expanded(child: underlineField(label('district'), localized(controller.districtLanguages.value, controller.districtController.text))),
            ],
          ),
          underlineField(label('state'), localized(controller.stateLanguages.value, controller.stateController.text)),
          pw.Row(
            children: [
              pw.Expanded(child: underlineField(label('mobile_number'), value(controller.mobileController.text))),
              pw.SizedBox(width: 10),
              pw.Expanded(child: underlineField(label('mobile_number_2'), value(controller.mobile2Controller.text))),
            ],
          ),
          underlineField(label('occupation'), localized(controller.occupationLanguages.value, controller.occupationController.text)),
          pw.Row(
            children: [
              pw.Expanded(child: underlineField(label('aadhaar_number'), value(controller.aadharNumberController.text))),
              pw.SizedBox(width: 10),
              pw.Expanded(child: underlineField(label('pan_number'), value(controller.panNumberController.text))),
            ],
          ),
          signatureBlock(),
          pageFooter(1),
        ],
      ),
    );

    // ============================================================
    // PAGE 2 — NOMINEE (VARASDAR) TABLE
    // ============================================================

    // Looks up a nominee-relation id (RegistrationController.relationOptions
    // — live from GetEnumBundle's Relation list) to its display name.
    String relationValue(int? relationId) {
      if (relationId == null) return notProvidedLabel;

      for (final option in controller.relationOptions) {
        if (option.id == relationId) return option.name;
      }

      return notProvidedLabel;
    }

    pw.Widget tableHeadCell(String text) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(text, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _brandDark)),
        );
    pw.Widget tableLabelCell(String text) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _textSecondary)),
        );
    pw.Widget tableValueCell(String text) => pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(text, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
        );

    // The printed form has 3 nominee columns, matching
    // RegistrationController.maxNominees exactly — a slot beyond
    // visibleNomineeSlots (the member added fewer than 3 nominees) is left
    // blank rather than invented.
    final nomineeColumnValues = List<List<String>>.generate(3, (index) {
      if (index >= controller.visibleNomineeSlots.value) {
        return [notProvidedLabel, notProvidedLabel, notProvidedLabel, notProvidedLabel];
      }

      final slot = controller.nomineeSlots[index];

      return [
        value(slot.nameController.text),
        value(slot.dateOfBirthController.text),
        relationValue(slot.relationId.value),
        value(slot.shareController.text),
      ];
    });

    final nomineeTable = pw.Table(
      border: pw.TableBorder.all(color: _border),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8F6EF)),
          children: [
            pw.SizedBox(),
            for (var i = 0; i < 3; i++) tableHeadCell(label('nominee_number').replaceFirst('@n', '${i + 1}')),
          ],
        ),
        pw.TableRow(children: [
          tableLabelCell(label('nominee_name')),
          for (final col in nomineeColumnValues) tableValueCell(col[0]),
        ]),
        pw.TableRow(children: [
          tableLabelCell(label('date_of_birth')),
          for (final col in nomineeColumnValues) tableValueCell(col[1]),
        ]),
        pw.TableRow(children: [
          tableLabelCell(label('relationship')),
          for (final col in nomineeColumnValues) tableValueCell(col[2]),
        ]),
        pw.TableRow(children: [
          tableLabelCell(label('nominee_share')),
          for (final col in nomineeColumnValues) tableValueCell(col[3]),
        ]),
      ],
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          letterhead(),
          formTitle(label('nominee_details')),
          nomineeTable,
          pw.SizedBox(height: 14),
          pw.Text(
            label('member_undertaking_text').replaceFirst('@name', fullName),
            style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2),
          ),
          signatureBlock(),
          pageFooter(2),
        ],
      ),
    );

    // ============================================================
    // PAGE 3 — HEALTH DECLARATION
    //
    // Sourced from the same RegistrationController health fields the
    // Preview screen's _healthDeclarationPage reads — filled in on the
    // (optional) Health step of MemberRegistrationScreen. Unanswered
    // questions render exactly as before: both Yes/No boxes unchecked,
    // blank fields showing notProvidedLabel.
    // ============================================================

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          letterhead(),
          formTitle(label('health_declaration_title')),
          dateMemberNoBox(),
          pw.SizedBox(height: 10),
          pw.Text(
            label('health_declaration_intro'),
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _textSecondary),
          ),
          pw.SizedBox(height: 10),
          yesNoQuestion(label('health_q_current_illness'), controller.hasCurrentIllness.value),
          if (controller.hasCurrentIllness.value == true)
            blankDetailField(label('health_q_current_illness_detail'), controller.seriousIllnessDetailController.text),
          pw.SizedBox(height: 4),
          pw.Text(label('health_q_past_diseases'), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final key in RegistrationController.diseaseKeys)
                checkChip(label(key), controller.selectedDiseaseKeys.contains(key)),
            ],
          ),
          if (controller.selectedDiseaseKeys.contains('disease_hereditary'))
            blankDetailField(label('health_hereditary_detail'), controller.otherHereditaryDetailController.text),
          pw.SizedBox(height: 12),
          yesNoQuestion(label('health_q_surgery'), controller.hadSurgery.value),
          if (controller.hadSurgery.value == true) ...[
            blankDetailField(label('health_q_surgery_detail'), controller.surgeryDetailController.text),
            blankDetailField(label('health_q_surgery_date'), controller.surgeryDateController.text),
          ],
          yesNoQuestion(label('health_q_medication'), controller.onRegularMedication.value),
          if (controller.onRegularMedication.value == true)
            blankDetailField(label('health_q_medication_detail'), controller.medicationDetailController.text),
          yesNoQuestion(label('health_q_allergy'), controller.hasAllergies.value),
          if (controller.hasAllergies.value == true)
            blankDetailField(label('health_q_allergy_detail'), controller.allergyDetailController.text),
          yesNoQuestion(label('health_q_tobacco'), controller.usesTobacco.value),
          yesNoQuestion(label('health_q_alcohol'), controller.consumesAlcohol.value),
          yesNoQuestion(label('health_q_drugs'), controller.usesDrugs.value),
          blankDetailField(label('health_q_other'), controller.otherHealthDetailController.text),
          pw.SizedBox(height: 4),
          pw.Text(label('health_declare_text'), style: const pw.TextStyle(fontSize: 9, lineSpacing: 2)),
          signatureBlock(),
          pageFooter(3),
        ],
      ),
    );

    // ============================================================
    // PAGE 4 — UNDERTAKING (JAHER KHABAR)
    // ============================================================
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          letterhead(),
          formTitle(label('undertaking_title')),
          pw.Text(label('undertaking_text'), style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 2.5)),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Container(
                width: 12,
                height: 12,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                  color: controller.acceptedRules.value ? _brand : PdfColors.white,
                ),
                child: controller.acceptedRules.value
                    ? pw.Center(child: pw.Text('X', style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)))
                    : null,
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Text(label('agree_terms'), style: const pw.TextStyle(fontSize: 9.5))),
            ],
          ),
          pw.SizedBox(height: 14),
          underlineField(label('full_name'), fullName),
          signatureBlock(),
          pageFooter(4),
        ],
      ),
    );

    return doc.save();
  }
}
