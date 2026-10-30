import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/refresh/app_refresh_indicator.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../../data/models/notification_filter.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_card.dart';

/// The member's notifications as a list of cards, with a Read / Unread filter
/// (All too, once the API supports it — see [NotificationFilterConfig]).
/// Opens with a shimmer while the first page loads, pulls down to refresh and
/// loads the next 25 as the list is scrolled to its end.
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
      body: Padding(
        padding: EdgeInsets.only(top: AppSubPageHeader.totalHeight() + 6.px(context)),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.px(context), 4.px(context), 18.px(context), 10.px(context)),
              child: _FilterBar(controller: controller),
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: controller.refresh,
                child: _NotificationList(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.px(context)),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16.px(context)),
          border: Border.all(color: AppColors.primary.withOpacity(.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list_rounded, size: 20.px(context), color: AppColors.primary),
            SizedBox(width: 8.px(context)),
            Text(
              AppStrings.notificationsFilterLabel.tr,
              style: TextStyle(
                fontSize: 13.px(context),
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(width: 10.px(context)),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<NotificationFilter>(
                  isExpanded: true,
                  value: controller.filter.value,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryDark, size: 24.px(context)),
                  borderRadius: BorderRadius.circular(14.px(context)),
                  dropdownColor: AppColors.card,
                  items: [
                    for (final f in NotificationFilterConfig.available)
                      DropdownMenuItem(
                        value: f,
                        child: Text(
                          f.labelKey.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.px(context),
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (f) {
                    if (f != null) controller.changeFilter(f);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.controller});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final bottom = 24.px(context) + MediaQuery.of(context).padding.bottom;
    final sides = EdgeInsets.fromLTRB(18.px(context), 2.px(context), 18.px(context), bottom);

    return Obx(() {
      // Read every piece of state up front so the list rebuilds on any change.
      final loading = controller.isLoading.value;
      final failed = controller.hasError.value;
      final items = controller.items.toList();
      final more = controller.hasMore.value;
      final loadingMore = controller.isLoadingMore.value;
      final moreFailed = controller.loadMoreFailed.value;

      if (loading) {
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: sides,
          itemCount: 6,
          itemBuilder: (_, __) => const NotificationCardSkeleton(),
        );
      }

      // Error / empty fill the screen inside a scrollable, so they can still
      // be pulled down to refresh.
      if (failed || items.isEmpty) {
        return LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: sides,
            children: [
              SizedBox(
                height: constraints.maxHeight - 20.px(context),
                child: Center(
                  child: failed
                      ? AppStateView.error(
                          message: AppStrings.somethingWentWrong.tr,
                          onRetry: controller.retry,
                        )
                      : const _EmptyNotifications(),
                ),
              ),
            ],
          ),
        );
      }

      final hasFooter = more || loadingMore || moreFailed;

      return ListView.builder(
        controller: controller.scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: sides,
        itemCount: items.length + (hasFooter ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return _Footer(
              failed: moreFailed,
              onRetry: controller.loadMore,
            );
          }
          final item = items[index];
          return NotificationCard(item: item, onTap: () => controller.onTap(item));
        },
      );
    });
  }
}

/// Nothing to show: a medium bell, "no notifications yet" and a hint that the
/// list can be pulled down to look for new ones.
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 36.px(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 104.px(context),
            height: 104.px(context),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(.10),
              border: Border.all(color: AppColors.primary.withOpacity(.18), width: 1.4),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 52.px(context),
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 22.px(context)),
          Text(
            AppStrings.notificationsEmpty.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17.px(context),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: 8.px(context)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward_rounded, size: 16.px(context), color: AppColors.textSecondary),
              SizedBox(width: 6.px(context)),
              Flexible(
                child: Text(
                  AppStrings.notificationsEmptyHint.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom of the list: a spinner while the next 25 load, or a tap-to-retry
/// note when that failed.
class _Footer extends StatelessWidget {
  const _Footer({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.px(context)),
      child: Center(
        child: failed
            ? TextButton(
                onPressed: onRetry,
                child: Text(
                  AppStrings.notificationsLoadMoreFailed.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5.px(context), color: AppColors.primaryDark),
                ),
              )
            : SizedBox(
                width: 22.px(context),
                height: 22.px(context),
                child: const CircularProgressIndicator(strokeWidth: 2.4),
              ),
      ),
    );
  }
}
