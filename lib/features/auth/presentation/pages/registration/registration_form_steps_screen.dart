import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/signature/app_signature_bottom_sheet.dart';
import 'package:psf_application/shared/utils/app_validators.dart';
import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';
import 'package:psf_application/shared/widgets/upload/app_upload_container.dart';

class MemberRegistrationScreen
    extends StatefulWidget {
  const MemberRegistrationScreen({
    super.key,
  });

  @override
  State<MemberRegistrationScreen> createState() =>
      _MemberRegistrationScreenState();
}

class _MemberRegistrationScreenState
    extends State<MemberRegistrationScreen> {
  final controller =
  Get.find<RegistrationController>();

  final PageController pageController =
  PageController();

  final GlobalKey<FormState>
  memberFormKey =
  GlobalKey<FormState>();

  final GlobalKey<FormState>
  nomineeFormKey =
  GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _loadMember();
    });
  }

  Future<void> _loadMember() async {
    final currentMember =
        controller.member.value;

    if (currentMember == null) {
      return;
    }

    await controller.getMemberStatus(
      isRegistered: true,
      firstName:
      currentMember.firstName ?? '',
      middleName:
      currentMember.lastName ?? '',
      surname:
      currentMember.surname ?? '',
      mobile:
      currentMember.mobile ?? '',
    );
  }

  // ============================================================
  // NEXT
  // ============================================================

  Future<void> _next() async {
    final step =
        controller.currentStep.value;

    if (step == 0) {
      if (!memberFormKey.currentState!
          .validate()) {
        return;
      }

      if (controller.profileImage.value ==
          null) {
        _showError(
          'Please upload profile photo',
        );
        return;
      }

      if (controller.signatureFile.value ==
          null) {
        _showError(
          'Please enter your signature',
        );
        return;
      }

      controller.nextStep();

      await pageController.animateToPage(
        1,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      return;
    }

    if (step == 1) {
      if (!nomineeFormKey.currentState!
          .validate()) {
        return;
      }

      if (controller.nomineeImage.value ==
          null) {
        _showError(
          'Please upload nominee photo',
        );
        return;
      }

      controller.nextStep();

      await pageController.animateToPage(
        2,
        duration:
        const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      return;
    }

    await _finishRegistration();
  }

  // ============================================================
  // BACK
  // ============================================================

  Future<void> _back() async {
    if (controller.currentStep.value == 0) {
      Get.back();
      return;
    }

    controller.previousStep();

    await pageController.animateToPage(
      controller.currentStep.value,
      duration:
      const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ============================================================
  // FINISH
  // ============================================================

  Future<void> _finishRegistration() async {
    if (!controller.acceptedRules.value) {
      _showError(
        'Please accept the rules and conditions',
      );
      return;
    }

    // ==========================================================
    // TODO:
    // Call final registration API here.
    //
    // Example:
    //
    // await controller.submitRegistration();
    // ==========================================================

    Get.snackbar(
      'Success',
      'Registration completed successfully',
    );

    Get.offAllNamed(
      AppRoutes.home,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Required',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _openSignature() async {
    final File? signature =
    await Get.bottomSheet<File>(
      const AppSignatureBottomSheet(),
      isScrollControlled: true,
    );

    if (signature != null) {
      controller.setSignature(
        signature,
      );
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Member Registration',
        ),
        backgroundColor:
        AppColors.background,
        elevation: 0,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Obx(
                  () => _StepIndicator(
                currentStep:
                controller.currentStep.value,
              ),
            ),

            SizedBox(
              height: 16.px(context),
            ),

            Expanded(
              child: PageView(
                controller:
                pageController,
                physics:
                const NeverScrollableScrollPhysics(),
                children: [
                  _buildMemberStep(
                    context,
                  ),
                  _buildNomineeStep(
                    context,
                  ),
                  _buildRulesStep(
                    context,
                  ),
                ],
              ),
            ),

            _buildBottomButtons(
              context,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 1
  // ============================================================

  Widget _buildMemberStep(
      BuildContext context,
      ) {
    return Form(
      key: memberFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 20.px(context),
          vertical: 10.px(context),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              context,
              'Personal Details',
            ),

            SizedBox(
              height: 16.px(context),
            ),

            Center(
              child: Obx(
                    () => AppUploadContainer(
                  title: 'Profile Photo',
                  subtitle:
                  'Tap to upload',
                  isCircle: true,
                  width:
                  130.px(context),
                  height:
                  130.px(context),
                  file: controller
                      .profileImage.value,
                  onTap: () {
                    controller
                        .showImageSourceSheet(
                      onSelected:
                      controller
                          .pickProfileImage,
                    );
                  },
                  onRemove: controller
                      .profileImage
                      .value !=
                      null
                      ? () {
                    controller
                        .profileImage
                        .value = null;
                  }
                      : null,
                ),
              ),
            ),

            SizedBox(
              height: 24.px(context),
            ),

            AppTextField.form(
              label: 'Father Name',
              controller:
              controller.fatherNameController,
              validator:
              AppValidators.name,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(
                    r'[a-zA-Z\s]',
                  ),
                ),
              ],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Date of Birth',
              controller:
              controller.dateOfBirthController,
              readOnly: true,
              validator:
              AppValidators.date,
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
              ),
              onTap: () {
                controller.pickDateOfBirth(
                  context,
                );
              },
            ),

            SizedBox(
              height: 16.px(context),
            ),

            Obx(
                  () => _dropdown(
                context: context,
                label: 'Gender',
                value: controller
                    .selectedGender
                    .value
                    .isEmpty
                    ? null
                    : controller
                    .selectedGender
                    .value,
                items: const [
                  'Male',
                  'Female',
                  'Other',
                ],
                onChanged: (value) {
                  controller
                      .selectedGender
                      .value = value ?? '';
                },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Please select gender';
                  }

                  return null;
                },
              ),
            ),

            SizedBox(
              height: 16.px(context),
            ),

            Obx(
                  () => _dropdown(
                context: context,
                label: 'Marital Status',
                value: controller
                    .selectedMaritalStatus
                    .value
                    .isEmpty
                    ? null
                    : controller
                    .selectedMaritalStatus
                    .value,
                items: const [
                  'Single',
                  'Married',
                ],
                onChanged: (value) {
                  controller
                      .selectedMaritalStatus
                      .value =
                      value ?? '';
                },
              ),
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'Address Details',
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Address',
              controller:
              controller.addressController,
              maxLines: 3,
              validator:
              AppValidators.requiredField,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Village',
              controller:
              controller.villageController,
              validator:
              AppValidators.name,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Taluka',
              controller:
              controller.talukaController,
              validator:
              AppValidators.name,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'District',
              controller:
              controller.districtController,
              validator:
              AppValidators.name,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'State',
              controller:
              controller.stateController,
              validator:
              AppValidators.name,
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'Identity Documents',
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Aadhaar Number',
              controller:
              controller
                  .aadharNumberController,
              keyboardType:
              TextInputType.number,
              maxLength: 12,
              validator:
              AppValidators.aadhar,
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly,
              ],
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Obx(
                  () => AppUploadContainer(
                title:
                'Upload Aadhaar Card',
                subtitle:
                'Tap to upload image',
                height:
                180.px(context),
                file: controller
                    .aadharImage.value,
                onTap: () {
                  controller
                      .showImageSourceSheet(
                    onSelected:
                    controller
                        .pickAadharImage,
                  );
                },
                onRemove: controller
                    .aadharImage
                    .value !=
                    null
                    ? () {
                  controller
                      .aadharImage
                      .value = null;
                }
                    : null,
              ),
            ),

            SizedBox(
              height: 20.px(context),
            ),

            AppTextField.form(
              label: 'PAN Number',
              controller:
              controller.panNumberController,
              textCapitalization:
              TextCapitalization.characters,
              validator:
              AppValidators.pan,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9]'),
                ),
              ],
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Obx(
                  () => AppUploadContainer(
                title: 'Upload PAN Card',
                subtitle:
                'Tap to upload image',
                height:
                180.px(context),
                file: controller
                    .panImage.value,
                onTap: () {
                  controller
                      .showImageSourceSheet(
                    onSelected:
                    controller
                        .pickPanImage,
                  );
                },
                onRemove: controller
                    .panImage
                    .value !=
                    null
                    ? () {
                  controller
                      .panImage
                      .value = null;
                }
                    : null,
              ),
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'Occupation',
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Occupation',
              controller:
              controller.occupationController,
              validator:
              AppValidators.name,
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'Signature',
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Obx(
                  () => AppUploadContainer(
                title: 'Your Signature',
                subtitle:
                'Tap to enter signature',
                height:
                160.px(context),
                file: controller
                    .signatureFile.value,
                onTap: _openSignature,
                onRemove: controller
                    .signatureFile.value !=
                    null
                    ? controller.clearSignature
                    : null,
              ),
            ),

            SizedBox(
              height: 30.px(context),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 2
  // ============================================================

  Widget _buildNomineeStep(
      BuildContext context,
      ) {
    return Form(
      key: nomineeFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 20.px(context),
          vertical: 10.px(context),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              context,
              'Nominee Details',
            ),

            SizedBox(
              height: 8.px(context),
            ),

            Text(
              'Please provide the nominee information.',
              style: TextStyle(
                fontSize: 14.px(context),
                color: AppColors.primaryDark
                    .withOpacity(0.65),
              ),
            ),

            SizedBox(
              height: 24.px(context),
            ),

            Center(
              child: Obx(
                    () => AppUploadContainer(
                  title: 'Nominee Photo',
                  subtitle:
                  'Tap to upload',
                  isCircle: true,
                  width:
                  120.px(context),
                  height:
                  120.px(context),
                  file: controller
                      .nomineeImage.value,
                  onTap: () {
                    controller
                        .showImageSourceSheet(
                      onSelected:
                      controller
                          .pickNomineeImage,
                    );
                  },
                  onRemove: controller
                      .nomineeImage
                      .value !=
                      null
                      ? () {
                    controller
                        .nomineeImage
                        .value = null;
                  }
                      : null,
                ),
              ),
            ),

            SizedBox(
              height: 24.px(context),
            ),

            AppTextField.form(
              label: 'First Name',
              controller:
              controller
                  .nomineeFirstNameController,
              validator:
              AppValidators.name,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(
                    r'[a-zA-Z\s]',
                  ),
                ),
              ],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Middle Name',
              controller:
              controller
                  .nomineeMiddleNameController,
              validator:
              AppValidators.name,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(
                    r'[a-zA-Z\s]',
                  ),
                ),
              ],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Surname',
              controller:
              controller
                  .nomineeSurnameController,
              validator:
              AppValidators.name,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(
                    r'[a-zA-Z\s]',
                  ),
                ),
              ],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Relation',
              controller:
              controller
                  .nomineeRelationController,
              validator:
              AppValidators.requiredField,
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Mobile Number',
              controller:
              controller
                  .nomineeMobileController,
              keyboardType:
              TextInputType.phone,
              maxLength: 10,
              validator:
              AppValidators.mobile,
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly,
              ],
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label: 'Date of Birth',
              controller:
              controller
                  .nomineeDateOfBirthController,
              readOnly: true,
              validator:
              AppValidators.date,
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
              ),
              onTap: () {
                controller
                    .pickNomineeDateOfBirth(
                  context,
                );
              },
            ),

            SizedBox(
              height: 24.px(context),
            ),

            _sectionTitle(
              context,
              'Identity Documents',
            ),

            SizedBox(
              height: 16.px(context),
            ),

            AppTextField.form(
              label:
              'Nominee Aadhaar Number',
              keyboardType:
              TextInputType.number,
              maxLength: 12,
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly,
              ],
              validator:
              AppValidators.aadhar,
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Obx(
                  () => AppUploadContainer(
                title:
                'Upload Nominee Aadhaar',
                subtitle:
                'Tap to upload image',
                height:
                180.px(context),
                file: controller
                    .nomineeAadharImage
                    .value,
                onTap: () {
                  controller
                      .showImageSourceSheet(
                    onSelected:
                    controller
                        .pickNomineeAadharImage,
                  );
                },
                onRemove: controller
                    .nomineeAadharImage
                    .value !=
                    null
                    ? () {
                  controller
                      .nomineeAadharImage
                      .value = null;
                }
                    : null,
              ),
            ),

            SizedBox(
              height: 20.px(context),
            ),

            AppTextField.form(
              label: 'Nominee PAN Number',
              textCapitalization:
              TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9]'),
                ),
              ],
              validator:
              AppValidators.pan,
            ),

            SizedBox(
              height: 12.px(context),
            ),

            Obx(
                  () => AppUploadContainer(
                title:
                'Upload Nominee PAN',
                subtitle:
                'Tap to upload image',
                height:
                180.px(context),
                file: controller
                    .nomineePanImage.value,
                onTap: () {
                  controller
                      .showImageSourceSheet(
                    onSelected:
                    controller
                        .pickNomineePanImage,
                  );
                },
                onRemove: controller
                    .nomineePanImage
                    .value !=
                    null
                    ? () {
                  controller
                      .nomineePanImage
                      .value = null;
                }
                    : null,
              ),
            ),

            SizedBox(
              height: 30.px(context),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STEP 3
  // ============================================================

  Widget _buildRulesStep(
      BuildContext context,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        20.px(context),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            context,
            'Rules & Declaration',
          ),

          SizedBox(
            height: 16.px(context),
          ),

          Container(
            padding:
            EdgeInsets.all(
              18.px(context),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                16.px(context),
              ),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _rule(
                  'I confirm that all information provided by me is correct.',
                ),
                _rule(
                  'I understand that incorrect information may result in rejection of my registration.',
                ),
                _rule(
                  'I agree to provide the required documents when requested.',
                ),
                _rule(
                  'I agree to the terms and conditions of Parivar Suraksha Foundation.',
                ),
              ],
            ),
          ),

          SizedBox(
            height: 20.px(context),
          ),

          Obx(
                () => CheckboxListTile(
              value: controller
                  .acceptedRules.value,
              onChanged: (value) {
                controller
                    .acceptedRules
                    .value = value ?? false;
              },
              contentPadding:
              EdgeInsets.zero,
              controlAffinity:
              ListTileControlAffinity.leading,
              title: const Text(
                'I have read and agree to all the above rules and declarations.',
              ),
            ),
          ),

          SizedBox(
            height: 30.px(context),
          ),
        ],
      ),
    );
  }

  Widget _rule(String text) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons(
      BuildContext context,
      ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.px(context),
        12.px(context),
        20.px(context),
        20.px(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color:
            Colors.black.withOpacity(0.08),
            offset:
            const Offset(0, -3),
          ),
        ],
      ),
      child: Obx(
            () {
          final step =
              controller.currentStep.value;

          final isFinish =
              step == 2;

          return Row(
            children: [
              if (step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _back,
                    child:
                    const Text('Back'),
                  ),
                ),
                SizedBox(
                  width: 12.px(context),
                ),
              ],

              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isFinish &&
                      !controller
                          .acceptedRules
                          .value
                      ? null
                      : _next,
                  child: Text(
                    isFinish
                        ? 'Finish'
                        : 'Next',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _dropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>
    onChanged,
    String? Function(String?)?
    validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration:
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),
      items: items
          .map(
            (item) =>
            DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
      )
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
      BuildContext context,
      String title,
      ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.px(context),
        fontWeight:
        FontWeight.w700,
        color:
        AppColors.primaryDark,
      ),
    );
  }
}

