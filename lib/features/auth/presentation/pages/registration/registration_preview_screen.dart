// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:psf_application/app/constants/app_colors.dart';
// import 'package:psf_application/app/routes/app_routes.dart';
// import 'package:psf_application/core/storage/app_prefs.dart';
// import 'package:psf_application/features/registration/domain/models/registration_application.dart';
//
// class RegistrationPreviewScreen extends StatefulWidget {
//   const RegistrationPreviewScreen({super.key});
//   @override
//   State<RegistrationPreviewScreen> createState() =>
//       _RegistrationPreviewScreenState();
// }
//
// class _RegistrationPreviewScreenState extends State<RegistrationPreviewScreen> {
//   bool _submitting = false;
//   late final RegistrationApplication application;
//   @override
//   void initState() {
//     super.initState();
//     application = Get.arguments as RegistrationApplication;
//   }
//
//   Future<void> _complete() async {
//     setState(() => _submitting = true);
//     // The API contract is intentionally kept at the model boundary. When the
//     // registration endpoint is provided, submit application.toJson() here and
//     // use its server-generated PDF download URL below.
//     await Future<void>.delayed(const Duration(milliseconds: 700));
//     await AppPrefs.setRegistrationStatus('pending');
//     if (!mounted) return;
//     await Get.dialog(_SuccessDialog(), barrierDismissible: false);
//     if (mounted) Get.offAllNamed(AppRoutes.registrationPending);
//   }
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//           child: Column(children: [
//         Padding(
//             padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
//             child: Row(children: [
//               IconButton(
//                   onPressed: Get.back,
//                   icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19)),
//               const Spacer(),
//               Text('application_preview'.tr,
//                   style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.primaryDark)),
//               const Spacer(),
//               IconButton(
//                   onPressed: _downloadOriginal,
//                   icon: const Icon(Icons.download_rounded,
//                       color: AppColors.primary),
//                   tooltip: 'download_pdf'.tr)
//             ])),
//         Expanded(
//             child: PageView(children: [_pageOne(), _pageTwo(), _termsPage()])),
//         Padding(
//             padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
//             child: SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                     onPressed: _submitting ? null : _complete,
//                     style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14))),
//                     child: _submitting
//                         ? const SizedBox(
//                             height: 22,
//                             width: 22,
//                             child: CircularProgressIndicator(
//                                 color: Colors.white, strokeWidth: 2))
//                         : Text('complete_registration'.tr,
//                             style: const TextStyle(
//                                 fontWeight: FontWeight.w700))))),
//       ])));
//
//   void _downloadOriginal() =>
//       Get.snackbar('download_pdf'.tr, 'download_from_server'.tr,
//           snackPosition: SnackPosition.BOTTOM);
//   Widget _paper(Widget child) => Container(
//       margin: const EdgeInsets.fromLTRB(24, 20, 24, 28),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(4),
//           boxShadow: const [
//             BoxShadow(
//                 color: AppColors.shadow, blurRadius: 15, offset: Offset(0, 6))
//           ]),
//       child: child);
//   Widget _pageOne() =>
//       _paper(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Center(
//             child: Column(children: [
//           const Icon(Icons.volunteer_activism_rounded,
//               size: 46, color: AppColors.primary),
//           const SizedBox(height: 6),
//           Text('family_safety_foundation'.tr,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w800,
//                   color: AppColors.primaryDark)),
//           const Divider(height: 28)
//         ])),
//         Text('beneficiary_application'.tr,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
//         const SizedBox(height: 18),
//         _line('full_name'.tr, application.fullName),
//         _line('fathers_name'.tr, application.fatherName),
//         _line('date_of_birth'.tr, application.dateOfBirth),
//         _line('gender'.tr, application.gender.tr),
//         _line('phone_number'.tr, application.mobile),
//         _line('aadhaar_number'.tr, application.aadhaarNumber),
//         _line('address'.tr, application.address),
//         const Spacer(),
//         Text('page_count'.trParams({'page': '1', 'total': '3'}),
//             style: const TextStyle(color: AppColors.textSecondary)),
//       ]));
//   Widget _pageTwo() =>
//       _paper(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text('nominee_details'.tr,
//             style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.primaryDark)),
//         const Divider(height: 28),
//         ...application.nominees.expand((n) => [
//               _line('nominee_name'.tr, n.name),
//               _line('relationship'.tr, n.relationship),
//               _line('phone_number'.tr, n.mobile),
//               const SizedBox(height: 10)
//             ]),
//         const Spacer(),
//         Text('page_count'.trParams({'page': '2', 'total': '3'}),
//             style: const TextStyle(color: AppColors.textSecondary))
//       ]));
//   Widget _termsPage() =>
//       _paper(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text('declaration'.tr,
//             style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800,
//                 color: AppColors.primaryDark)),
//         const Divider(height: 28),
//         Text('declaration_text'.tr, style: const TextStyle(height: 1.65)),
//         const Spacer(),
//         const Icon(Icons.verified_rounded, color: AppColors.primary, size: 36),
//         const SizedBox(height: 8),
//         Text('agree_terms'.tr,
//             style: const TextStyle(fontWeight: FontWeight.w700)),
//         const Spacer(),
//         Text('page_count'.trParams({'page': '3', 'total': '3'}),
//             style: const TextStyle(color: AppColors.textSecondary))
//       ]));
//   Widget _line(String label, String value) => Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: RichText(
//           text: TextSpan(
//               style:
//                   const TextStyle(color: AppColors.textPrimary, fontSize: 14),
//               children: [
//             TextSpan(
//                 text: '$label: ',
//                 style: const TextStyle(fontWeight: FontWeight.w700)),
//             TextSpan(text: value)
//           ])));
// }
//
// class _SuccessDialog extends StatefulWidget {
//   @override
//   State<_SuccessDialog> createState() => _SuccessDialogState();
// }
//
// class _SuccessDialogState extends State<_SuccessDialog>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 850))
//       ..forward();
//     Timer(const Duration(seconds: 5), () {
//       if (mounted) Get.back();
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) => Dialog(
//       child: Padding(
//           padding: const EdgeInsets.all(30),
//           child: Column(mainAxisSize: MainAxisSize.min, children: [
//             ScaleTransition(
//                 scale: CurvedAnimation(
//                     parent: _controller, curve: Curves.elasticOut),
//                 child: const CircleAvatar(
//                     radius: 35,
//                     backgroundColor: Color(0xFFDEF4E8),
//                     child: Icon(Icons.celebration_rounded,
//                         size: 42, color: AppColors.primary))),
//             const SizedBox(height: 20),
//             Text('registration_submitted'.tr,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w800,
//                     color: AppColors.primaryDark)),
//             const SizedBox(height: 8),
//             Text('registration_submitted_hint'.tr,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(height: 1.45))
//           ])));
// }
