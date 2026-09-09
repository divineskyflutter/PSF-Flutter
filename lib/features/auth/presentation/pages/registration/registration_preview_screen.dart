// Application Preview screen — shown after the member finishes the Rules
// & Declaration step. Pages are laid out to mirror the printed "Yojna
// Labharthi Sabhya Form" (member form / nominee table / health
// declaration / undertaking) field-for-field and section-for-section, as
// a swipeable, page-turning "book" — see _memberPage/_nomineePage/
// _healthDeclarationPage/_declarationPage below. The letterhead
// (organization name, tagline, registration numbers, addresses) is
// reproduced literally, exactly as printed, since it is the
// organization's own fixed identity block and not user content. Every
// other label and value is still resolved in whichever language the app
// is currently set to — see `_localizedValue` below — reading straight
// off the already-populated RegistrationController, the same pattern
// MemberRegistrationScreen already uses to reach this controller with no
// binding of its own.
//
// The nominee table (page 2) reads from RegistrationController.nomineeSlots
// / visibleNomineeSlots — up to 3 nominees, matching the printed form's 3
// columns exactly (see _nomineePage/_nomineeRelationLabel below); a slot
// beyond however many the member actually added is shown blank rather
// than invented. One field is still not collected anywhere in this app
// (no screen/API for it yet): the Health Declaration answers (page 3).
// Those are shown exactly as laid out on the paper form, left blank,
// rather than invented — see registration_pdf_builder.dart, which mirrors
// the same chain for the downloaded PDF.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:page_flip/page_flip.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/shared/widgets/images/common_image_view.dart';

class RegistrationPreviewScreen extends StatefulWidget {
  const RegistrationPreviewScreen({super.key});

  @override
  State<RegistrationPreviewScreen> createState() =>
      _RegistrationPreviewScreenState();
}

