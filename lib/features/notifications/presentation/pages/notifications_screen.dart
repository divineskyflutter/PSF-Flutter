import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../controllers/notifications_controller.dart';

/// The member's notifications. The list API isn't available yet, so for now
/// this shows the "no notifications" empty state, with pull-to-refresh already
/// wired to [NotificationsController.refresh] for when it is.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      // The header stays fixed and the page scrolls under its wavy edge.
      extendBodyBehindAppBar: true,
      appBar: AppSubPageHeader(title: AppStrings.notificationsTitle.tr),
      body: AppRefreshIndicator(
        onRefresh: controller.refresh,
        edgeOffset: AppSubPageHeader.totalHeight(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final top = AppSubPageHeader.totalHeight();

            // A scrollable that always fills the screen, so the empty state
            // can be pulled down to refresh.
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: top),
              children: [
                SizedBox(
                  height: constraints.maxHeight - top,
                  child: Center(
                    child: AppStateView.empty(message: AppStrings.notificationsEmpty.tr),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
