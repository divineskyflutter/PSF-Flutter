import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
import 'package:psf_application/shared/utils/relative_time.dart';
import 'package:psf_application/shared/widgets/loaders/app_shimmer.dart';

import '../../data/models/notification_item_model.dart';

/// One notification as a card: title, message and how long ago it was sent
/// (months / years also show the date). An unread notification stands out — a
/// tinted card with a theme-coloured edge, a bold title, an active bell and a
/// dot; a read one is a plain white card. Long text is cut with an ellipsis,
/// never overflowing.
class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final radius = BorderRadius.circular(18.px(context));
    final when = item.sendDateTime == null ? null : RelativeTime.of(item.sendDateTime!);

    return Padding(
      padding: EdgeInsets.only(bottom: 12.px(context)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: unread ? AppColors.primary.withOpacity(.09) : AppColors.card,
              borderRadius: radius,
              border: Border.all(
                color: unread ? AppColors.primary.withOpacity(.38) : AppColors.border,
                width: unread ? 1.3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: unread ? AppColors.primary.withOpacity(.12) : AppColors.shadow,
                  blurRadius: unread ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A coloured edge marks an unread notification.
                    Container(
                      width: unread ? 5.px(context) : 0,
                      color: AppColors.primary,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(14.px(context)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40.px(context),
                              height: 40.px(context),
                              decoration: BoxDecoration(
                                color: unread
                                    ? AppColors.primary.withOpacity(.16)
                                    : AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                unread
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_none_rounded,
                                size: 22.px(context),
                                color: unread ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 12.px(context)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.isEmpty ? '-' : item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5.px(context),
                                      height: 1.25,
                                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                                      color: unread
                                          ? AppColors.primaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (item.message.isNotEmpty) ...[
                                    SizedBox(height: 4.px(context)),
                                    Text(
                                      item.message,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5.px(context),
                                        height: 1.35,
                                        color: unread
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (when != null) ...[
                                    SizedBox(height: 8.px(context)),
                                    Wrap(
                                      spacing: 8.px(context),
                                      runSpacing: 2.px(context),
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              size: 13.px(context),
                                              color: AppColors.textSecondary,
                                            ),
                                            SizedBox(width: 4.px(context)),
                                            Text(
                                              when.text,
                                              style: TextStyle(
                                                fontSize: 11.5.px(context),
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (when.showDate)
                                          Text(
                                            AppDateFormat.medium(item.sendDateTime!),
                                            style: TextStyle(
                                              fontSize: 11.px(context),
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (unread) ...[
                              SizedBox(width: 8.px(context)),
                              Padding(
                                padding: EdgeInsets.only(top: 4.px(context)),
                                child: Container(
                                  width: 10.px(context),
                                  height: 10.px(context),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A shimmering placeholder card, shown while a page loads.
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.px(context)),
      child: AppShimmer(
        child: Container(
          height: 98.px(context),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.px(context)),
          ),
        ),
      ),
    );
  }
}
