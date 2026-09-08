import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/config/env/env.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/network/exceptions/api_exceptions.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/features/enum_bundle/data/repository/enum_bundle_repository.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/enums/document_module.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/navigation/registration_navigator.dart';
import 'package:psf_application/shared/repo/document_repository.dart';
import 'package:psf_application/shared/repo/language_translation_repository.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/image_picker_util.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/loaders/app_loader_controller.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

import '../../data/models/get_member_status_request_model.dart';
import '../../data/models/health_declaration_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/nominee_model.dart';
import '../../data/models/save_member_personal_detail_request_model.dart';
import '../../data/models/save_member_step1_request_model.dart';
import '../../domain/repositories/health_declaration_repository.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/nominee_repository.dart';

class RegistrationController extends GetxController {
  RegistrationController(
    this._repository,
    this._translationRepository,
    this._documentRepository,
    this._enumBundleRepository,
    this._nomineeRepository,
    this._healthDeclarationRepository,
  );

  final MemberRepository _repository;
  final LanguageTranslationRepository _translationRepository;
  final DocumentRepository _documentRepository;
  final EnumBundleRepository _enumBundleRepository;
  final NomineeRepository _nomineeRepository;
  final HealthDeclarationRepository _healthDeclarationRepository;


  final AppLoaderController _loaderController =
      Get.find<AppLoaderController>();

  StreamSubscription<void>? _reconnectSubscription;

  @override
  void onInit() {
    super.onInit();
    loadEnumOptions();

    // Same reasoning as AuthBannerController: gender/marital-status load
    // automatically with nothing for the user to re-tap, so pick the load
    // back up on its own once the connection returns — only if it never
    // actually finished. Save/Continue flows deliberately do NOT subscribe
    // here; those only ever resume when the user taps the button again.
    _reconnectSubscription =
        Get.find<ConnectivityService>().onReconnected.listen((_) {
      if (genderOptions.value.isEmpty || maritalStatusOptions.value.isEmpty) {
        loadEnumOptions();
      }
    });

    // Wire each nominee slot's own name-translation focus node and
    // running-share-total recompute here (once, for the controller's
    // whole lifetime) rather than in the screen's State — NomineeSlot
    // objects live on this controller, not the widget, and there are up
    // to `maxNominees` of them instead of one.
    for (final slot in nomineeSlots) {
      slot.nameFocusNode.addListener(() {
        if (slot.nameFocusNode.hasFocus) return;
        translateNameFieldOnUnfocus(
          text: slot.nameController.text,
          targetModel: slot.nameLanguages,
          isDirty: slot.isNameDirty,
        );
      });
      slot.shareController.addListener(recomputeTotalShare);
    }
  }


  // ============================================================
  // SELECTED APP LANGUAGE
  // ============================================================

  final Rx<AppLanguage> selectedInputLanguage =
      AppLanguage.english.obs;

  // ============================================================
  // TRANSLATED NAME VALUES
  // ============================================================

  final Rx<LocalizedTextModel> firstNameLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> middleNameLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> surnameLanguages =
      LocalizedTextModel.empty().obs;

  // ============================================================
  // DIRTY FLAGS
  // ============================================================

  final RxBool isFirstNameDirty = true.obs;

  final RxBool isMiddleNameDirty = true.obs;

  final RxBool isSurnameDirty = true.obs;

  // ============================================================
  // TRANSLATED STEP-2 FIELD VALUES (SaveMemberPersonalDetail)
  //
  // Same background-translate-on-blur pattern as first/middle/surname
  // above, reused for every text field that carries h-/g- variants on
  // SaveMemberPersonalDetail.
  // ============================================================

  final Rx<LocalizedTextModel> fatherNameLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> addressLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> villageLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> talukaLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> districtLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> stateLanguages =
      LocalizedTextModel.empty().obs;

  final Rx<LocalizedTextModel> occupationLanguages =
      LocalizedTextModel.empty().obs;

  final RxBool isFatherNameDirty = true.obs;
  final RxBool isAddressDirty = true.obs;
  final RxBool isVillageDirty = true.obs;
  final RxBool isTalukaDirty = true.obs;
  final RxBool isDistrictDirty = true.obs;
  final RxBool isStateDirty = true.obs;
  final RxBool isOccupationDirty = true.obs;

  // ============================================================
  // MEMBER
  // ============================================================

  final Rxn<MemberModel> member =
  Rxn<MemberModel>();

  // ============================================================
  // STEP
  // ============================================================

  final RxInt currentStep = 0.obs;

  // Member (0) / Nominee (1) / Health Declaration (2) / Rules &
  // Declaration (3) — was 3 before the Health step existed.
  static const int totalSteps = 4;

  bool get isLastStep => currentStep.value == totalSteps - 1;

  // ============================================================
  // MEMBER TEXT CONTROLLERS
  // ============================================================

  final fatherNameController =
  TextEditingController();

  final dateOfBirthController =
  TextEditingController();

  final addressController =
  TextEditingController();

  final villageController =
  TextEditingController();

  final talukaController =
  TextEditingController();

  final districtController =
  TextEditingController();

  final stateController =
  TextEditingController();

  final occupationController =
  TextEditingController();

  final aadharNumberController =
  TextEditingController();

  final panNumberController =
  TextEditingController();

  /// Prefilled from whichever API already returned it (Legal Rules /
  /// GetSingleMember), but — unlike the read-only full-name display —
  /// this one stays editable, so the user can correct it before it's sent
  /// as `mobile1` on SaveMemberPersonalDetail.
  final mobileController =
  TextEditingController();

  /// Second/alternate mobile number, sent as `mobile2` on
  /// SaveMemberPersonalDetail. No existing API response returns a value
  /// for this (unlike mobile1), so it's always a plain, always-editable,
  /// optional field — see AppValidators.mobileOptional.
  final mobile2Controller =
  TextEditingController();

  // ============================================================
  // NOMINEE (Nominee step — up to `maxNominees` slots)
  //
  // Replaces the old single-nominee text controllers (first/middle/
  // surname + mobile + Aadhaar/PAN) that existed only because no
  // SaveNominee endpoint was available yet. The real API
  // (SaveNominee/GetNomineeByMemberId/SaveNomineeScreen) collects a much
  // simpler record per nominee — name, relation, date of birth, share,
  // photo — repeated up to 3 times, so nominee state is now a fixed-size
  // list of [NomineeSlot] instead of one flat set of fields.
  // ============================================================

  /// The printed application form (see registration_pdf_builder.dart /
  /// registration_preview_screen.dart) has exactly 3 nominee columns, and
  /// the backend's own SaveNominee/GetNomineeByMemberId shape has no count
  /// limit of its own — 3 is this app's UI limit, matching the form.
  static const int maxNominees = 3;

  /// One slot's worth of state per possible nominee. Fixed-length (never
  /// grows/shrinks) — [visibleNomineeSlots] controls how many of these are
  /// actually shown/used at any point, via the "Add another nominee"
  /// button on the Nominee step.
  final List<NomineeSlot> nomineeSlots =
      List.generate(maxNominees, (_) => NomineeSlot());

  /// How many of [nomineeSlots] are currently shown on the Nominee step.
  /// Starts at 1 (every member must have at least one nominee); revealed
  /// one at a time by [revealNextNomineeSlot], capped at [maxNominees].
  /// Also updated by [loadExistingNominees] when resuming registration
  /// with nominees already saved.
  final RxInt visibleNomineeSlots = 1.obs;

  /// Live nominee-relation options (Father/Mother/Spouse/...), from
  /// GetEnumBundle's `Relation` list — see loadEnumOptions.
  final RxList<EnumItem> relationOptions = <EnumItem>[].obs;

  /// Sum of every currently-visible nominee's share value — recomputed on
  /// every keystroke in any visible slot's share field (see the listener
  /// wired in onInit), and whenever a slot is revealed, removed, or
  /// prefilled. Purely a running total the UI displays; SaveNominee itself
  /// accepts any value, since the backend — not this app — is the source
  /// of truth for whether a member's total allocation is valid.
  final RxDouble totalShareEntered = 0.0.obs;

  /// A member's nominee shares are meant to add up to (at most) 100% of
  /// what they leave behind — see the Nominee step's running-total label.
  /// This app only warns when the total goes OVER 100; it does not yet
  /// require the total to reach exactly 100 before Continue is allowed
  /// (the user described that as a later refinement, not needed now).
  static const double maxTotalShare = 100.0;

  /// Small tolerance for floating-point share entries (e.g. 33.33 x 3).
  static const double _shareTolerance = 0.01;

  bool get shareExceedsLimit =>
      totalShareEntered.value > maxTotalShare + _shareTolerance;

  /// Recalculates [totalShareEntered] from every currently-visible slot's
  /// share field. Slots beyond [visibleNomineeSlots] are ignored even if
  /// they still hold a leftover value from before being removed.
  void recomputeTotalShare() {
    var sum = 0.0;

    for (var i = 0; i < visibleNomineeSlots.value; i++) {
      final text = nomineeSlots[i].shareController.text.trim();
      sum += double.tryParse(text) ?? 0.0;
    }

    totalShareEntered.value = sum;
  }

  // ============================================================
  // DATE
  // ============================================================

  final Rxn<DateTime> dateOfBirth =
  Rxn<DateTime>();

  // Per-nominee date of birth now lives on NomineeSlot.dateOfBirth (see
  // the NOMINEE section above) — one per slot instead of one shared field.

  // ============================================================
  // GENDER / MARITAL STATUS — live from GetEnumBundle, never a
  // hardcoded app-side enum. Selection is stored by the option's real
  // `id` (an int), since that's exactly what SaveMemberPersonalDetail's
  // `gender`/`maritalStatus` fields expect.
  // ============================================================

  final RxList<EnumItem> genderOptions = <EnumItem>[].obs;

  final RxList<EnumItem> maritalStatusOptions = <EnumItem>[].obs;

  final RxBool isLoadingEnumOptions = false.obs;

  final Rxn<int> selectedGenderId = Rxn<int>();

  final Rxn<int> selectedMaritalStatusId = Rxn<int>();

  // ============================================================
  // RULES
  // ============================================================

  final RxBool acceptedRules =
      false.obs;

  // ============================================================
  // HEALTH DECLARATION (SaveMemberHealthDeclaration /
  // GetHealthDeclarationByMemberId)
  //
  // Five yes/no questions each gate their own free-text detail field,
  // shown only once answered "yes" — matches the swagger
  // SaveHealthDeclarationModel exactly: hasCurrentIllness->isSeriousIllness
  // (+seriousIllness detail, translated), the 'disease_hereditary' chip
  // below ->anyHerediatry (+`other` detail, translated — the swagger
  // schema has no separate boolean for this one, the chip selection IS
  // the gate), hadSurgery->isSurgery (+surgery detail + date, translated),
  // onRegularMedication->ismedicationRegularly (+medicationRegularly
  // detail — NOT translated, the swagger schema has no h/g pair for this
  // field), hasAllergies->anyAllergies (+allergies detail, translated).
  // See HealthDeclarationModel's doc comment for the full field mapping.
  // ============================================================

