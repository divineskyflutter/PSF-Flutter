// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
//
// import 'package:psf_application/app/constants/app_colors.dart';
// import 'package:psf_application/app/routes/app_routes.dart';
// import 'package:psf_application/features/auth/data/models/member_model.dart';
// import 'package:psf_application/features/auth/presentation/controllers/registration_controller.dart';
// import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
// import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
// import 'package:psf_application/shared/signature/app_signature_bottom_sheet.dart';
// import 'package:psf_application/shared/utils/app_date_picker.dart';
// import 'package:psf_application/shared/utils/app_validators.dart';
// import 'package:psf_application/shared/utils/toast_util.dart';
// import 'package:psf_application/shared/widgets/images/common_image_view.dart';
// import 'package:psf_application/shared/widgets/text_fields/app_text_field.dart';
// import 'package:psf_application/shared/widgets/upload/app_upload_container.dart';
//
// /// Keeps a nominee-share text field honest as the member types: only
// /// digits + a single decimal point (max 2 decimal places, same as before),
// /// AND the resulting number can never exceed 100 — since share is a
// /// percentage and the three nominee slots together can't add up to more
// /// than 100% anyway (see RegistrationController.shareExceedsLimit). This
// /// replaces the old formatter that only capped decimal places and let the
// /// member type arbitrarily large whole numbers (e.g. "9999").
// class _ShareInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//     TextEditingValue oldValue,
//     TextEditingValue newValue,
//   ) {
//     final text = newValue.text;
//
//     if (text.isEmpty) return newValue;
//
//     if (!RegExp(r'^\d{0,3}(\.\d{0,2})?$').hasMatch(text)) {
//       return oldValue;
//     }
//
//     final parsed = double.tryParse(text);
//
//     // A bare "100." or similar partial entry parses fine and is <= 100,
//     // so it's only actually-over-100 numeric values that get rejected.
//     if (parsed != null && parsed > 100) {
//       return oldValue;
//     }
//
//     return newValue;
//   }
// }
//
// class MemberRegistrationScreen
//     extends StatefulWidget {
//   const MemberRegistrationScreen({
//     super.key,
//   });
//
//   @override
//   State<MemberRegistrationScreen> createState() =>
//       _MemberRegistrationScreenState();
// }
//
// class _MemberRegistrationScreenState
//     extends State<MemberRegistrationScreen> {
//   final controller =
//   Get.find<RegistrationController>();
//
//   final PageController pageController =
//   PageController();
//
//   final GlobalKey<FormState>
//   memberFormKey =
//   GlobalKey<FormState>();
//
//   /// One Form key per nominee slot (RegistrationController.nomineeSlots is
//   /// fixed-length, so this is too) — each slot validates independently,
//   /// since slots are revealed/saved one at a time rather than all at once.
//   final List<GlobalKey<FormState>> nomineeSlotFormKeys = List.generate(
//     RegistrationController.maxNominees,
//     (_) => GlobalKey<FormState>(),
//   );
//
//   // ============================================================
//   // BACKGROUND-TRANSLATION FOCUS NODES
//   //
//   // Same pattern as register_screen.dart: fire the translate-on-blur call
//   // the moment the user leaves a field, so its hi/gu variants are usually
//   // already ready by the time Next is pressed.
//   // ============================================================
//
//   late final FocusNode fatherNameFocusNode;
//   late final FocusNode addressFocusNode;
//   late final FocusNode villageFocusNode;
//   late final FocusNode talukaFocusNode;
//   late final FocusNode districtFocusNode;
//   late final FocusNode stateFocusNode;
//   late final FocusNode occupationFocusNode;
//
//   // Health step's own translated free-text detail fields — same
//   // translate-on-blur pattern as the focus nodes above.
//   // medicationDetailController has no focus node here: the swagger
//   // schema's `medicationRegularly` has no hi/gu pair, so nothing needs to
//   // fire on its unfocus (see RegistrationController's doc comment).
//   late final FocusNode seriousIllnessDetailFocusNode;
//   late final FocusNode otherHereditaryDetailFocusNode;
//   late final FocusNode surgeryDetailFocusNode;
//   late final FocusNode allergyDetailFocusNode;
//   late final FocusNode otherHealthDetailFocusNode;
//
//   // Editable combined first+middle+surname field. Seeded from whatever's
//   // already saved (or prefilled via GetMemberStatus) by an `ever()`
//   // worker (see initState) rather than being written directly inside
//   // build — writing to a TextFormField's controller from inside an Obx
//   // builder synchronously notifies that field's listener, which walks up
//   // to the ancestor Form and calls setState() on it mid-build. Flutter
//   // only allows marking a DESCENDANT dirty during a widget's build, not
//   // an ancestor (the enclosing Form, in this case), so that crashed with
//   // "setState() or markNeedsBuild() called during build." Updating the
//   // controller from a worker callback — which runs outside of any build
//   // phase — avoids the whole problem. In practice this worker only ever
//   // fires before the user reaches this screen (member.value is set by
//   // earlier GetMemberStatus/prefill flows, not while this field is being
//   // edited), so it doesn't fight with the user's own edits below.
//   late final TextEditingController fullNameController;
//
//   late final FocusNode fullNameFocusNode;
//
//   Worker? _fullNameWorker;
//
//   final _nameInputFormatter = FilteringTextInputFormatter.allow(
//     RegExp(r'[a-zA-Z\s]'),
//   );
//
//   @override
//   void initState() {
//     super.initState();
//
//     fullNameController = TextEditingController(
//       text: controller.member.value?.fullName ?? '',
//     );
//
//     // `ever` fires only on SUBSEQUENT changes to controller.member, so the
//     // constructor above still needs to seed the initial value itself.
//     _fullNameWorker = ever<MemberModel?>(controller.member, (member) {
//       fullNameController.text = member?.fullName ?? '';
//     });
//
//     fullNameFocusNode = FocusNode()..addListener(_onFullNameFocusChange);
//
//     fatherNameFocusNode = FocusNode()..addListener(_onFatherNameFocusChange);
//     addressFocusNode = FocusNode()..addListener(_onAddressFocusChange);
//     villageFocusNode = FocusNode()..addListener(_onVillageFocusChange);
//     talukaFocusNode = FocusNode()..addListener(_onTalukaFocusChange);
//     districtFocusNode = FocusNode()..addListener(_onDistrictFocusChange);
//     stateFocusNode = FocusNode()..addListener(_onStateFocusChange);
//     occupationFocusNode = FocusNode()..addListener(_onOccupationFocusChange);
//
//     seriousIllnessDetailFocusNode = FocusNode()
//       ..addListener(_onSeriousIllnessDetailFocusChange);
//     otherHereditaryDetailFocusNode = FocusNode()
//       ..addListener(_onOtherHereditaryDetailFocusChange);
//     surgeryDetailFocusNode = FocusNode()
//       ..addListener(_onSurgeryDetailFocusChange);
//     allergyDetailFocusNode = FocusNode()
//       ..addListener(_onAllergyDetailFocusChange);
//     otherHealthDetailFocusNode = FocusNode()
//       ..addListener(_onOtherHealthDetailFocusChange);
//
//     WidgetsBinding.instance
//         .addPostFrameCallback((_) {
//       _loadMember();
//
//       // Prefill the Nominee step from whatever was already saved for this
//       // member, if any — e.g. the member saved one nominee, closed the
//       // app, and reopened it later; GetMemberStatus/legal-rules will have
//       // routed straight back to this screen with memberId already known.
//       // Runs regardless of which step is currently showing since all four
//       // steps share this one screen/controller.
//       controller.loadExistingNominees();
//
//       // Same "prefill from whatever's already saved" reasoning, for the
//       // Health step.
//       controller.loadExistingHealthDeclaration();
//
//       // Resume on the correct internal step (Member/Nominee/Health/Rules)
//       // instead of always opening on step 1 — see
//       // RegistrationNavigator.navigateToScreen, which is the only caller
//       // that ever sets this argument.
//       _applyResumeStepFromArguments();
//     });
//   }
//
//   /// Reads the `initialStep` route argument RegistrationNavigator attaches
//   /// when resuming mid-registration (e.g. the member re-entered their name
//   /// on the Register screen and GetSingleMemberByRegistredStatus returned
//   /// "/member-registration-step3") and jumps straight there — both the
//   /// controller's own step counter (drives _StepIndicator/back-button
//   /// logic) and the PageView itself. A no-op on a fresh registration,
//   /// where no such argument is passed.
//   void _applyResumeStepFromArguments() {
//     final arguments = Get.arguments;
//
//     if (arguments is! Map || arguments['initialStep'] is! int) return;
//
//     final requestedStep = arguments['initialStep'] as int;
//     final step = requestedStep < 0
//         ? 0
//         : (requestedStep > RegistrationController.totalSteps - 1
//             ? RegistrationController.totalSteps - 1
//             : requestedStep);
//
//     controller.currentStep.value = step;
//
//     if (pageController.hasClients) {
//       pageController.jumpToPage(step);
//     }
//   }
//
//   Future<void> _loadMember() async {
//     final currentMember =
//         controller.member.value;
//
//     if (currentMember == null) {
//       return;
//     }
//
//     await controller.getMemberStatus(
//       isRegistered: true,
//       firstName:
//       currentMember.firstName ?? '',
//       middleName:
//       currentMember.lastName ?? '',
//       surname:
//       currentMember.surname ?? '',
//       mobile:
//       currentMember.mobile ?? '',
//     );
//   }
//
//   // ============================================================
//   // FOCUS-CHANGE TRANSLATION LISTENERS
//   // ============================================================
//
//   void _onFullNameFocusChange() {
//     if (fullNameFocusNode.hasFocus) return;
//     controller.splitAndTranslateFullName(fullNameController.text);
//   }
//
//   void _onFatherNameFocusChange() {
//     if (fatherNameFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.fatherNameController.text,
//       targetModel: controller.fatherNameLanguages,
//       isDirty: controller.isFatherNameDirty,
//     );
//   }
//
//   void _onAddressFocusChange() {
//     if (addressFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.addressController.text,
//       targetModel: controller.addressLanguages,
//       isDirty: controller.isAddressDirty,
//     );
//   }
//
//   void _onSeriousIllnessDetailFocusChange() {
//     if (seriousIllnessDetailFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.seriousIllnessDetailController.text,
//       targetModel: controller.seriousIllnessLanguages,
//       isDirty: controller.isSeriousIllnessDirty,
//     );
//   }
//
//   void _onOtherHereditaryDetailFocusChange() {
//     if (otherHereditaryDetailFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.otherHereditaryDetailController.text,
//       targetModel: controller.otherHereditaryLanguages,
//       isDirty: controller.isOtherHereditaryDirty,
//     );
//   }
//
//   void _onSurgeryDetailFocusChange() {
//     if (surgeryDetailFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.surgeryDetailController.text,
//       targetModel: controller.surgeryLanguages,
//       isDirty: controller.isSurgeryDirty,
//     );
//   }
//
//   void _onAllergyDetailFocusChange() {
//     if (allergyDetailFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.allergyDetailController.text,
//       targetModel: controller.allergyLanguages,
//       isDirty: controller.isAllergyDirty,
//     );
//   }
//
//   void _onOtherHealthDetailFocusChange() {
//     if (otherHealthDetailFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.otherHealthDetailController.text,
//       targetModel: controller.otherHealthDetailLanguages,
//       isDirty: controller.isOtherHealthDetailDirty,
//     );
//   }
//
//   void _onVillageFocusChange() {
//     if (villageFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.villageController.text,
//       targetModel: controller.villageLanguages,
//       isDirty: controller.isVillageDirty,
//     );
//   }
//
//   void _onTalukaFocusChange() {
//     if (talukaFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.talukaController.text,
//       targetModel: controller.talukaLanguages,
//       isDirty: controller.isTalukaDirty,
//     );
//   }
//
//   void _onDistrictFocusChange() {
//     if (districtFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.districtController.text,
//       targetModel: controller.districtLanguages,
//       isDirty: controller.isDistrictDirty,
//     );
//   }
//
//   void _onStateFocusChange() {
//     if (stateFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.stateController.text,
//       targetModel: controller.stateLanguages,
//       isDirty: controller.isStateDirty,
//     );
//   }
//
//   void _onOccupationFocusChange() {
//     if (occupationFocusNode.hasFocus) return;
//     controller.translateNameFieldOnUnfocus(
//       text: controller.occupationController.text,
//       targetModel: controller.occupationLanguages,
//       isDirty: controller.isOccupationDirty,
//     );
//   }
//
//   // ============================================================
//   // NEXT
//   // ============================================================
//
//   Future<void> _next() async {
//     final step =
//         controller.currentStep.value;
//
//     if (step == 0) {
//       if (!memberFormKey.currentState!
//           .validate()) {
//         return;
//       }
//
//       // Also passes when a document id already exists (from an earlier
//       // session's upload, prefilled by getMemberStatus) — a returning
//       // member isn't forced to re-pick a photo that already uploaded
//       // successfully. See uploadStep1Documents' matching check.
//       if (controller.profileImage.value == null &&
//           controller.profileImageId.value == null) {
//         _showError(
//           'please_upload_profile_photo'.tr,
//         );
//         return;
//       }
//
//       if (controller.signatureFile.value == null &&
//           controller.signatureFileId.value == null) {
//         _showError(
//           'please_enter_your_signature'.tr,
//         );
//         return;
//       }
//
//       if (controller.selectedGenderId.value == null) {
//         _showError('please_select_gender'.tr);
//         return;
//       }
//
//       if (controller.selectedMaritalStatusId.value == null) {
//         _showError('please_select_marital_status'.tr);
//         return;
//       }
//
//       // Dismiss keyboard so no focus events fire during the async work.
//       FocusScope.of(context).unfocus();
//
//       // Safety net for the full-name split/translate: normally already
//       // done by _onFullNameFocusChange when the field loses focus, this
//       // just guarantees it's finished (and re-attempts it if the previous
//       // attempt failed) even if that never fired in time — same reasoning
//       // as translateAllStep1Fields below. The Form validation above has
//       // already confirmed the text is a validly-formatted full name.
//       await controller.splitAndTranslateFullName(fullNameController.text);
//
//       // Translate every dirty/incomplete field before saving.
//       await controller.translateAllStep1Fields();
//
//       final incompleteField =
//           controller.firstIncompleteStep1Field();
//
//       if (incompleteField != null) {
//         ToastUtil.error(
//           '$incompleteField could not be translated. '
//           'Please check your connection and try again.',
//         );
//         return;
//       }
//
//       // Upload documents, then save the personal-detail step. The loader
//       // is shown internally for the whole sequence.
//       final saved = await controller.saveMemberPersonalDetail();
//
//       if (!saved) {
//         return;
//       }
//
//       ToastUtil.success('information_saved_successfully'.tr);
//
//       controller.nextStep();
//
//       await pageController.animateToPage(
//         1,
//         duration:
//         const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//
//       return;
//     }
//
//     if (step == 1) {
//       // Only the currently-last-visible nominee slot can still be
//       // unsaved here — every earlier slot was already validated + saved
//       // via SaveNominee the moment "Add another nominee" revealed the
//       // next one (see _saveNomineeSlotAndReveal). Re-validating/re-saving
//       // that last slot on Next covers the case where the member filled it
//       // in and tapped Next directly, without ever tapping "Add another".
//       final lastNomineeIndex =
//           controller.visibleNomineeSlots.value - 1;
//
//       if (!nomineeSlotFormKeys[lastNomineeIndex]
//           .currentState!
//           .validate()) {
//         return;
//       }
//
//       final lastSlot =
//           controller.nomineeSlots[lastNomineeIndex];
//
//       if (lastSlot.photo.value == null &&
//           lastSlot.photoDocumentId.value == null) {
//         _showError(
//           'please_upload_nominee_photo'.tr,
//         );
//         return;
//       }
//
//       if (lastSlot.relationId.value == null) {
//         _showError(
//           'please_select_option'.trParams({'label': 'relationship'.tr}),
//         );
//         return;
//       }
//
//       FocusScope.of(context).unfocus();
//
//       final nomineeSaved =
//           await controller.saveNomineeSlot(lastNomineeIndex);
//
//       if (!nomineeSaved) {
//         return;
//       }
//
//       final nomineeScreenSaved =
//           await controller.saveNomineeScreen();
//
//       if (!nomineeScreenSaved) {
//         return;
//       }
//
//       controller.nextStep();
//
//       await pageController.animateToPage(
//         2,
//         duration:
//         const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//
//       return;
//     }
//
//     if (step == 2) {
//       // Health Declaration — the yes/no questions are required (their
//       // attached detail field too, once answered "yes" — see
//       // firstMissingHealthDetail), and SaveMemberHealthDeclaration is
//       // always called here (create on the first Next, update on every one
//       // after).
//       //
//       // Dismiss the keyboard/unfocus whatever detail field was still
//       // being typed in BEFORE calling saveHealthDeclaration — the same
//       // "tap Next without ever tapping away from the field first" case
//       // the Member step's full-name/other text fields guard against.
//       // saveHealthDeclaration() itself awaits each visible detail field's
//       // hi/gu translation (re-reading the controller's current text, not
//       // whatever was last translated) before building the save request,
//       // so the just-typed value's translated languages are always what
//       // gets saved, never a stale/empty one — and only then is the save
//       // API itself called, also awaited.
//       FocusScope.of(context).unfocus();
//
//       final healthDeclarationSaved =
//           await controller.saveHealthDeclaration();
//
//       if (!healthDeclarationSaved) {
//         return;
//       }
//
//       controller.nextStep();
//
//       await pageController.animateToPage(
//         3,
//         duration:
//         const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//       );
//
//       return;
//     }
//
//     await _finishRegistration();
//   }
//
//   // ============================================================
//   // BACK
//   // ============================================================
//
//   Future<void> _back() async {
//     if (controller.currentStep.value == 0) {
//       Get.back();
//       return;
//     }
//
//     controller.previousStep();
//
//     await pageController.animateToPage(
//       controller.currentStep.value,
//       duration:
//       const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }
//
//   // ============================================================
//   // FINISH
//   //
//   // No SaveNominee/finish endpoint was provided for this last step —
//   // nominee details currently have nowhere on the backend to be
//   // submitted. "Finish" here just means the user is done editing, so
//   // this hands off to the Application Preview screen (a review + PDF
//   // download step) instead of completing registration outright — the
//   // actual "registration_completed_successfully" + navigate-home now
//   // happens from that screen's own "Complete Registration" button.
//   // ============================================================
//
//   Future<void> _finishRegistration() async {
//     if (!controller.acceptedRules.value) {
//       _showError(
//         'accept_terms_error'.tr,
//       );
//       return;
//     }
//
//     // SaveRulesRegulationAcceptScreen — this step's own accept-checkbox
//     // save, distinct from SaveRulesRegulationScreen (already called much
//     // earlier, from the Legal Rules screen). Only navigate to Preview once
//     // it succeeds.
//     final accepted = await controller.saveRulesRegulationAcceptScreen();
//
//     if (!accepted) {
//       return;
//     }
//
//     Get.toNamed(
//       AppRoutes.registrationPreview,
//     );
//   }
//
//   void _showError(String message) {
//     ToastUtil.error(message, title: 'required'.tr);
//   }
//
//   Future<void> _openSignature() async {
//     final File? signature =
//     await Get.bottomSheet<File>(
//       const AppSignatureBottomSheet(),
//       isScrollControlled: true,
//     );
//
//     if (signature != null) {
//       controller.setSignature(
//         signature,
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     fatherNameFocusNode
//       ..removeListener(_onFatherNameFocusChange)
//       ..dispose();
//     addressFocusNode
//       ..removeListener(_onAddressFocusChange)
//       ..dispose();
//     villageFocusNode
//       ..removeListener(_onVillageFocusChange)
//       ..dispose();
//     talukaFocusNode
//       ..removeListener(_onTalukaFocusChange)
//       ..dispose();
//     districtFocusNode
//       ..removeListener(_onDistrictFocusChange)
//       ..dispose();
//     stateFocusNode
//       ..removeListener(_onStateFocusChange)
//       ..dispose();
//     occupationFocusNode
//       ..removeListener(_onOccupationFocusChange)
//       ..dispose();
//     seriousIllnessDetailFocusNode
//       ..removeListener(_onSeriousIllnessDetailFocusChange)
//       ..dispose();
//     otherHereditaryDetailFocusNode
//       ..removeListener(_onOtherHereditaryDetailFocusChange)
//       ..dispose();
//     surgeryDetailFocusNode
//       ..removeListener(_onSurgeryDetailFocusChange)
//       ..dispose();
//     allergyDetailFocusNode
//       ..removeListener(_onAllergyDetailFocusChange)
//       ..dispose();
//     otherHealthDetailFocusNode
//       ..removeListener(_onOtherHealthDetailFocusChange)
//       ..dispose();
//
//     fullNameController.dispose();
//     fullNameFocusNode
//       ..removeListener(_onFullNameFocusChange)
//       ..dispose();
//     _fullNameWorker?.dispose();
//
//     pageController.dispose();
//     super.dispose();
//   }
//
//   // ============================================================
//   // BUILD
//   // ============================================================
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor:
//       AppColors.background,
//
//       appBar: AppBar(
//         title: Text(
//           'member_registration'.tr,
//         ),
//         backgroundColor:
//         AppColors.background,
//         elevation: 0,
//       ),
//
//       body: SafeArea(
//         child: Column(
//           children: [
//             Obx(
//                   () => _StepIndicator(
//                 currentStep:
//                 controller.currentStep.value,
//               ),
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             Expanded(
//               child: PageView(
//                 controller:
//                 pageController,
//                 physics:
//                 const NeverScrollableScrollPhysics(),
//                 children: [
//                   _buildMemberStep(
//                     context,
//                   ),
//                   _buildNomineeStep(
//                     context,
//                   ),
//                   _buildHealthStep(
//                     context,
//                   ),
//                   _buildRulesStep(
//                     context,
//                   ),
//                 ],
//               ),
//             ),
//
//             _buildBottomButtons(
//               context,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Shows a network-loaded preview (with a small edit badge) when nothing
//   /// was picked THIS session but [networkUrl] is already available for a
//   /// previously-uploaded document — resumed registration, prefilled by
//   /// RegistrationController.getMemberStatus/loadExistingNominees — falling
//   /// back to the normal [AppUploadContainer] "tap to upload" tile
//   /// otherwise. Generalizes the Stack+CommonImageView pattern
//   /// [_nomineeSlotCard] already uses for the nominee photo so every
//   /// resumable document tile on this wizard (profile, Aadhaar front/back,
//   /// PAN, signature, and the nominee's own new document tiles) shows the
//   /// same way.
//   Widget _uploadOrNetworkImage({
//     required BuildContext context,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//     File? file,
//     String? networkUrl,
//     VoidCallback? onRemove,
//     bool isCircle = false,
//     double? width,
//     double? height,
//   }) {
//     if (file == null && networkUrl != null) {
//       final tileWidth = width ?? double.infinity;
//       final tileHeight = height ?? 160.px(context);
//
//       final image = SizedBox(
//         width: tileWidth,
//         height: tileHeight,
//         child: CommonImageView(
//           image: networkUrl,
//           type: CommonImageType.network,
//           fit: BoxFit.cover,
//           showPlaceholder: false,
//         ),
//       );
//
//       return GestureDetector(
//         onTap: onTap,
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             isCircle
//                 ? ClipOval(child: image)
//                 : ClipRRect(
//               borderRadius: BorderRadius.circular(16.px(context)),
//               child: image,
//             ),
//             Positioned(
//               right: isCircle ? 0 : 8.px(context),
//               bottom: isCircle ? 0 : 8.px(context),
//               child: Container(
//                 padding: EdgeInsets.all(6.px(context)),
//                 decoration: const BoxDecoration(
//                   color: AppColors.primary,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   Icons.edit,
//                   color: Colors.white,
//                   size: 14.px(context),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return AppUploadContainer(
//       title: title,
//       subtitle: subtitle,
//       isCircle: isCircle,
//       width: width,
//       height: height,
//       file: file,
//       onTap: onTap,
//       onRemove: onRemove,
//     );
//   }
//
//   // ============================================================
//   // STEP 1
//   // ============================================================
//
//   Widget _buildMemberStep(
//       BuildContext context,
//       ) {
//     return Form(
//       key: memberFormKey,
//       child: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: 20.px(context),
//           vertical: 10.px(context),
//         ),
//         child: Column(
//           crossAxisAlignment:
//           CrossAxisAlignment.start,
//           children: [
//             _sectionTitle(
//               context,
//               'personal_information'.tr,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             Center(
//               child: Obx(
//                     () => _uploadOrNetworkImage(
//                   context: context,
//                   title: 'profile_photo'.tr,
//                   subtitle:
//                   'tap_to_upload'.tr,
//                   isCircle: true,
//                   width:
//                   130.px(context),
//                   height:
//                   130.px(context),
//                   file: controller
//                       .profileImage.value,
//                   networkUrl: controller
//                       .profileImageUrl.value,
//                   onTap: () {
//                     controller
//                         .showImageSourceSheet(
//                       onSelected:
//                       controller
//                           .pickProfileImage,
//                     );
//                   },
//                   onRemove: controller
//                       .profileImage
//                       .value !=
//                       null
//                       ? () {
//                     controller
//                         .profileImage
//                         .value = null;
//                   }
//                       : null,
//                 ),
//               ),
//             ),
//
//             SizedBox(
//               height: 24.px(context),
//             ),
//
//             // Editable combined first + middle + surname field. Format is
//             // validated (at least "First Surname", each part letters-only,
//             // no leftover double/leading/trailing space from deleting a
//             // word) by AppValidators.fullName; on unfocus (and again right
//             // before Save) the value is split back into parts and each one
//             // re-translated — see splitAndTranslateFullName.
//             AppTextField.form(
//               label: 'full_name'.tr,
//               controller: fullNameController,
//               focusNode: fullNameFocusNode,
//               inputFormatters: [_nameInputFormatter],
//               validator: (value) =>
//                   AppValidators.fullName(value, message: 'full_name_format_error'.tr),
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'father_name'.tr,
//               controller:
//               controller.fatherNameController,
//               focusNode: fatherNameFocusNode,
//               validator:
//               AppValidators.name,
//               inputFormatters: [
//                 _nameInputFormatter,
//               ],
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             // Read-only, same reasoning as Full Name above: this is the
//             // number the member already submitted and confirmed back on
//             // the Register screen (seeded into mobileController.text by
//             // saveMemberStep1, then re-confirmed by getMemberStatus for a
//             // resumed member or saveRulesAcceptance for a brand-new one —
//             // see RegistrationController), so it's a summary field here,
//             // never editable — a correction means going back to Register,
//             // not overwriting the confirmed number in the middle of the
//             // wizard.
//             AppTextField.form(
//               label: 'mobile_number'.tr,
//               controller:
//               controller.mobileController,
//               readOnly: true,
//               enabled: false,
//               keyboardType:
//               TextInputType.phone,
//               maxLength: 10,
//               validator:
//               AppValidators.mobile,
//               inputFormatters: [
//                 FilteringTextInputFormatter
//                     .digitsOnly,
//               ],
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             // Second/alternate number — no API response returns a value
//             // for this one, so it's always blank to start and, unlike
//             // Mobile Number above, isn't required: AppValidators.mobileOptional
//             // only checks the format when the user actually enters
//             // something, instead of demanding a value the API never had.
//             AppTextField.form(
//               label: 'mobile_number_2'.tr,
//               controller:
//               controller.mobile2Controller,
//               keyboardType:
//               TextInputType.phone,
//               maxLength: 10,
//               validator:
//               AppValidators.mobileOptional,
//               inputFormatters: [
//                 FilteringTextInputFormatter
//                     .digitsOnly,
//               ],
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             Row(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: AppTextField.form(
//                     label: 'date_of_birth'.tr,
//                     controller:
//                     controller.dateOfBirthController,
//                     readOnly: true,
//                     validator:
//                     AppValidators.date,
//                     suffixIcon: const Icon(
//                       Icons.calendar_today_outlined,
//                     ),
//                     onTap: () {
//                       controller.pickDateOfBirth(
//                         context,
//                       );
//                     },
//                   ),
//                 ),
//
//                 SizedBox(width: 12.px(context)),
//
//                 // Age, derived automatically from the selected date of
//                 // birth — nothing for the user to enter.
//                 Expanded(
//                   child: Obx(() {
//                     final selectedDateOfBirth =
//                         controller.dateOfBirth.value;
//
//                     final ageText = selectedDateOfBirth != null
//                         ? 'age_years'.trParams({
//                             'age':
//                                 '${AppDatePicker.calculateAge(selectedDateOfBirth)}',
//                           })
//                         : '';
//
//                     return Container(
//                       height: 56,
//                       alignment: Alignment.center,
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 8.px(context),
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius:
//                         BorderRadius.circular(14),
//                         border: Border.all(
//                           color: const Color(0xFFD5D5D5),
//                         ),
//                       ),
//                       child: Text(
//                         ageText,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 13.px(context),
//                           color: AppColors.primaryDark,
//                         ),
//                       ),
//                     );
//                   }),
//                 ),
//               ],
//             ),
//
//             SizedBox(
//               height: 20.px(context),
//             ),
//
//             _sectionTitle(context, 'gender'.tr),
//
//             SizedBox(height: 10.px(context)),
//
//             Obx(() => _genderRadioGroup(context)),
//
//             SizedBox(
//               height: 20.px(context),
//             ),
//
//             Obx(
//                   () => _enumDropdown(
//                 context: context,
//                 label: 'marital_status'.tr,
//                 value: controller
//                     .selectedMaritalStatusId
//                     .value,
//                 items: controller
//                     .maritalStatusOptions
//                     .value,
//                 onChanged: (value) {
//                   controller
//                       .selectedMaritalStatusId
//                       .value = value;
//                 },
//               ),
//             ),
//
//             SizedBox(
//               height: 24.px(context),
//             ),
//
//             _sectionTitle(
//               context,
//               'address_details'.tr,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'address'.tr,
//               controller:
//               controller.addressController,
//               focusNode: addressFocusNode,
//               maxLines: 3,
//               validator:
//               AppValidators.requiredField,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'village'.tr,
//               controller:
//               controller.villageController,
//               focusNode: villageFocusNode,
//               validator:
//               AppValidators.placeName,
//               inputFormatters: [
//                 FilteringTextInputFormatter.allow(
//                   RegExp(r'[a-zA-Z0-9\s,\-]'),
//                 ),
//               ],
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'taluka'.tr,
//               controller:
//               controller.talukaController,
//               focusNode: talukaFocusNode,
//               validator:
//               AppValidators.name,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'district'.tr,
//               controller:
//               controller.districtController,
//               focusNode: districtFocusNode,
//               validator:
//               AppValidators.name,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'state'.tr,
//               controller:
//               controller.stateController,
//               focusNode: stateFocusNode,
//               validator:
//               AppValidators.name,
//             ),
//
//             SizedBox(
//               height: 24.px(context),
//             ),
//
//             _sectionTitle(
//               context,
//               'identity_documents'.tr,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'aadhaar_number'.tr,
//               controller:
//               controller
//                   .aadharNumberController,
//               keyboardType:
//               TextInputType.number,
//               maxLength: 12,
//               validator:
//               AppValidators.aadhar,
//               inputFormatters: [
//                 FilteringTextInputFormatter
//                     .digitsOnly,
//               ],
//             ),
//
//             SizedBox(
//               height: 12.px(context),
//             ),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title:
//                 'aadhaar_photo'.tr,
//                 subtitle:
//                 'tap_to_upload_image'.tr,
//                 height:
//                 180.px(context),
//                 file: controller
//                     .aadharImage.value,
//                 networkUrl: controller
//                     .aadharImageUrl.value,
//                 onTap: () {
//                   controller
//                       .showImageSourceSheet(
//                     onSelected:
//                     controller
//                         .pickAadharImage,
//                   );
//                 },
//                 onRemove: controller
//                     .aadharImage
//                     .value !=
//                     null
//                     ? () {
//                   controller
//                       .aadharImage
//                       .value = null;
//                 }
//                     : null,
//               ),
//             ),
//
//             SizedBox(
//               height: 12.px(context),
//             ),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title:
//                 'aadhaar_back_photo'.tr,
//                 subtitle:
//                 'tap_to_upload_image'.tr,
//                 height:
//                 180.px(context),
//                 file: controller
//                     .aadharBackImage.value,
//                 networkUrl: controller
//                     .aadharBackImageUrl.value,
//                 onTap: () {
//                   controller
//                       .showImageSourceSheet(
//                     onSelected:
//                     controller
//                         .pickAadharBackImage,
//                   );
//                 },
//                 onRemove: controller
//                     .aadharBackImage
//                     .value !=
//                     null
//                     ? () {
//                   controller
//                       .aadharBackImage
//                       .value = null;
//                 }
//                     : null,
//               ),
//             ),
//
//             SizedBox(
//               height: 20.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'pan_number'.tr,
//               controller:
//               controller.panNumberController,
//               textCapitalization:
//               TextCapitalization.characters,
//               validator:
//               AppValidators.pan,
//               inputFormatters: [
//                 FilteringTextInputFormatter.allow(
//                   RegExp(r'[a-zA-Z0-9]'),
//                 ),
//               ],
//             ),
//
//             SizedBox(
//               height: 12.px(context),
//             ),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title: 'upload_pan_card'.tr,
//                 subtitle:
//                 'tap_to_upload_image'.tr,
//                 height:
//                 180.px(context),
//                 file: controller
//                     .panImage.value,
//                 networkUrl: controller
//                     .panImageUrl.value,
//                 onTap: () {
//                   controller
//                       .showImageSourceSheet(
//                     onSelected:
//                     controller
//                         .pickPanImage,
//                   );
//                 },
//                 onRemove: controller
//                     .panImage
//                     .value !=
//                     null
//                     ? () {
//                   controller
//                       .panImage
//                       .value = null;
//                 }
//                     : null,
//               ),
//             ),
//
//             SizedBox(
//               height: 24.px(context),
//             ),
//
//             _sectionTitle(
//               context,
//               'occupation'.tr,
//             ),
//
//             SizedBox(
//               height: 16.px(context),
//             ),
//
//             AppTextField.form(
//               label: 'occupation'.tr,
//               controller:
//               controller.occupationController,
//               focusNode: occupationFocusNode,
//               validator:
//               AppValidators.name,
//             ),
//
//             SizedBox(
//               height: 24.px(context),
//             ),
//
//             _sectionTitle(
//               context,
//               'signature'.tr,
//             ),
//
//             SizedBox(
//               height: 12.px(context),
//             ),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title: 'your_signature'.tr,
//                 subtitle:
//                 'tap_to_enter_signature'.tr,
//                 height:
//                 160.px(context),
//                 file: controller
//                     .signatureFile.value,
//                 networkUrl: controller
//                     .signatureFileUrl.value,
//                 onTap: _openSignature,
//                 onRemove: controller
//                     .signatureFile.value !=
//                     null
//                     ? controller.clearSignature
//                     : null,
//               ),
//             ),
//
//             SizedBox(
//               height: 30.px(context),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // STEP 2 — NOMINEE (up to RegistrationController.maxNominees slots)
//   // ============================================================
//
//   Widget _buildNomineeStep(
//       BuildContext context,
//       ) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal: 20.px(context),
//         vertical: 10.px(context),
//       ),
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//         children: [
//           _sectionTitle(
//             context,
//             'nominee_details'.tr,
//           ),
//
//           SizedBox(
//             height: 8.px(context),
//           ),
//
//           Text(
//             'please_provide_nominee_information'.tr,
//             style: TextStyle(
//               fontSize: 14.px(context),
//               color: AppColors.primaryDark
//                   .withOpacity(0.65),
//             ),
//           ),
//
//           SizedBox(
//             height: 24.px(context),
//           ),
//
//           Obx(() {
//             final visibleCount =
//                 controller.visibleNomineeSlots.value;
//
//             return Column(
//               children: [
//                 for (var index = 0; index < visibleCount; index++) ...[
//                   _nomineeSlotCard(context, index),
//                   SizedBox(height: 20.px(context)),
//                 ],
//
//                 if (visibleCount < RegistrationController.maxNominees)
//                   _addAnotherNomineeButton(context, visibleCount - 1),
//               ],
//             );
//           }),
//
//           SizedBox(height: 12.px(context)),
//
//           _nomineeShareTotal(context),
//
//           SizedBox(
//             height: 30.px(context),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// One nominee's card — photo, name, relationship (dropdown, live from
//   /// GetEnumBundle's Relation list), date of birth, and share. Wrapped in
//   /// its own Form (nomineeSlotFormKeys[index]) so slots can be validated
//   /// and saved independently as they're revealed one at a time.
//   Widget _nomineeSlotCard(
//       BuildContext context,
//       int index,
//       ) {
//     final slot = controller.nomineeSlots[index];
//
//     return Container(
//       padding: EdgeInsets.all(16.px(context)),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16.px(context)),
//         border: Border.all(color: AppColors.border),
//       ),
//       child: Form(
//         key: nomineeSlotFormKeys[index],
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     'nominee_number'.trParams({'n': '${index + 1}'}),
//                     style: TextStyle(
//                       fontSize: 16.px(context),
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.primaryDark,
//                     ),
//                   ),
//                 ),
//                 Obx(
//                       () => slot.isSaved.value
//                       ? Icon(
//                     Icons.check_circle,
//                     color: AppColors.success,
//                     size: 18.px(context),
//                   )
//                       : const SizedBox.shrink(),
//                 ),
//
//                 // Lets the member undo an accidental "Add another nominee"
//                 // tap. Only ever shown for the LAST visible card (removing
//                 // a middle one would leave a gap) and only while it has
//                 // never gone through SaveNominee — the mandatory first
//                 // nominee (index 0) never gets this button either way. See
//                 // RegistrationController.removeLastNomineeSlot for the
//                 // exact rule, including why a prefilled-from-server or
//                 // previously-saved-then-cleared card can only be edited,
//                 // never removed.
//                 Obx(() {
//                   // Read every observable unconditionally, before any
//                   // branching — `index` is a plain int, so a short-circuit
//                   // like `index > 0 && controller.visibleNomineeSlots.value
//                   // == ...` would skip the `.value` reads entirely for the
//                   // first card (index 0), leaving this Obx subscribed to
//                   // nothing. GetX then has no dependency to track, which is
//                   // exactly what threw "the improper use of a GetX has been
//                   // detected" and cascaded into the RenderFlex overflow on
//                   // this Row. Always touching both `.value`s first keeps the
//                   // subscription registered on every build, index 0 included.
//                   final visibleSlots = controller.visibleNomineeSlots.value;
//                   final isSaved = slot.isSaved.value;
//                   final canRemove =
//                       index > 0 && index == visibleSlots - 1 && !isSaved;
//
//                   if (!canRemove) return const SizedBox.shrink();
//
//                   return Padding(
//                     padding: EdgeInsets.only(left: 8.px(context)),
//                     child: SizedBox(
//                       // Explicit bounds so this InkWell can never be handed
//                       // unbounded constraints as a direct Row child — the
//                       // other likely contributor to the reported overflow.
//                       height: 22.px(context),
//                       width: 22.px(context),
//                       child: InkWell(
//                         onTap: controller.removeLastNomineeSlot,
//                         borderRadius: BorderRadius.circular(999),
//                         child: Padding(
//                           padding: EdgeInsets.all(2.px(context)),
//                           child: Icon(
//                             Icons.close_rounded,
//                             color: AppColors.textSecondary,
//                             size: 18.px(context),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }),
//               ],
//             ),
//
//             SizedBox(height: 16.px(context)),
//
//             Center(
//               child: Obx(() {
//                 final pickPhoto = () => controller.showImageSourceSheet(
//                       onSelected: (source) =>
//                           controller.pickNomineeSlotImage(index, source),
//                     );
//
//                 // Nothing picked THIS session, but the nominee already has
//                 // a photo on the server (resumed registration) AND the
//                 // response happened to carry a loadable URL for it (see
//                 // NomineeModel.photoUrl — not guaranteed) — show that
//                 // instead of the "tap to upload" placeholder.
//                 //
//                 // AppUploadContainer itself only knows how to display a
//                 // local File (see its own doc comment), so this is a
//                 // separate small tile rather than a change to that shared
//                 // widget, which every other photo on this wizard also
//                 // uses.
//                 if (slot.photo.value == null && slot.photoUrl.value != null) {
//                   return GestureDetector(
//                     onTap: pickPhoto,
//                     child: Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         ClipOval(
//                           child: SizedBox(
//                             width: 110.px(context),
//                             height: 110.px(context),
//                             child: CommonImageView(
//                               image: slot.photoUrl.value!,
//                               type: CommonImageType.network,
//                               fit: BoxFit.cover,
//                               showPlaceholder: false,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           right: 0,
//                           bottom: 0,
//                           child: Container(
//                             padding: EdgeInsets.all(6.px(context)),
//                             decoration: const BoxDecoration(
//                               color: AppColors.primary,
//                               shape: BoxShape.circle,
//                             ),
//                             child: Icon(
//                               Icons.edit,
//                               color: Colors.white,
//                               size: 14.px(context),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//
//                 return AppUploadContainer(
//                   title: 'nominee_photo'.tr,
//                   subtitle: slot.photo.value == null &&
//                       slot.photoDocumentId.value != null
//                       ? 'file_selected'.tr
//                       : 'tap_to_upload'.tr,
//                   isCircle: true,
//                   width: 110.px(context),
//                   height: 110.px(context),
//                   file: slot.photo.value,
//                   onTap: pickPhoto,
//                   onRemove: slot.photo.value != null
//                       ? () => slot.photo.value = null
//                       : null,
//                 );
//               }),
//             ),
//
//             SizedBox(height: 20.px(context)),
//
//             AppTextField.form(
//               label: 'nominee_name'.tr,
//               controller: slot.nameController,
//               // Leaving this field is what fires the same background
//               // Hindi/Gujarati transliteration every other name field on
//               // this wizard uses (see RegistrationController.onInit,
//               // where this focus node's listener is wired) — sent to
//               // SaveNominee as hName/gName.
//               focusNode: slot.nameFocusNode,
//               validator: AppValidators.name,
//               inputFormatters: [
//                 _nameInputFormatter,
//               ],
//             ),
//
//             SizedBox(height: 16.px(context)),
//
//             Obx(
//                   () => _enumDropdown(
//                 context: context,
//                 label: 'relationship'.tr,
//                 value: slot.relationId.value,
//                 items: controller.relationOptions.value,
//                 onChanged: (value) {
//                   slot.relationId.value = value;
//                 },
//               ),
//             ),
//
//             SizedBox(height: 16.px(context)),
//
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: AppTextField.form(
//                     label: 'date_of_birth'.tr,
//                     controller: slot.dateOfBirthController,
//                     readOnly: true,
//                     validator: AppValidators.date,
//                     suffixIcon: const Icon(
//                       Icons.calendar_today_outlined,
//                     ),
//                     onTap: () {
//                       controller.pickNomineeSlotDateOfBirth(
//                         context,
//                         index,
//                       );
//                     },
//                   ),
//                 ),
//
//                 SizedBox(width: 12.px(context)),
//
//                 // What "share" means exactly isn't specified by the API
//                 // beyond it being a plain nullable number — this app treats
//                 // it as each nominee's percentage of the payout, so it's a
//                 // free-form numeric field with no per-field range, but see
//                 // _nomineeShareTotal / saveNomineeSlot's shareExceedsLimit
//                 // check for the one rule enforced today: the running total
//                 // across all visible nominees can't exceed 100%.
//                 Expanded(
//                   child: AppTextField.form(
//                     label: 'nominee_share'.tr,
//                     controller: slot.shareController,
//                     keyboardType: const TextInputType.numberWithOptions(
//                       decimal: true,
//                     ),
//                     inputFormatters: [
//                       _ShareInputFormatter(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//
//             SizedBox(height: 16.px(context)),
//
//             // Aadhaar number + front/back photo + passbook/cheque photo —
//             // all added to SaveNominee's schema after this card was first
//             // built; none of them are required (see
//             // AppValidators.aadharOptional / NomineeModel's doc comments),
//             // unlike the member's own Aadhaar/PAN on step 1.
//             AppTextField.form(
//               label: 'nominee_aadhaar_number'.tr,
//               controller: slot.aadharNoController,
//               keyboardType: TextInputType.number,
//               maxLength: 12,
//               validator: AppValidators.aadharOptional,
//               inputFormatters: [
//                 FilteringTextInputFormatter.digitsOnly,
//               ],
//             ),
//
//             SizedBox(height: 12.px(context)),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title: 'nominee_aadhaar_front_photo'.tr,
//                 subtitle: 'tap_to_upload_image'.tr,
//                 height: 160.px(context),
//                 file: slot.aadharFrontImage.value,
//                 networkUrl: slot.aadharFrontImageUrl.value,
//                 onTap: () {
//                   controller.showImageSourceSheet(
//                     onSelected: (source) => controller
//                         .pickNomineeSlotAadharFrontImage(index, source),
//                   );
//                 },
//                 onRemove: slot.aadharFrontImage.value != null
//                     ? () => slot.aadharFrontImage.value = null
//                     : null,
//               ),
//             ),
//
//             SizedBox(height: 12.px(context)),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title: 'nominee_aadhaar_back_photo'.tr,
//                 subtitle: 'tap_to_upload_image'.tr,
//                 height: 160.px(context),
//                 file: slot.aadharBackImage.value,
//                 networkUrl: slot.aadharBackImageUrl.value,
//                 onTap: () {
//                   controller.showImageSourceSheet(
//                     onSelected: (source) => controller
//                         .pickNomineeSlotAadharBackImage(index, source),
//                   );
//                 },
//                 onRemove: slot.aadharBackImage.value != null
//                     ? () => slot.aadharBackImage.value = null
//                     : null,
//               ),
//             ),
//
//             SizedBox(height: 12.px(context)),
//
//             Obx(
//                   () => _uploadOrNetworkImage(
//                 context: context,
//                 title: 'nominee_passbook_cheque_photo'.tr,
//                 subtitle: 'tap_to_upload_image'.tr,
//                 height: 160.px(context),
//                 file: slot.passbookChequeImage.value,
//                 networkUrl: slot.passbookChequeImageUrl.value,
//                 onTap: () {
//                   controller.showImageSourceSheet(
//                     onSelected: (source) => controller
//                         .pickNomineeSlotPassbookChequeImage(index, source),
//                   );
//                 },
//                 onRemove: slot.passbookChequeImage.value != null
//                     ? () => slot.passbookChequeImage.value = null
//                     : null,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// "Add another nominee" — validates + saves [lastVisibleIndex] (via
//   /// SaveNominee) and, only on success, reveals the next slot. Hidden once
//   /// all `RegistrationController.maxNominees` slots are visible; Next on
//   /// the last slot is what proceeds from there (see _next()'s step==1
//   /// branch).
//   Widget _addAnotherNomineeButton(
//       BuildContext context,
//       int lastVisibleIndex,
//       ) {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton.icon(
//         onPressed: () => _saveNomineeSlotAndReveal(
//           context,
//           lastVisibleIndex,
//         ),
//         icon: const Icon(Icons.add_circle_outline),
//         label: Text('add_another_nominee'.tr),
//         style: OutlinedButton.styleFrom(
//           padding: EdgeInsets.symmetric(
//             vertical: 14.px(context),
//           ),
//           side: const BorderSide(color: AppColors.primary),
//           foregroundColor: AppColors.primary,
//         ),
//       ),
//     );
//   }
//
//   /// Running total across every visible nominee's share field — recomputed
//   /// live as the member types (see the shareController listeners wired in
//   /// RegistrationController.onInit). Members aren't required to reach
//   /// exactly 100% today (see RegistrationController.shareExceedsLimit's
//   /// doc comment), only warned when they go over it, so this is styled as
//   /// a quiet hint rather than a hard error — the actual block-and-toast
//   /// happens inside saveNomineeSlot, on Add Another / Next.
//   Widget _nomineeShareTotal(BuildContext context) {
//     return Obx(() {
//       final total = controller.totalShareEntered.value;
//       final exceeds = controller.shareExceedsLimit;
//
//       return AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: EdgeInsets.symmetric(
//           horizontal: 14.px(context),
//           vertical: 10.px(context),
//         ),
//         decoration: BoxDecoration(
//           color: exceeds
//               ? AppColors.danger.withOpacity(0.08)
//               : AppColors.primary.withOpacity(0.06),
//           borderRadius: BorderRadius.circular(12.px(context)),
//           border: Border.all(
//             color: exceeds
//                 ? AppColors.danger.withOpacity(0.4)
//                 : AppColors.primary.withOpacity(0.2),
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               exceeds ? Icons.error_outline : Icons.pie_chart_outline,
//               size: 18.px(context),
//               color: exceeds ? AppColors.danger : AppColors.primary,
//             ),
//             SizedBox(width: 8.px(context)),
//             Expanded(
//               child: Text(
//                 exceeds
//                     ? 'nominee_share_exceeds_limit'.trParams({
//                         'total': _formatShareForDisplay(total),
//                       })
//                     : 'nominee_total_share'.trParams({
//                         'total': _formatShareForDisplay(total),
//                       }),
//                 style: TextStyle(
//                   fontSize: 12.5.px(context),
//                   fontWeight: FontWeight.w600,
//                   color: exceeds ? AppColors.danger : AppColors.primaryDark,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     });
//   }
//
//   String _formatShareForDisplay(double value) {
//     return value == value.roundToDouble()
//         ? value.toInt().toString()
//         : value.toStringAsFixed(2);
//   }
//
//   Future<void> _saveNomineeSlotAndReveal(
//       BuildContext context,
//       int index,
//       ) async {
//     if (!nomineeSlotFormKeys[index].currentState!.validate()) {
//       return;
//     }
//
//     final slot = controller.nomineeSlots[index];
//
//     if (slot.photo.value == null && slot.photoDocumentId.value == null) {
//       _showError('please_upload_nominee_photo'.tr);
//       return;
//     }
//
//     if (slot.relationId.value == null) {
//       _showError(
//         'please_select_option'.trParams({'label': 'relationship'.tr}),
//       );
//       return;
//     }
//
//     FocusScope.of(context).unfocus();
//
//     final saved = await controller.saveNomineeSlot(index);
//
//     if (!saved) {
//       return;
//     }
//
//     ToastUtil.success('nominee_saved_successfully'.tr);
//
//     controller.revealNextNomineeSlot();
//   }
//
//
//   // ============================================================
//   // STEP 3 — HEALTH DECLARATION (SaveMemberHealthDeclaration /
//   // GetHealthDeclarationByMemberId)
//   //
//   // Mirrors the Preview screen's / downloaded PDF's health-declaration
//   // page (see registration_preview_screen.dart's _healthDeclarationPage
//   // and registration_pdf_builder.dart's PAGE 3), but interactive instead
//   // of a static read-only render. Every yes/no question's detail field is
//   // shown only once answered "yes" — matches the swagger schema exactly,
//   // see RegistrationController's HEALTH DECLARATION section doc comment
//   // for the full field mapping. Every yes/no question here must be
//   // answered (and its detail field filled in, once answered "yes") to
//   // Continue — see RegistrationController.firstMissingHealthDetail,
//   // called from saveHealthDeclaration() before it will save. Only the
//   // standalone "any other details" field and the 13 fixed disease
//   // checkboxes stay optional.
//   // ============================================================
//
//   Widget _buildHealthStep(
//       BuildContext context,
//       ) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.symmetric(
//         horizontal: 20.px(context),
//         vertical: 10.px(context),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _sectionTitle(context, 'health_declaration_title'.tr),
//
//           SizedBox(height: 8.px(context)),
//
//           Text(
//             'health_declaration_intro'.tr,
//             style: TextStyle(
//               fontSize: 12.5.px(context),
//               fontStyle: FontStyle.italic,
//               color: AppColors.primaryDark.withOpacity(0.65),
//             ),
//           ),
//
//           SizedBox(height: 8.px(context)),
//
//           Text(
//             'health_step_optional_note'.tr,
//             style: TextStyle(
//               fontSize: 11.5.px(context),
//               color: AppColors.primaryDark.withOpacity(0.5),
//               fontStyle: FontStyle.italic,
//             ),
//           ),
//
//           SizedBox(height: 22.px(context)),
//
//           // isSeriousIllness -> seriousIllness (translated)
//           Obx(() {
//             final hasIllness = controller.hasCurrentIllness.value;
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _yesNoField(
//                   context,
//                   question: 'health_q_current_illness'.tr,
//                   value: hasIllness,
//                   onChanged: (value) =>
//                   controller.setHasCurrentIllness(value),
//                 ),
//                 if (hasIllness == true) ...[
//                   SizedBox(height: 12.px(context)),
//                   AppTextField.form(
//                     label: 'health_q_current_illness_detail'.tr,
//                     controller: controller.seriousIllnessDetailController,
//                     focusNode: seriousIllnessDetailFocusNode,
//                     maxLines: 2,
//                   ),
//                 ],
//               ],
//             );
//           }),
//
//           SizedBox(height: 22.px(context)),
//
//           Text(
//             'health_q_past_diseases'.tr,
//             style: TextStyle(
//               fontSize: 14.px(context),
//               fontWeight: FontWeight.w600,
//               color: AppColors.primaryDark,
//             ),
//           ),
//
//           SizedBox(height: 10.px(context)),
//
//           Obx(
//                 () => Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               children: [
//                 for (final key in RegistrationController.diseaseKeys)
//                   _diseaseChip(context, key),
//               ],
//             ),
//           ),
//
//           // anyHerediatry -> other (translated) — the 'disease_hereditary'
//           // chip's own "please specify" detail.
//           Obx(() {
//             final isHereditary =
//                 controller.selectedDiseaseKeys.contains('disease_hereditary');
//
//             if (!isHereditary) return const SizedBox.shrink();
//
//             return Padding(
//               padding: EdgeInsets.only(top: 12.px(context)),
//               child: AppTextField.form(
//                 label: 'health_hereditary_detail'.tr,
//                 controller: controller.otherHereditaryDetailController,
//                 focusNode: otherHereditaryDetailFocusNode,
//                 maxLines: 2,
//               ),
//             );
//           }),
//
//           SizedBox(height: 22.px(context)),
//
//           // isSurgery -> surgery + surgeryDate (translated)
//           Obx(() {
//             final hadSurgery = controller.hadSurgery.value;
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _yesNoField(
//                   context,
//                   question: 'health_q_surgery'.tr,
//                   value: hadSurgery,
//                   onChanged: (value) => controller.setHadSurgery(value),
//                 ),
//                 if (hadSurgery == true) ...[
//                   SizedBox(height: 12.px(context)),
//                   AppTextField.form(
//                     label: 'health_q_surgery_detail'.tr,
//                     controller: controller.surgeryDetailController,
//                     focusNode: surgeryDetailFocusNode,
//                     maxLines: 2,
//                   ),
//                   SizedBox(height: 12.px(context)),
//                   AppTextField.form(
//                     label: 'health_q_surgery_date'.tr,
//                     controller: controller.surgeryDateController,
//                     readOnly: true,
//                     suffixIcon: const Icon(Icons.calendar_today_outlined),
//                     onTap: () => controller.pickSurgeryDate(context),
//                   ),
//                 ],
//               ],
//             );
//           }),
//
//           SizedBox(height: 22.px(context)),
//
//           // ismedicationRegularly -> medicationRegularly (NOT translated —
//           // the swagger schema has no h/g pair for this field).
//           Obx(() {
//             final onMedication = controller.onRegularMedication.value;
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _yesNoField(
//                   context,
//                   question: 'health_q_medication'.tr,
//                   value: onMedication,
//                   onChanged: (value) =>
//                   controller.setOnRegularMedication(value),
//                 ),
//                 if (onMedication == true) ...[
//                   SizedBox(height: 12.px(context)),
//                   AppTextField.form(
//                     label: 'health_q_medication_detail'.tr,
//                     controller: controller.medicationDetailController,
//                     maxLines: 2,
//                   ),
//                 ],
//               ],
//             );
//           }),
//
//           SizedBox(height: 22.px(context)),
//
//           // anyAllergies -> allergies (translated)
//           Obx(() {
//             final hasAllergies = controller.hasAllergies.value;
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _yesNoField(
//                   context,
//                   question: 'health_q_allergy'.tr,
//                   value: hasAllergies,
//                   onChanged: (value) =>
//                   controller.setHasAllergies(value),
//                 ),
//                 if (hasAllergies == true) ...[
//                   SizedBox(height: 12.px(context)),
//                   AppTextField.form(
//                     label: 'health_q_allergy_detail'.tr,
//                     controller: controller.allergyDetailController,
//                     focusNode: allergyDetailFocusNode,
//                     maxLines: 2,
//                   ),
//                 ],
//               ],
//             );
//           }),
//
//           SizedBox(height: 22.px(context)),
//
//           Obx(
//                 () => _yesNoField(
//               context,
//               question: 'health_q_tobacco'.tr,
//               value: controller.usesTobacco.value,
//               onChanged: (value) => controller.usesTobacco.value = value,
//             ),
//           ),
//
//           SizedBox(height: 16.px(context)),
//
//           Obx(
//                 () => _yesNoField(
//               context,
//               question: 'health_q_alcohol'.tr,
//               value: controller.consumesAlcohol.value,
//               onChanged: (value) => controller.consumesAlcohol.value = value,
//             ),
//           ),
//
//           SizedBox(height: 16.px(context)),
//
//           Obx(
//                 () => _yesNoField(
//               context,
//               question: 'health_q_drugs'.tr,
//               value: controller.usesDrugs.value,
//               onChanged: (value) => controller.usesDrugs.value = value,
//             ),
//           ),
//
//           SizedBox(height: 22.px(context)),
//
//           // otherDetails (translated) — standalone, always optional, no
//           // yes/no gate (the swagger schema has no boolean flag for it).
//           AppTextField.form(
//             label: 'health_q_other'.tr,
//             controller: controller.otherHealthDetailController,
//             focusNode: otherHealthDetailFocusNode,
//             maxLines: 2,
//           ),
//
//           SizedBox(height: 30.px(context)),
//         ],
//       ),
//     );
//   }
//
//   Widget _yesNoField(
//       BuildContext context, {
//         required String question,
//         required bool? value,
//         required ValueChanged<bool?> onChanged,
//       }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           question,
//           style: TextStyle(fontSize: 14.px(context)),
//         ),
//         SizedBox(height: 8.px(context)),
//         Row(
//           children: [
//             _yesNoChip(
//               context,
//               label: 'yes'.tr,
//               selected: value == true,
//               onTap: () => onChanged(true),
//             ),
//             SizedBox(width: 12.px(context)),
//             _yesNoChip(
//               context,
//               label: 'no'.tr,
//               selected: value == false,
//               onTap: () => onChanged(false),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _yesNoChip(
//       BuildContext context, {
//         required String label,
//         required bool selected,
//         required VoidCallback onTap,
//       }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: 22.px(context),
//           vertical: 10.px(context),
//         ),
//         decoration: BoxDecoration(
//           color: selected ? AppColors.primary : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: selected ? AppColors.primary : AppColors.border,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: selected ? Colors.white : AppColors.primaryDark,
//             fontWeight: FontWeight.w600,
//             fontSize: 13.px(context),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _diseaseChip(BuildContext context, String key) {
//     final selected = controller.selectedDiseaseKeys.contains(key);
//
//     return InkWell(
//       onTap: () => controller.toggleDiseaseKey(key),
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: 14.px(context),
//           vertical: 9.px(context),
//         ),
//         decoration: BoxDecoration(
//           color: selected ? AppColors.primary.withOpacity(0.12) : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: selected ? AppColors.primary : AppColors.border,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               selected
//                   ? Icons.check_box_rounded
//                   : Icons.check_box_outline_blank_rounded,
//               size: 16,
//               color: selected ? AppColors.primary : AppColors.textSecondary,
//             ),
//             SizedBox(width: 6.px(context)),
//             Text(
//               key.tr,
//               style: TextStyle(
//                 fontSize: 12.5.px(context),
//                 color: AppColors.primaryDark,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ============================================================
//   // STEP 4 — RULES & DECLARATION
//   // ============================================================
//
//   Widget _buildRulesStep(
//       BuildContext context,
//       ) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(
//         20.px(context),
//       ),
//       child: Column(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//         children: [
//           _sectionTitle(
//             context,
//             'rules_and_declaration'.tr,
//           ),
//
//           SizedBox(
//             height: 16.px(context),
//           ),
//
//           Container(
//             padding:
//             EdgeInsets.all(
//               18.px(context),
//             ),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//               BorderRadius.circular(
//                 16.px(context),
//               ),
//               border: Border.all(
//                 color: AppColors.border,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment:
//               CrossAxisAlignment.start,
//               children: [
//                 _rule(
//                   'rule_info_correct'.tr,
//                 ),
//                 _rule(
//                   'rule_info_rejection'.tr,
//                 ),
//                 _rule(
//                   'rule_provide_documents'.tr,
//                 ),
//                 _rule(
//                   'rule_agree_foundation_terms'.tr,
//                 ),
//               ],
//             ),
//           ),
//
//           SizedBox(
//             height: 20.px(context),
//           ),
//
//           Obx(
//                 () => CheckboxListTile(
//               value: controller
//                   .acceptedRules.value,
//               onChanged: (value) {
//                 controller
//                     .acceptedRules
//                     .value = value ?? false;
//               },
//               contentPadding:
//               EdgeInsets.zero,
//               controlAffinity:
//               ListTileControlAffinity.leading,
//               title: Text(
//                 'agree_terms'.tr,
//               ),
//             ),
//           ),
//
//           SizedBox(
//             height: 30.px(context),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _rule(String text) {
//     return Padding(
//       padding:
//       const EdgeInsets.only(
//         bottom: 14,
//       ),
//       child: Row(
//         crossAxisAlignment:
//         CrossAxisAlignment.start,
//         children: [
//           const Icon(
//             Icons.check_circle_outline,
//             color: AppColors.primary,
//             size: 20,
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ============================================================
//   // BOTTOM BUTTONS
//   // ============================================================
//
//   Widget _buildBottomButtons(
//       BuildContext context,
//       ) {
//     return Container(
//       padding: EdgeInsets.fromLTRB(
//         20.px(context),
//         12.px(context),
//         20.px(context),
//         20.px(context),
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             blurRadius: 12,
//             color:
//             Colors.black.withOpacity(0.08),
//             offset:
//             const Offset(0, -3),
//           ),
//         ],
//       ),
//       child: Obx(
//             () {
//           final step =
//               controller.currentStep.value;
//
//           final isFinish =
//               step == 3;
//
//           return Row(
//             children: [
//               if (step > 0) ...[
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: _back,
//                     child:
//                     Text('back'.tr),
//                   ),
//                 ),
//                 SizedBox(
//                   width: 12.px(context),
//                 ),
//               ],
//
//               Expanded(
//                 flex: 2,
//                 child: ElevatedButton(
//                   onPressed: isFinish &&
//                       !controller
//                           .acceptedRules
//                           .value
//                       ? null
//                       : _next,
//                   child: Text(
//                     isFinish
//                         ? 'finish'.tr
//                         : 'next'.tr,
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   // ============================================================
//   // GENDER — RADIO GROUP (live from GetEnumBundle)
//   // ============================================================
//
//   Widget _genderRadioGroup(BuildContext context) {
//     if (controller.isLoadingEnumOptions.value &&
//         controller.genderOptions.value.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 8),
//         child: SizedBox(
//           height: 20,
//           width: 20,
//           child: CircularProgressIndicator(strokeWidth: 2),
//         ),
//       );
//     }
//
//     if (controller.genderOptions.value.isEmpty) {
//       return Row(
//         children: [
//           Text(
//             'could_not_load_options'.trParams({'label': 'gender'.tr}),
//             style: TextStyle(
//               fontSize: 13.px(context),
//               color: AppColors.primaryDark.withOpacity(0.6),
//             ),
//           ),
//           TextButton(
//             onPressed: controller.loadEnumOptions,
//             child: Text('retry'.tr),
//           ),
//         ],
//       );
//     }
//
//     // Column, not Row — stays readable regardless of how many options the
//     // backend returns or how long their labels are.
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: controller.genderOptions.value.map((option) {
//         return RadioListTile<int>(
//           value: option.id,
//           groupValue: controller.selectedGenderId.value,
//           onChanged: (value) {
//             controller.selectedGenderId.value = value;
//           },
//           title: Text(
//             option.name,
//             style: TextStyle(fontSize: 14.px(context)),
//           ),
//           contentPadding: EdgeInsets.zero,
//           dense: true,
//           activeColor: AppColors.primary,
//         );
//       }).toList(),
//     );
//   }
//
//   // ============================================================
//   // ENUM-BACKED DROPDOWN (Marital Status)
//   // ============================================================
//
//   Widget _enumDropdown({
//     required BuildContext context,
//     required String label,
//     required int? value,
//     required List<EnumItem> items,
//     required ValueChanged<int?> onChanged,
//   }) {
//     if (controller.isLoadingEnumOptions.value && items.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 8),
//         child: SizedBox(
//           height: 20,
//           width: 20,
//           child: CircularProgressIndicator(strokeWidth: 2),
//         ),
//       );
//     }
//
//     if (items.isEmpty) {
//       return Row(
//         children: [
//           Expanded(
//             child: Text(
//               'could_not_load_options'.trParams({'label': label}),
//               style: TextStyle(
//                 fontSize: 13.px(context),
//                 color: AppColors.primaryDark.withOpacity(0.6),
//               ),
//             ),
//           ),
//           TextButton(
//             onPressed: controller.loadEnumOptions,
//             child: Text('retry'.tr),
//           ),
//         ],
//       );
//     }
//
//     // items contains the currently selected value (or it's null), so this
//     // matches DropdownButtonFormField's requirement that `value` be one of
//     // `items`' values (or null).
//     final validValue =
//         items.any((item) => item.id == value) ? value : null;
//
//     return DropdownButtonFormField<int>(
//       value: validValue,
//       decoration:
//       InputDecoration(
//         labelText: label,
//         filled: true,
//         fillColor: Colors.white,
//         border:
//         OutlineInputBorder(
//           borderRadius:
//           BorderRadius.circular(
//             14,
//           ),
//         ),
//       ),
//       items: items
//           .map(
//             (item) =>
//             DropdownMenuItem<int>(
//               value: item.id,
//               child: Text(item.name),
//             ),
//       )
//           .toList(),
//       onChanged: onChanged,
//       validator: (value) {
//         if (value == null) {
//           return 'please_select_option'.trParams({'label': label});
//         }
//         return null;
//       },
//     );
//   }
//
//   // ============================================================
//   // SECTION TITLE
//   // ============================================================
//
//   Widget _sectionTitle(
//       BuildContext context,
//       String title,
//       ) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 20.px(context),
//         fontWeight:
//         FontWeight.w700,
//         color:
//         AppColors.primaryDark,
//       ),
//     );
//   }
// }
//
// // ============================================================================
// // STEP INDICATOR
// // ============================================================================
//
// class _StepIndicator
//     extends StatelessWidget {
//   final int currentStep;
//
//   const _StepIndicator({
//     required this.currentStep,
//   });
//
//   @override
//   Widget build(
//       BuildContext context,
//       ) {
//     final titles = [
//       'step_member'.tr,
//       'step_nominee'.tr,
//       'step_health'.tr,
//       'finish'.tr,
//     ];
//
//     // Each step's circle+label is its own fixed-size widget (NOT wrapped
//     // in an equal-width Expanded segment). Only the connector lines
//     // between them are Expanded, so they soak up exactly the leftover
//     // space. This is what makes the first circle sit flush at the left
//     // edge and the LAST circle sit flush at the right edge, with the
//     // steps spread evenly across the full width in between.
//     //
//     // The previous version wrapped every step — including the last one —
//     // in its own equal 1/3-width Expanded segment, with the connector
//     // line only ever trailing after a circle. Since the last step had no
//     // trailing connector to fill its segment, that whole final third of
//     // the row sat empty, and the entire indicator visually read as
//     // pushed toward the left with unused space on the right.
//     final children = <Widget>[];
//
//     for (var index = 0; index < titles.length; index++) {
//       final completed = index < currentStep;
//       final active = index == currentStep;
//
//       children.add(
//         Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             AnimatedContainer(
//               duration: const Duration(
//                 milliseconds: 250,
//               ),
//               width: 34,
//               height: 34,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: completed || active
//                     ? AppColors.primary
//                     : Colors.white,
//                 border: Border.all(
//                   color: AppColors.primary,
//                   width: 1.5,
//                 ),
//               ),
//               child: Center(
//                 child: completed
//                     ? const Icon(
//                   Icons.check,
//                   color: Colors.white,
//                   size: 18,
//                 )
//                     : Text(
//                   '${index + 1}',
//                   style: TextStyle(
//                     color: active
//                         ? Colors.white
//                         : AppColors.primaryDark,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Text(
//               titles[index],
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: active
//                     ? FontWeight.w700
//                     : FontWeight.w500,
//                 color: active
//                     ? AppColors.primaryDark
//                     : Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       );
//
//       if (index < titles.length - 1) {
//         children.add(
//           Expanded(
//             child: Container(
//               height: 2,
//               margin: const EdgeInsets.only(
//                 bottom: 22,
//               ),
//               color: index < currentStep
//                   ? AppColors.primary
//                   : Colors.grey.shade300,
//             ),
//           ),
//         );
//       }
//     }
//
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: 20.px(context),
//         vertical: 8.px(context),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: children,
//       ),
//     );
//   }
// }
