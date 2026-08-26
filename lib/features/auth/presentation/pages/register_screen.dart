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

    firstNameFocusNode = FocusNode();
    middleNameFocusNode = FocusNode();
    surnameFocusNode = FocusNode();
    phoneFocusNode = FocusNode();

  }


  @override
  void dispose() {
    firstNameFocusNode.dispose();
    middleNameFocusNode.dispose();
    surnameFocusNode.dispose();
    phoneFocusNode.dispose();

    firstNameController.dispose();
    middleNameController.dispose();
    surnameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ==========================================================
  // CONTINUE (RESUME CHECK & SAVE FLOW)
  // ==========================================================

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Translate any dirty name fields before API call
    await registrationController.translateNameFieldOnUnfocus(
      text: firstNameController.text,
      targetModel: registrationController.firstNameLanguages,
      isDirty: registrationController.isFirstNameDirty,
    );
    await registrationController.translateNameFieldOnUnfocus(
      text: middleNameController.text,
      targetModel: registrationController.middleNameLanguages,
      isDirty: registrationController.isMiddleNameDirty,
    );
    await registrationController.translateNameFieldOnUnfocus(
      text: surnameController.text,
      targetModel: registrationController.surnameLanguages,
      isDirty: registrationController.isSurnameDirty,
    );

    final firstName = firstNameController.text.trim();
    final middleName = middleNameController.text.trim();
    final surname = surnameController.text.trim();
    final mobile = phoneController.text.trim();

    // 1. Call getMemberStatus API to check existing member screen status
    final memberResult = await registrationController.getMemberStatus(
      isRegistered: false,
      firstName: firstName,
      middleName: middleName,
      surname: surname,
      mobile: mobile,
    );

    final targetRoute = RegistrationNavigator.mapScreenNameToRoute(
      memberResult?.memberDetailStatus,
    );

    // 2. If member status returns a screen other than the current registration screen, navigate there
    if (memberResult?.memberDetailStatus != null &&
        memberResult!.memberDetailStatus!.trim().isNotEmpty &&
        targetRoute != AppRoutes.registerScreen) {
      await RegistrationNavigator.navigateToScreen(
        memberResult.memberDetailStatus,
      );
      return;
    }

    // 3. Otherwise (same screen / no screen returned), call save API and navigate to legal rules / next step
    final success = await registrationController.saveMemberStep1(
      mobile: mobile,
    );

    if (success) {
      ToastUtil.success('Information saved successfully');
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
                        onUnfocus: () {
                          registrationController.translateNameFieldOnUnfocus(
                            text: firstNameController.text,
                            targetModel: registrationController.firstNameLanguages,
                            isDirty: registrationController.isFirstNameDirty,
                          );
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
                        onUnfocus: () {
                          registrationController.translateNameFieldOnUnfocus(
                            text: middleNameController.text,
                            targetModel: registrationController.middleNameLanguages,
                            isDirty: registrationController.isMiddleNameDirty,
                          );
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
                        onUnfocus: () {
                          registrationController.translateNameFieldOnUnfocus(
                            text: surnameController.text,
                            targetModel: registrationController.surnameLanguages,
                            isDirty: registrationController.isSurnameDirty,
                          );
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

                          if (phone.length != 10) {
                            return 'please_enter_valid_phone_number'.tr;
                          }

                          if (!RegExp(
                            r'^\d+$',
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
