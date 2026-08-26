import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/core/storage/app_prefs.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/models/localized_text_model.dart';
import 'package:psf_application/shared/navigation/registration_navigator.dart';
import 'package:psf_application/shared/repo/language_translation_repository.dart';
import 'package:psf_application/shared/utils/app_date_picker.dart';
import 'package:psf_application/shared/utils/image_picker_util.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/loaders/app_loader_controller.dart';

import '../../data/models/get_member_status_request_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/save_member_step1_request_model.dart';
import '../../domain/repositories/member_repository.dart';

class RegistrationController extends GetxController {
  RegistrationController(
    this._repository,
    this._translationRepository,);

  final MemberRepository _repository;
  final LanguageTranslationRepository _translationRepository;


  final AppLoaderController _loaderController =
      Get.find<AppLoaderController>();


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
  // MEMBER
  // ============================================================

  final Rxn<MemberModel> member =
  Rxn<MemberModel>();

  // ============================================================
  // STEP
  // ============================================================

  final RxInt currentStep = 0.obs;

  static const int totalSteps = 3;

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

  // ============================================================
  // NOMINEE
  // ============================================================

  final nomineeFirstNameController =
  TextEditingController();

  final nomineeMiddleNameController =
  TextEditingController();

  final nomineeSurnameController =
  TextEditingController();

  final nomineeRelationController =
  TextEditingController();

  final nomineeMobileController =
  TextEditingController();

  final nomineeDateOfBirthController =
  TextEditingController();

  // ============================================================
  // DATE
  // ============================================================

  final Rxn<DateTime> dateOfBirth =
  Rxn<DateTime>();

  final Rxn<DateTime> nomineeDateOfBirth =
  Rxn<DateTime>();

  // ============================================================
  // DROPDOWNS
  // ============================================================

  final RxString selectedGender =
      ''.obs;

  final RxString selectedMaritalStatus =
      ''.obs;

  // ============================================================
  // RULES
  // ============================================================

  final RxBool acceptedRules =
      false.obs;

  // ============================================================
  // IMAGES
  // ============================================================

  final Rxn<File> profileImage =
  Rxn<File>();

  final Rxn<File> aadharImage =
  Rxn<File>();

  final Rxn<File> panImage =
  Rxn<File>();

  final Rxn<File> nomineeImage =
  Rxn<File>();

  final Rxn<File> nomineeAadharImage =
  Rxn<File>();

  final Rxn<File> nomineePanImage =
  Rxn<File>();

  final Rxn<File> signatureFile =
  Rxn<File>();

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
      debugPrint('Translation error on unfocus: $e');
    }
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

      member.value = result;

      await AppSecureStorage.saveMemberId(
        result.memberId,
      );

      await AppPrefs.setRegistrationStatus(
        'Screen 1',
      );

      return true;
    } catch (e) {
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
  // GET MEMBER STATUS
  // ============================================================

  Future<MemberModel?> getMemberStatus({
    required bool isRegistered,
    required String firstName,
    required String middleName,
    required String surname,
    required String mobile,
  }) async {
    try {
      _loaderController.show();

      final memberId =
          (await AppSecureStorage.getMemberId()) ?? 0;

      final request =
      GetMemberStatusRequestModel(
        isRegistered: isRegistered,
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

      dateOfBirthController.text =
          result.dateOfBirth ?? '';

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

      aadharNumberController.text =
          result.aadharNo ?? '';

      panNumberController.text =
          result.panNo ?? '';

      selectedGender.value =
          result.gender ?? '';

      selectedMaritalStatus.value =
          result.maritalStatus ?? '';

      if (result.memberDetailStatus != null) {
        await AppPrefs.setRegistrationStatus(
          result.memberDetailStatus!,
        );
      }

      return result;
    } catch (e) {
      ToastUtil.error(e.toString().replaceFirst('Exception: ', ''));

      return null;
    } finally {
      _loaderController.hide();
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

  Future<void> pickNomineeDateOfBirth(
      BuildContext context,
      ) async {
    final selectedDate =
    await AppDatePicker.pickDate(
      context: context,
      initialDate:
      nomineeDateOfBirth.value ??
          DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate == null) {
      return;
    }

    nomineeDateOfBirth.value =
        selectedDate;

    nomineeDateOfBirthController.text =
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
    );

    if (image != null) {
      aadharImage.value = image;
    }
  }

  Future<void> pickPanImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
    );

    if (image != null) {
      panImage.value = image;
    }
  }

  Future<void> pickNomineeImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
    );

    if (image != null) {
      nomineeImage.value = image;
    }
  }

  Future<void> pickNomineeAadharImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
    );

    if (image != null) {
      nomineeAadharImage.value = image;
    }
  }

  Future<void> pickNomineePanImage(
      ImageSource source,
      ) async {
    final image =
    await ImagePickerUtil.pickImage(
      source: source,
      crop: true,
    );

    if (image != null) {
      nomineePanImage.value = image;
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
                title: const Text(
                  'Camera',
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
                title: const Text(
                  'Gallery',
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

    nomineeFirstNameController.dispose();
    nomineeMiddleNameController.dispose();
    nomineeSurnameController.dispose();
    nomineeRelationController.dispose();
    nomineeMobileController.dispose();
    nomineeDateOfBirthController.dispose();

    super.onClose();
  }
}