  /// The 13 "have you ever had..." disease keys shown as a fixed
  /// checklist (no attached detail field of their own) on the
  /// health-declaration step, the Preview screen, and the downloaded PDF —
  /// kept in exactly one place so all three stay in sync, and in the same
  /// order as HealthDeclarationModel's matching boolean fields. Each is a
  /// translation key in registration_strings.dart (e.g. 'disease_bp').
  /// 'disease_hereditary' is the one exception with a detail field — see
  /// [otherHereditaryDetailController] below.
  static const List<String> diseaseKeys = [
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

  /// Id of this member's health declaration row — 0/null means "not saved
  /// yet, SaveMemberHealthDeclaration will create one"; a real value
  /// (either already known from a previous save this session, or prefilled
  /// by [loadExistingHealthDeclaration]) means "update this one instead of
  /// creating a duplicate."
  final Rxn<int> healthDeclarationId = Rxn<int>();

  final Rxn<bool> hasCurrentIllness = Rxn<bool>();

  final seriousIllnessDetailController = TextEditingController();

  final Rx<LocalizedTextModel> seriousIllnessLanguages =
      LocalizedTextModel.empty().obs;

  final RxBool isSeriousIllnessDirty = true.obs;

  final RxSet<String> selectedDiseaseKeys = <String>{}.obs;

  /// "Please specify" detail for the 'disease_hereditary' chip — maps to
  /// HealthDeclarationModel's `other`/`hOther`/`gOther`.
  final otherHereditaryDetailController = TextEditingController();

  final Rx<LocalizedTextModel> otherHereditaryLanguages =
      LocalizedTextModel.empty().obs;

  final RxBool isOtherHereditaryDirty = true.obs;

  final Rxn<bool> hadSurgery = Rxn<bool>();

  final surgeryDetailController = TextEditingController();

  final Rx<LocalizedTextModel> surgeryLanguages =
      LocalizedTextModel.empty().obs;

  final RxBool isSurgeryDirty = true.obs;

  final Rxn<DateTime> surgeryDate = Rxn<DateTime>();

  final surgeryDateController = TextEditingController();

  final Rxn<bool> onRegularMedication = Rxn<bool>();

  /// No hi/gu translation is fired for this field — see
  /// HealthDeclarationModel's doc comment: `medicationRegularly` is the
  /// only detail field in the swagger schema with no h/g pair.
  final medicationDetailController = TextEditingController();

  final Rxn<bool> hasAllergies = Rxn<bool>();

  final allergyDetailController = TextEditingController();

  final Rx<LocalizedTextModel> allergyLanguages =
      LocalizedTextModel.empty().obs;

  final RxBool isAllergyDirty = true.obs;

  final Rxn<bool> usesTobacco = Rxn<bool>();

  final Rxn<bool> consumesAlcohol = Rxn<bool>();

  final Rxn<bool> usesDrugs = Rxn<bool>();

  /// Standalone "any other detail" field — always optional, no yes/no
  /// gate (matches HealthDeclarationModel's `otherDetails`, which has no
  /// boolean flag of its own either).
  final otherHealthDetailController = TextEditingController();

  final Rx<LocalizedTextModel> otherHealthDetailLanguages =
      LocalizedTextModel.empty().obs;

  final RxBool isOtherHealthDetailDirty = true.obs;

  void toggleDiseaseKey(String key) {
    if (selectedDiseaseKeys.contains(key)) {
      selectedDiseaseKeys.remove(key);

      // Selecting the hereditary chip off again clears its detail field
      // too, same reasoning as the yes/no gates below — a hidden field
      // should never silently still hold (and submit) a stale value.
      if (key == 'disease_hereditary') {
        otherHereditaryDetailController.clear();
        otherHereditaryLanguages.value = LocalizedTextModel.empty();
        isOtherHereditaryDirty.value = true;
      }
    } else {
      selectedDiseaseKeys.add(key);
    }
  }

  /// Sets [hasCurrentIllness] and, whenever the new answer isn't "yes",
  /// clears the paired detail field — both the visible text and its
  /// translated model — so a value the user already typed while the
  /// answer was "yes" can never still be sitting in the field (and
  /// therefore never still go out in the API payload — see
  /// saveHealthDeclaration) after they switch the answer to "no".
  void setHasCurrentIllness(bool? value) {
    hasCurrentIllness.value = value;
    if (value != true) {
      seriousIllnessDetailController.clear();
      seriousIllnessLanguages.value = LocalizedTextModel.empty();
      isSeriousIllnessDirty.value = true;
    }
  }

  /// Same reasoning as [setHasCurrentIllness], for the surgery yes/no —
  /// also clears the surgery date, since that's the second half of this
  /// question's detail.
  void setHadSurgery(bool? value) {
    hadSurgery.value = value;
    if (value != true) {
      surgeryDetailController.clear();
      surgeryLanguages.value = LocalizedTextModel.empty();
      isSurgeryDirty.value = true;
      surgeryDate.value = null;
      surgeryDateController.clear();
    }
  }

  /// Same reasoning as [setHasCurrentIllness]. medicationRegularly has no
  /// hi/gu translation (see its field's doc comment above), so there's no
  /// language model to reset here.
  void setOnRegularMedication(bool? value) {
    onRegularMedication.value = value;
    if (value != true) {
      medicationDetailController.clear();
    }
  }

  /// Same reasoning as [setHasCurrentIllness].
  void setHasAllergies(bool? value) {
    hasAllergies.value = value;
    if (value != true) {
      allergyDetailController.clear();
      allergyLanguages.value = LocalizedTextModel.empty();
      isAllergyDirty.value = true;
    }
  }

  /// Checks every yes/no question on the Health step and returns the
  /// translation key of the first problem found, or null once everything
  /// required is answered/filled in. Used by [saveHealthDeclaration] to
  /// block Continue with a toast instead of silently saving an incomplete
  /// declaration. Two kinds of problem:
  ///   • the question itself was never answered at all (still null) —
  ///     every yes/no toggle is required, so this always blocks;
  ///   • the question was answered "yes" but its attached detail field
  ///     is empty.
  /// Only the standalone "any other details" field (see
  /// [otherHealthDetailController]) and the 13 fixed disease checkboxes
  /// (including the 'disease_hereditary' chip itself — only its "please
  /// specify" detail is required, once selected) stay optional; they have
  /// no yes/no gate of their own to be "unanswered".
  String? firstMissingHealthDetail() {
    if (hasCurrentIllness.value == null) {
      return 'health_q_current_illness';
    }
    if (hasCurrentIllness.value == true &&
        seriousIllnessDetailController.text.trim().isEmpty) {
      return 'health_q_current_illness_detail';
    }
    if (selectedDiseaseKeys.contains('disease_hereditary') &&
        otherHereditaryDetailController.text.trim().isEmpty) {
      return 'health_hereditary_detail';
    }
    if (hadSurgery.value == null) {
      return 'health_q_surgery';
    }
    if (hadSurgery.value == true &&
        surgeryDetailController.text.trim().isEmpty) {
      return 'health_q_surgery_detail';
    }
    if (hadSurgery.value == true && surgeryDate.value == null) {
      return 'health_q_surgery_date';
    }
    if (onRegularMedication.value == null) {
      return 'health_q_medication';
    }
    if (onRegularMedication.value == true &&
        medicationDetailController.text.trim().isEmpty) {
      return 'health_q_medication_detail';
    }
    if (hasAllergies.value == null) {
      return 'health_q_allergy';
    }
    if (hasAllergies.value == true &&
        allergyDetailController.text.trim().isEmpty) {
      return 'health_q_allergy_detail';
    }
    if (usesTobacco.value == null) {
      return 'health_q_tobacco';
    }
    if (consumesAlcohol.value == null) {
      return 'health_q_alcohol';
    }
    if (usesDrugs.value == null) {
      return 'health_q_drugs';
    }
    return null;
  }

  /// Prefills the Health step from whatever was already saved for this
  /// member — called once when MemberRegistrationScreen opens (same
  /// "GET first, then allow editing/updating" pattern as
  /// [loadExistingNominees]), so a member who saved a declaration, then
  /// closed and reopened the app mid-registration, sees it filled in
  /// instead of blank. Silent on failure besides a debug log — best-effort
  /// prefill, not something that should block the screen from opening.
  Future<void> loadExistingHealthDeclaration() async {
    try {
      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;
      if (memberId <= 0) return;

      final declaration = await _healthDeclarationRepository
          .getHealthDeclarationByMemberId(memberId);

      if (declaration == null) return;

      healthDeclarationId.value = declaration.healthDeclarationId > 0
          ? declaration.healthDeclarationId
          : null;

      hasCurrentIllness.value = declaration.isSeriousIllness;
      seriousIllnessDetailController.text = declaration.seriousIllness;
      seriousIllnessLanguages.value = LocalizedTextModel(
        original: declaration.seriousIllness,
        english: declaration.seriousIllness,
        hindi: declaration.hSeriousIllness,
        gujarati: declaration.gSeriousIllness,
      );
      isSeriousIllnessDirty.value = declaration.seriousIllness.isNotEmpty &&
          (declaration.hSeriousIllness.isEmpty ||
              declaration.gSeriousIllness.isEmpty);

      selectedDiseaseKeys
        ..clear()
        ..addAll([
          if (declaration.heartDisease) 'disease_heart',
          if (declaration.heartAttack) 'disease_heart_attack',
          if (declaration.highBloodPressure) 'disease_bp',
          if (declaration.diabetes) 'disease_diabetes',
          if (declaration.breathingProblem) 'disease_asthma',
          if (declaration.tb) 'disease_tb',
          if (declaration.cancerTumor) 'disease_cancer',
          if (declaration.liverDisease) 'disease_liver_kidney',
          if (declaration.hiv) 'disease_hiv',
          if (declaration.infectiousDiseas) 'disease_other_infectious',
          if (declaration.stroke) 'disease_stroke',
          if (declaration.anxiety) 'disease_mental',
          if (declaration.anyHerediatry) 'disease_hereditary',
        ]);

      otherHereditaryDetailController.text = declaration.other;
      otherHereditaryLanguages.value = LocalizedTextModel(
        original: declaration.other,
        english: declaration.other,
        hindi: declaration.hOther,
        gujarati: declaration.gOther,
      );
      isOtherHereditaryDirty.value = declaration.other.isNotEmpty &&
          (declaration.hOther.isEmpty || declaration.gOther.isEmpty);

      hadSurgery.value = declaration.isSurgery;
      surgeryDetailController.text = declaration.surgery;
      surgeryLanguages.value = LocalizedTextModel(
        original: declaration.surgery,
        english: declaration.surgery,
        hindi: declaration.hSurgery,
        gujarati: declaration.gSurgery,
      );
      isSurgeryDirty.value = declaration.surgery.isNotEmpty &&
          (declaration.hSurgery.isEmpty || declaration.gSurgery.isEmpty);
      surgeryDate.value = declaration.surgeryDate;
      surgeryDateController.text = declaration.surgeryDate != null
          ? AppDatePicker.format(declaration.surgeryDate!)
          : '';

      onRegularMedication.value = declaration.ismedicationRegularly;
      medicationDetailController.text = declaration.medicationRegularly;

      hasAllergies.value = declaration.anyAllergies;
      allergyDetailController.text = declaration.allergies;
      allergyLanguages.value = LocalizedTextModel(
        original: declaration.allergies,
        english: declaration.allergies,
        hindi: declaration.hAllergies,
        gujarati: declaration.gAllergies,
      );
      isAllergyDirty.value = declaration.allergies.isNotEmpty &&
          (declaration.hAllergies.isEmpty || declaration.gAllergies.isEmpty);

      usesTobacco.value = declaration.tabaccoBidiCigarates;
      consumesAlcohol.value = declaration.addictionToAlcohol;
      usesDrugs.value = declaration.drugs;

      otherHealthDetailController.text = declaration.otherDetails;
      otherHealthDetailLanguages.value = LocalizedTextModel(
        original: declaration.otherDetails,
        english: declaration.otherDetails,
        hindi: declaration.hotherDetails,
        gujarati: declaration.gotherDetails,
      );
      isOtherHealthDetailDirty.value = declaration.otherDetails.isNotEmpty &&
          (declaration.hotherDetails.isEmpty ||
              declaration.gotherDetails.isEmpty);
    } catch (e) {
      debugPrint('Failed to load existing health declaration: $e');
    }
  }

  /// Always called on the Health step's Next button — see
  /// MemberRegistrationScreen._next()'s step==2 branch. Blocks (with a
  /// toast) when any yes/no question hasn't been answered, or was
  /// answered "yes" but its detail field is still empty — see
  /// [firstMissingHealthDetail] — and also on a real save failure
  /// (mirrors saveNomineeSlot's reasoning). Only the standalone "any
  /// other details" field and the 13 fixed disease checkboxes stay
  /// optional.
  Future<bool> saveHealthDeclaration() async {
    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;
      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return false;
      }

      final missingDetailKey = firstMissingHealthDetail();
      if (missingDetailKey != null) {
        ToastUtil.error(
          'health_detail_required'.trParams({'label': missingDetailKey.tr}),
        );
        return false;
      }

      final isHereditary = selectedDiseaseKeys.contains('disease_hereditary');

      // Safety net for every visible detail field's hi/gu translation —
      // same reasoning as translateAllStep1Fields/saveNomineeSlot: normally
      // already done by each field's own focus-loss listener (see
      // MemberRegistrationScreen), this just guarantees it's finished
      // before the request is built even if that never fired. Only
      // translates fields that are actually gated "on" right now — a
      // hidden field's stale translation is never sent (see toJson).
      await Future.wait([
        if (hasCurrentIllness.value == true &&
            (isSeriousIllnessDirty.value ||
                needsTranslation(seriousIllnessLanguages.value)))
          translateNameFieldOnUnfocus(
            text: seriousIllnessDetailController.text,
            targetModel: seriousIllnessLanguages,
            isDirty: isSeriousIllnessDirty,
          ),
        if (isHereditary &&
            (isOtherHereditaryDirty.value ||
                needsTranslation(otherHereditaryLanguages.value)))
          translateNameFieldOnUnfocus(
            text: otherHereditaryDetailController.text,
            targetModel: otherHereditaryLanguages,
            isDirty: isOtherHereditaryDirty,
          ),
        if (hadSurgery.value == true &&
            (isSurgeryDirty.value ||
                needsTranslation(surgeryLanguages.value)))
          translateNameFieldOnUnfocus(
            text: surgeryDetailController.text,
            targetModel: surgeryLanguages,
            isDirty: isSurgeryDirty,
          ),
        if (hasAllergies.value == true &&
            (isAllergyDirty.value ||
                needsTranslation(allergyLanguages.value)))
          translateNameFieldOnUnfocus(
            text: allergyDetailController.text,
            targetModel: allergyLanguages,
            isDirty: isAllergyDirty,
          ),
        if (isOtherHealthDetailDirty.value ||
            needsTranslation(otherHealthDetailLanguages.value))
          translateNameFieldOnUnfocus(
            text: otherHealthDetailController.text,
            targetModel: otherHealthDetailLanguages,
            isDirty: isOtherHealthDetailDirty,
          ),
      ]);

      // Every detail field below is read ONLY when its yes/no gate is
      // currently true — otherwise an empty string (null for the surgery
      // date) is sent regardless of what's still sitting in the
      // controller/language model. The setXxx methods above already clear
      // those on toggle-to-"no", but gating here too means a stale value
      // can never reach the API even if some other path changed the
      // gate's Rxn<bool> directly without clearing its detail field.
      final hasIllness = hasCurrentIllness.value == true;
      final hasSurgery = hadSurgery.value == true;
      final hasMedication = onRegularMedication.value == true;
      final hasAllergy = hasAllergies.value == true;

      final request = HealthDeclarationModel(
        healthDeclarationId: healthDeclarationId.value ?? 0,
        memberId: memberId,
        isSeriousIllness: hasCurrentIllness.value ?? false,
        seriousIllness:
            hasIllness ? seriousIllnessDetailController.text.trim() : '',
        hSeriousIllness: hasIllness ? seriousIllnessLanguages.value.hindi : '',
        gSeriousIllness:
            hasIllness ? seriousIllnessLanguages.value.gujarati : '',
        heartDisease: selectedDiseaseKeys.contains('disease_heart'),
        heartAttack: selectedDiseaseKeys.contains('disease_heart_attack'),
        highBloodPressure: selectedDiseaseKeys.contains('disease_bp'),
        diabetes: selectedDiseaseKeys.contains('disease_diabetes'),
        breathingProblem: selectedDiseaseKeys.contains('disease_asthma'),
        tb: selectedDiseaseKeys.contains('disease_tb'),
        cancerTumor: selectedDiseaseKeys.contains('disease_cancer'),
        liverDisease: selectedDiseaseKeys.contains('disease_liver_kidney'),
        hiv: selectedDiseaseKeys.contains('disease_hiv'),
        infectiousDiseas:
            selectedDiseaseKeys.contains('disease_other_infectious'),
        stroke: selectedDiseaseKeys.contains('disease_stroke'),
        anxiety: selectedDiseaseKeys.contains('disease_mental'),
        anyHerediatry: isHereditary,
        other: isHereditary ? otherHereditaryDetailController.text.trim() : '',
        hOther: isHereditary ? otherHereditaryLanguages.value.hindi : '',
        gOther: isHereditary ? otherHereditaryLanguages.value.gujarati : '',
        isSurgery: hadSurgery.value ?? false,
        surgery: hasSurgery ? surgeryDetailController.text.trim() : '',
        hSurgery: hasSurgery ? surgeryLanguages.value.hindi : '',
        gSurgery: hasSurgery ? surgeryLanguages.value.gujarati : '',
        surgeryDate: hasSurgery ? surgeryDate.value : null,
        ismedicationRegularly: onRegularMedication.value ?? false,
        medicationRegularly:
            hasMedication ? medicationDetailController.text.trim() : '',
        anyAllergies: hasAllergies.value ?? false,
        allergies: hasAllergy ? allergyDetailController.text.trim() : '',
        hAllergies: hasAllergy ? allergyLanguages.value.hindi : '',
        gAllergies: hasAllergy ? allergyLanguages.value.gujarati : '',
        tabaccoBidiCigarates: usesTobacco.value ?? false,
        addictionToAlcohol: consumesAlcohol.value ?? false,
        drugs: usesDrugs.value ?? false,
        otherDetails: otherHealthDetailController.text.trim(),
        hotherDetails: otherHealthDetailLanguages.value.hindi,
        gotherDetails: otherHealthDetailLanguages.value.gujarati,
      );

      final saved =
          await _healthDeclarationRepository.saveHealthDeclaration(request);

      if (saved.healthDeclarationId > 0) {
        healthDeclarationId.value = saved.healthDeclarationId;
      }

      return true;
    } catch (e) {
      if (isNetworkInterruption(e)) return false;
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // IMAGES
  // ============================================================

  final Rxn<File> profileImage =
  Rxn<File>();

  final Rxn<File> aadharImage =
  Rxn<File>();

  final Rxn<File> panImage =
  Rxn<File>();

  /// Aadhaar BACK photo — added alongside SaveMemberPersonalDetail's new
  /// `aadharBackImage` field (`aadharImage` above is the front).
  final Rxn<File> aadharBackImage =
  Rxn<File>();

  // Per-nominee photo (+ its uploaded document id) now lives on
  // NomineeSlot.photo / NomineeSlot.photoDocumentId — see the NOMINEE
  // section above. The old nominee Aadhaar/PAN photo fields are gone
  // entirely: the real SaveNominee API has no fields for them.

  final Rxn<File> signatureFile =
  Rxn<File>();

  // ============================================================
  // UPLOADED DOCUMENT IDS
  //
  // Populated by uploadStep1Documents() right before
  // saveMemberPersonalDetail() — SaveDocument is always called first to
  // get these ids, which then get sent (not the raw files) on the save
  // call. Each nominee's photo is uploaded the same way, but per-slot
  // (see NomineeSlot.photoDocumentId / saveNominee below) since there can
  // be up to `maxNominees` of them, not one fixed field.
  //
  // Also populated by getMemberStatus() when the member already uploaded
  // these in an earlier session (from MemberModel.image / .aadharImage /
  // .aadharBackImage / .panImage / .digitalSign) — that's what lets
  // uploadStep1Documents() skip re-uploading on resume; see there.
  // ============================================================

  final Rxn<int> profileImageId = Rxn<int>();

  final Rxn<int> aadharImageId = Rxn<int>();

  final Rxn<int> aadharBackImageId = Rxn<int>();

  final Rxn<int> panImageId = Rxn<int>();

  final Rxn<int> signatureFileId = Rxn<int>();

  // ============================================================
  // BEST-EFFORT DOCUMENT URLS (for resumed-registration previews)
  //
  // Populated by getMemberStatus() from MemberModel.imageUrl / etc. — a
  // best-effort, multi-key-fallback parse of GetSingleMemberByRegistredStatus's
  // response (see MemberModel's doc comment). `null` whenever the response
  // doesn't include a recognizable URL field, which is the expected case
  // until the backend documents one; the upload tiles simply fall back to
  // "tap to upload" when both the File and the Url are null.
  // ============================================================

  final Rxn<String> profileImageUrl = Rxn<String>();

  final Rxn<String> aadharImageUrl = Rxn<String>();

  final Rxn<String> aadharBackImageUrl = Rxn<String>();

  final Rxn<String> panImageUrl = Rxn<String>();

  final Rxn<String> signatureFileUrl = Rxn<String>();

  // ============================================================
  // ENUM BUNDLE (GENDER / MARITAL STATUS)
  // ============================================================

  Future<void> loadEnumOptions() async {
    try {
      isLoadingEnumOptions.value = true;

      final bundle = await _enumBundleRepository.getEnumBundle();

      genderOptions.value = bundle.gender;
      maritalStatusOptions.value = bundle.maritalStatus;
      relationOptions.value = bundle.relation;
    } catch (e) {
      debugPrint('Failed to load enum bundle: $e');

      if (!isNetworkInterruption(e)) {
        ToastUtil.error(
          'could_not_load_gender_marital_status_options'.tr,
        );
      }
    } finally {
      isLoadingEnumOptions.value = false;
    }
  }

  // ============================================================
  // UNFOCUS TRANSLATION LOGIC
  // ============================================================

  Future<void> translateNameFieldOnUnfocus({
    required String text,
    required Rx<LocalizedTextModel> targetModel,
    required RxBool isDirty,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      targetModel.value = LocalizedTextModel.empty();
      isDirty.value = false;
      return;
    }

    if (!isDirty.value && targetModel.value.original == trimmed) {
      return;
    }

    try {
      final localizedModel = await _translationRepository.translateAllScripts(
        text: trimmed,
      );
      targetModel.value = localizedModel;
      isDirty.value = false;
    } catch (e) {
      // Leave isDirty at true so the Continue-button safety net
      // (see register_screen._continue) retries this field instead of
      // silently sending an incomplete/untranslated value. A connectivity
      // drop is already surfaced by the app-wide no-internet dialog, so
      // only show a toast for a real API/service failure.
      debugPrint('Translation error on unfocus: $e');

      if (!isNetworkInterruption(e)) {
        ToastUtil.error(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  // ============================================================
  // NEEDS TRANSLATION CHECK
  // ============================================================

  /// Returns true when the model has a non-empty [original] value but
  /// at least one language string (english / hindi / gujarati) is still
  /// empty, meaning the translation API must be called.
  ///
  /// Returns false when:
  ///   • [original] is empty  (nothing to translate)
  ///   • all three language fields are already populated
  bool needsTranslation(LocalizedTextModel model) {
    if (model.original.isEmpty) return false;
    return model.english.isEmpty ||
        model.hindi.isEmpty ||
        model.gujarati.isEmpty;
  }

  /// Save-time guard: returns a human-readable label for the first name
  /// field whose hi/gu/en variants are still incomplete (its background
  /// translation never finished — usually because it failed), or `null`
  /// when every field is ready to submit. The caller should block the
  /// save and show an error instead of sending duplicated/original text
  /// as a stand-in for a missing translation.
  // NOTE: returns a translation KEY (not display text) — the caller
  // resolves it via .tr in the user's currently-selected language when
  // building the toast message, instead of this ever showing raw
  // hardcoded English regardless of language.
  String? firstIncompleteNameField() {
    if (needsTranslation(firstNameLanguages.value)) return 'first_name';
    if (needsTranslation(middleNameLanguages.value)) return 'middle_name';
    if (needsTranslation(surnameLanguages.value)) return 'surname';
    return null;
  }

  /// Same save-time guard as [firstIncompleteNameField], for the extra
  /// text fields SaveMemberPersonalDetail needs translated (father name +
  /// address block), plus first/middle/surname themselves — the Member
  /// step's full-name field is now editable (see
  /// [splitAndTranslateFullName]), so an edited name's translation can
  /// still be mid-flight (or have failed) by the time Save is tapped, the
  /// same way any other field here can.
  // Also returns a translation KEY — see firstIncompleteNameField's note.
  String? firstIncompleteStep1Field() {
    final incompleteName = firstIncompleteNameField();
    if (incompleteName != null) return incompleteName;
    if (needsTranslation(fatherNameLanguages.value)) return 'father_name';
    if (needsTranslation(addressLanguages.value)) return 'address';
    if (needsTranslation(villageLanguages.value)) return 'village';
    if (needsTranslation(talukaLanguages.value)) return 'taluka';
    if (needsTranslation(districtLanguages.value)) return 'district';
    if (needsTranslation(stateLanguages.value)) return 'state';
    if (needsTranslation(occupationLanguages.value)) return 'occupation';
    return null;
  }

  /// Seeds [target] from a resumed member's plain + hi/gu server values, in
  /// place — used by [getMemberStatus]'s prefill. Skips entirely when
  /// [original] wasn't returned (null/empty), so a confirmatory re-check
  /// that comes back without a later step's data (e.g. right after
  /// SaveMemberStep1, before address/village/etc. have ever been saved)
  /// can't stomp on whatever the member is mid-typing this session. When
  /// [original] IS present but a hi/gu variant isn't, that language falls
  /// back to [original] — same rule _localizedValue itself uses — so the
  /// preview never shows blank instead of at least the plain text.
  void _seedLanguagesIfPresent(
    Rx<LocalizedTextModel> target,
    String? original,
    String? hindi,
    String? gujarati,
  ) {
    if (original == null || original.trim().isEmpty) return;

    target.value = LocalizedTextModel(
      original: original,
      english: original,
      hindi: (hindi != null && hindi.trim().isNotEmpty) ? hindi : original,
      gujarati:
          (gujarati != null && gujarati.trim().isNotEmpty) ? gujarati : original,
    );
  }

  /// Runs translateNameFieldOnUnfocus for every step-2 field that's dirty
  /// or still incomplete, in parallel — mirrors register_screen._continue's
  /// pre-save translation batch.
  Future<void> translateAllStep1Fields() async {
    await Future.wait([
      if (needsTranslation(fatherNameLanguages.value) || isFatherNameDirty.value)
        translateNameFieldOnUnfocus(
          text: fatherNameController.text,
          targetModel: fatherNameLanguages,
          isDirty: isFatherNameDirty,
        ),
      if (needsTranslation(addressLanguages.value) || isAddressDirty.value)
        translateNameFieldOnUnfocus(
          text: addressController.text,
          targetModel: addressLanguages,
          isDirty: isAddressDirty,
        ),
      if (needsTranslation(villageLanguages.value) || isVillageDirty.value)
        translateNameFieldOnUnfocus(
          text: villageController.text,
          targetModel: villageLanguages,
          isDirty: isVillageDirty,
        ),
      if (needsTranslation(talukaLanguages.value) || isTalukaDirty.value)
        translateNameFieldOnUnfocus(
          text: talukaController.text,
          targetModel: talukaLanguages,
          isDirty: isTalukaDirty,
        ),
      if (needsTranslation(districtLanguages.value) || isDistrictDirty.value)
        translateNameFieldOnUnfocus(
          text: districtController.text,
          targetModel: districtLanguages,
          isDirty: isDistrictDirty,
        ),
      if (needsTranslation(stateLanguages.value) || isStateDirty.value)
        translateNameFieldOnUnfocus(
          text: stateController.text,
          targetModel: stateLanguages,
          isDirty: isStateDirty,
        ),
      if (needsTranslation(occupationLanguages.value) || isOccupationDirty.value)
        translateNameFieldOnUnfocus(
          text: occupationController.text,
          targetModel: occupationLanguages,
          isDirty: isOccupationDirty,
        ),
    ]);
  }

  // ============================================================
  // FULL NAME EDIT (Member step's editable "First Middle Surname" field)
  // ============================================================

  /// Splits an already-format-valid full name into [firstName, middleName,
  /// surname]. Only ever called on text AppValidators.fullName has already
  /// accepted (see [splitAndTranslateFullName]), so this doesn't re-check
  /// format itself. Two words -> no middle name, matching MemberModel.
  /// fullName's own join (which skips an empty middle part); three or
  /// more words -> the first word is the first name, the last word is the
  /// surname, and everything in between (rejoined with single spaces) is
  /// the middle name.
  List<String> _splitFullName(String raw) {
    final words = raw.trim().split(RegExp(r'\s+'));

    if (words.length == 2) {
      return [words[0], '', words[1]];
    }

    return [
      words.first,
      words.sublist(1, words.length - 1).join(' '),
      words.last,
    ];
  }

  /// Called when the Member step's full-name field loses focus, and again
  /// (awaited) right before Save — see
  /// MemberRegistrationScreen._next()'s step==0 branch — this splits the
  /// currently-edited full name into first/middle/surname and re-runs each
  /// part through the same hi/gu transliteration flow as every other
  /// step-1 field, updating [firstNameLanguages]/[middleNameLanguages]/
  /// [surnameLanguages] so [saveMemberPersonalDetail] automatically sends
  /// the newly translated values with no further changes needed there.
  ///
  /// A no-op for text that isn't a validly-formatted full name yet — the
  /// field's own validator (AppValidators.fullName) already shows an
  /// inline error for that, so nothing needs to be split or sent anywhere
  /// until it's fixed. Safe to call repeatedly with unchanged text:
  /// splitting itself does no network work, and translateNameFieldOnUnfocus
  /// already skips re-calling the API when a given part's text hasn't
  /// actually changed since it was last translated.
  Future<void> splitAndTranslateFullName(String rawFullName) async {
    if (AppValidators.fullName(rawFullName) != null) return;

    final parts = _splitFullName(rawFullName);

    await Future.wait([
      translateNameFieldOnUnfocus(
        text: parts[0],
        targetModel: firstNameLanguages,
        isDirty: isFirstNameDirty,
      ),
      translateNameFieldOnUnfocus(
        text: parts[1],
        targetModel: middleNameLanguages,
        isDirty: isMiddleNameDirty,
      ),
      translateNameFieldOnUnfocus(
        text: parts[2],
        targetModel: surnameLanguages,
        isDirty: isSurnameDirty,
      ),
    ]);
  }

  // ============================================================
  // SAVE MEMBER STEP 1
  // ============================================================

  Future<bool> saveMemberStep1({
    required String mobile,
  }) async {
    try {
      _loaderController.show();

      final first =
          firstNameLanguages.value;

      final middle =
          middleNameLanguages.value;

      final surname =
          surnameLanguages.value;

      final request =
      SaveMemberStep1RequestModel(
        // ENGLISH
        firstName: first.english.isNotEmpty ? first.english : first.original,
        lastName: middle.english.isNotEmpty ? middle.english : middle.original,
        surname: surname.english.isNotEmpty ? surname.english : surname.original,

        // GUJARATI
        gFirstName: first.gujarati.isNotEmpty ? first.gujarati : first.original,
        gLastName: middle.gujarati.isNotEmpty ? middle.gujarati : middle.original,
        gSurname: surname.gujarati.isNotEmpty ? surname.gujarati : surname.original,

        // HINDI
        hFirstName: first.hindi.isNotEmpty ? first.hindi : first.original,
        hLastName: middle.hindi.isNotEmpty ? middle.hindi : middle.original,
        hSurname: surname.hindi.isNotEmpty ? surname.hindi : surname.original,

        mobile: mobile.trim(),
      );

      final result =
      await _repository.saveMemberStep1(
        request,
      );

      // SaveMemberStep1's response only carries the new memberId and the
      // resumable route — it doesn't echo back first/middle/surname, so
      // MemberModel.fromJson parses those as null from this response.
      // Without patching them back in here, the step-1 screen's read-only
      // Full Name field would show blank immediately after a fresh
      // registration, even though the name was literally just entered
      // and submitted in this same request. Reuse the exact strings the
      // request itself was built with, rather than recomputing them.
      member.value = result.copyWith(
        firstName: request.firstName,
        lastName: request.lastName,
        surname: request.surname,
        mobile: request.mobile,
      );

      // Same "the response doesn't echo this back" gap as the name fields
      // above — seed step 1's read-only Mobile Number field from the exact
      // string this request was just submitted with, so it's already
      // showing correctly the moment the member reaches step 1 (whether or
      // not SaveRulesRegulationScreen's own response — see
      // saveRulesAcceptance — also happens to carry it).
      mobileController.text = request.mobile;

      await AppSecureStorage.saveMemberId(
        result.memberId,
      );

      // Store the actual resumable route the backend returned (e.g.
      // "/legal-rules"), consistent with getMemberStatus — the literal
      // string "Screen 1" here previously wasn't a real route at all.
      if (result.memberDetailStatusName != null &&
          result.memberDetailStatusName!.isNotEmpty) {
        await AppPrefs.setRegistrationStatus(
          result.memberDetailStatusName!,
        );
      }

      return true;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return false;
      }
      ToastUtil.error(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );

      return false;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // DOCUMENT UPLOAD (SaveDocument)
  //
  // One common function used for every document type — the caller only
  // supplies which file and which module id. Uploads immediately; the
  // caller shows its own loader/toast around the whole batch (see
  // uploadStep1Documents) so 4 sequential uploads don't flash 4 separate
  // loaders.
  // ============================================================

  Future<int?> uploadDocument({
    required File file,
    required int module,
  }) async {
    try {
      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      return await _documentRepository.saveDocument(
        filePath: file.path,
        createdBy: memberId,
        module: module,
        platform: DocumentPlatform.memberMobile,
      );
    } catch (e) {
      debugPrint('Document upload error: $e');

      if (!isNetworkInterruption(e)) {
        ToastUtil.error(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }

      return null;
    }
  }

  /// Uploads every step-1 document (profile photo, Aadhaar front/back, PAN,
  /// signature) and stores the returned ids. Returns false — with an error
  /// already shown — the moment any required document is missing or fails
  /// to upload, so the caller can stop before calling
  /// SaveMemberPersonalDetail with a missing id.
  ///
  /// A document already has an id (from getMemberStatus() prefilling a
  /// resumed member's earlier upload) is treated the same as one just
  /// uploaded here — its `File` stays null and nothing is re-uploaded, so
  /// a returning member isn't forced to redo photos that already
  /// succeeded. Only a document with neither a fresh File nor an existing
  /// id blocks the save.
  Future<bool> uploadStep1Documents() async {
    if (profileImage.value == null && profileImageId.value == null) {
      ToastUtil.error('please_upload_profile_photo'.tr);
      return false;
    }

    if (aadharImage.value == null && aadharImageId.value == null) {
      ToastUtil.error('please_upload_aadhaar_photo'.tr);
      return false;
    }

    if (aadharBackImage.value == null && aadharBackImageId.value == null) {
      ToastUtil.error('please_upload_aadhaar_back_photo'.tr);
      return false;
    }

    if (panImage.value == null && panImageId.value == null) {
      ToastUtil.error('please_upload_pan_photo'.tr);
      return false;
    }

    if (signatureFile.value == null && signatureFileId.value == null) {
      ToastUtil.error('please_enter_your_signature'.tr);
      return false;
    }

    if (profileImage.value != null) {
      final newProfileImageId = await uploadDocument(
        file: profileImage.value!,
        module: DocumentModule.memberProfile,
      );
      if (newProfileImageId == null) return false;
      profileImageId.value = newProfileImageId;
    }

    if (aadharImage.value != null) {
      final newAadharImageId = await uploadDocument(
        file: aadharImage.value!,
        module: DocumentModule.memberAadhar,
      );
      if (newAadharImageId == null) return false;
      aadharImageId.value = newAadharImageId;
    }

    if (aadharBackImage.value != null) {
      final newAadharBackImageId = await uploadDocument(
        file: aadharBackImage.value!,
        module: DocumentModule.memberAadharBack,
      );
      if (newAadharBackImageId == null) return false;
      aadharBackImageId.value = newAadharBackImageId;
    }

    if (panImage.value != null) {
      final newPanImageId = await uploadDocument(
        file: panImage.value!,
        module: DocumentModule.memberPan,
      );
      if (newPanImageId == null) return false;
      panImageId.value = newPanImageId;
    }

    if (signatureFile.value != null) {
      final newSignatureFileId = await uploadDocument(
        file: signatureFile.value!,
        module: DocumentModule.memberESign,
      );
      if (newSignatureFileId == null) return false;
      signatureFileId.value = newSignatureFileId;
    }

    return true;
  }

  // ============================================================
  // SAVE MEMBER PERSONAL DETAIL (Step 2)
  //
  // Flow, exactly as requested: upload every document first (getting back
  // document ids), THEN call SaveMemberPersonalDetail with those ids.
  // ============================================================

  Future<bool> saveMemberPersonalDetail() async {
    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return false;
      }

      if (selectedGenderId.value == null) {
        ToastUtil.error('please_select_gender'.tr);
        return false;
      }

      if (selectedMaritalStatusId.value == null) {
        ToastUtil.error('please_select_marital_status'.tr);
        return false;
      }

      final resolvedDateOfBirth = _resolvedDateOfBirth();

      if (resolvedDateOfBirth == null) {
        ToastUtil.error('please_select_valid_dob'.tr);
        return false;
      }

      // 1. Documents first. Was commented out while SaveDocument was
      // rejecting large (often uncompressed-PNG) photos with a generic
      // "Invalid request." — re-enabled now that ImagePickerUtil always
      // compresses to a small JPEG before handing a file back (see its
      // _compressImage), which removes the oversized-upload cause. If
      // SaveDocument still fails for a different reason, this is the
      // block to re-comment while that gets diagnosed.
      final documentsUploaded = await uploadStep1Documents();
      if (!documentsUploaded) {
        return false;
      }

      // 2. Own name (already translated/saved in step 1 — reused here
      // since SaveMemberPersonalDetail's schema re-sends it).
      final first = firstNameLanguages.value;
      final middle = middleNameLanguages.value;
      final surname = surnameLanguages.value;

      // 3. Father name / address block.
      final father = fatherNameLanguages.value;
      final address = addressLanguages.value;
      final village = villageLanguages.value;
      final taluka = talukaLanguages.value;
      final district = districtLanguages.value;
      final state = stateLanguages.value;
      final occupation = occupationLanguages.value;

      String pick(LocalizedTextModel m, String Function(LocalizedTextModel) f) {
        final value = f(m);
        return value.isNotEmpty ? value : m.original;
      }

      final request = SaveMemberPersonalDetailRequestModel(
        memberId: memberId,

        firstName: pick(first, (m) => m.english),
        lastName: pick(middle, (m) => m.english),
        surname: pick(surname, (m) => m.english),
        gFirstName: pick(first, (m) => m.gujarati),
        gLastName: pick(middle, (m) => m.gujarati),
        gSurname: pick(surname, (m) => m.gujarati),
        hFirstName: pick(first, (m) => m.hindi),
        hLastName: pick(middle, (m) => m.hindi),
        hSurname: pick(surname, (m) => m.hindi),

        fatherName: pick(father, (m) => m.english),
        hFatherName: pick(father, (m) => m.hindi),
        gFatherName: pick(father, (m) => m.gujarati),

        image: profileImageId.value ?? 0,

        dateOfBirth: resolvedDateOfBirth.toIso8601String(),

        gender: selectedGenderId.value!,
        maritalStatus: selectedMaritalStatusId.value!,

        address: pick(address, (m) => m.english),
        hAddress: pick(address, (m) => m.hindi),
        gAddress: pick(address, (m) => m.gujarati),

        village: pick(village, (m) => m.english),
        hVillage: pick(village, (m) => m.hindi),
        gVillage: pick(village, (m) => m.gujarati),

        taluka: pick(taluka, (m) => m.english),
        hTaluka: pick(taluka, (m) => m.hindi),
        gTaluka: pick(taluka, (m) => m.gujarati),

        district: pick(district, (m) => m.english),
        hDistrict: pick(district, (m) => m.hindi),
        gDistrict: pick(district, (m) => m.gujarati),

        state: pick(state, (m) => m.english),
        hState: pick(state, (m) => m.hindi),
        gState: pick(state, (m) => m.gujarati),

        mobile1: mobileController.text.trim(),
        mobile2: mobile2Controller.text.trim(),

        occupation: pick(occupation, (m) => m.english),
        hOccupation: pick(occupation, (m) => m.hindi),
        gOccupation: pick(occupation, (m) => m.gujarati),

        // The field displays this grouped into 4-4-4 blocks with spaces
        // (see AppValidators.formatAadhar / _AadharInputFormatter) — strip
        // that back out to the plain 12-digit string the API expects.
        aadharNo: AppValidators.stripAadharFormatting(
          aadharNumberController.text.trim(),
        ),
        aadharImage: aadharImageId.value ?? 0,
        aadharBackImage: aadharBackImageId.value ?? 0,

        panNo: panNumberController.text.trim().toUpperCase(),
        panImage: panImageId.value ?? 0,

        digitalSign: signatureFileId.value ?? 0,
      );

      final nextRoute = await _repository.saveMemberPersonalDetail(request);

      if (nextRoute != null && nextRoute.isNotEmpty) {
        await AppPrefs.setRegistrationStatus(nextRoute);
      }

      return true;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return false;
      }
      ToastUtil.error(
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // NOMINEE STEP (SaveNominee / GetNomineeByMemberId / SaveNomineeScreen)
  // ============================================================

  /// Blanks every field on [slot] — shared by [revealNextNomineeSlot] (so a
  /// freshly-revealed card can never show stale data left over from an
  /// earlier type-then-remove cycle this session) and
  /// [removeLastNomineeSlot] (so a removed card comes back blank if
  /// revealed again). Never called on a slot that's already [NomineeSlot.
  /// isSaved] — that data came from SaveNominee or GetNomineeByMemberId and
  /// is real, not stale.
  void _clearNomineeSlot(NomineeSlot slot) {
    slot.nameController.clear();
    slot.shareController.clear();
    slot.dateOfBirthController.clear();
    slot.dateOfBirth.value = null;
    slot.relationId.value = null;
    slot.aadharNoController.clear();
    slot.photo.value = null;
    slot.photoDocumentId.value = null;
    slot.photoUrl.value = null;
    slot.aadharFrontImage.value = null;
    slot.aadharFrontImageDocumentId.value = null;
    slot.aadharFrontImageUrl.value = null;
    slot.aadharBackImage.value = null;
    slot.aadharBackImageDocumentId.value = null;
    slot.aadharBackImageUrl.value = null;
    slot.passbookChequeImage.value = null;
    slot.passbookChequeImageDocumentId.value = null;
    slot.passbookChequeImageUrl.value = null;
    slot.nomineeId.value = null;
    slot.nameLanguages.value = LocalizedTextModel.empty();
    slot.isNameDirty.value = true;
  }

  /// Reveals the next hidden nominee slot (up to [maxNominees]) — called
  /// after the currently-last-visible slot has been saved successfully via
  /// [saveNomineeSlot]. No-op once every slot is already visible.
  ///
  /// Every [NomineeSlot] in [nomineeSlots] is a fixed, reused object (see
  /// its own doc comment) rather than a fresh one per reveal, so a slot
  /// that was typed into, then removed via [removeLastNomineeSlot], then
  /// revealed again later in the same session, is the SAME slot object
  /// coming back. [removeLastNomineeSlot] already blanks it before hiding
  /// it, but this clears it again here too — defensively, and only while
  /// it isn't [NomineeSlot.isSaved] — so a freshly-revealed card is
  /// guaranteed blank no matter how it got into view, instead of ever
  /// showing another nominee's leftover data.
  void revealNextNomineeSlot() {
    if (visibleNomineeSlots.value < maxNominees) {
      visibleNomineeSlots.value++;

      final revealedSlot = nomineeSlots[visibleNomineeSlots.value - 1];

      if (!revealedSlot.isSaved.value) {
        _clearNomineeSlot(revealedSlot);
      }

      recomputeTotalShare();
    }
  }

  /// Undoes the "Add another nominee" that revealed the currently-last
  /// slot — the Nominee step's per-card remove ("×") button. Only ever
  /// offered by the UI for the last visible slot, and only while that
  /// slot has never been saved (see [NomineeSlot.isSaved]): once a slot
  /// has gone through SaveNominee — this session, or in an earlier one via
  /// GetNomineeByMemberId's prefill — the member can only edit or clear
  /// its fields, never remove the card outright, so there's always a
  /// record on the server matching what's on screen. The mandatory first
  /// nominee (index 0) can never be removed either way.
  ///
  /// Clears the slot's fields so it comes back blank if revealed again,
  /// rather than showing stale data.
  void removeLastNomineeSlot() {
    if (visibleNomineeSlots.value <= 1) return;

    final lastIndex = visibleNomineeSlots.value - 1;
    final slot = nomineeSlots[lastIndex];

    if (slot.isSaved.value) return;

    _clearNomineeSlot(slot);

    visibleNomineeSlots.value = lastIndex;
    recomputeTotalShare();
  }

  /// Same "picked value first, fall back to parsing the displayed
  /// dd/MM/yyyy text" logic as [_resolvedDateOfBirth], for one nominee
  /// slot — needed so a date prefilled from GetNomineeByMemberId (which
  /// only sets the text controller, not the DateTime, until the user taps
  /// the field) still resolves correctly on save.
  DateTime? _resolvedNomineeDateOfBirth(NomineeSlot slot) {
    if (slot.dateOfBirth.value != null) {
      return slot.dateOfBirth.value;
    }

    final text = slot.dateOfBirthController.text.trim();
    if (text.isEmpty) {
      return null;
    }

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return null;
    }
  }

  /// Saves one nominee slot via `SaveNominee`: uploads its photo first
  /// (only if a new one was picked — a slot prefilled from
  /// [loadExistingNominees] that isn't being re-photographed already has a
  /// [NomineeSlot.photoDocumentId] and skips this), then submits the
  /// slot's fields. `nomineeId` is 0 for a brand-new nominee or the
  /// existing id for one being edited/re-saved — same create-vs-update
  /// convention as everywhere else on this API. Shows its own error
  /// toasts and returns false on any failure, so the caller (the "Add
  /// another nominee" button, or Next on the last slot) can simply stop.
  Future<bool> saveNomineeSlot(int slotIndex) async {
    final slot = nomineeSlots[slotIndex];

    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return false;
      }

      if (slot.photo.value == null && slot.photoDocumentId.value == null) {
        ToastUtil.error('please_upload_nominee_photo'.tr);
        return false;
      }

      if (slot.relationId.value == null) {
        ToastUtil.error(
          'please_select_option'.trParams({'label': 'relationship'.tr}),
        );
        return false;
      }

      // Nominee document uploads — previously optional, now required the
      // same way step 1's Aadhaar/PAN uploads are: the member can't
      // proceed to the next step without all three, matching every other
      // required-upload check on this screen (see uploadStep1Documents).
      if (slot.aadharFrontImage.value == null &&
          slot.aadharFrontImageDocumentId.value == null) {
        ToastUtil.error('please_upload_nominee_aadhaar_front_photo'.tr);
        return false;
      }

      if (slot.aadharBackImage.value == null &&
          slot.aadharBackImageDocumentId.value == null) {
        ToastUtil.error('please_upload_nominee_aadhaar_back_photo'.tr);
        return false;
      }

      if (slot.passbookChequeImage.value == null &&
          slot.passbookChequeImageDocumentId.value == null) {
        ToastUtil.error('please_upload_nominee_passbook_cheque_photo'.tr);
        return false;
      }

      // The API defines aadharNo as optional (see NomineeModel.aadharNo),
      // but the screen now requires every nominee field, so this is
      // checked with AppValidators.aadhar (required) instead of the
      // aadharOptional variant used before — matches the screen's own
      // validator on this field.
      final aadharError = AppValidators.aadhar(
        slot.aadharNoController.text,
      );
      if (aadharError != null) {
        ToastUtil.error(aadharError);
        return false;
      }

      final resolvedDateOfBirth = _resolvedNomineeDateOfBirth(slot);

      if (resolvedDateOfBirth == null) {
        ToastUtil.error('please_select_valid_dob'.tr);
        return false;
      }

      // Now required on this screen, same as every other nominee field —
      // matches the share field's own validator.
      if (slot.shareController.text.trim().isEmpty) {
        ToastUtil.error('please_enter_nominee_share'.tr);
        return false;
      }

      // Nominee shares aren't required to hit exactly 100% (see
      // shareExceedsLimit's doc comment), but going OVER it is always
      // wrong — block the save instead of sending it.
      recomputeTotalShare();

      if (shareExceedsLimit) {
        ToastUtil.error(
          'nominee_share_exceeds_limit'.trParams({
            'total': _formatShare(totalShareEntered.value),
          }),
        );
        return false;
      }

      var photoId = slot.photoDocumentId.value;

      if (slot.photo.value != null) {
        final uploadedId = await uploadDocument(
          file: slot.photo.value!,
          module: DocumentModule.nomineeProfile,
        );

        if (uploadedId == null) return false;

        photoId = uploadedId;
        slot.photoDocumentId.value = uploadedId;
      }

      // Same "upload only if a new File was picked, otherwise keep
      // whatever document id this slot already has" pattern as the photo
      // above. All three are now required (checked above, before this
      // point is reached) — this null-id fallback only matters for a
      // slot prefilled from an earlier session that already has an id
      // and isn't being re-photographed, so a null id (never
      // uploaded) is simply sent as 0.
      var aadharFrontImageId = slot.aadharFrontImageDocumentId.value;
      if (slot.aadharFrontImage.value != null) {
        final uploadedId = await uploadDocument(
          file: slot.aadharFrontImage.value!,
          module: DocumentModule.nomineeAadharFront,
        );
        if (uploadedId == null) return false;
        aadharFrontImageId = uploadedId;
        slot.aadharFrontImageDocumentId.value = uploadedId;
      }

      var aadharBackImageId = slot.aadharBackImageDocumentId.value;
      if (slot.aadharBackImage.value != null) {
        final uploadedId = await uploadDocument(
          file: slot.aadharBackImage.value!,
          module: DocumentModule.nomineeAadharBack,
        );
        if (uploadedId == null) return false;
        aadharBackImageId = uploadedId;
        slot.aadharBackImageDocumentId.value = uploadedId;
      }

      var passbookChequeImageId = slot.passbookChequeImageDocumentId.value;
      if (slot.passbookChequeImage.value != null) {
        final uploadedId = await uploadDocument(
          file: slot.passbookChequeImage.value!,
          module: DocumentModule.nomineePassbookCheque,
        );
        if (uploadedId == null) return false;
        passbookChequeImageId = uploadedId;
        slot.passbookChequeImageDocumentId.value = uploadedId;
      }

      // Safety net for the hi/gu name translation, same reasoning as
      // translateAllStep1Fields — normally already done by the focus-loss
      // listener wired in onInit, this just guarantees it's finished
      // before the request is built even if that never fired (e.g. the
      // user picked a photo and tapped Save without ever leaving the name
      // field with a keyboard "next"/tab).
      if (slot.isNameDirty.value ||
          needsTranslation(slot.nameLanguages.value)) {
        await translateNameFieldOnUnfocus(
          text: slot.nameController.text,
          targetModel: slot.nameLanguages,
          isDirty: slot.isNameDirty,
        );
      }

      final shareText = slot.shareController.text.trim();
      final share = shareText.isEmpty ? 0.0 : (double.tryParse(shareText) ?? 0.0);

      final request = NomineeModel(
        nomineeId: slot.nomineeId.value ?? 0,
        name: slot.nameController.text.trim(),
        hName: slot.nameLanguages.value.hindi,
        gName: slot.nameLanguages.value.gujarati,
        dateOfBirth: resolvedDateOfBirth.toIso8601String(),
        relation: slot.relationId.value,
        share: share,
        profilePhoto: photoId ?? 0,
        memberId: memberId,
        // Same grouped-display stripping as saveMemberPersonalDetail's own
        // aadharNo above.
        aadharNo: AppValidators.stripAadharFormatting(
          slot.aadharNoController.text.trim(),
        ),
        aadharFrontImage: aadharFrontImageId ?? 0,
        aadharBackImage: aadharBackImageId ?? 0,
        passBookCheque: passbookChequeImageId ?? 0,
      );

      final savedNomineeId = await _nomineeRepository.saveNominee(request);

      // A real id lets a later re-save of this same slot update it
      // instead of creating a duplicate nominee record. `savedNomineeId`
      // can legitimately be 0 (see NomineeRepositoryImpl) — in that case
      // just leave whatever id the slot already had.
      if (savedNomineeId > 0) {
        slot.nomineeId.value = savedNomineeId;
      }

      slot.isSaved.value = true;

      return true;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return false;
      }
      ToastUtil.error(
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      _loaderController.hide();
    }
  }

  /// Prefills the Nominee step from whatever was already saved for this
  /// member — called once when MemberRegistrationScreen opens (not gated
  /// on which step is currently showing), so a member who saved one or
  /// more nominees, then closed and reopened the app mid-registration,
  /// sees that data already filled in instead of blank fields. Silent on
  /// failure (besides a debug log / toast for a real error) since this is
  /// a best-effort prefill, not something that should block the screen
  /// from opening.
  Future<void> loadExistingNominees() async {
    try {
      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) return;

      final nominees = await _nomineeRepository.getNomineeByMemberId(memberId);

      if (nominees.isEmpty) return;

      final count =
          nominees.length > maxNominees ? maxNominees : nominees.length;

      for (var i = 0; i < count; i++) {
        final nominee = nominees[i];
        final slot = nomineeSlots[i];

        slot.nomineeId.value = nominee.nomineeId > 0 ? nominee.nomineeId : null;

        slot.nameController.text = nominee.name;

        // hName/gName are now part of GetNomineeByMemberId's own schema
        // (see NomineeModel), so a nominee that already has them prefills
        // as already-translated instead of re-calling the transliteration
        // API for data the server already has. If either comes back empty
        // (e.g. a nominee saved before this field existed), isNameDirty
        // stays true so the normal focus-loss/save-time translation runs
        // as soon as the member touches (or re-saves) this slot.
        slot.nameLanguages.value = LocalizedTextModel(
          original: nominee.name,
          english: nominee.name,
          hindi: nominee.hName,
          gujarati: nominee.gName,
        );
        slot.isNameDirty.value =
            nominee.hName.isEmpty || nominee.gName.isEmpty;

        final parsedDateOfBirth = DateTime.tryParse(nominee.dateOfBirth);
        slot.dateOfBirth.value = parsedDateOfBirth;
        slot.dateOfBirthController.text = parsedDateOfBirth != null
            ? AppDatePicker.format(parsedDateOfBirth)
            : '';

        slot.relationId.value = nominee.relation;

        slot.shareController.text =
            nominee.share != null ? _formatShare(nominee.share!) : '';

        // No local File to show for a photo that already exists on the
        // server — only the document id, so saveNomineeSlot knows not to
        // require/re-upload a new one unless the user picks one.
        slot.photoDocumentId.value =
            nominee.profilePhoto > 0 ? nominee.profilePhoto : null;
        slot.photoUrl.value = _resolveDocumentUrl(nominee.photoUrl);

        // Grouped into 4-4-4 blocks the same way the field formats it
        // while typing (see AppValidators.formatAadhar /
        // _AadharInputFormatter) — otherwise a resumed nominee's Aadhaar
        // number showed as one unbroken string instead of matching what
        // typing it in fresh would look like.
        slot.aadharNoController.text =
            AppValidators.formatAadhar(nominee.aadharNo);

        slot.aadharFrontImageDocumentId.value =
            nominee.aadharFrontImage > 0 ? nominee.aadharFrontImage : null;
        slot.aadharFrontImageUrl.value =
            _resolveDocumentUrl(nominee.aadharFrontImageUrl);

        slot.aadharBackImageDocumentId.value =
            nominee.aadharBackImage > 0 ? nominee.aadharBackImage : null;
        slot.aadharBackImageUrl.value =
            _resolveDocumentUrl(nominee.aadharBackImageUrl);

        slot.passbookChequeImageDocumentId.value =
            nominee.passBookCheque > 0 ? nominee.passBookCheque : null;
        slot.passbookChequeImageUrl.value =
            _resolveDocumentUrl(nominee.passBookChequeUrl);

        slot.isSaved.value = true;
      }

      visibleNomineeSlots.value = count < 1 ? 1 : count;
      recomputeTotalShare();
    } catch (e) {
      debugPrint('Failed to load existing nominees: $e');

      if (!isNetworkInterruption(e)) {
        ToastUtil.error(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  /// Resolves a possibly-relative document path to a full URL the same
  /// way BannerModel does for banner images — [path] already absolute
  /// (`http(s)://...`) is returned as-is, otherwise it's joined onto
  /// [Env.config.baseUrl]. `null`/empty in, `null` out.
  String? _resolveDocumentUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final base = Env.config.baseUrl.endsWith('/')
        ? Env.config.baseUrl.substring(0, Env.config.baseUrl.length - 1)
        : Env.config.baseUrl;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    return '$base/$cleanPath';
  }

  /// Formats a share value without a trailing ".0" for whole numbers
  /// (e.g. 50.0 -> "50", 33.5 -> "33.5"), so a prefilled share field reads
  /// naturally instead of looking machine-generated.
  String _formatShare(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  /// Marks the Nominee step done via `SaveNomineeScreen` — call only after
  /// every visible nominee slot has already been individually saved via
  /// [saveNomineeSlot].
  Future<bool> saveNomineeScreen() async {
    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return false;
      }

      final nextRoute = await _repository.saveNomineeScreen(
        memberId: memberId,
      );

      if (nextRoute != null && nextRoute.isNotEmpty) {
        await AppPrefs.setRegistrationStatus(nextRoute);
      }

      return true;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return false;
      }
      ToastUtil.error(
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // SAVE RULES ACCEPTANCE (SaveRulesRegulationScreen)
  // ============================================================

  Future<String?> saveRulesAcceptance() async {
    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return null;
      }

      final result = await _repository.saveRulesRegulationScreen(
        memberId: memberId,
      );

      final nextRoute = result?.memberDetailStatusName;

      // This is the response that lets a BRAND-NEW registrant see step 1's
      // read-only Name/Mobile fields prefilled, the same way a resumed
      // member already does via getMemberStatus — Register screen ->
      // saveMemberStep1 already set `member`/`mobileController` once, but
      // this merges in whatever SaveRulesRegulationScreen's own response
      // carries on top, preferring its fresh values and falling back to
      // whatever's already known for anything it doesn't return (mirrors
      // saveMemberStep1's reasoning for why a raw overwrite isn't safe).
      if (result != null) {
        final previous = member.value;

        member.value = (previous ?? result).copyWith(
          memberId: result.memberId > 0 ? result.memberId : null,
          firstName: result.firstName,
          lastName: result.lastName,
          surname: result.surname,
          mobile: result.mobile,
          mobile2: result.mobile2,
          fatherName: result.fatherName,
          dateOfBirth: result.dateOfBirth,
          gender: result.gender,
          maritalStatus: result.maritalStatus,
          address: result.address,
          village: result.village,
          taluka: result.taluka,
          district: result.district,
          state: result.state,
          occupation: result.occupation,
          aadharNo: result.aadharNo,
          panNo: result.panNo,
          status: result.status,
          memberDetailStatus: result.memberDetailStatus,
          memberDetailStatusName: result.memberDetailStatusName,
        );

        if ((result.mobile ?? '').isNotEmpty) {
          mobileController.text = result.mobile!;
        }

        if ((result.mobile2 ?? '').isNotEmpty) {
          mobile2Controller.text = result.mobile2!;
        }
      }

      if (nextRoute != null && nextRoute.isNotEmpty) {
        await AppPrefs.setRegistrationStatus(nextRoute);
      }

      return nextRoute;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return null;
      }
      ToastUtil.error(
        e.toString().replaceFirst('Exception: ', ''),
      );

      return null;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // SAVE RULES REGULATION ACCEPT SCREEN (SaveRulesRegulationAcceptScreen)
  //
  // The Rules & Declaration step's OWN accept-checkbox screen (step 5,
  // _buildRulesStep/CheckboxListTile bound to acceptedRules) — distinct
  // from saveRulesAcceptance() above, which calls SaveRulesRegulationScreen
  // and runs earlier, from the Legal Rules screen before step 1. Called
  // from _finishRegistration() once the member has ticked "I agree" and
  // tapped Finish, before navigating to the Preview screen.
  // ============================================================

  Future<bool> saveRulesRegulationAcceptScreen() async {
    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return false;
      }

      final nextRoute = await _repository.saveRulesRegulationAcceptScreen(
        memberId: memberId,
      );

      if (nextRoute != null && nextRoute.isNotEmpty) {
        await AppPrefs.setRegistrationStatus(nextRoute);
      }

      return true;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return false;
      }
      ToastUtil.error(
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // SAVE PREVIEW SCREEN (SavePreviewScreen)
  //
  // Called from the Preview screen's own final "Complete Registration"
  // button, right before it marks registration complete and navigates to
  // Home.
  // ============================================================

  Future<bool> savePreviewScreen() async {
    try {
      _loaderController.show();

      final memberId = (await AppSecureStorage.getMemberId()) ?? 0;

      if (memberId <= 0) {
        ToastUtil.error('member_not_found_error'.tr);
        return false;
      }

      return await _repository.savePreviewScreen(memberId: memberId);
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return false;
      }
      ToastUtil.error(
        e.toString().replaceFirst('Exception: ', ''),
      );

      return false;
    } finally {
      _loaderController.hide();
    }
  }

  // ============================================================
  // GET MEMBER STATUS
  // ============================================================

  /// True when [known] (the in-memory `member.value`) still represents the
  /// exact identity currently being submitted to [getMemberStatus] — same
  /// first/middle/surname and mobile, ignoring case and surrounding
  /// whitespace. This is what decides whether a locally stored memberId is
  /// still safe to attach to a new lookup request — see the long comment
  /// in [getMemberStatus] for why that matters.
  bool _memberMatchesIdentity(
    MemberModel known, {
    required String firstName,
    required String middleName,
    required String surname,
    required String mobile,
  }) {
    bool same(String? a, String b) =>
        (a ?? '').trim().toLowerCase() == b.trim().toLowerCase();

    return same(known.firstName, firstName) &&
        same(known.lastName, middleName) &&
        same(known.surname, surname) &&
        same(known.mobile, mobile);
  }

  Future<MemberModel?> getMemberStatus({
    required bool isRegistered,
    required String firstName,
    required String middleName,
    required String surname,
    required String mobile,
  }) async {
    try {
      _loaderController.show();

      final storedMemberId =
          (await AppSecureStorage.getMemberId()) ?? 0;

      // The stored memberId is only safe to send when it still belongs to
      // the identity currently being submitted. Without this check, once
      // ANY member had been looked up/created on this device, every LATER
      // call here for a *different* name+mobile — a second family member
      // registering on the same phone, or a corrected typo — would still
      // attach the OLD memberId to the request. The backend resolves the
      // lookup by memberId when one is present, so it kept handing back
      // the OLD member's data/resume-route instead of searching fresh by
      // the newly typed name+mobile: the screen would silently show/resume
      // the wrong person's registration.
      //
      // `member.value` is the in-memory record the stored id actually
      // belongs to — the two are always set together, here and in
      // saveMemberStep1. If it's missing, belongs to a different id, or
      // its name/mobile no longer match what's being submitted now, the
      // stored id can't be trusted for THIS request — fall back to
      // memberId 0, which makes the backend do a genuine name+mobile
      // search instead, exactly like a brand-new registrant.
      final knownMember = member.value;
      final identityChanged = storedMemberId == 0 ||
          knownMember == null ||
          knownMember.memberId != storedMemberId ||
          !_memberMatchesIdentity(
            knownMember,
            firstName: firstName,
            middleName: middleName,
            surname: surname,
            mobile: mobile,
          );

      final memberId = identityChanged ? 0 : storedMemberId;

      final request =
      GetMemberStatusRequestModel(
        isRegistered: memberId == 0 ? isRegistered : false,
        firstName: firstName,
        lastName: middleName,
        surname: surname,
        mobile: mobile,
        memberId: memberId,
      );

      final result =
      await _repository
          .getSingleMemberByRegisteredStatus(
        request,
      );

      // No existing member for this name/mobile combination. This is the
      // normal, expected outcome for a brand-new registrant — NOT an
      // error. A sentinel (memberId: 0, no status) is returned instead of
      // null so the caller can tell "not found, go ahead and create the
      // member" apart from null, which here always means "stop — a real
      // error or a connectivity drop already handled/toasted this".
      //
      // Only actually clear `member.value` when we didn't already have a
      // confirmed member. getMemberStatus is also called as a
      // confirmatory re-check (e.g. MemberRegistrationScreen's initState,
      // right after the member was just created via SaveMemberStep1) —
      // if that particular query doesn't match it back (timing, or a
      // different `isRegistered` filter), that must NOT wipe out a name
      // the app already knows is correct. Once a real member is known,
      // "not found" from a later call is treated as "this query didn't
      // match", not "the member doesn't exist".
      //
      // The one exception is `identityChanged` above: that already means
      // whatever `member.value`/stored id we had belongs to a DIFFERENT
      // name+mobile than what was just searched for, so it must not be
      // kept around just because it happens to be "confirmed" — it's
      // confirmed for the wrong person. Drop both the in-memory record
      // and the stale stored id so neither can leak into a later call for
      // this new identity.
      if (result == null) {
        final alreadyHasConfirmedMember = (member.value?.memberId ?? 0) > 0;

        if (!alreadyHasConfirmedMember || identityChanged) {
          member.value = null;
        }

        if (identityChanged && storedMemberId > 0) {
          await AppSecureStorage.deleteMemberId();
        }

        return const MemberModel(memberId: 0);
      }

      member.value = result;

      if (result.memberId > 0) {
        await AppSecureStorage.saveMemberId(
          result.memberId,
        );
      }

      // ========================================================
      // PREFILL MEMBER DATA
      // ========================================================

      fatherNameController.text =
          result.fatherName ?? '';

      // The server returns DOB as an ISO date-time string
      // (e.g. "2026-08-29T10:54:58.5"); parse it so both the picker's
      // DateTime state and the displayed "dd/MM/yyyy" text stay correct,
      // instead of showing the raw ISO string in the field.
      final parsedDateOfBirth = DateTime.tryParse(result.dateOfBirth ?? '');
      dateOfBirth.value = parsedDateOfBirth;
      dateOfBirthController.text = parsedDateOfBirth != null
          ? AppDatePicker.format(parsedDateOfBirth)
          : '';

      addressController.text =
          result.address ?? '';

      villageController.text =
          result.village ?? '';

      talukaController.text =
          result.taluka ?? '';

      districtController.text =
          result.district ?? '';

      stateController.text =
          result.state ?? '';

      occupationController.text =
          result.occupation ?? '';

      // Grouped into 4-4-4 blocks the same way the field formats it while
      // typing — see the matching comment on NomineeSlot's aadharNo
      // prefill above.
      aadharNumberController.text =
          AppValidators.formatAadhar(result.aadharNo ?? '');

      panNumberController.text =
          result.panNo ?? '';

      // Seed every *Languages model straight from the server's own h-/g-
      // fields, when resuming an existing member — this is what the
      // Preview screen's _localizedValue actually reads to decide what to
      // show in the selected app language. Before this, only the plain
      // *Controller.text above was ever set on resume, so a member who
      // picked Hindi/Gujarati and reopened the app mid-registration saw
      // English/plain text in the preview no matter what language was
      // selected — GetMemberStatus's response was never parsed for its
      // hi/gu variants even though SaveMemberPersonalDetail sends them
      // (see MemberModel's hAddress/hVillage/etc. doc comment).
      //
      // Only seeded when the server actually returned that plain field —
      // same "don't clobber an in-progress edit" reasoning already used
      // above for the document ids/URLs, since getMemberStatus can also
      // fire as a confirmatory re-check while the member is mid-typing a
      // later step whose value hasn't been saved yet.
      _seedLanguagesIfPresent(firstNameLanguages, result.firstName, result.hFirstName, result.gFirstName);
      _seedLanguagesIfPresent(middleNameLanguages, result.lastName, result.hLastName, result.gLastName);
      _seedLanguagesIfPresent(surnameLanguages, result.surname, result.hSurname, result.gSurname);
      _seedLanguagesIfPresent(fatherNameLanguages, result.fatherName, result.hFatherName, result.gFatherName);
      _seedLanguagesIfPresent(addressLanguages, result.address, result.hAddress, result.gAddress);
      _seedLanguagesIfPresent(villageLanguages, result.village, result.hVillage, result.gVillage);
      _seedLanguagesIfPresent(talukaLanguages, result.taluka, result.hTaluka, result.gTaluka);
      _seedLanguagesIfPresent(districtLanguages, result.district, result.hDistrict, result.gDistrict);
      _seedLanguagesIfPresent(stateLanguages, result.state, result.hState, result.gState);
      _seedLanguagesIfPresent(occupationLanguages, result.occupation, result.hOccupation, result.gOccupation);

      // Already-uploaded document ids + best-effort URLs — lets
      // uploadStep1Documents() skip re-uploading a document the member
      // uploaded in an earlier session, and lets the upload tiles show a
      // network preview instead of "tap to upload" when resuming. Only
      // overwrite when the fetched value is actually present, so this
      // never clobbers an id/File the user already picked earlier in THIS
      // session (e.g. re-entering step 1 after this same query re-runs).
      if (result.image != null) {
        profileImageId.value = result.image;
      }
      if (result.aadharImage != null) {
        aadharImageId.value = result.aadharImage;
      }
      if (result.aadharBackImage != null) {
        aadharBackImageId.value = result.aadharBackImage;
      }
      if (result.panImage != null) {
        panImageId.value = result.panImage;
      }
      if (result.digitalSign != null) {
        signatureFileId.value = result.digitalSign;
      }

      profileImageUrl.value =
          _resolveDocumentUrl(result.imageUrl) ?? profileImageUrl.value;
      aadharImageUrl.value =
          _resolveDocumentUrl(result.aadharImageUrl) ?? aadharImageUrl.value;
      aadharBackImageUrl.value =
          _resolveDocumentUrl(result.aadharBackImageUrl) ??
              aadharBackImageUrl.value;
      panImageUrl.value =
          _resolveDocumentUrl(result.panImageUrl) ?? panImageUrl.value;
      signatureFileUrl.value =
          _resolveDocumentUrl(result.digitalSignUrl) ?? signatureFileUrl.value;

      // Mobile Number is read-only on step 1 (see registration_form_steps_
      // screen.dart) — there's no user-typed edit to protect here, so this
      // always mirrors the resumed member's actual number, same as every
      // other field in this prefill block. Only skips writing when the
      // response happens not to carry one, so a value already seeded by
      // saveMemberStep1/saveRulesAcceptance for this same member isn't
      // blanked out by an incomplete response.
      if ((result.mobile ?? '').isNotEmpty) {
        mobileController.text = result.mobile!;
      }

      // Mobile Number 2 — same "only skip when the response doesn't carry
      // one" rule as Mobile Number above; this one IS user-editable on
      // step 1, but was never being prefilled at all before (see
      // MemberModel.mobile2's doc comment), so a resumed member always saw
      // it blank even after having filled it in and saved earlier.
      if ((result.mobile2 ?? '').isNotEmpty) {
        mobile2Controller.text = result.mobile2!;
      }

      // MemberModel stores gender/maritalStatus as the API's stringified
      // int id (e.g. "1"), matching the id genderOptions/maritalStatusOptions
      // use — not a display label.
      selectedGenderId.value =
          int.tryParse(result.gender ?? '');

      selectedMaritalStatusId.value =
          int.tryParse(result.maritalStatus ?? '');

      // Store the actual resumable route (e.g. "/member-registration-step2"),
      // not the raw numeric status code, since that's the only form of
      // this value anything else in the app could act on.
      if (result.memberDetailStatusName != null &&
          result.memberDetailStatusName!.isNotEmpty) {
        await AppPrefs.setRegistrationStatus(
          result.memberDetailStatusName!,
        );
      }

      return result;
    } catch (e) {
      if (isNetworkInterruption(e)) {
        return null;
      }
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));

      return null;
    } finally {
      _loaderController.hide();
    }
  }

  /// Prefers the picked [dateOfBirth] value; falls back to parsing
  /// [dateOfBirthController]'s displayed "dd/MM/yyyy" text, which is the
  /// only value set when a resumed member's DOB was prefilled from the
  /// server without the user re-opening the date picker. Returns null
  /// (never "today") when neither is available/parseable, so the caller
  /// blocks the save instead of silently submitting the wrong date.
  DateTime? _resolvedDateOfBirth() {
    if (dateOfBirth.value != null) {
      return dateOfBirth.value;
    }

    final text = dateOfBirthController.text.trim();
    if (text.isEmpty) {
      return null;
    }

    try {
      return DateFormat('dd/MM/yyyy').parseStrict(text);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DATE PICKERS
  // ============================================================

  Future<void> pickDateOfBirth(
      BuildContext context,
      ) async {
    final selectedDate =
    await AppDatePicker.pickDate(
      context: context,
      initialDate:
      dateOfBirth.value ??
          DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    dateOfBirth.value = selectedDate;

    dateOfBirthController.text =
        AppDatePicker.format(
          selectedDate,
        );
  }

  /// Date picker for the Health step's surgery detail (`surgeryDate` on
  /// HealthDeclarationModel) — only ever shown once [hadSurgery] is true.
  Future<void> pickSurgeryDate(
      BuildContext context,
      ) async {
    final selectedDate =
    await AppDatePicker.pickDate(
      context: context,
      initialDate:
      surgeryDate.value ??
          DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    surgeryDate.value = selectedDate;

    surgeryDateController.text =
        AppDatePicker.format(
          selectedDate,
        );
  }

  /// Date-of-birth picker for one nominee slot — [slotIndex] into
  /// [nomineeSlots].
  Future<void> pickNomineeSlotDateOfBirth(
      BuildContext context,
      int slotIndex,
      ) async {
    final slot = nomineeSlots[slotIndex];

    final selectedDate =
    await AppDatePicker.pickDate(
      context: context,
      initialDate:
      slot.dateOfBirth.value ??
          DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    slot.dateOfBirth.value = selectedDate;

    slot.dateOfBirthController.text =
        AppDatePicker.format(
          selectedDate,
        );
  }

  // ============================================================
  // IMAGE PICKERS
  // ============================================================

  Future<void> pickProfileImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
    );

    if (image != null) {
      profileImage.value = image;
    }
  }

  Future<void> pickAadharImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
      // Aadhaar/PAN/passbook are flat document photos, naturally wider
      // than tall — default the crop box to that shape instead of
      // leaving the member to resize it themselves (still freely
      // adjustable — see ImagePickerUtil.pickImage's own doc comment).
      aspectRatioPreset: CropAspectRatioPreset.ratio3x2,
    );

    if (image != null) {
      aadharImage.value = image;
    }
  }

  Future<void> pickAadharBackImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
      aspectRatioPreset: CropAspectRatioPreset.ratio3x2,
    );

    if (image != null) {
      aadharBackImage.value = image;
    }
  }

  Future<void> pickPanImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
      aspectRatioPreset: CropAspectRatioPreset.ratio3x2,
    );

    if (image != null) {
      panImage.value = image;
    }
  }

