import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// One tab definition for [AppBottomNavBar].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;

  final IconData activeIcon;

  final String label;
}

/// The app's bottom navigation bar (Home / Loans / Profile), styled with
/// the app's own theme (rounded top corners, [AppColors.primary]) rather
/// than a plain [BottomNavigationBar].
///
/// Moved here from `shared/widgets/common/` (left in place there, just
/// unused, rather than deleted) so the bottom-nav shell's UI lives inside
/// its own `features/navigation/presentation/widgets/` folder — same
/// "feature owns its own widgets" convention every other feature already
/// follows (e.g. Home's `MemberSummaryCard`/`PaymentReminderCard`). Used
/// by `features/navigation/presentation/pages/main_navigation_screen.dart`
/// as the single shell for every tab.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;

  final int currentIndex;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.px(context))),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66.px(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavItem(
                  item: items[i],
                  isActive: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppBottomNavItem item;

  final bool isActive;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.px(context),
                  vertical: 6.px(context),
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withOpacity(.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.px(context)),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: color,
                  size: 22.px(context),
                ),
              ),
              SizedBox(height: 4.px(context)),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11.px(context),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
