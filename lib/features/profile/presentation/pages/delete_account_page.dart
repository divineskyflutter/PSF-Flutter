import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/buttons/app_button.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';

import '../controllers/profile_controller.dart';

/// A dedicated confirmation screen (not just a dialog) for the
/// destructive "Delete Account" action, matching how the rest of the
/// Profile menu's destructive/legal screens are full pages rather than
/// pop-ups.
class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.deleteAccount.tr),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.px(context)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(26.px(context)),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22.px(context)),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76.px(context),
                  height: 76.px(context),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                    size: 34.px(context),
                  ),
                ),
                SizedBox(height: 18.px(context)),
                Text(
                  AppStrings.deleteAccount.tr,
                  style: TextStyle(
                    fontSize: 18.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
                SizedBox(height: 10.px(context)),
                Text(
                  AppStrings.deleteAccountQuestion.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5.px(context), color: AppColors.textSecondary),
                ),
                SizedBox(height: 8.px(context)),
                Text(
                  AppStrings.deleteAccountWarning.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5.px(context),
                    color: AppColors.textSecondary.withOpacity(.8),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24.px(context)),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: AppButton.outlined(
                          label: AppStrings.cancel.tr,
                          onPressed: controller.isDeletingAccount.value ? null : () => Get.back(),
                        ),
                      ),
                      SizedBox(width: 14.px(context)),
                      Expanded(
                        child: AppButton(
                          label: AppStrings.delete.tr,
                          backgroundColor: AppColors.danger,
                          gradient: null,
                          onPressed: controller.isDeletingAccount.value
                              ? null
                              : () => _handleDelete(controller),
                        ),
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

  Future<void> _handleDelete(ProfileController controller) async {
    final success = await controller.deleteAccount();

    if (success) {
      ToastUtil.success(AppStrings.deleteAccount.tr);
      Get.offAllNamed(AppRoutes.authChoice);
    }
  }
}
