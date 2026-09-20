import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';
import '../member_card_layout.dart';

/// Two-option switch (Horizontal | Vertical) shown in the open wallet. The
/// highlight slides between the options; whichever is selected is the card
/// shape shown and downloaded.
class WalletLayoutSwitch extends StatelessWidget {
  const WalletLayoutSwitch({super.key, required this.controller});

  final MemberCardController controller;

  @override
  Widget build(BuildContext context) {
    final height = 42.px(context);
    final radius = BorderRadius.circular(height / 2);

    return Obx(() {
      final vertical = controller.layout.value == MemberCardLayout.vertical;

      return Container(
        height: height,
        padding: EdgeInsets.all(3.px(context)),
        decoration: BoxDecoration(
          color: AppColors.primaryDark.withOpacity(.55),
          borderRadius: radius,
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: vertical ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: .5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.18),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _Option(
                  icon: Icons.crop_landscape_rounded,
                  textKey: 'card_layout_horizontal',
                  selected: !vertical,
                  onTap: () => _select(MemberCardLayout.horizontal),
                ),
                _Option(
                  icon: Icons.crop_portrait_rounded,
                  textKey: 'card_layout_vertical',
                  selected: vertical,
                  onTap: () => _select(MemberCardLayout.vertical),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void _select(MemberCardLayout layout) {
    if (controller.layout.value == layout) return;
    HapticFeedback.selectionClick();
    controller.setLayout(layout);
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.textKey,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;

  final String textKey;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : Colors.white;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.px(context), color: color),
              SizedBox(width: 6.px(context)),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: color,
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w700,
                  ),
                  child: Text(textKey.tr, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
