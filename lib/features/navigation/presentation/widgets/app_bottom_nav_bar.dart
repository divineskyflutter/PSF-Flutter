import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// The app's floating bottom navigation bar: a rounded, elevated pill with
/// the item at [centerIndex] (Home) lifted out of the bar as a gradient
/// button. Selecting a tab only animates the icon, its highlight and the
/// label — there is deliberately no ripple/splash/press effect, so nothing
/// ever paints outside the bar's own rounded shape.
///
/// Every slot is tappable across its full height and width, including the
/// area above the bar that the raised center button sits in.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerIndex = 1,
  });

  final List<AppBottomNavItem> items;

  final int currentIndex;

  final ValueChanged<int> onTap;

  /// Which item is the raised center button.
  final int centerIndex;

  static double barHeightOf(BuildContext context) => 62.px(context);

  /// How far the raised center button rises above the bar.
  static double liftOf(BuildContext context) => 16.px(context);

  static double _bottomMargin(BuildContext context) => 8.px(context);

  /// Space the bar covers at the bottom of the screen (bar + raised
  /// button + margin + system inset). The bar floats OVER the page
  /// (`Scaffold.extendBody`), so scrolling pages add this to their bottom
  /// padding to keep their last item clear of it.
  static double occupiedHeight(BuildContext context) =>
      barHeightOf(context) +
      liftOf(context) +
      _bottomMargin(context) +
      MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final barHeight = barHeightOf(context);
    final lift = liftOf(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.px(context), 0, 16.px(context), _bottomMargin(context)),
        child: SizedBox(
          height: barHeight + lift,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(30.px(context)),
                    border: Border.all(color: AppColors.primary.withOpacity(.10)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withOpacity(.22),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: i == centerIndex
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _select(i),
                              child: _CenterSlot(
                                item: items[i],
                                isActive: i == currentIndex,
                              ),
                            )
                          // Only the bar's own height is tappable here — the
                          // strip above it belongs to the page underneath.
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _select(i),
                                child: SizedBox(
                                  height: barHeight,
                                  width: double.infinity,
                                  child: _SideSlot(
                                    item: items[i],
                                    isActive: i == currentIndex,
                                  ),
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(int index) {
    if (index != currentIndex) HapticFeedback.selectionClick();
    onTap(index);
  }
}

class _SideSlot extends StatelessWidget {
  const _SideSlot({
    required this.item,
    required this.isActive,
  });

  final AppBottomNavItem item;

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: isActive ? 52.px(context) : 34.px(context),
            height: 28.px(context),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(16.px(context)),
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: color,
              size: 22.px(context),
            ),
          ),
          SizedBox(height: 2.px(context)),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: color,
              fontSize: 11.px(context),
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            ),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _CenterSlot extends StatelessWidget {
  const _CenterSlot({required this.item, required this.isActive});

  final AppBottomNavItem item;

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final size = 52.px(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isActive
                  ? AppColors.headerGradient
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
              border: Border.all(color: AppColors.card, width: 4.px(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(isActive ? .5 : .28),
                  blurRadius: isActive ? 18 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: Colors.white,
              size: 28.px(context),
            ),
          ),
        ),
        Positioned(
          bottom: 4.px(context),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontSize: 11.px(context),
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            ),
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }
}
