import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';

/// The Card tab. Intentionally empty for now — the wallet-style member card
/// lives in the side drawer (see `AppSideDrawer` / `MemberWalletPanel`),
/// and this tab is reserved for more card-related details later.
class MemberCardScreen extends StatelessWidget {
  const MemberCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Content scrolls under the fixed header (see MyProfilePage).
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(
        title: 'nav_card'.tr,
        showBackButton: false,
      ),
      body: const SizedBox.expand(),
    );
  }
}
