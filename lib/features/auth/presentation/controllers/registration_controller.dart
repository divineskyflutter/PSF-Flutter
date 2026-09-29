import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:psf_application/app/config/env/env.dart';
import 'package:psf_application/core/network/exceptions/api_exceptions.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/features/enum_bundle/data/repository/enum_bundle_repository.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/enums/document_module.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/repo/document_repository.dart';
import 'package:psf_application/shared/repo/language_translation_repository.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/utils/script_detector.dart';
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
import '../../data/models/query_item_model.dart';
import '../../domain/repositories/health_declaration_repository.dart';
import '../../domain/repositories/member_repository.dart';
import '../../domain/repositories/nominee_repository.dart';
import 'query_resolution_state.dart';

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

  /// `true` for the rest of this wizard session when it was opened because
  /// a successful login came back with `isInEditMode: true` (see
  /// LoginScreen) — an existing member correcting their application, not
  /// someone applying for the first time. RegistrationPreviewScreen reads
  /// this at the end to send them to Home instead of the normal
  /// "just submitted, awaiting approval" pending screen. Reset once
  /// consumed so a later, genuinely fresh registration isn't affected.
  bool isEditingAfterLogin = false;

  /// Drives the narrower "fix these specific fields" flow — see its own
  /// doc comment. Inactive (`isActive == false`) for every normal
  /// registration/full-edit session, so nothing here changes existing
  /// behavior unless a login actually came back with unresolved queries.
  final QueryResolutionState queryState = QueryResolutionState();

  /// Called from LoginScreen once a login comes back with
  /// `hasUnresolvedQueries == true`, before navigating to Step 1. Seeds
  /// every queried Step 1 field's shared input with the specific
  /// language-slot value that needs fixing (see `_step1TripleFields`),
  /// since otherwise it would still show whatever it displayed before —
  /// normally the English/original slot, even if it's the Gujarati slot
  /// that's actually queried.
  void startQueryResolutionMode(List<QueryItem> queries) {
    queryState.start(queries);
    _primeQueryModeTables();
  }

  /// (Re)computes every table's current pass, seeds the shared input boxes
  /// and flags script mismatches. Runs when the flow starts AND again when
  /// the field-name list arrives — a login can finish before the enum
  /// bundle does, and until the names are known every field looks plain
  /// (no Gujarati/Hindi variant), so nothing would be set up correctly.
  void _primeQueryModeTables() {
    queryState.primeLocalLanguageForScreen(1);
    seedQueryModeStep1Fields();
    recheckStep1ScriptMismatches();

    // Nominee data itself loads separately (loadExistingNominees, called
    // from the screen's initState) and may not have arrived yet — seeding
    // here is a no-op until it has (nomineeItemNumbersWithQueries has
    // nothing to seed against without prefilled nominee names), so
    // loadExistingNominees calls this again once it actually has data,
    // the same reseed-after-load pattern Step 1 uses.
    primeAllQueriedNominees();

    // Health Declaration data also loads separately (loadExistingHealth
    // Declaration, from the screen's initState) — same reseed-after-load
    // pattern as Nominee above.
    if (queryState.hasQueriesForTable(3)) {
      queryState.primeLocalLanguageForScreen(3);
      seedQueryModeHealthFields();
      recheckHealthScriptMismatches();
    }
  }

  /// Makes sure the field-name lists are loaded before the query flow is
  /// set up — the login screen awaits this so a fast login never starts
  /// the flow with no names known.
  Future<void> ensureFieldEnumsLoaded() async {
    if (queryState.hasFieldNames) return;
    await loadEnumOptions();
  }

  /// Flags (or clears) each currently-unlocked Step 1 field's script
  /// mismatch against its own prefilled/leftover text, right now — instead
  /// of waiting for the member's first edit. A field a pass just opened
  /// almost always still holds whatever the PREVIOUS pass left there
  /// (e.g. Gujarati text sitting in a box that now requires Hindi), which
  /// essentially never already satisfies its own new requirement, so
  /// without this the red border + explanatory error text wouldn't appear
  /// until the member touched the field themselves. Call this every time
  /// a pass is (re)primed: from [startQueryResolutionMode] and again after
  /// every `queryState.primeLocalLanguageForScreen` call in the Next
  /// handler.
  void recheckStep1ScriptMismatches() {
    for (final fieldId in queryState.editableFieldIds(1)) {
      final text = queryModeStep1FieldText(fieldId);
      final fieldName = queryState.fieldNameFor(1, fieldId);
      queryState.setScriptMismatch(
        1,
        fieldId,
        !ScriptDetector.matchesRequiredScript(text, fieldName),
      );
    }
  }

  /// Overwrites each queried Step 1 field's shared input with the specific
  /// language-slot value that needs fixing. Called from
  /// [startQueryResolutionMode] and again from [getMemberStatus] (see its
  /// own doc comment) — safe to call repeatedly, it always reflects
  /// whatever `_step1TripleFields`' models currently hold.
  void seedQueryModeStep1Fields() {
    _ensureStep1TripleFields();

    for (final spec in _step1TripleFields) {
      final variantId = queryModeVariantFor(spec.baseId, spec.hId, spec.gId);
      if (variantId != null) {
        spec.controller.text = queryModeStep1FieldText(variantId);
      }
    }

    final nameScript = queryModeNameScript();
    if (nameScript != null) {
      queryFullNameController.text = queryModeFullNameText(nameScript);
    }
  }

  /// Whichever of [baseId]/[hId]/[gId] is currently queried and in the
  /// active pass, on [tableId] (+ nominee [itemNumber]) — Gujarati > Hindi
  /// > base priority, in the rare case more than one somehow got queried
  /// together. `null` when none are (or none match the current pass),
  /// meaning this field stays fully locked right now. Defaults to table 1
  /// with no itemNumber for Step 1's own triple fields; Nominee's Name/
  /// HName/GName group passes `tableId: 2, itemNumber: <slot>`.
  int? queryModeVariantFor(
    int baseId,
    int hId,
    int gId, {
    int tableId = 1,
    int? itemNumber,
  }) {
    for (final id in [gId, hId, baseId]) {
      if (queryState.isFieldEditable(tableId, id, itemNumber: itemNumber)) {
        return id;
      }
    }
    return null;
  }

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
      // Same resume-in-selected-language fix as getMemberStatus/
      // loadExistingNominees — see _resumeLocalizedValue's doc comment.
      seriousIllnessDetailController.text = _resumeLocalizedValue(
        original: declaration.seriousIllness,
        hindi: declaration.hSeriousIllness,
        gujarati: declaration.gSeriousIllness,
      );
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

      otherHereditaryDetailController.text = _resumeLocalizedValue(
        original: declaration.other,
        hindi: declaration.hOther,
        gujarati: declaration.gOther,
      );
      otherHereditaryLanguages.value = LocalizedTextModel(
        original: declaration.other,
        english: declaration.other,
        hindi: declaration.hOther,
        gujarati: declaration.gOther,
      );
      isOtherHereditaryDirty.value = declaration.other.isNotEmpty &&
          (declaration.hOther.isEmpty || declaration.gOther.isEmpty);

      hadSurgery.value = declaration.isSurgery;
      surgeryDetailController.text = _resumeLocalizedValue(
        original: declaration.surgery,
        hindi: declaration.hSurgery,
        gujarati: declaration.gSurgery,
      );
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
      allergyDetailController.text = _resumeLocalizedValue(
        original: declaration.allergies,
        hindi: declaration.hAllergies,
        gujarati: declaration.gAllergies,
      );
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

      otherHealthDetailController.text = _resumeLocalizedValue(
        original: declaration.otherDetails,
        hindi: declaration.hotherDetails,
        gujarati: declaration.gotherDetails,
      );
      otherHealthDetailLanguages.value = LocalizedTextModel(
        original: declaration.otherDetails,
        english: declaration.otherDetails,
        hindi: declaration.hotherDetails,
        gujarati: declaration.gotherDetails,
      );
      isOtherHealthDetailDirty.value = declaration.otherDetails.isNotEmpty &&
          (declaration.hotherDetails.isEmpty ||
              declaration.gotherDetails.isEmpty);

      // Re-seed AFTER this prefill lands — this method runs asynchronously
      // from the screen's initState and usually finishes after
      // startQueryResolutionMode's own attempt (which found no health data
      // yet to seed against), same reseed-after-load fix as Nominee/Step 1.
      if (queryState.isActive && queryState.hasQueriesForTable(3)) {
        seedQueryModeHealthFields();
        queryState.primeLocalLanguageForScreen(3);
        recheckHealthScriptMismatches();
      }
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
      // Query-resolution mode never calls the transliteration API — the
      // member types each queried field's required script themselves
      // (see QueryResolutionState's doc comment) — so this whole safety
      // net is skipped entirely in that mode, same as Step 1/Nominee's
      // saves.
      if (!queryState.isActive) {
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
      }

      // Every detail field below is read ONLY when its yes/no gate is
      // currently true — otherwise an empty string (null for the surgery
      // date) is sent regardless of what's still sitting in the
      // controller/language model. The setXxx methods above already clear
      // those on toggle-to-"no", but gating here too means a stale value
      // can never reach the API even if some other path changed the
      // gate's Rxn<bool> directly without clearing its detail field.
      // In query-resolution mode a detail box may currently show the
      // Hindi/Gujarati text being fixed (or a value localized to the app
      // language on load), so the plain/English value always comes from
      // the per-language model instead of whatever the box displays.
      String plainOf(TextEditingController c, LocalizedTextModel m) =>
          queryState.isActive && m.original.trim().isNotEmpty
              ? m.original.trim()
              : c.text.trim();

      // A hereditary-detail query unlocks its field even when the
      // hereditary checkbox itself is unticked (see the screen), so its
      // value must still be sent then.
      final sendHereditary = isHereditary ||
          (queryState.isActive &&
              (queryState.hasQueryFor(3, 18) ||
                  queryState.hasQueryFor(3, 32) ||
                  queryState.hasQueryFor(3, 33)));

      // Same idea as [sendHereditary]: a queried detail field is shown
      // (and must be sent) even while its yes/no answer is "no".
      bool queried(List<int> ids) =>
          queryState.isActive &&
          ids.any((id) => queryState.hasQueryFor(3, id));

      final hasIllness =
          hasCurrentIllness.value == true || queried(const [4, 30, 31]);
      final hasSurgery =
          hadSurgery.value == true || queried(const [20, 34, 35, 21]);
      final hasMedication =
          onRegularMedication.value == true || queried(const [23]);
      final hasAllergy =
          hasAllergies.value == true || queried(const [25, 36, 37]);

      final request = HealthDeclarationModel(
        healthDeclarationId: healthDeclarationId.value ?? 0,
        memberId: memberId,
        isSeriousIllness: hasCurrentIllness.value ?? false,
        seriousIllness: hasIllness
            ? plainOf(seriousIllnessDetailController, seriousIllnessLanguages.value)
            : '',
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
        other: sendHereditary
            ? plainOf(otherHereditaryDetailController, otherHereditaryLanguages.value)
            : '',
        hOther: sendHereditary ? otherHereditaryLanguages.value.hindi : '',
        gOther: sendHereditary ? otherHereditaryLanguages.value.gujarati : '',
        isSurgery: hadSurgery.value ?? false,
        surgery: hasSurgery
            ? plainOf(surgeryDetailController, surgeryLanguages.value)
            : '',
        hSurgery: hasSurgery ? surgeryLanguages.value.hindi : '',
        gSurgery: hasSurgery ? surgeryLanguages.value.gujarati : '',
        surgeryDate: hasSurgery ? surgeryDate.value : null,
        ismedicationRegularly: onRegularMedication.value ?? false,
        medicationRegularly:
            hasMedication ? medicationDetailController.text.trim() : '',
        anyAllergies: hasAllergies.value ?? false,
        allergies: hasAllergy
            ? plainOf(allergyDetailController, allergyLanguages.value)
            : '',
        hAllergies: hasAllergy ? allergyLanguages.value.hindi : '',
        gAllergies: hasAllergy ? allergyLanguages.value.gujarati : '',
        tabaccoBidiCigarates: usesTobacco.value ?? false,
        addictionToAlcohol: consumesAlcohol.value ?? false,
        drugs: usesDrugs.value ?? false,
        otherDetails:
            plainOf(otherHealthDetailController, otherHealthDetailLanguages.value),
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
      queryState.setFieldEnums(bundle);
      // The flow may already be running (login can finish before this
      // load does) — set every table up again now the names are known.
      if (queryState.isActive) _primeQueryModeTables();
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

  /// Same 3-tier fallback RegistrationPreviewScreen's _localizedValue and
  /// RegistrationPdfBuilder use for the downloaded PDF — prefer the
  /// currently-selected APP language's own translation, then fall back to
  /// the plain/original text. Used by [getMemberStatus]'s prefill so a
  /// resumed member who picked Hindi/Gujarati sees their own already-saved
  /// translation in this step's EDITABLE fields, not just in the read-only
  /// Preview screen — before this, every *Controller.text below was always
  /// set from the plain/English server field regardless of the selected
  /// app language.
  String _resumeLocalizedValue({
    required String? original,
    required String? hindi,
    required String? gujarati,
  }) {
    final language = Get.find<LanguageController>().currentAppLanguage;

    final fromLanguage = switch (language) {
      AppLanguage.hindi => hindi,
      AppLanguage.gujarati => gujarati,
      AppLanguage.english => original,
    };

    if (fromLanguage != null && fromLanguage.trim().isNotEmpty) {
      return fromLanguage;
    }

    return original ?? '';
  }

  /// The saved value of [model] in the currently selected app language,
  /// falling back to the plain text — `null` when the model holds nothing
  /// at all (never translated / never loaded), so callers can leave
  /// whatever the box already shows alone.
  String? _localizedOrNull(LocalizedTextModel model) {
    if (model.original.trim().isEmpty &&
        model.hindi.trim().isEmpty &&
        model.gujarati.trim().isEmpty) {
      return null;
    }
    return _resumeLocalizedValue(
      original: model.original,
      hindi: model.hindi,
      gujarati: model.gujarati,
    );
  }

  /// "Middle Surname" from the just-entered full name, in the currently
  /// selected app language — used to default the Father/Husband's Name
  /// field for a brand-new member (see [getMemberStatus]'s own doc
  /// comment for where this is used). `null` when there's no middle name
  /// or surname to build it from yet.
  String? defaultFatherNameFromFullName() {
    final parts = [
      _localizedOrNull(middleNameLanguages.value),
      _localizedOrNull(surnameLanguages.value),
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// "First Middle Surname" in the current app language (see
  /// [_localizedOrNull]); `null` if no name has been loaded yet.
  String? localizedFullNameText() {
    final parts = [
      _localizedOrNull(firstNameLanguages.value),
      _localizedOrNull(middleNameLanguages.value),
      _localizedOrNull(surnameLanguages.value),
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  /// Re-shows every saved text value (name-like fields, address block,
  /// occupation, nominee names, health detail boxes) in the app language
  /// that was just selected — the values came from the API with English,
  /// Hindi and Gujarati versions all together, so switching language just
  /// picks the matching one. Numbers (Aadhaar, PAN, mobile, share...) have
  /// no language versions and stay as they are. In query mode, a box that
  /// is currently open for correcting one specific language keeps showing
  /// that language (it is the thing being fixed).
  void refreshLocalizedDisplay() {
    _ensureStep1TripleFields();
    for (final spec in _step1TripleFields) {
      if (queryState.isActive &&
          queryModeVariantFor(spec.baseId, spec.hId, spec.gId) != null) {
        continue;
      }
      final text = _localizedOrNull(spec.model.value);
      if (text != null && spec.controller.text != text) {
        spec.controller.text = text;
      }
    }

    for (final (baseId, hId, gId) in const [
      (18, 32, 33),
      (29, 38, 39),
      (4, 30, 31),
      (20, 34, 35),
      (25, 36, 37),
    ]) {
      if (queryState.isActive &&
          queryModeVariantFor(baseId, hId, gId, tableId: 3) != null) {
        continue;
      }
      final match = _healthFieldSpecFor(baseId);
      if (match == null) continue;
      final (textController, model, _) = match;
      final text = _localizedOrNull(model.value);
      if (text != null && textController.text != text) {
        textController.text = text;
      }
    }

    for (var i = 0; i < nomineeSlots.length; i++) {
      final slot = nomineeSlots[i];
      if (queryState.isActive &&
          queryModeVariantFor(2, 8, 9, tableId: 2, itemNumber: i + 1) !=
              null) {
        continue;
      }
      final text = _localizedOrNull(slot.nameLanguages.value);
      if (text != null && slot.nameController.text != text) {
        slot.nameController.text = text;
      }
    }
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
  // QUERY-RESOLUTION MODE — STEP 1 FIELD MAPPING
  //
  // Every free-text Step 1 field the member can edit today has ONE input
  // (this controller) feeding a single Rx<LocalizedTextModel> with THREE
  // language slots (original/hindi/gujarati) — the H/G slots are normally
  // filled automatically by translateAllStep1Fields, never typed directly.
  // In query-resolution mode there's no separate Gujarati/Hindi box to
  // unlock for e.g. a queried `GAddress`, so the SAME Address field is
  // reused: it displays/edits that specific language slot directly, no
  // auto-translation involved. See QueryResolutionState's doc comment.
  // ============================================================

  /// One field's base/H/G enum ids (see `tblMemberField`) plus how to
  /// read/write its one shared `Rx<LocalizedTextModel>`.
  final List<_TripleFieldSpec> _step1TripleFields = [];

  void _ensureStep1TripleFields() {
    if (_step1TripleFields.isNotEmpty) return;
    _step1TripleFields.addAll([
      _TripleFieldSpec(
        baseId: 12, hId: 13, gId: 14,
        controller: fatherNameController,
        model: fatherNameLanguages,
      ),
      _TripleFieldSpec(
        baseId: 21, hId: 22, gId: 23,
        controller: addressController,
        model: addressLanguages,
      ),
      _TripleFieldSpec(
        baseId: 24, hId: 25, gId: 26,
        controller: villageController,
        model: villageLanguages,
      ),
      _TripleFieldSpec(
        baseId: 27, hId: 28, gId: 29,
        controller: talukaController,
        model: talukaLanguages,
      ),
      _TripleFieldSpec(
        baseId: 30, hId: 31, gId: 32,
        controller: districtController,
        model: districtLanguages,
      ),
      _TripleFieldSpec(
        baseId: 33, hId: 34, gId: 35,
        controller: stateController,
        model: stateLanguages,
      ),
      _TripleFieldSpec(
        baseId: 38, hId: 39, gId: 40,
        controller: occupationController,
        model: occupationLanguages,
      ),
    ]);
  }

  /// Finds which triple-field [fieldId] belongs to and which of its 3
  /// language slots it names — `null` if [fieldId] isn't one of the Step 1
  /// free-text triple fields (e.g. it's Gender/DOB/Aadhaar, or an unknown
  /// id).
  (_TripleFieldSpec, ScriptType)? _step1FieldSpecFor(int fieldId) {
    _ensureStep1TripleFields();
    for (final spec in _step1TripleFields) {
      if (spec.baseId == fieldId) return (spec, ScriptType.latin);
      if (spec.hId == fieldId) return (spec, ScriptType.devanagari);
      if (spec.gId == fieldId) return (spec, ScriptType.gujarati);
    }
    return null;
  }

  /// The current value of the specific language slot [fieldId] names —
  /// used to seed the shared input field's displayed text when it's
  /// unlocked for that slot in query-resolution mode.
  String queryModeStep1FieldText(int fieldId) {
    final match = _step1FieldSpecFor(fieldId);
    if (match != null) {
      final (spec, script) = match;
      return switch (script) {
        ScriptType.gujarati => spec.model.value.gujarati,
        ScriptType.devanagari => spec.model.value.hindi,
        ScriptType.latin => spec.model.value.original,
      };
    }
    final nameScript = _nameScriptOf(fieldId);
    if (nameScript != null) return queryModeFullNameText(nameScript);
    // The 2 plain (no language variant) Step 1 fields query mode can
    // unlock — Aadhaar/PAN numbers — aren't triple-fields, so they fall
    // through _step1FieldSpecFor above.
    if (fieldId == 41) return aadharNumberController.text;
    if (fieldId == 43) return panNumberController.text;
    return '';
  }

  /// Writes [text] into exactly the language slot [fieldId] names (leaving
  /// the field's other slots untouched — they aren't being resolved, so
  /// whatever was already saved for them keeps being sent as-is), marks
  /// the query touched, and updates its script-mismatch state.
  ///
  /// When more than one variant of this SAME field is queried together
  /// (e.g. both plain `Occupation` and `GOccupation` flagged at once),
  /// they are NOT resolved together — only [fieldId]'s own query is
  /// marked. `QueryResolutionState`'s pass system unlocks the sibling
  /// variant afterward (same screen, language switched), one at a time.
  void queryModeUpdateStep1Field(int fieldId, String text) {
    final match = _step1FieldSpecFor(fieldId);
    if (match == null) return;
    final (spec, script) = match;

    spec.model.value = switch (script) {
      ScriptType.gujarati => spec.model.value.copyWith(gujarati: text),
      ScriptType.devanagari => spec.model.value.copyWith(hindi: text),
      ScriptType.latin => spec.model.value.copyWith(original: text, english: text),
    };

    queryState.markTouched(1, fieldId);

    final fieldName = queryState.fieldNameFor(1, fieldId);
    queryState.setScriptMismatch(
      1,
      fieldId,
      !ScriptDetector.matchesRequiredScript(text, fieldName),
    );
  }

  // ---- Name parts (the one "Full Name" box) --------------------------
  //
  // The app has ONE Full Name box for First + Middle + Surname, but the
  // admin can flag each part in each language separately (FirstName=3,
  // LastName/middle=4, Surname=2 and their Gujarati 7/8/6 and Hindi
  // 10/11/9 versions). In query mode that box is reused for whichever
  // language is currently being fixed, showing/editing that language's
  // three parts together; any edit resolves every flagged name part of
  // that language.

  static const Map<ScriptType, List<int>> _nameIdsByScript = {
    ScriptType.latin: [3, 4, 2],
    ScriptType.gujarati: [7, 8, 6],
    ScriptType.devanagari: [10, 11, 9],
  };

  /// The box the Full Name field shows/edits in query mode (kept separate
  /// from the screen's own normal Full Name controller).
  final TextEditingController queryFullNameController =
      TextEditingController();

  ScriptType? _nameScriptOf(int fieldId) {
    for (final entry in _nameIdsByScript.entries) {
      if (entry.value.contains(fieldId)) return entry.key;
    }
    return null;
  }

  /// The language whose flagged name parts are open for editing right now,
  /// or `null` when no name part is flagged in the current pass.
  ScriptType? queryModeNameScript() {
    for (final script in const [
      ScriptType.gujarati,
      ScriptType.devanagari,
      ScriptType.latin,
    ]) {
      if (_nameIdsByScript[script]!
          .any((id) => queryState.isFieldEditable(1, id))) {
        return script;
      }
    }
    return null;
  }

  /// The flagged name-part ids of [script]'s language.
  List<int> queryModeQueriedNameIds(ScriptType script) => [
        for (final id in _nameIdsByScript[script]!)
          if (queryState.hasQueryFor(1, id)) id,
      ];

  /// "First Middle Surname" in [script]'s language, from the saved values.
  String queryModeFullNameText(ScriptType script) {
    String part(Rx<LocalizedTextModel> model) => switch (script) {
          ScriptType.gujarati => model.value.gujarati,
          ScriptType.devanagari => model.value.hindi,
          ScriptType.latin => model.value.original,
        };
    return [
      part(firstNameLanguages),
      part(middleNameLanguages),
      part(surnameLanguages),
    ].where((p) => p.trim().isNotEmpty).join(' ');
  }

  /// Writes an edited Full Name into the current language's first/middle/
  /// surname slots, marks every flagged name part of that language as
  /// touched, and checks the text is in the required script.
  void queryModeUpdateFullName(String text) {
    final script = queryModeNameScript();
    if (script == null) return;

    final words =
        text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final parts = words.length >= 3
        ? [words.first, words.sublist(1, words.length - 1).join(' '), words.last]
        : words.length == 2
            ? [words[0], '', words[1]]
            : [words.isEmpty ? '' : words[0], '', ''];

    void write(Rx<LocalizedTextModel> model, String value) {
      model.value = switch (script) {
        ScriptType.gujarati => model.value.copyWith(gujarati: value),
        ScriptType.devanagari => model.value.copyWith(hindi: value),
        ScriptType.latin =>
          model.value.copyWith(original: value, english: value),
      };
    }

    write(firstNameLanguages, parts[0]);
    write(middleNameLanguages, parts[1]);
    write(surnameLanguages, parts[2]);

    for (final id in _nameIdsByScript[script]!) {
      if (!queryState.hasQueryFor(1, id)) continue;
      queryState.markTouched(1, id);
      queryState.setScriptMismatch(
        1,
        id,
        !ScriptDetector.matchesRequiredScript(
          text,
          queryState.fieldNameFor(1, id),
        ),
      );
    }
  }

  /// Same idea as [queryModeUpdateStep1Field], for a plain field with no
  /// language variants at all (e.g. Aadhaar/PAN numbers) — just marks the
  /// query touched and checks its script (trivially "latin" for numeric
  /// fields, but reused for consistency since a name-like plain field
  /// could theoretically be queried too). No `_step1TripleFields`/model
  /// lookup needed since there's only ever the one slot to begin with.
  void queryModeTouchSimpleField(
    int tableId,
    int fieldId,
    String text, {
    int? itemNumber,
  }) {
    queryState.markTouched(tableId, fieldId, itemNumber: itemNumber);
    final fieldName = queryState.fieldNameFor(tableId, fieldId);
    queryState.setScriptMismatch(
      tableId,
      fieldId,
      !ScriptDetector.matchesRequiredScript(text, fieldName),
      itemNumber: itemNumber,
    );
  }

  /// `true` once every query belonging to table 1's CURRENT pass (see
  /// `QueryResolutionState`'s doc comment) is resolved — gates Next,
  /// additive to the existing Form validation. There may still be a
  /// later pass pending even when this is true; see
  /// [queryModeStep1FullyResolved] for "every query on this table, done".
  bool queryModeStep1Resolved() => queryState.isCurrentPassResolved(1);

  /// `true` once every query on table 1 is resolved, across all passes —
  /// only then does Next actually leave Step 1.
  bool queryModeStep1FullyResolved() => queryState.isTableFullyResolved(1);

  /// Resolves every table-1 query the member just fixed **in this pass**
  /// (not already sent to the API by an earlier pass) — call right after
  /// `saveMemberPersonalDetail()` succeeds, only in query-resolution mode.
  Future<void> resolveStep1Queries() async {
    final ids = queryState.newlyResolvedQueryIdsFor(1);
    for (final queryId in ids) {
      await _repository.queryResolve(queryId: queryId);
    }
    queryState.markApiResolved(ids);
  }

  // ============================================================
  // QUERY-RESOLUTION MODE — NOMINEE (table 2)
  //
  // Only one nominee slot is ever "current" at a time — the lowest
  // itemNumber (ascending nomineeId ordinal) that still has an unresolved
  // query. Every other slot, and every non-queried field within the
  // current slot, stays fully locked. Name/HName/GName(2/8/9) is the one
  // triple-language field here, same base>H>G priority as Step 1's 7;
  // every other nominee field (Relation/Share/DateOfBirth/AadharNo, and
  // the 4 photos) is plain/single-slot, handled the same way Step 1's
  // Aadhaar/PAN and images are.
  // ============================================================

  /// The lowest nominee itemNumber that still has ANY unresolved query —
  /// `null` once every queried nominee is fully done. Drives which single
  /// slot's fields the Nominee screen unlocks at a time — "Complete
  /// Nominee 1's relevant queries before moving to Nominee 2" (see
  /// QueryResolutionState's own class doc comment on passes).
  int? queryModeCurrentNomineeItemNumber() {
    for (final itemNumber in queryState.nomineeItemNumbersWithQueries()) {
      if (!queryState.isTableApiResolved(2, itemNumber: itemNumber)) {
        return itemNumber;
      }
    }
    return null;
  }

  /// Every nominee with at least one still-unresolved query, ascending —
  /// all of them are editable at once on the Nominee screen (one Next
  /// saves each in turn, then resolves its queries).
  List<int> queryModeUnresolvedNominees() => [
        for (final itemNumber in queryState.nomineeItemNumbersWithQueries())
          if (!queryState.isTableApiResolved(2, itemNumber: itemNumber))
            itemNumber,
      ];

  /// Seeds + primes the current pass for every queried nominee.
  void primeAllQueriedNominees() {
    final unresolved = queryModeUnresolvedNominees();
    for (final itemNumber in unresolved) {
      queryState.primeLocalLanguageForScreen(2, itemNumber: itemNumber);
    }
    // Seed AFTER priming — which variant (Name/HName/GName) is editable
    // depends on each nominee's current pass.
    seedQueryModeNomineeFields();
    for (final itemNumber in unresolved) {
      recheckNomineeScriptMismatches(itemNumber);
    }
  }

  /// The current text of nominee [itemNumber]'s Name/HName/GName slot
  /// named by [fieldId] — `''` for any other field id (this only covers
  /// the one triple-language nominee field; see [_nomineeSimpleFieldText]
  /// for the plain ones).
  String queryModeNomineeFieldText(int itemNumber, int fieldId) {
    final slotIndex = itemNumber - 1;
    if (slotIndex < 0 || slotIndex >= nomineeSlots.length) return '';
    final slot = nomineeSlots[slotIndex];
    return switch (fieldId) {
      9 => slot.nameLanguages.value.gujarati,
      8 => slot.nameLanguages.value.hindi,
      2 => slot.nameLanguages.value.original,
      _ => '',
    };
  }

  String _nomineeSimpleFieldText(int itemNumber, int fieldId) {
    final slotIndex = itemNumber - 1;
    if (slotIndex < 0 || slotIndex >= nomineeSlots.length) return '';
    final slot = nomineeSlots[slotIndex];
    return switch (fieldId) {
      13 => slot.aadharNoController.text,
      5 => slot.shareController.text,
      3 => slot.dateOfBirthController.text,
      _ => '',
    };
  }

  /// Overwrites the current nominee's shared Name box with whichever
  /// language slot needs fixing — same idea as [seedQueryModeStep1Fields],
  /// just for the one nominee field that has base/H/G variants. Called
  /// from [startQueryResolutionMode] and again from [loadExistingNominees]
  /// (see its own doc comment), safe to call repeatedly.
  void seedQueryModeNomineeFields() {
    for (final itemNumber in queryState.nomineeItemNumbersWithQueries()) {
      final slotIndex = itemNumber - 1;
      if (slotIndex < 0 || slotIndex >= nomineeSlots.length) continue;
      final variantId =
          queryModeVariantFor(2, 8, 9, tableId: 2, itemNumber: itemNumber);
      if (variantId != null) {
        nomineeSlots[slotIndex].nameController.text =
            queryModeNomineeFieldText(itemNumber, variantId);
      }
    }
  }

  /// Same idea as [recheckStep1ScriptMismatches], for the currently-active
  /// nominee slot — call once from [startQueryResolutionMode] (via
  /// [seedQueryModeNomineeFields]'s caller) and again after every
  /// `queryState.primeLocalLanguageForScreen(2, itemNumber: ...)` call.
  void recheckNomineeScriptMismatches(int itemNumber) {
    for (final fieldId in queryState.editableFieldIds(2, itemNumber: itemNumber)) {
      final text = fieldId == 2 || fieldId == 8 || fieldId == 9
          ? queryModeNomineeFieldText(itemNumber, fieldId)
          : _nomineeSimpleFieldText(itemNumber, fieldId);
      final fieldName = queryState.fieldNameFor(2, fieldId);
      queryState.setScriptMismatch(
        2,
        fieldId,
        !ScriptDetector.matchesRequiredScript(text, fieldName),
        itemNumber: itemNumber,
      );
    }
  }

  /// Writes [text] into nominee [itemNumber]'s Name/HName/GName slot named
  /// by [fieldId] — mirrors [queryModeUpdateStep1Field] for the one
  /// nominee field with language variants.
  void queryModeUpdateNomineeNameField(
    int itemNumber,
    int fieldId,
    String text,
  ) {
    final slotIndex = itemNumber - 1;
    if (slotIndex < 0 || slotIndex >= nomineeSlots.length) return;
    final slot = nomineeSlots[slotIndex];

    slot.nameLanguages.value = switch (fieldId) {
      9 => slot.nameLanguages.value.copyWith(gujarati: text),
      8 => slot.nameLanguages.value.copyWith(hindi: text),
      2 => slot.nameLanguages.value.copyWith(original: text, english: text),
      _ => slot.nameLanguages.value,
    };

    queryModeTouchSimpleField(2, fieldId, text, itemNumber: itemNumber);
  }

  /// `true` once every query belonging to nominee [itemNumber]'s CURRENT
  /// pass is resolved — gates Next the same way [queryModeStep1Resolved]
  /// does for Step 1.
  bool queryModeNomineeCurrentPassResolved(int itemNumber) =>
      queryState.isCurrentPassResolved(2, itemNumber: itemNumber);

  /// `true` once every query on nominee [itemNumber] is resolved, across
  /// all passes.
  bool queryModeNomineeFullyResolved(int itemNumber) =>
      queryState.isTableFullyResolved(2, itemNumber: itemNumber);

  /// Resolves every nominee-[itemNumber] query the member just fixed in
  /// this pass — mirrors [resolveStep1Queries].
  Future<void> resolveNomineeQueries(int itemNumber) async {
    final ids = queryState.newlyResolvedQueryIdsFor(2, itemNumber: itemNumber);
    for (final queryId in ids) {
      await _repository.queryResolve(queryId: queryId);
    }
    queryState.markApiResolved(ids);
  }

  // ============================================================
  // QUERY-RESOLUTION MODE — HEALTH DECLARATION (table 3)
  //
  // Same single-pass mechanics as Step 1 (no itemNumber here — Health
  // Declaration is one record per member, not per-nominee). Only 2 of its
  // fields have base/H/G language variants (Other=18/32/33,
  // otherDetails=29/38/39); the rest this flow can unlock are plain
  // yes/no toggles (IsSeriousIllness=3, IsSurgery=19,
  // AddictionToAlcohol=27, drugs=28) with no script of their own to
  // check, touched directly via queryModeTouchSimpleField (their
  // "true"/"false" text is plain Latin either way, so the existing
  // generic mismatch check is a safe no-op for them).
  // ============================================================

  (TextEditingController, Rx<LocalizedTextModel>, ScriptType)?
      _healthFieldSpecFor(int fieldId) {
    return switch (fieldId) {
      18 => (otherHereditaryDetailController, otherHereditaryLanguages, ScriptType.latin),
      32 => (otherHereditaryDetailController, otherHereditaryLanguages, ScriptType.devanagari),
      33 => (otherHereditaryDetailController, otherHereditaryLanguages, ScriptType.gujarati),
      29 => (otherHealthDetailController, otherHealthDetailLanguages, ScriptType.latin),
      38 => (otherHealthDetailController, otherHealthDetailLanguages, ScriptType.devanagari),
      39 => (otherHealthDetailController, otherHealthDetailLanguages, ScriptType.gujarati),
      4 => (seriousIllnessDetailController, seriousIllnessLanguages, ScriptType.latin),
      30 => (seriousIllnessDetailController, seriousIllnessLanguages, ScriptType.devanagari),
      31 => (seriousIllnessDetailController, seriousIllnessLanguages, ScriptType.gujarati),
      20 => (surgeryDetailController, surgeryLanguages, ScriptType.latin),
      34 => (surgeryDetailController, surgeryLanguages, ScriptType.devanagari),
      35 => (surgeryDetailController, surgeryLanguages, ScriptType.gujarati),
      25 => (allergyDetailController, allergyLanguages, ScriptType.latin),
      36 => (allergyDetailController, allergyLanguages, ScriptType.devanagari),
      37 => (allergyDetailController, allergyLanguages, ScriptType.gujarati),
      _ => null,
    };
  }

  String queryModeHealthFieldText(int fieldId) {
    final match = _healthFieldSpecFor(fieldId);
    if (match == null) return '';
    final (_, model, script) = match;
    return switch (script) {
      ScriptType.gujarati => model.value.gujarati,
      ScriptType.devanagari => model.value.hindi,
      ScriptType.latin => model.value.original,
    };
  }

  void seedQueryModeHealthFields() {
    for (final (baseId, hId, gId) in const [
      (18, 32, 33),
      (29, 38, 39),
      (4, 30, 31),
      (20, 34, 35),
      (25, 36, 37),
    ]) {
      final variantId = queryModeVariantFor(baseId, hId, gId, tableId: 3);
      if (variantId == null) continue;
      final match = _healthFieldSpecFor(variantId);
      if (match == null) continue;
      final (textController, _, _) = match;
      textController.text = queryModeHealthFieldText(variantId);
    }
  }

  void recheckHealthScriptMismatches() {
    for (final fieldId in queryState.editableFieldIds(3)) {
      final text = queryModeHealthFieldText(fieldId);
      final fieldName = queryState.fieldNameFor(3, fieldId);
      queryState.setScriptMismatch(
        3,
        fieldId,
        !ScriptDetector.matchesRequiredScript(text, fieldName),
      );
    }
  }

  void queryModeUpdateHealthField(int fieldId, String text) {
    final match = _healthFieldSpecFor(fieldId);
    if (match == null) return;
    final (_, model, script) = match;

    model.value = switch (script) {
      ScriptType.gujarati => model.value.copyWith(gujarati: text),
      ScriptType.devanagari => model.value.copyWith(hindi: text),
      ScriptType.latin => model.value.copyWith(original: text, english: text),
    };

    queryModeTouchSimpleField(3, fieldId, text);
  }

  bool queryModeHealthResolved() => queryState.isCurrentPassResolved(3);

  bool queryModeHealthFullyResolved() => queryState.isTableFullyResolved(3);

  Future<void> resolveHealthQueries() async {
    final ids = queryState.newlyResolvedQueryIdsFor(3);
    for (final queryId in ids) {
      await _repository.queryResolve(queryId: queryId);
    }
    queryState.markApiResolved(ids);
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

        // The fields display these grouped into the Indian 5+5 format
        // with a space (see AppValidators.formatMobile /
        // _MobileInputFormatter) — strip that back out to the plain
        // 10-digit string the API expects, same as aadharNo below.
        mobile1: AppValidators.stripMobileFormatting(
          mobileController.text.trim(),
        ),
        mobile2: AppValidators.stripMobileFormatting(
          mobile2Controller.text.trim(),
        ),

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

      // Each nominee's Aadhaar must be unique among the OTHER currently
      // visible slots — checked here (not just as a format validator)
      // since it depends on every other slot's own value, not just this
      // one field in isolation.
      final thisAadhar =
          AppValidators.stripAadharFormatting(slot.aadharNoController.text);
      for (var i = 0; i < visibleNomineeSlots.value; i++) {
        if (i == slotIndex) continue;
        final otherAadhar = AppValidators.stripAadharFormatting(
          nomineeSlots[i].aadharNoController.text,
        );
        if (otherAadhar.isNotEmpty && otherAadhar == thisAadhar) {
          ToastUtil.error('nominee_duplicate_aadhaar_error'.tr);
          return false;
        }
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
      // Query-resolution mode never calls the transliteration API — the
      // member types each queried language's text themselves.
      if (!queryState.isActive &&
          (slot.isNameDirty.value ||
              needsTranslation(slot.nameLanguages.value))) {
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
        // In query mode the shared Name box may currently hold the Hindi/
        // Gujarati text being fixed (see seedQueryModeNomineeFields), so
        // the plain name always comes from the per-language model instead.
        name: queryState.isActive &&
                slot.nameLanguages.value.original.trim().isNotEmpty
            ? slot.nameLanguages.value.original.trim()
            : slot.nameController.text.trim(),
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

        // Localized the same way getMemberStatus's own resumed fields are
        // (see _resumeLocalizedValue) — before this, a resumed nominee's
        // name always showed the plain/English value in this editable
        // field regardless of the selected app language, even though
        // nameLanguages (seeded right below) already had the hi/gu
        // translation the whole time.
        slot.nameController.text = _resumeLocalizedValue(
          original: nominee.name,
          hindi: nominee.hName,
          gujarati: nominee.gName,
        );

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

      // Re-seed AFTER this prefill lands, not just once from
      // startQueryResolutionMode — this method runs asynchronously from
      // the screen's initState and usually finishes after that initial
      // seed attempt (which found no nominee data yet to seed against),
      // same reseed-after-load fix as Step 1's getMemberStatus.
      if (queryState.isActive) {
        primeAllQueriedNominees();
      }
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

      // `member.value` is the in-memory record the locally stored id
      // belongs to (the two are always set together, here and in
      // saveMemberStep1) — still checked below so a stale record can be
      // cleared out when a genuinely different name+mobile is submitted
      // (see the result == null branch), but no longer used to decide
      // what this request itself sends.
      final knownMember = member.value;
      final identityChanged = knownMember == null ||
          !_memberMatchesIdentity(
            knownMember,
            firstName: firstName,
            middleName: middleName,
            surname: surname,
            mobile: mobile,
          );

      // Always search fresh by name+mobile — never attach a locally
      // stored memberId to this request, and always pass isRegistered as
      // true. Sending a stored id here used to let the backend resolve
      // the lookup by that id instead of the name/mobile actually being
      // submitted, which meant a second family member registering on the
      // same phone (or a corrected typo) could silently get shown a
      // previous member's data/resume-route instead of a fresh
      // name+mobile search. Always sending memberId 0 removes that risk
      // entirely, by design, rather than only when a mismatch is detected.
      final request =
      GetMemberStatusRequestModel(
        isRegistered: true,
        firstName: firstName,
        lastName: middleName,
        surname: surname,
        mobile: mobile,
        memberId: 0,
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

      fatherNameController.text = _resumeLocalizedValue(
        original: result.fatherName,
        hindi: result.hFatherName,
        gujarati: result.gFatherName,
      );

      // The server returns DOB as an ISO date-time string
      // (e.g. "2026-08-29T10:54:58.5"); parse it so both the picker's
      // DateTime state and the displayed "dd/MM/yyyy" text stay correct,
      // instead of showing the raw ISO string in the field.
      final parsedDateOfBirth = DateTime.tryParse(result.dateOfBirth ?? '');
      dateOfBirth.value = parsedDateOfBirth;
      dateOfBirthController.text = parsedDateOfBirth != null
          ? AppDatePicker.format(parsedDateOfBirth)
          : '';

      addressController.text = _resumeLocalizedValue(
        original: result.address,
        hindi: result.hAddress,
        gujarati: result.gAddress,
      );

      villageController.text = _resumeLocalizedValue(
        original: result.village,
        hindi: result.hVillage,
        gujarati: result.gVillage,
      );

      talukaController.text = _resumeLocalizedValue(
        original: result.taluka,
        hindi: result.hTaluka,
        gujarati: result.gTaluka,
      );

      districtController.text = _resumeLocalizedValue(
        original: result.district,
        hindi: result.hDistrict,
        gujarati: result.gDistrict,
      );

      stateController.text = _resumeLocalizedValue(
        original: result.state,
        hindi: result.hState,
        gujarati: result.gState,
      );

      occupationController.text = _resumeLocalizedValue(
        original: result.occupation,
        hindi: result.hOccupation,
        gujarati: result.gOccupation,
      );

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

      // Father/Husband's Name has no saved value of its own yet for a
      // brand-new member (the fatherNameController.text assignment above
      // just set it to '' in that case) — default it from the middle
      // name + surname just entered on Register, since many members share
      // that with their father. Purely a starting suggestion: still fully
      // editable, and never runs once a real father's name has been saved
      // (fatherNameController.text is non-empty then, from the resumed
      // value above).
      if (fatherNameController.text.trim().isEmpty) {
        final defaultFatherName = defaultFatherNameFromFullName();
        if (defaultFatherName != null) {
          fatherNameController.text = defaultFatherName;
        }
      }

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

      // Step 1's own initState re-confirms this same prefill after
      // navigating in (see _loadMember), which would otherwise clobber
      // query-resolution mode's field seeding (a queried field showing
      // its plain/English value again instead of the specific language
      // slot that actually needs fixing) — reapply it every time this
      // method runs, not just from startQueryResolutionMode, so whichever
      // call happens to run last still leaves the right text showing.
      if (queryState.isActive) {
        seedQueryModeStep1Fields();
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

    if (queryState.isActive) {
      queryModeTouchSimpleField(1, 18, dateOfBirthController.text);
    }
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

    if (queryState.isActive) {
      queryModeTouchSimpleField(3, 21, surgeryDateController.text);
    }
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

    if (queryState.isActive) {
      queryModeTouchSimpleField(
        2,
        3,
        slot.dateOfBirthController.text,
        itemNumber: slotIndex + 1,
      );
    }
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
      if (queryState.isActive) queryState.markTouched(1, 17);
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
      if (queryState.isActive) queryState.markTouched(1, 42);
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
      if (queryState.isActive) queryState.markTouched(1, 61);
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
      if (queryState.isActive) queryState.markTouched(1, 44);
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
      if (queryState.isActive) {
        queryState.markTouched(2, 6, itemNumber: slotIndex + 1);
      }
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
      if (queryState.isActive) {
        queryState.markTouched(2, 10, itemNumber: slotIndex + 1);
      }
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
      if (queryState.isActive) {
        queryState.markTouched(2, 11, itemNumber: slotIndex + 1);
      }
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
      if (queryState.isActive) {
        queryState.markTouched(2, 12, itemNumber: slotIndex + 1);
      }
    }
  }

  // ============================================================
  // SIGNATURE
  // ============================================================

  void setSignature(File file) {
    signatureFile.value = file;
    if (queryState.isActive) queryState.markTouched(1, 45);
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'image_size_limit_note'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
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

  /// In query-resolution mode, the next wizard page to land on from
  /// [fromStep] — skips any page (0/1/2, whose `tableId` is `page+1`)
  /// with no queries at all, since there's nothing to fix there. Page 3
  /// (Rules accept) is outside the table scope and always reached
  /// normally, same as the non-query flow. Backward navigation needs no
  /// matching logic — `previousStep()` already only ever moves one step
  /// at a time, so every step stays reachable going back.
  int queryModeNextPage(int fromStep) {
    var target = fromStep + 1;
    while (target < 3 && !queryState.hasQueriesForTable(target + 1)) {
      target++;
    }
    return target;
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

/// One Step 1 free-text field's base/H/G enum ids plus how to read/write
/// its one shared `Rx<LocalizedTextModel>` — see
/// RegistrationController._step1TripleFields.
class _TripleFieldSpec {
  const _TripleFieldSpec({
    required this.baseId,
    required this.hId,
    required this.gId,
    required this.controller,
    required this.model,
  });

  final int baseId;
  final int hId;
  final int gId;
  final TextEditingController controller;
  final Rx<LocalizedTextModel> model;
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
