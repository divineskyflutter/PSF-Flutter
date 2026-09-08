import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/app/routes/app_routes.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_header_curve_clipper.dart';
import 'package:psf_application/shared/widgets/common/app_menu_tile.dart';
import 'package:psf_application/shared/widgets/dialogs/app_dialog.dart';

import '../controllers/profile_controller.dart';

/// Profile tab root — the branded header (avatar + name + member id) and
/// the settings-style menu (Profile / Membership Card / Passbook /
/// Language / About Us / Terms & Conditions / Privacy Policy / Contact Us
/// / Logout / Delete Account), all built from [AppMenuTile] so every row
/// looks and behaves the same.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(controller: controller),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16.px(context),
                  20.px(context),
                  16.px(context),
                  32.px(context),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20.px(context)),
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 6.px(context)),
                      AppMenuTile(
                        icon: Icons.person_outline_rounded,
                        label: AppStrings.myProfile.tr,
                        onTap: () => Get.toNamed(AppRoutes.myProfile),
                      ),
                      AppMenuTile(
                        icon: Icons.badge_outlined,
                        label: AppStrings.membershipCard.tr,
                        onTap: () => Get.toNamed(AppRoutes.membershipCard),
                      ),
                      AppMenuTile(
                        icon: Icons.menu_book_outlined,
                        label: AppStrings.passbook.tr,
                        onTap: () => Get.toNamed(AppRoutes.passbook),
                      ),
                      AppMenuTile(
                        icon: Icons.translate_rounded,
                        label: AppStrings.language.tr,
                        onTap: () => _openLanguageSettings(context),
                      ),
                      AppMenuTile(
                        icon: Icons.info_outline_rounded,
                        label: AppStrings.aboutUs.tr,
                        onTap: () => Get.toNamed(AppRoutes.aboutUs),
                      ),
                      AppMenuTile(
                        icon: Icons.description_outlined,
                        label: AppStrings.termsAndConditionsApply.tr,
                        onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
                      ),
                      AppMenuTile(
                        icon: Icons.shield_outlined,
                        label: AppStrings.privacyPolicy.tr,
                        onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                      ),
                      AppMenuTile(
                        icon: Icons.support_agent_outlined,
                        label: AppStrings.contactUs.tr,
                        onTap: () => Get.toNamed(AppRoutes.contactUs),
                      ),
                      AppMenuTile(
                        icon: Icons.logout_rounded,
                        label: AppStrings.logout.tr,
                        iconBackgroundColor: AppColors.warning.withOpacity(.10),
                        iconColor: AppColors.warning,
                        onTap: () => _confirmLogout(controller),
                      ),
                      AppMenuTile(
                        icon: Icons.delete_outline_rounded,
                        label: AppStrings.deleteAccount.tr,
                        iconBackgroundColor: AppColors.danger.withOpacity(.10),
                        iconColor: AppColors.danger,
                        labelColor: AppColors.danger,
                        showDivider: false,
                        onTap: () => Get.toNamed(AppRoutes.deleteAccount),
                      ),
                      SizedBox(height: 6.px(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(ProfileController controller) {
    AppDialog.logout(
      title: AppStrings.logout.tr,
      message: AppStrings.logoutConfirmMessage.tr,
      logoutText: AppStrings.logout.tr,
      cancelText: AppStrings.cancel.tr,
      onLogout: controller.logout,
    );
  }

  void _openLanguageSettings(BuildContext context) {
    Get.bottomSheet(
      const _LanguageSettingsSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const AppHeaderCurveClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          22.px(context),
          16.px(context),
          22.px(context),
          46.px(context),
        ),
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Obx(() {
          final profile = controller.profile.value;

          return Row(
            children: [
              Container(
                width: 68.px(context),
                height: 68.px(context),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(.3), width: 2),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 36.px(context),
                ),
              ),
              SizedBox(width: 16.px(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.welcomeToProfile.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 11.5.px(context),
                      ),
                    ),
                    SizedBox(height: 3.px(context)),
                    Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName
                          : AppStrings.myProfile.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.px(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.px(context)),
                    Text(
                      '${AppStrings.memberId.tr}: ${profile?.memberIdLabel ?? '-'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(.75),
                        fontSize: 12.px(context),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Get.toNamed(AppRoutes.myProfile),
                child: Container(
                  padding: EdgeInsets.all(9.px(context)),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_outlined, color: Colors.white, size: 17.px(context)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LanguageSettingsSheet extends StatelessWidget {
  const _LanguageSettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.px(context),
        16.px(context),
        20.px(context),
        28.px(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.px(context))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 16.px(context)),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              AppStrings.chooseLanguage.tr,
              style: TextStyle(fontSize: 16.px(context), fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16.px(context)),
            const _LanguageOptionsList(),
          ],
        ),
      ),
    );
  }
}

/// Applies the chosen language immediately and closes the sheet — unlike
/// the onboarding language screen (which routes onward on "Continue"),
/// this is a settings-style picker: no separate confirm step.
class _LanguageOptionsList extends StatelessWidget {
  const _LanguageOptionsList();

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final currentLanguage = languageController.currentAppLanguage;

      return Column(
        children: [
          for (final language in AppLanguage.values) ...[
            _LanguageTile(
              language: language,
              isSelected: language == currentLanguage,
              onTap: () async {
                await languageController.changeAppLanguage(language);
                if (context.mounted) Get.back();
              },
            ),
            if (language != AppLanguage.values.last) SizedBox(height: 10.px(context)),
          ],
        ],
      );
    });
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withOpacity(.08) : AppColors.background,
      borderRadius: BorderRadius.circular(16.px(context)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.px(context)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.px(context), vertical: 14.px(context)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.px(context)),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.displayName,
                  style: TextStyle(
                    fontSize: 15.px(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(.5),
                size: 20.px(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