class _RegistrationPreviewScreenState
    extends State<RegistrationPreviewScreen> {
  final RegistrationController controller = Get.find<RegistrationController>();
  final LanguageController languageController = Get.find<LanguageController>();

  final PageFlipController _pageFlipController = PageFlipController();
  final RxInt _currentPageIndex = 0.obs;

  static const int _totalPages = 4;

  @override
  void initState() {
    super.initState();

    // Reaching this screen at all is only possible after the Rules &
    // Declaration step's checkbox was checked — it gates that step's
    // Next/Submit button — so if this screen was opened without that ever
    // happening THIS session (see _loadMissingRegistrationData below), the
    // checkbox would otherwise read as unchecked purely because it's a
    // local-only flag the backend never returns, not because it wasn't
    // actually accepted. Reaching this screen is itself proof it was, so
    // set it up front rather than waiting on the network call below.
    controller.acceptedRules.value = true;

    _loadMissingRegistrationData();
  }

  /// A member can reach this screen two ways: normally, right after
  /// finishing the step wizard THIS session — which already prefills
  /// nominee/health data into RegistrationController the moment it opens
  /// (see MemberRegistrationScreen.initState / loadExistingNominees /
  /// loadExistingHealthDeclaration) — or by closing the app mid
  /// registration and reopening it, where GetSingleMemberByRegistredStatus
  /// resolves straight to this screen without the wizard ever mounting. In
  /// that second case nothing had a chance to load the nominee/health
  /// data into the controller, so this screen showed personal details
  /// only, with the nominee table, health declaration and rules checkbox
  /// all blank/unchecked even though the member had already filled them
  /// in before closing the app.
  ///
  /// Re-running the exact same "GET, then populate" prefill here is
  /// harmless and idempotent in the normal case (it just re-fetches
  /// exactly what's already there and overwrites it with the same
  /// values) and guarantees this screen always has everything regardless
  /// of how it was reached. The pages below read these values directly
  /// (not through Obx — PageFlipWidget builds its page widgets once, up
  /// front), so a rebuild is forced once the fetch actually settles.
  Future<void> _loadMissingRegistrationData() async {
    await Future.wait([
      controller.loadExistingNominees(),
      controller.loadExistingHealthDeclaration(),
    ]);

    if (mounted) setState(() {});
  }

  // ============================================================
  // LANGUAGE-AWARE VALUE RESOLUTION
  //
  // Same 3-tier fallback RegistrationPdfBuilder uses for the downloaded
  // PDF, kept in sync so the on-screen preview and the download always
  // agree: prefer the selected language's translation → the originally
  // typed text → the plain (server-hydrated) controller text.
  // ============================================================

  String _localizedValue(LocalizedTextModel model, String fallback) {
    final language = languageController.currentAppLanguage;

    final fromLanguage = switch (language) {
      AppLanguage.hindi => model.hindi,
      AppLanguage.gujarati => model.gujarati,
      AppLanguage.english => model.english,
    };

    if (fromLanguage.trim().isNotEmpty) return fromLanguage;
    if (model.original.trim().isNotEmpty) return model.original;
    return fallback.trim();
  }

  String _orNotProvided(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'not_provided'.tr : trimmed;
  }

  /// Same idea as _orNotProvided, but for the nominee table specifically —
  /// an empty nominee field shows a plain '-' there instead of the
  /// 'not_provided' text used everywhere else on the printed form.
  String _orDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  // ============================================================
  // Static enum-option label translations — GetEnumBundle (Gender,
  // Marital Status, nominee Relation) returns English-only `name`
  // values with no h/g variant, unlike every other field on this
  // screen, so there's no per-language text to read from the backend
  // for these. This table covers the known option set the backend
  // currently defines; any option not listed here (e.g. a new value
  // added server-side later) simply falls back to its own English
  // `name` untranslated instead of showing blank.
  // ============================================================

  static const Map<String, Map<String, String>> _optionTranslations = {
    'male': {'hi': 'पुरुष', 'gu': 'પુરુષ'},
    'female': {'hi': 'महिला', 'gu': 'સ્ત્રી'},
    'other': {'hi': 'अन्य', 'gu': 'અન્ય'},
    'single': {'hi': 'अविवाहित', 'gu': 'અપરિણીત'},
    'married': {'hi': 'विवाहित', 'gu': 'પરિણીત'},
    'divorced': {'hi': 'तलाकशुदा', 'gu': 'છૂટાછેડા લીધેલ'},
    'widowed': {'hi': 'विधवा/विधुर', 'gu': 'વિધવા/વિધુર'},
    'father': {'hi': 'पिता', 'gu': 'પિતા'},
    'mother': {'hi': 'माता', 'gu': 'માતા'},
    'husband': {'hi': 'पति', 'gu': 'પતિ'},
    'wife': {'hi': 'पत्नी', 'gu': 'પત્ની'},
    'son': {'hi': 'बेटा', 'gu': 'દીકરો'},
    'daughter': {'hi': 'बेटी', 'gu': 'દીકરી'},
    'brother': {'hi': 'भाई', 'gu': 'ભાઈ'},
    'sister': {'hi': 'बहन', 'gu': 'બહેન'},
    'grandson': {'hi': 'पौत्र', 'gu': 'પૌત્ર'},
    'granddaughter': {'hi': 'पौत्री', 'gu': 'પૌત્રી'},
    'son in law': {'hi': 'दामाद', 'gu': 'જમાઈ'},
    'daughter in law': {'hi': 'बहू', 'gu': 'વહુ'},
    'father in law': {'hi': 'ससुर', 'gu': 'સસરા'},
    'mother in law': {'hi': 'सास', 'gu': 'સાસુ'},
    'other relative': {'hi': 'अन्य रिश्तेदार', 'gu': 'અન્ય સંબંધી'},
  };

  String _translatedOptionName(String englishName) {
    final language = languageController.currentAppLanguage;
    if (language == AppLanguage.english) return englishName;

    final entry = _optionTranslations[englishName.trim().toLowerCase()];
    if (entry == null) return englishName;

    final translated =
        language == AppLanguage.hindi ? entry['hi'] : entry['gu'];
    return (translated != null && translated.isNotEmpty)
        ? translated
        : englishName;
  }

  /// First + middle + surname in the selected language, falling back to
  /// the plain server-hydrated name — the same value the Full Name field
  /// and the undertaking paragraphs need, so it's factored out once
  /// instead of every page re-deriving it.
  String _resolvedFullName() {
    final member = controller.member.value;

    final parts = [
      _localizedValue(
        controller.firstNameLanguages.value,
        member?.firstName ?? '',
      ),
      _localizedValue(
        controller.middleNameLanguages.value,
        member?.lastName ?? '',
      ),
      _localizedValue(
        controller.surnameLanguages.value,
        member?.surname ?? '',
      ),
    ].where((part) => part.trim().isNotEmpty).join(' ');

    return _orNotProvided(parts.isNotEmpty ? parts : (member?.fullName ?? ''));
  }

  // Deliberately always blank for now. This used to show
  // controller.member.value.memberId, but that's only the member's
  // internal database id — not a real member/application number — and
  // showing it here read as if it were one. The API doesn't return an
  // actual member number yet; once it does, wire that field in here
  // instead of memberId.
  String _resolvedMemberNo() {
    return _orNotProvided('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: PageFlipWidget(
                controller: _pageFlipController,
                backgroundColor: AppColors.background,
                onPageFlipped: (index) => _currentPageIndex.value = index,
                children: [
                  _memberPage(context),
                  _nomineePage(context),
                  _healthDeclarationPage(context),
                  _declarationPage(context),
                ],
              ),
            ),
            _buildPageIndicator(context),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR — back, title, download
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          ),
          Expanded(
            child: Text(
              'application_preview'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          // Balances the back button on the left so the title above stays
          // visually centered — the download option that used to sit here
          // has been removed from this screen entirely.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE INDICATOR — dots, tap to jump to that page
  // ============================================================

  Widget _buildPageIndicator(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalPages, (index) {
            final active = index == _currentPageIndex.value;

            return GestureDetector(
              onTap: () => _pageFlipController.goToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR — Complete Registration
  // ============================================================

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: AppButton(
        label: 'complete_registration'.tr,
        onPressed: _completeRegistration,
      ),
    );
  }

  Future<void> _completeRegistration() async {
    // SavePreviewScreen — only navigate on to the Pending screen once the
    // backend has actually confirmed the final save.
    final saved = await controller.savePreviewScreen();

    if (!saved) {
      return;
    }

    // Deliberately NOT calling AppPrefs.setRegistrationCompleted(true)
    // here. That flag is what lets SplashScreen skip straight to Home on
    // a later launch (see SplashScreen._routeNext()) — appropriate once
    // an admin has actually approved the member, but this member's
    // application has only just been submitted and is now waiting on
    // that approval. Leaving it unset means a later launch instead goes
    // through Language -> Auth-choice -> Register like any resuming
    // member, where GetSingleMemberByRegistredStatus's returned screen
    // name (now '/registration-pending' — see
    // RegistrationNavigator.mapScreenNameToRoute) sends them straight
    // back to RegistrationPendingScreen rather than Home. Set this flag
    // for real wherever an actual "approved" signal is wired up.
    ToastUtil.success('registration_completed_successfully'.tr);
    Get.offAllNamed(AppRoutes.registrationPending);
  }

  // ============================================================
  // "PAPER" CARD — shared look for every page
  // ============================================================

  Widget _paper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 15, offset: Offset(0, 6)),
        ],
      ),
      child: SingleChildScrollView(child: child),
    );
  }

  // ============================================================
  // LETTERHEAD — the organization's own printed identity block.
  //
  // Reproduced literally (not run through `.tr`) since this is fixed
  // organizational/legal detail — name, tagline, CIN/PAN/license
  // numbers, contact, both registered addresses — printed identically on
  // every page of the official form regardless of which language the
  // applicant's own data is shown in.
  // ============================================================

  Widget _letterhead() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.logo, width: 56, height: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'પરિવાર સુરક્ષા ફાઉન્ડેશન',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    'પરિવારની સુરક્ષાનું સાચું વચન',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Reg.No.(CIN): U94990GJ2025NPL167764, Pan No.: AAQCP1978H, Lic No.: 173515',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
        ),
        const Text(
          'Office Contact : 96646 98982 , Mail : psk4mail@gmail.com',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        const Divider(height: 12, thickness: 1, color: AppColors.border),
        const Text(
          'રજી. એડ્રેસ : પ૭, ડી.કે. નગર-ર, સંતોષીકૃપા સોસાયટીની બાજુમાં, ડભોલી ચાર રસ્તા, કતારગામ, સુરત ૩૯૫ ૦૦૪',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
        const Text(
          'ઓફિસ : B/29, બીજો માળ, દાનેવ આશિષ સોસાયટી, ચિકુવાડી રોડ, કતારગામ, સુરત ૩૯૫ ૦૦૪',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 8, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ============================================================
  // SHARED FIELD WIDGETS
  // ============================================================

  Widget _dateMemberNoBox({required String date, required String memberNo}) {
    return Row(
      children: [
        Expanded(child: _boxedCell('form_date'.tr, date)),
        const SizedBox(width: 8),
        Expanded(child: _boxedCell('member_no'.tr, memberNo)),
      ],
    );
  }

  Widget _boxedCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Label : ____ value ____" — the underlined-blank style used
  /// throughout the printed form, filled in with the resolved value
  /// instead of left blank.
  ///
  /// Used for fields placed two-to-a-row (mobile numbers, Aadhaar/PAN,
  /// taluka/district, date of birth/age) where each field only gets half
  /// the paper's width. Two things can otherwise go wrong there: a long
  /// Hindi/Gujarati label can outgrow its half of the row entirely
  /// (a RenderFlex overflow, same class of bug already fixed on the
  /// upload circle), and a value longer than what's left can wrap onto a
  /// second line and break the underlined "form field" look. Both the
  /// label and the value now auto-shrink (FittedBox, never enlarging —
  /// only ever scaling down) to whatever room they actually have instead
  /// of overflowing, wrapping, or being cut off with "..." — the member
  /// always sees the whole value, just smaller if it needs to be. The
  /// label is capped to a share of the row (via LayoutBuilder) so a long
  /// label can't eat into the value's space; when the label is short (the
  /// common case) that cap never binds and the value still gets all the
  /// remaining room exactly as before. See _underlineFieldMultiline below
  /// for fields that need more room by design (e.g. Address).
  Widget _underlineField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.42,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$label : ',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Same underlined style as _underlineField, but the label sits on its
  /// own line above the value instead of sharing a row with it — gives a
  /// long value (Address, chiefly) the FULL paper width to wrap into
  /// instead of whatever's left after the label, so it always reads in
  /// full with no missing/clipped lines regardless of how long it is.
  Widget _underlineFieldMultiline(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label :',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  /// "Label : [ ] optionA  [ ] optionB  ..." — the checkbox-style choice
  /// rows (gender, marital status), one chip per option the backend's
  /// enum bundle actually returned, with the applicant's selection
  /// shown checked.
  Widget _choiceRow(String label, List<EnumItem> options, int? selectedId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          if (options.isEmpty)
            Text(
              'not_provided'.tr,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            )
          else
            for (final option in options)
              _choiceChip(
                _translatedOptionName(option.name),
                option.id == selectedId,
              ),
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 17,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ],
    );
  }

  /// "Question — [ ] Yes  [ ] No" — used for the health-declaration
  /// yes/no questions. [answer] is null (both boxes unchecked) when the
  /// member skipped the optional health step.
  Widget _yesNoQuestion(String question, bool? answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 6,
        children: [
          Text(question, style: const TextStyle(fontSize: 12.5)),
          _choiceChip('yes'.tr, answer == true),
          _choiceChip('no'.tr, answer == false),
        ],
      ),
    );
  }

  /// "Question ______" — the free-text detail questions on the health
  /// declaration page. Shows whatever the member typed on the Health
  /// step, or the 'not_provided' placeholder when they left it blank
  /// (that step is entirely optional).
  Widget _blankDetailField(String question, String? value) {
    final displayValue = (value != null && value.trim().isNotEmpty)
        ? value.trim()
        : 'not_provided'.tr;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Profile / nominee photo preview — a locally-picked `File` only lives
  /// in memory for the session it was picked in (image_picker), so it's
  /// null on a resumed registration opened fresh from an earlier app
  /// launch. [networkUrl] (the API's own copy of the same photo) is the
  /// real source of truth for anything already uploaded — checked first
  /// here as a genuine network image, with [file] only as an immediate
  /// preview for a photo just picked this session and not uploaded yet.
  /// Falls back to the 'no_images_available' placeholder only when
  /// neither is available.
  Widget _photoBox(
    String label,
    File? file, {
    String? networkUrl,
    double height = 90,
    double? width,
  }) {
    // One consistent shape for every image box on the printed preview —
    // rounded rect, radius 8, always with a visible border — whether it's
    // an actual photo or the "no image" placeholder, and matching
    // _nomineePage's photoCell exactly (see that function's own comment).
    // Used to only put a border around the placeholder, leaving an actual
    // photo borderless — which is what read as images "showing in
    // different shapes".
    final Widget content;

    if (file != null) {
      content = Image.file(file, height: height, width: width, fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl.isNotEmpty) {
      content = SizedBox(
        height: height,
        width: width,
        child: CommonImageView(
          image: networkUrl,
          type: CommonImageType.network,
          fit: BoxFit.cover,
          showShimmer: false,
        ),
      );
    } else {
      content = Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        color: AppColors.background,
        child: Text(
          'no_images_available'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          height: height,
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: content,
        ),
      ],
    );
  }

  /// "Yours faithfully" + signature image (if captured) + "Member's
  /// Signature" underline + today's date — the closing block every page
  /// of the printed form ends on.
  Widget _signatureBlock() {
    final date = AppDatePicker.format(DateTime.now());
    final signature = controller.signatureFile.value;

    // signatureFile is only ever set when the user just captured a
    // signature THIS session (setSignature). On resume — GetMemberStatus
    // repopulating an already-submitted step from the server — there is no
    // local File any more, only signatureFileUrl (digitalSignUrl from the
    // API). The old code only ever checked signatureFile, so a previously
    // saved signature silently rendered as blank space here; fall back to
    // the network image the same way every other resumed document does.
    final signatureUrl = controller.signatureFileUrl.value;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('your_faithfully'.tr, style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 8),
          if (signature != null)
            Image.file(signature, height: 44, fit: BoxFit.contain)
          else if (signatureUrl != null && signatureUrl.isNotEmpty)
            SizedBox(
              height: 44,
              child: CommonImageView(
                image: signatureUrl,
                type: CommonImageType.network,
                fit: BoxFit.contain,
                showShimmer: false,
              ),
            )
          else
            const SizedBox(height: 44),
          Container(
            width: 170,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'member_signature'.tr,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 6),
          Text('${'form_date'.tr} : $date', style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _pageFooter(int pageNumber) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        'page_count'.trParams({
          'page': '$pageNumber',
          'total': '$_totalPages',
        }),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
      ),
    );
  }

  // ============================================================
  // PAGE 1 — MEMBER FORM
  // ============================================================

  Widget _memberPage(BuildContext context) {
    return Obx(() {
      final fullName = _resolvedFullName();

      final selectedGender = controller.genderOptions;
      final selectedMaritalStatus = controller.maritalStatusOptions;

      final dob = controller.dateOfBirth.value;
      final dobText = controller.dateOfBirthController.text;
      final ageText = dob != null ? '${AppDatePicker.calculateAge(dob)}' : '';

      return _paper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _letterhead(),
            Center(
              child: Text(
                'member_form_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _dateMemberNoBox(
                    date: AppDatePicker.format(DateTime.now()),
                    memberNo: _resolvedMemberNo(),
                  ),
                ),
                const SizedBox(width: 12),
                _photoBox(
                  'photo'.tr,
                  controller.profileImage.value,
                  networkUrl: controller.profileImageUrl.value,
                  height: 88,
                  width: 88,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _underlineField('full_name'.tr, fullName),
            _underlineField(
              'father_husband_name'.tr,
              _orNotProvided(_localizedValue(
                controller.fatherNameLanguages.value,
                controller.fatherNameController.value.text,
              )),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: _underlineField('date_of_birth'.tr, _orNotProvided(dobText)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _underlineField(
                    'age_label'.tr,
                    ageText.isEmpty ? 'not_provided'.tr : ageText,
                  ),
                ),
              ],
            ),
            _choiceRow('gender'.tr, selectedGender, controller.selectedGenderId.value),
            _choiceRow(
              'marital_status'.tr,
              selectedMaritalStatus,
              controller.selectedMaritalStatusId.value,
            ),
            _underlineFieldMultiline(
              'address'.tr,
              _orNotProvided(_localizedValue(
                controller.addressLanguages.value,
                controller.addressController.text,
              )),
            ),
            _underlineField(
              'native_place'.tr,
              _orNotProvided(_localizedValue(
                controller.villageLanguages.value,
                controller.villageController.text,
              )),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _underlineField(
                    'taluka'.tr,
                    _orNotProvided(_localizedValue(
                      controller.talukaLanguages.value,
                      controller.talukaController.text,
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _underlineField(
                    'district'.tr,
                    _orNotProvided(_localizedValue(
                      controller.districtLanguages.value,
                      controller.districtController.text,
                    )),
                  ),
                ),
              ],
            ),
            _underlineField(
              'state'.tr,
              _orNotProvided(_localizedValue(
                controller.stateLanguages.value,
                controller.stateController.text,
              )),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _underlineField(
                    'mobile_number'.tr,
                    _orNotProvided(controller.mobileController.text),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _underlineField(
                    'mobile_number_2'.tr,
                    _orNotProvided(controller.mobile2Controller.text),
                  ),
                ),
              ],
            ),
            _underlineField(
              'occupation'.tr,
              _orNotProvided(_localizedValue(
                controller.occupationLanguages.value,
                controller.occupationController.text,
              )),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _underlineField(
                    'aadhaar_number'.tr,
                    _orNotProvided(controller.aadharNumberController.text),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _underlineField(
                    'pan_number'.tr,
                    _orNotProvided(controller.panNumberController.text),
                  ),
                ),
              ],
            ),
            _signatureBlock(),
            _pageFooter(1),
          ],
        ),
      );
    });
  }

  // ============================================================
  // PAGE 2 — NOMINEE (VARASDAR) TABLE
  // ============================================================

  /// Looks up a nominee-relation id (RegistrationController.relationOptions
  /// — live from GetEnumBundle's Relation list) to its display name.
  /// 'not_provided' when the id is null or no longer matches a loaded
  /// option (e.g. options haven't finished loading yet).
  String _nomineeRelationLabel(int? relationId) {
    if (relationId == null) return '-';

    for (final option in controller.relationOptions) {
      if (option.id == relationId) return _translatedOptionName(option.name);
    }

    return '-';
  }

  Widget _nomineePage(BuildContext context) {
    return Obx(() {
      // The printed form has 3 nominee columns, matching
      // RegistrationController.maxNominees exactly — a slot beyond
      // visibleNomineeSlots (the member chose to add fewer than 3
      // nominees) is shown blank rather than invented.
      final columns = List<_NomineeColumn>.generate(3, (index) {
        if (index >= controller.visibleNomineeSlots.value) {
          return const _NomineeColumn(
            name: '-',
            dob: '-',
            relation: '-',
            share: '-',
            photo: null,
          );
        }

        final slot = controller.nomineeSlots[index];

        return _NomineeColumn(
          name: _orDash(_localizedValue(
            slot.nameLanguages.value,
            slot.nameController.text,
          )),
          dob: _orDash(slot.dateOfBirthController.text),
          relation: _nomineeRelationLabel(slot.relationId.value),
          share: _orDash(slot.shareController.text),
          photo: slot.photo.value,
          photoUrl: slot.photoUrl.value,
        );
      });

      return _paper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _letterhead(),
            Center(
              child: Text(
                'nominee_details'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _nomineeTable(columns),
            const SizedBox(height: 18),
            Text(
              'member_undertaking_text'.trParams({'name': _resolvedFullName()}),
              style: const TextStyle(fontSize: 11.5, height: 1.55),
            ),
            _signatureBlock(),
            _pageFooter(2),
          ],
        ),
      );
    });
  }

  Widget _nomineeTable(List<_NomineeColumn> columns) {
    Widget headCell(String text) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        );

    Widget labelCell(String text) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        );

    Widget valueCell(String text) => Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        );

    // [file] wins when set (picked this session). Otherwise, for a
    // nominee resumed from a previous session, fall back to [url] — see
    // _NomineeColumn.photoUrl's doc comment for why that may still be
    // null even then. Same shape as _photoBox above (rounded rect, radius
    // 8, always bordered) so every image box on the printed preview reads
    // as one consistent shape.
    Widget photoCell(File? file, String? url) {
      final Widget content;

      // Every one of these previously set only `height: 46`, with no
      // `width` — BoxFit.cover needs a bounded box on BOTH axes to know
      // what to cover, so without a width the image just rendered at its
      // own natural width (whatever that happened to be) instead of
      // filling the cell, and the bordered box below shrink-wrapped to
      // that same natural width instead of the table column — the photo
      // visibly didn't fill its frame. `double.infinity` here fills
      // whatever width the surrounding Container (also now `width:
      // double.infinity`, filling the table column) actually gives it.
      if (file != null) {
        content = Image.file(
          file,
          height: 46,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else if (url != null) {
        content = CommonImageView(
          image: url,
          type: CommonImageType.network,
          height: 46,
          width: double.infinity,
          fit: BoxFit.cover,
          showPlaceholder: false,
          showShimmer: false,
        );
      } else {
        content = Container(
          height: 46,
          width: double.infinity,
          alignment: Alignment.center,
          color: AppColors.background,
          child: Text(
            'no_images_available'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 7.5, color: AppColors.textSecondary),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(6),
        child: Container(
          height: 46,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: content,
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: AppColors.border),
      columnWidths: const {
        0: FlexColumnWidth(1.15),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.background),
          children: [
            const SizedBox.shrink(),
            for (var i = 0; i < columns.length; i++)
              headCell('nominee_number'.trParams({'n': '${i + 1}'})),
          ],
        ),
        TableRow(children: [
          labelCell('nominee_name'.tr),
          for (final c in columns) valueCell(c.name),
        ]),
        TableRow(children: [
          labelCell('date_of_birth'.tr),
          for (final c in columns) valueCell(c.dob),
        ]),
        TableRow(children: [
          labelCell('relationship'.tr),
          for (final c in columns) valueCell(c.relation),
        ]),
        TableRow(children: [
          labelCell('nominee_share'.tr),
          for (final c in columns) valueCell(c.share),
        ]),
        TableRow(children: [
          labelCell('nominee_photo'.tr),
          for (final c in columns) photoCell(c.photo, c.photoUrl),
        ]),
      ],
    );
  }

  // ============================================================
  // PAGE 3 — HEALTH DECLARATION
  //
  // Sourced from RegistrationController's health fields, filled in on
  // the (optional) Health step of MemberRegistrationScreen — Obx-wrapped
  // since, unlike the other pages, this data can genuinely still be
  // empty/being filled in when this screen is reached (nothing on that
  // step is required). Unanswered questions render exactly as before:
  // both Yes/No boxes unchecked, blank fields showing 'not_provided'.
  // ============================================================

  Widget _healthDeclarationPage(BuildContext context) {
    return Obx(() => _paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _letterhead(),
          Center(
            child: Text(
              'health_declaration_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _dateMemberNoBox(
            date: AppDatePicker.format(DateTime.now()),
            memberNo: _resolvedMemberNo(),
          ),
          const SizedBox(height: 12),
          Text(
            'health_declaration_intro'.tr,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _yesNoQuestion(
            'health_q_current_illness'.tr,
            controller.hasCurrentIllness.value,
          ),
          if (controller.hasCurrentIllness.value == true)
            _blankDetailField(
              'health_q_current_illness_detail'.tr,
              _localizedValue(
                controller.seriousIllnessLanguages.value,
                controller.seriousIllnessDetailController.text,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'health_q_past_diseases'.tr,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final key in RegistrationController.diseaseKeys)
                _choiceChip(key.tr, controller.selectedDiseaseKeys.contains(key)),
            ],
          ),
          if (controller.selectedDiseaseKeys.contains('disease_hereditary'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _blankDetailField(
                'health_hereditary_detail'.tr,
                _localizedValue(
                  controller.otherHereditaryLanguages.value,
                  controller.otherHereditaryDetailController.text,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _yesNoQuestion(
            'health_q_surgery'.tr,
            controller.hadSurgery.value,
          ),
          if (controller.hadSurgery.value == true) ...[
            _blankDetailField(
              'health_q_surgery_detail'.tr,
              _localizedValue(
                controller.surgeryLanguages.value,
                controller.surgeryDetailController.text,
              ),
            ),
            _blankDetailField(
              'health_q_surgery_date'.tr,
              controller.surgeryDateController.text,
            ),
          ],
          _yesNoQuestion(
            'health_q_medication'.tr,
            controller.onRegularMedication.value,
          ),
          if (controller.onRegularMedication.value == true)
            _blankDetailField(
              'health_q_medication_detail'.tr,
              controller.medicationDetailController.text,
            ),
          _yesNoQuestion(
            'health_q_allergy'.tr,
            controller.hasAllergies.value,
          ),
          if (controller.hasAllergies.value == true)
            _blankDetailField(
              'health_q_allergy_detail'.tr,
              _localizedValue(
                controller.allergyLanguages.value,
                controller.allergyDetailController.text,
              ),
            ),
          _yesNoQuestion('health_q_tobacco'.tr, controller.usesTobacco.value),
          _yesNoQuestion('health_q_alcohol'.tr, controller.consumesAlcohol.value),
          _yesNoQuestion('health_q_drugs'.tr, controller.usesDrugs.value),
          _blankDetailField(
            'health_q_other'.tr,
            _localizedValue(
              controller.otherHealthDetailLanguages.value,
              controller.otherHealthDetailController.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'health_declare_text'.tr,
            style: const TextStyle(fontSize: 11, height: 1.5),
          ),
          _signatureBlock(),
          _pageFooter(3),
        ],
      ),
    ));
  }

  // ============================================================
  // PAGE 4 — UNDERTAKING (JAHER KHABAR)
  // ============================================================

  Widget _declarationPage(BuildContext context) {
    return Obx(() {
      final fullName = _resolvedFullName();

      return _paper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _letterhead(),
            Center(
              child: Text(
                'undertaking_title'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'undertaking_text'.tr,
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  controller.acceptedRules.value
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'agree_terms'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _underlineField('full_name'.tr, fullName),
            _signatureBlock(),
            _pageFooter(4),
          ],
        ),
      );
    });
  }
}

class _NomineeColumn {
  const _NomineeColumn({
    required this.name,
    required this.dob,
    required this.relation,
    required this.share,
    required this.photo,
    this.photoUrl,
  });

  final String name;
  final String dob;
  final String relation;
  final String share;

  /// Set when this nominee's photo was picked THIS session — see
  /// NomineeSlot.photo's own doc comment.
  final File? photo;

  /// Fallback for a resumed nominee whose photo already exists on the
  /// server (so [photo] is null — no local file for it) — see
  /// NomineeSlot.photoUrl. Not guaranteed to be non-null even then; the
  /// API's response shape for this isn't documented (see
  /// NomineeModel.photoUrl's own doc comment).
  final String? photoUrl;
}
