import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';
import '../member_card_layout.dart';
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
///    peels down and away, trailing a soft paper-peel shadow, while the
///    card is revealed in full. Tap the card again to close.
///  * Swipe the open card left or right: it flips between front and back
///    in 3D.
///  * Download is always visible under the card. The Horizontal | Vertical
///    switch is hidden for now (see [kShowCardLayoutSwitch]).
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
    duration: const Duration(milliseconds: 900),
  );

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // Idle shimmer over the closed cover (see WalletShine).
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
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

  // Open: the wallet (one piece) slides away, the card is revealed. A
  // gentle easeInOut (not the steeper *Cubic) so the motion reads as evenly
  // paced the whole way, instead of sitting still then darting through the
  // middle.
  late final Animation<double> _walletShift = CurvedAnimation(
    parent: _open,
    curve: const Interval(0, 1, curve: Curves.easeInOut),
  );
  late final Animation<double> _walletFadeOut = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.5, 1, curve: Curves.easeIn)),
  );
  // A springy overshoot-and-settle pop as the wallet peels away, like paper
  // unwrapping off the card, instead of a flat linear grow — paired with a
  // matching little rotational "settle" wobble (_cardTilt) so the card
  // looks like it was just set down rather than simply scaled up.
  late final Animation<double> _cardScale = Tween<double>(begin: 1, end: 1.045).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.15, 1, curve: Curves.easeOutBack)),
  );
  late final Animation<double> _cardTilt = Tween<double>(begin: .05, end: 0).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.15, 1, curve: Curves.easeOutBack)),
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
      _intro.forward().whenComplete(() {
        if (mounted && !_isOpen) _shine.repeat();
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _open.dispose();
    _flip.dispose();
    _shine.dispose();
    super.dispose();
  }

  void _openWallet() {
    if (_isOpen) return;
    HapticFeedback.lightImpact();
    setState(() => _isOpen = true);
    _shine.stop();
    _controller.isWalletBusy.value = true;
    _open.forward().whenComplete(() {
      _controller.isWalletBusy.value = false;
    });
  }

  void _closeWallet() {
    if (!_isOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = false);
    _flip.animateBack(0, duration: const Duration(milliseconds: 280));
    _controller.isWalletBusy.value = true;
    _open.reverse().whenComplete(() {
      _controller.isWalletBusy.value = false;
      if (mounted && !_isOpen) _shine.repeat();
    });
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

  /// Tap: open the wallet, or close it again when it is open.
  void _onCardTap() => _isOpen ? _closeWallet() : _openWallet();

  double _dragDistance = 0;

  /// Swipe (open wallet only): flips the card — swipe left turns it one way,
  /// swipe right the other.
  void _onSwipeEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final swiped = velocity.abs() > 250 || _dragDistance.abs() > 40;
    if (swiped) {
      final toLeft = velocity != 0 ? velocity < 0 : _dragDistance < 0;
      _flipCard(toLeft ? 1 : -1);
    }
    _dragDistance = 0;
  }

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
  /// its parts sliding apart.
  ///
  /// Stays mounted (transformed off-screen, not removed from the tree) even
  /// once fully open — tearing it down and rebuilding it on every open/close
  /// forced Skia to reallocate its layer's GPU resources from scratch each
  /// time, which measured as a 100ms+ single-frame stall on this device
  /// (`dumpsys gfxinfo` / the performance overlay's raster graph both showed
  /// it) and made the transition look like it snapped instead of sliding.
  /// Keeping the widget alive lets its RepaintBoundary keep the same layer
  /// and just re-transform it, which is cheap.
  Widget _walletPiece({required Widget child, required double distance}) {
    return AnimatedBuilder(
      animation: _open,
      child: FadeTransition(
        opacity: _introFade,
        child: FadeTransition(opacity: _walletFadeOut, child: child),
      ),
      builder: (context, cached) {
        final shift = _walletShift.value;

        // The wallet peels away: it slides down while tipping back on its
        // top edge, like a flap being folded open.
        return IgnorePointer(
          ignoring: _open.isCompleted,
          child: Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0009)
              ..translate(0.0, shift * distance)
              ..rotateX(shift * .58),
            child: cached,
          ),
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
          final optionsHeight = (kShowCardLayoutSwitch ? 110 : 58).px(context);
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

          final pocketShape = BorderRadius.only(
            topLeft: Radius.circular(38.px(context)),
            topRight: Radius.circular(38.px(context)),
            bottomLeft: Radius.circular(30.px(context)),
            bottomRight: Radius.circular(30.px(context)),
          );

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
                          child: AnimatedBuilder(
                            animation: _open,
                            builder: (context, child) => Transform.rotate(
                              angle: _cardTilt.value,
                              child: Transform.scale(scale: _cardScale.value, child: child),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _onCardTap,
                              onHorizontalDragStart: (_) => _dragDistance = 0,
                              onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
                              onHorizontalDragEnd: _onSwipeEnd,
                              // Clipped to the card's own rounding so the
                              // peel shadow never pokes out past the corners.
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(cardWidth * 22 / 540),
                                child: Stack(
                                  children: [
                                    _flipper(front, back),
                                    // Paper-peel shadow trailing the departing wallet.
                                    CardRevealShadow(animation: _walletShift, axis: Axis.vertical),
                                  ],
                                ),
                              ),
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
                          child: Stack(
                            children: [
                              Positioned.fill(child: WalletPocket(qrView: _qr(140))),
                              Positioned.fill(child: WalletShine(animation: _shine, shape: pocketShape)),
                            ],
                          ),
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

        // How edge-on the card is right now: 0 at rest (front or back
        // facing flat), 1 exactly side-on at the midpoint — a small pull-in
        // plus a shadow there makes the flip read as a solid card turning
        // in space instead of a flat image stretching and snapping back.
        final edgeOn = math.sin(t * math.pi);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0013)
            ..rotateY(angle)
            ..scale(1 - edgeOn * .06),
          child: Stack(
            children: [
              showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: back,
                    )
                  : front,
              IgnorePointer(
                child: Opacity(
                  opacity: edgeOn * .4,
                  child: const ColoredBox(color: Colors.black, child: SizedBox.expand()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _options(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // The Horizontal | Vertical switch is hidden for now (see
        // kShowCardLayoutSwitch). Download is always there.
        if (kShowCardLayoutSwitch) ...[
          IgnorePointer(
            ignoring: !_isOpen,
            child: FadeTransition(
              opacity: _controlsFade,
              child: SlideTransition(
                position: _controlsSlide,
                child: WalletLayoutSwitch(controller: _controller),
              ),
            ),
          ),
          SizedBox(height: 12.px(context)),
        ],
        WalletDownloadButton(controller: _controller),
      ],
    );
  }
}
