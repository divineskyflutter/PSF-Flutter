import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';
import 'vertical_card_faces.dart';
import 'member_qr_view.dart';
import 'wallet_controls.dart';
import 'wallet_layout_switch.dart';
import 'wallet_pouch.dart';

/// The VERTICAL (portrait) wallet + member card, shown in the middle of the
/// side drawer when the member picks the vertical layout.
///
///  * On appear, the card drops down into the wallet: the front pocket
///    covers ~90% of it (only a thin strip of the card's top shows) and
///    carries the member's QR code.
///  * Tap the wallet: the whole wallet (back + pocket, moving as one piece)
///    slides down and away while the card is revealed in full; the flip
///    arrows and the Download button fade in.
///  * Tap the card (anywhere, including its left side) or use the arrows:
///    the card flips between front and back in 3D.
///
/// Every animation is driven by `Animation` objects handed to transition
/// widgets around prebuilt, repaint-isolated children, so nothing heavy is
/// rebuilt or re-rasterized per frame — the card faces are built once per
/// data change and only their transform changes while flipping.
class VerticalWalletPanel extends StatefulWidget {
  const VerticalWalletPanel({super.key, this.startOpen = false});

  /// Start with the wallet already open (used when the member switches the
  /// card shape from inside the open wallet).
  final bool startOpen;

  @override
  State<VerticalWalletPanel> createState() => _VerticalWalletPanelState();
}