  /// Photo picker for one nominee slot — [slotIndex] into [nomineeSlots].
  /// Same ImagePickerUtil.pickImage call as every other photo on this
  /// screen, so the file is already cropped + compressed to a small JPEG
  /// by the time it lands here (see ImagePickerUtil's own
  /// _compressImage); actually uploading it happens later, in
  /// [saveNomineeSlot], the same "pick now, upload at save time" pattern
  /// pickProfileImage/pickAadharImage/pickPanImage use for step 1.
  Future<void> pickNomineeSlotImage(
      int slotIndex,
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
    );

    if (image != null) {
      nomineeSlots[slotIndex].photo.value = image;
    }
  }

  /// Aadhaar front/back + passbook-cheque pickers for one nominee slot —
  /// same "pick now, upload at save time" pattern as [pickNomineeSlotImage]
  /// above. Same 3:2 default crop shape as the member's own Aadhaar/PAN
  /// pickers above — these are the same kind of flat document photo.
  Future<void> pickNomineeSlotAadharFrontImage(
      int slotIndex,
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
      aspectRatioPreset: CropAspectRatioPreset.ratio3x2,
    );

    if (image != null) {
      nomineeSlots[slotIndex].aadharFrontImage.value = image;
    }
  }

  Future<void> pickNomineeSlotAadharBackImage(
      int slotIndex,
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
      aspectRatioPreset: CropAspectRatioPreset.ratio3x2,
    );

    if (image != null) {
      nomineeSlots[slotIndex].aadharBackImage.value = image;
    }
  }

  Future<void> pickNomineeSlotPassbookChequeImage(
      int slotIndex,
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
      aspectRatioPreset: CropAspectRatioPreset.ratio3x2,
    );

    if (image != null) {
      nomineeSlots[slotIndex].passbookChequeImage.value = image;
    }
  }

  // ============================================================
  // SIGNATURE
  // ============================================================

  void setSignature(File file) {
    signatureFile.value = file;
  }

  void clearSignature() {
    signatureFile.value = null;
  }

  // ============================================================
  // IMAGE SOURCE SHEET
  // ============================================================

  void showImageSourceSheet({
    required Future<void> Function(
        ImageSource source,
        ) onSelected,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding:
          const EdgeInsets.all(20),
          decoration:
          const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                ),
                title: Text(
                  'camera'.tr,
                ),
                onTap: () async {
                  Get.back();

                  await onSelected(
                    ImageSource.camera,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                ),
                title: Text(
                  'gallery'.tr,
                ),
                onTap: () async {
                  Get.back();

                  await onSelected(
                    ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ============================================================
  // STEP NAVIGATION
  // ============================================================

  void nextStep() {
    if (currentStep.value <
        totalSteps - 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  @override
  void onClose() {
    _reconnectSubscription?.cancel();

    fatherNameController.dispose();
    dateOfBirthController.dispose();
    addressController.dispose();
    villageController.dispose();
    talukaController.dispose();
    districtController.dispose();
    stateController.dispose();
    occupationController.dispose();
    aadharNumberController.dispose();
    panNumberController.dispose();
    mobileController.dispose();
    mobile2Controller.dispose();

    for (final slot in nomineeSlots) {
      slot.dispose();
    }

    seriousIllnessDetailController.dispose();
    otherHereditaryDetailController.dispose();
    surgeryDetailController.dispose();
    surgeryDateController.dispose();
    medicationDetailController.dispose();
    allergyDetailController.dispose();
    otherHealthDetailController.dispose();

    super.onClose();
  }
}

/// One nominee's worth of editable state on the Nominee step — see
/// RegistrationController.nomineeSlots. Deliberately plain (not a
/// GetxController of its own): it's owned and disposed by
/// RegistrationController, same as every other TextEditingController on
/// this controller.
class NomineeSlot {
  final nameController = TextEditingController();

  final shareController = TextEditingController();

  final dateOfBirthController = TextEditingController();

  final Rxn<DateTime> dateOfBirth = Rxn<DateTime>();

  /// Id from GetEnumBundle's `Relation` list — see
  /// RegistrationController.relationOptions.
  final Rxn<int> relationId = Rxn<int>();

  /// Nominee's Aadhaar number — see NomineeModel.aadharNo's doc comment
  /// for why this is validated (when non-empty) but never required.
  final aadharNoController = TextEditingController();

  /// The locally picked photo, kept set after a successful upload too (so
  /// the picker keeps showing the actual picture rather than reverting to
  /// a placeholder) — [photoDocumentId] is the lasting record SaveNominee
  /// actually needs; this is purely for display.
  final Rxn<File> photo = Rxn<File>();

  /// Document id from SaveDocument — either just-uploaded, or prefilled
  /// from GetNomineeByMemberId for a nominee that already has a photo on
  /// the server (in which case [photo] stays null; there's no local file
  /// to show for it, only this id — see the "file_selected" fallback
  /// subtitle on the Nominee step's upload tile).
  final Rxn<int> photoDocumentId = Rxn<int>();

  /// Full, directly-loadable URL for the same already-uploaded photo
  /// [photoDocumentId] refers to — set only when GetNomineeByMemberId's
  /// response happens to include a usable path (see
  /// NomineeModel.photoUrl's doc comment; not confirmed against a real
  /// response). Lets the Nominee step and the Preview screen show a
  /// resumed nominee's actual photo via a network image instead of
  /// falling back to "no photo" just because there's no local [File] for
  /// it — see the Obx image builders on both screens.
  final Rxn<String> photoUrl = Rxn<String>();

  /// Aadhaar front/back + passbook-cheque photos — same "local File until
  /// uploaded, then a document id, plus a best-effort URL for a resumed
  /// nominee" pattern as [photo]/[photoDocumentId]/[photoUrl] above, one
  /// triple per new document added to SaveNominee's schema.
  final Rxn<File> aadharFrontImage = Rxn<File>();
  final Rxn<int> aadharFrontImageDocumentId = Rxn<int>();
  final Rxn<String> aadharFrontImageUrl = Rxn<String>();

  final Rxn<File> aadharBackImage = Rxn<File>();
  final Rxn<int> aadharBackImageDocumentId = Rxn<int>();
  final Rxn<String> aadharBackImageUrl = Rxn<String>();

  final Rxn<File> passbookChequeImage = Rxn<File>();
  final Rxn<int> passbookChequeImageDocumentId = Rxn<int>();
  final Rxn<String> passbookChequeImageUrl = Rxn<String>();

  /// 0/null = not saved yet (new nominee); a real id = this nominee
  /// already exists on the backend, so the next SaveNominee call for this
  /// slot updates it instead of creating a duplicate.
  final Rxn<int> nomineeId = Rxn<int>();

  /// True once this slot has been successfully saved at least once (via
  /// SaveNominee, or prefilled from GetNomineeByMemberId) — purely a UI
  /// hint (see the check icon on the Nominee step's card header), not
  /// re-checked against unsaved edits. Also gates whether this slot's
  /// "remove" button shows at all — see the Nominee step's card header:
  /// once a slot has ever gone through SaveNominee (this session or a
  /// prior one, via GetNomineeByMemberId), it can only be edited/cleared,
  /// never removed.
  final RxBool isSaved = false.obs;

  /// True once this slot's Add More/Save/Next has failed validation at
  /// least once — mirrors RegistrationController's own
  /// _showStep1Errors flag (see registration_form_steps_screen.dart), but
  /// per-slot since up to maxNominees nominee cards can each be mid-entry
  /// at once. Drives the relationship dropdown's inline error text/red
  /// border; set to true right before validating on Add More/Save/Next.
  final RxBool showErrors = false.obs;

  // ============================================================
  // NAME — HINDI/GUJARATI (mirrors RegistrationController's
  // fatherNameLanguages/isFatherNameDirty pattern, one copy per slot
  // since there are up to `maxNominees` names in play at once)
  // ============================================================

  /// English/Hindi/Gujarati variants of [nameController]'s text, filled in
  /// by RegistrationController.translateNameFieldOnUnfocus — the same
  /// background transliteration call used for every other name field on
  /// this wizard. Now sent as `hName`/`gName` on every SaveNominee call —
  /// see saveNomineeSlot.
  final Rx<LocalizedTextModel> nameLanguages = LocalizedTextModel.empty().obs;

  /// True until [nameLanguages] has been translated for the CURRENT text
  /// in [nameController] — same convention as
  /// RegistrationController.isFatherNameDirty.
  final RxBool isNameDirty = true.obs;

  /// Fires the translate-on-blur call the moment the user leaves this
  /// slot's name field — same pattern as the focus nodes in
  /// registration_form_steps_screen.dart, just owned here instead since
  /// there are up to three of these instead of one.
  final FocusNode nameFocusNode = FocusNode();

  void dispose() {
    nameController.dispose();
    shareController.dispose();
    dateOfBirthController.dispose();
    aadharNoController.dispose();
    nameFocusNode.dispose();
  }
}
