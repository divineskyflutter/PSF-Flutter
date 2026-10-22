import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import 'profile_card_style.dart';

/// Segmented control with a gradient "pill" under the selected tab. The pill
/// is driven by [pages]' scroll position, so it slides along with the finger
/// while the page is swiped, and a tap on a tab calls [onTap] (the owner
/// animates [pages] to it). Labels get the full width of their tab and wrap
/// onto a second centered line instead of overflowing.
class ProfileSegmentedTabs extends StatelessWidget {
  const ProfileSegmentedTabs({
    super.key,
    required this.labels,
    required this.icons,
    required this.pages,
    required this.onTap,
  }) : assert(labels.length == icons.length && labels.length > 1);

  final List<String> labels;
  final List<IconData> icons;
  final PageController pages;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pages,
      builder: (context, _) {
        final last = labels.length - 1.0;
        final position = pages.hasClients && pages.position.haveDimensions
            ? (pages.page ?? 0).clamp(0.0, last)
            : pages.initialPage.toDouble().clamp(0.0, last);
        return _build(context, position);
      },
    );
  }

  Widget _build(BuildContext context, double position) {
    final selectedIndex = position.round();

    return Container(
      padding: EdgeInsets.all(4.px(context)),
      decoration: profileCardDecoration(context).copyWith(
        borderRadius: BorderRadius.circular(20.px(context)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment(-1 + position * (2 / (labels.length - 1)), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(16.px(context)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(.38),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.px(context),
                        vertical: 10.px(context),
                      ),
                      child: _TabLabel(
                        icon: icons[i],
                        label: labels[i],
                        selected: selectedIndex == i,
                      ),
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

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: selected ? 1.15 : 1,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: Icon(
            icon,
            size: 20.px(context),
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.px(context)),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5.px(context),
            height: 1.2,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
          child: Text(label, textAlign: TextAlign.center, softWrap: true),
        ),
      ],
    );
  }
}
