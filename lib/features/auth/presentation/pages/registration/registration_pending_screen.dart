import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:psf_application/app/constants/app_colors.dart';

class RegistrationPendingScreen extends StatelessWidget {
  const RegistrationPendingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Spacer(),
                Container(
                    width: 108,
                    height: 108,
                    decoration: const BoxDecoration(
                        color: Color(0xFFD9F0ED), shape: BoxShape.circle),
                    child: const Icon(Icons.hourglass_top_rounded,
                        color: AppColors.primary, size: 55)),
                const SizedBox(height: 28),
                Text('approval_pending'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark)),
                const SizedBox(height: 12),
                Text('approval_pending_hint'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        height: 1.55,
                        color: AppColors.primaryDark.withOpacity(.7))),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('approval_time'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark)),
                        const SizedBox(height: 5),
                        Text('approval_time_value'.tr),
                        const Divider(height: 24),
                        Text('contact_us'.tr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark)),
                        const SizedBox(height: 5),
                        Text('support_contact'.tr)
                      ]),
                ),
                const SizedBox(height: 18)
              ]))));
}