// ============================================================================
// STEP INDICATOR
// ============================================================================

class _StepIndicator
    extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({
    required this.currentStep,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    const titles = [
      'Member',
      'Nominee',
      'Finish',
    ];

    return Padding(
      padding:
      EdgeInsets.symmetric(
        horizontal: 20.px(context),
        vertical: 8.px(context),
      ),
      child: Row(
        children: List.generate(
          titles.length,
              (index) {
            final completed =
                index < currentStep;

            final active =
                index == currentStep;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration:
                        const Duration(
                          milliseconds: 250,
                        ),
                        width: 34,
                        height: 34,
                        decoration:
                        BoxDecoration(
                          shape:
                          BoxShape.circle,
                          color: completed ||
                              active
                              ? AppColors.primary
                              : Colors.white,
                          border:
                          Border.all(
                            color: AppColors
                                .primary,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: completed
                              ? const Icon(
                            Icons.check,
                            color:
                            Colors.white,
                            size: 18,
                          )
                              : Text(
                            '${index + 1}',
                            style:
                            TextStyle(
                              color: active
                                  ? Colors.white
                                  : AppColors.primaryDark,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        titles[index],
                        style:
                        TextStyle(
                          fontSize: 11,
                          fontWeight:
                          active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color:
                          active
                              ? AppColors.primaryDark
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  if (index <
                      titles.length - 1)
                    Expanded(
                      child:
                      Container(
                        height: 2,
                        margin:
                        const EdgeInsets
                            .only(
                          bottom: 22,
                        ),
                        color:
                        index < currentStep
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}