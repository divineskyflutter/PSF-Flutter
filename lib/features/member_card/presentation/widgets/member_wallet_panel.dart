import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/member_card_controller.dart';
import '../member_card_layout.dart';
import 'horizontal_wallet_panel.dart';
import 'vertical_wallet_panel.dart';

/// The wallet + member card shown in the middle of the side drawer. Shows the
/// horizontal or the vertical design depending on the layout the member
/// picked with the switch inside the open wallet, cross-fading between them.
class MemberWalletPanel extends StatelessWidget {
  const MemberWalletPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MemberCardController>();

    return Obx(() {
      final layout = controller.layout.value;
      // A panel created by a layout switch (not by opening the drawer)
      // continues with the wallet open.
      final resumeOpen = controller.takeResumeOpen();

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 380),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        child: layout == MemberCardLayout.horizontal
            ? HorizontalWalletPanel(key: const ValueKey('horizontal'), startOpen: resumeOpen)
            : VerticalWalletPanel(key: const ValueKey('vertical'), startOpen: resumeOpen),
      );
    });
  }
}