class _VerticalWalletPanelState extends State<VerticalWalletPanel>
    with TickerProviderStateMixin {
  final MemberCardController _controller = Get.find<MemberCardController>();

  final ProfileController _profile = Get.find<ProfileController>();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // Intro: the card drops into the wallet.
  late final Animation<double> _introFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, .5, curve: Curves.easeOut),
  );
  late final Animation<Offset> _cardDrop = Tween<Offset>(
    begin: const Offset(0, -.16),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _intro,
    curve: const Interval(.15, 1, curve: Curves.easeOutCubic),
  ));

  // Open: the wallet (one piece) slides away, the card is revealed.
  late final Animation<double> _walletShift = CurvedAnimation(
    parent: _open,
    curve: const Interval(0, .8, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _walletFadeOut = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.4, .85, curve: Curves.easeIn)),
  );
  late final Animation<double> _cardScale = Tween<double>(begin: 1, end: 1.03).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.2, 1, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> _controlsFade = CurvedAnimation(
    parent: _open,
    curve: const Interval(.5, 1, curve: Curves.easeOut),
  );
  late final Animation<Offset> _controlsSlide = Tween<Offset>(
    begin: const Offset(0, .15),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _open,
    curve: const Interval(.5, 1, curve: Curves.easeOutCubic),
  ));

  bool _isOpen = false;

  int _flipDirection = 1;

  @override
  void initState() {
    super.initState();
    if (widget.startOpen) {
      _intro.value = 1;
      _open.value = 1;
      _isOpen = true;
    } else {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _open.dispose();
    _flip.dispose();
    super.dispose();
  }

  void _openWallet() {
    if (_isOpen) return;
    HapticFeedback.lightImpact();
    setState(() => _isOpen = true);
    _open.forward();
  }

  void _closeWallet() {
    if (!_isOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = false);
    _flip.animateBack(0, duration: const Duration(milliseconds: 280));
    _open.reverse();
  }

  void _flipCard(int direction) {
    if (!_isOpen || _flip.isAnimating) return;
    HapticFeedback.selectionClick();
    setState(() => _flipDirection = direction);
    if (_flip.value < .5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  void _onCardTap() => _isOpen ? _flipCard(1) : _openWallet();

  Widget _qr(double size) {
    return Obx(
      () => MemberQrView(
        qr: _controller.qr.value,
        isLoading: _controller.isQrLoading.value,
        hasError: _controller.hasQrError.value,
        onRetry: _controller.loadQr,
        size: size,
      ),
    );
  }

  /// One wallet piece (back or pocket). Both pieces get the SAME pixel
  /// [distance], so the wallet leaves as a single solid object instead of
  /// its parts sliding apart. Removed from the tree once fully open.
  Widget _walletPiece({required Widget child, required double distance}) {
    return AnimatedBuilder(
      animation: _open,
      child: FadeTransition(
        opacity: _introFade,
        child: FadeTransition(opacity: _walletFadeOut, child: child),
      ),
      builder: (context, cached) {
        if (_open.isCompleted) return const SizedBox.shrink();
        return Transform.translate(
          offset: Offset(0, _walletShift.value * distance),
          child: cached,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read so the card rebuilds when the profile, the enum bundle
      // (gender / status names), the app language or the QR changes.
      _profile.memberDetails.value;
      _profile.profile.value;
      _profile.enumBundle.value;
      Get.find<LanguageController>().locale.value;

      final data = _controller.buildData(localized: true);

      return LayoutBuilder(
        builder: (context, constraints) {
          final optionsHeight = 226.px(context);
          final gap = 14.px(context);

          var cardHeight = math.min(
            (constraints.maxHeight - optionsHeight - gap) / 1.06,
            constraints.maxWidth * .70 / verticalCardAspectRatio,
          );
          cardHeight = math.max(cardHeight, 220);

          final cardWidth = cardHeight * verticalCardAspectRatio;
          final walletWidth = cardWidth * 1.14;
          final stageHeight = cardHeight * 1.06;
          final walletDistance = cardHeight * 1.0;

          final front = VerticalCardFront(data: data);
          const back = VerticalCardBack();

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: walletWidth,
                height: stageHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Wallet back.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cardHeight * .93,
                      child: _walletPiece(
                        distance: walletDistance,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openWallet,
                          child: const WalletBack(),
                        ),
                      ),
                    ),
                    // Card.
                    Positioned(
                      left: (walletWidth - cardWidth) / 2,
                      bottom: cardHeight * .02,
                      width: cardWidth,
                      height: cardHeight,
                      child: FadeTransition(
                        opacity: _introFade,
                        child: SlideTransition(
                          position: _cardDrop,
                          child: ScaleTransition(
                            scale: _cardScale,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onCardTap,
                              child: _flipper(front, back),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Front pocket (covers ~90% of the card; carries the QR).
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: cardHeight * .90,
                      child: _walletPiece(
                        distance: walletDistance,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openWallet,
                          child: WalletPocket(qrView: _qr(140)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 26.px(context)),
                child: SizedBox(
                  height: optionsHeight,
                  width: double.infinity,
                  child: _options(context),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _flipper(Widget front, Widget back) {
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_flip.value);
        final angle = t * math.pi * _flipDirection;
        final showBack = t > .5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0012)
            ..rotateY(angle),
          child: showBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: back,
                )
              : front,
        );
      },
    );
  }

  Widget _options(BuildContext context) {
    return IgnorePointer(
      ignoring: !_isOpen,
      child: FadeTransition(
        opacity: _controlsFade,
        child: SlideTransition(
          position: _controlsSlide,
          child: Column(
            children: [
              WalletLayoutSwitch(controller: _controller),
              SizedBox(height: 12.px(context)),
              Row(
                children: [
                  WalletArrowButton(icon: Icons.chevron_left_rounded, onTap: () => _flipCard(-1)),
                  const Expanded(
                    child: Center(child: WalletPill(textKey: 'tap_to_flip_card')),
                  ),
                  WalletArrowButton(icon: Icons.chevron_right_rounded, onTap: () => _flipCard(1)),
                ],
              ),
              SizedBox(height: 14.px(context)),
              WalletDownloadButton(controller: _controller),
              SizedBox(height: 4.px(context)),
              TextButton.icon(
                onPressed: _closeWallet,
                icon: Icon(Icons.lock_outline_rounded, size: 16.px(context)),
                label: Text('close_wallet'.tr),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    fontSize: 12.5.px(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
