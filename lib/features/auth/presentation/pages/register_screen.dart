import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';

import 'package:psf_application/shared/navigation/registration_navigator.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/network/ConnectivityService.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  late final RegistrationController registrationController;
  final _formKey = GlobalKey<FormState>();

  late final FocusNode firstNameFocusNode;
  late final FocusNode middleNameFocusNode;
  late final FocusNode surnameFocusNode;
  late final FocusNode phoneFocusNode;

  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final surnameController = TextEditingController();
  final phoneController = TextEditingController();

  final _nameInputFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z\u0900-\u097F\u0A80-\u0AFF ]'),
  );

  @override
  void initState() {
    super.initState();

    registrationController =
        Get.find<RegistrationController>();

    firstNameFocusNode = FocusNode()
      ..addListener(_onFirstNameFocusChange);
    middleNameFocusNode = FocusNode()
      ..addListener(_onMiddleNameFocusChange);
    surnameFocusNode = FocusNode()
      ..addListener(_onSurnameFocusChange);
    phoneFocusNode = FocusNode();

  }


  @override
  void dispose() {
    firstNameFocusNode
      ..removeListener(_onFirstNameFocusChange)
      ..dispose();
    middleNameFocusNode
      ..removeListener(_onMiddleNameFocusChange)
      ..dispose();
    surnameFocusNode
      ..removeListener(_onSurnameFocusChange)
      ..dispose();
    phoneFocusNode.dispose();

    firstNameController.dispose();
    middleNameController.dispose();
    surnameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ==========================================================
  // BACKGROUND TRANSLATION ON FIELD BLUR
  //
  // Fired the moment the user leaves a name field, so the hi/gu variants
  // are usually already cached by the time they reach Continue. Errors
  // are handled inside translateNameFieldOnUnfocus (toast + isDirty stays
  // true); the Continue-button flow below re-awaits any field still
  // incomplete, so this is a speed optimization, not the only path.
  // ==========================================================

  void _onFirstNameFocusChange() {
    if (firstNameFocusNode.hasFocus) return;

    registrationController.translateNameFieldOnUnfocus(
      text: firstNameController.text,
      targetModel: registrationController.firstNameLanguages,
      isDirty: registrationController.isFirstNameDirty,
    );
  }

  void _onMiddleNameFocusChange() {
    if (middleNameFocusNode.hasFocus) return;

    registrationController.translateNameFieldOnUnfocus(
      text: middleNameController.text,
      targetModel: registrationController.middleNameLanguages,
      isDirty: registrationController.isMiddleNameDirty,
    );
  }

  void _onSurnameFocusChange() {
    if (surnameFocusNode.hasFocus) return;

    registrationController.translateNameFieldOnUnfocus(
      text: surnameController.text,
      targetModel: registrationController.surnameLanguages,
      isDirty: registrationController.isSurnameDirty,
    );
  }

  // ==========================================================
  // CONTINUE (RESUME CHECK & SAVE FLOW)
  // ==========================================================

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard so no focus events fire during the async work
    FocusScope.of(context).unfocus();

    final connectivity = Get.find<ConnectivityService>();
    final interruptionVersion = connectivity.interruptionVersion;
    if (!connectivity.canContinueFlow(interruptionVersion)) {
      connectivity.handleNetworkFailure();
      return;
    }

    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final surname = surnameController.text.trim();
    final mobile = phoneController.text.trim();

    // Translate all dirty / untranslated fields in parallel before calling any API.
    // A field needs translation when:
    //   • it is dirty (user typed something new), OR
    //   • hindi or gujarati is still empty (translation never completed)
    await Future.wait([
      if (registrationController.needsTranslation(
        registrationController.firstNameLanguages.value,
      ) || registrationController.isFirstNameDirty.value)
        registrationController.translateNameFieldOnUnfocus(
          text: firstName,
          targetModel: registrationController.firstNameLanguages,
          isDirty: registrationController.isFirstNameDirty,
        ),
      if (registrationController.needsTranslation(
        registrationController.middleNameLanguages.value,
      ) || registrationController.isMiddleNameDirty.value)
        registrationController.translateNameFieldOnUnfocus(
          text: middleName,
          targetModel: registrationController.middleNameLanguages,
          isDirty: registrationController.isMiddleNameDirty,
        ),
      if (registrationController.needsTranslation(
        registrationController.surnameLanguages.value,
      ) || registrationController.isSurnameDirty.value)
        registrationController.translateNameFieldOnUnfocus(
          text: surname,
          targetModel: registrationController.surnameLanguages,
          isDirty: registrationController.isSurnameDirty,
        ),
    ]);

    // Translation calls may be cancelled when the network drops. Never start
    // the member-status request, save request, or navigation after that.
    if (!connectivity.canContinueFlow(interruptionVersion)) {
      return;
    }

    // A field's translation can still be incomplete here if its API call
    // failed (translateNameFieldOnUnfocus already showed an error toast for
    // that) — block the save instead of silently sending blank/duplicated
    // text for that language.
    final incompleteField =
        registrationController.firstIncompleteNameField();

    if (incompleteField != null) {
      ToastUtil.error(
        '$incompleteField could not be translated. '
            'Please check your connection and try again.',
      );
      return;
    }

    // 1. Call getMemberStatus to check whether this name/mobile already
    // has a registration in progress.
    final memberResult = await registrationController.getMemberStatus(
      isRegistered: true,
      firstName: firstName,
      middleName: middleName,
      surname: surname,
      mobile: mobile,
    );

    // null here means either the connectivity dialog already handled a
    // network drop, or a real error was already toasted inside
    // getMemberStatus — either way, stop.
    if (memberResult == null ||
        !connectivity.canContinueFlow(interruptionVersion)) {
      return;
    }

    // 2. An existing member was found (memberId > 0) — resume wherever
    // they left off using the backend's *route* (memberDetailStatusName,
    // e.g. "/member-registration-step2"), never the raw numeric status
    // code. Do NOT also call SaveMemberStep1 in this case.
    if (memberResult.memberId > 0) {
      final targetRoute = RegistrationNavigator.mapScreenNameToRoute(
        memberResult.memberDetailStatusName,
      );

      if (targetRoute != AppRoutes.registerScreen) {
        await RegistrationNavigator.navigateToScreen(
          memberResult.memberDetailStatusName,
        );

        return;
      }
    }

    // 3. No existing member for this name/mobile — this is the normal
    // first-time path, create one.
    final success = await registrationController.saveMemberStep1(
      mobile: mobile,
    );

    if (success && connectivity.canContinueFlow(interruptionVersion)) {
      ToastUtil.success(
        'information_saved_successfully'.tr,
      );

      await RegistrationNavigator.navigateToScreen(
        AppRoutes.legalRules,
      );
    }
  }


  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.px(context),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 5.px(context),
                      ),

                      // Heading
                      Expanded(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 35.px(context),
                            ),
                            Center(
                              child: Text(
                                'family_safety_foundation'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22.px(context),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Center(
                              child: Text(
                                'family_safety_subtitle'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.px(context),
                                  height: 1.5,
                                  color:
                                      AppColors.primaryDark.withOpacity(0.65),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Logo
                      SvgPicture.asset(
                        AppAssets.logo,
                        height: 45.px(context),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 32.px(context),
                ),

                // ==================================================
                // FORM
                // ==================================================

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // INFORMATION HEADING
                      // ==================================================

                      Text(
                        'enter_your_information'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        'enter_information_correctly'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark.withOpacity(0.60),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ==================================================
                      // FIRST NAME
                      // ==================================================

                      _buildLabel(
                        'first_name'.tr,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AppTextField.form(
                        controller: firstNameController,
                        focusNode: firstNameFocusNode,
                        hintText: 'enter_first_name'.tr,
                        onChanged: (_) {
                          registrationController.isFirstNameDirty.value = true;
                        },
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          _nameInputFormatter,
                        ],
                        validator: (value) {
                          return _validateName(
                            value,
                            'please_enter_first_name'.tr,
                          );
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // MIDDLE NAME
                      // ==================================================

                      _buildLabel(
                        'middle_name'.tr,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AppTextField.form(
                        controller: middleNameController,
                        focusNode: middleNameFocusNode,
                        hintText: 'enter_middle_name'.tr,
                        onChanged: (_) {
                          registrationController.isMiddleNameDirty.value = true;
                        },
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          _nameInputFormatter,
                        ],
                        validator: (value) {
                          return _validateName(
                            value,
                            'please_enter_middle_name'.tr,
                          );
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // SURNAME
                      // ==================================================

                      _buildLabel(
                        'surname'.tr,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AppTextField.form(
                        controller: surnameController,
                        focusNode: surnameFocusNode,
                        hintText: 'enter_surname'.tr,
                        onChanged: (_) {
                          registrationController.isSurnameDirty.value = true;
                        },
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                        ),
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          _nameInputFormatter,
                        ],
                        validator: (value) {
                          return _validateName(
                            value,
                            'please_enter_surname'.tr,
                          );
                        },
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PHONE NUMBER
                      // ==================================================

                      _buildLabel(
                        'phone_number'.tr,
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      AppTextField.form(
                        controller: phoneController,
                        focusNode: phoneFocusNode,

                        hintText: 'enter_mobile_number'.tr,

                        prefixIcon: Container(
                          width: 80,
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  AppAssets.indianFlagGif,
                                  width: 24,
                                  height: 18,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '+91',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),

                        keyboardType: TextInputType.number,

                        textInputAction: TextInputAction.done,

                        maxLength: 10,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],

                        validator: (value) {
                          final phone = value?.trim() ?? '';

                          if (phone.isEmpty) {
                            return 'please_enter_phone_number'.tr;
                          }

                          // Same format as AppValidators.mobile: exactly
                          // 10 digits, no restriction on the leading
                          // digit. Kept in sync with that one so both
                          // screens accept/reject the same numbers.
                          if (!RegExp(
                            r'^\d{10}$',
                          ).hasMatch(phone)) {
                            return 'please_enter_valid_phone_number'.tr;
                          }

                          return null;
                        },

                        // If your AppTextField supports
                        // suffix/prefix customization,
                        // use the country prefix there.
                      ),

                      const SizedBox(
                        height: 30,
                      ),

                      // ==================================================
                      // CONTINUE BUTTON
                      // ==================================================

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.background,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                          ),
                          child: Text(
                            'continue'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // ==================================================
                      // SECURITY
                      // ==================================================

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 24,
                              width: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryDark.withOpacity(
                                    0.35,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: AppColors.primaryDark.withOpacity(
                                  0.55,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'secure_encrypted_login'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryDark.withOpacity(
                                  0.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NAME VALIDATION
  // ==========================================================

  String? _validateName(
    String? value,
    String emptyMessage,
  ) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return emptyMessage;
    }

    // Same characters allowed by the formatter.
    final validName = RegExp(
      r'^[a-zA-Z\u0900-\u097F\u0A80-\u0AFF]+(?:[ ][a-zA-Z\u0900-\u097F\u0A80-\u0AFF]+)*$',
    );

    if (!validName.hasMatch(name)) {
      return 'please_enter_valid_name'.tr;
    }

    return null;
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryDark,
      ),
    );
  }
}
