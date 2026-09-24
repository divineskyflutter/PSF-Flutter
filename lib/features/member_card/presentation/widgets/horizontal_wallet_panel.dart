import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

import '../controllers/member_card_controller.dart';
import '../member_card_layout.dart';
import 'horizontal_card_faces.dart';
import 'member_qr_view.dart';
import 'wallet_controls.dart';
import 'wallet_layout_switch.dart';
import 'wallet_pouch.dart';

/// The HORIZONTAL wallet + member card (the design that matches the
/// foundation's printed card), shown in the middle of the side drawer.
///
///  * On appear, the wallet cover slides in from the LEFT over the card,
///    covering ~90% of it (a thin strip of the card stays visible on the
///    right). The cover carries the member's QR code.
///  * Tap the wallet (or the card): the cover peels away to the LEFT,
///    trailing a soft paper-peel shadow, and the card is revealed in full.
///    Tap the card again to close — the cover slides back in from the left.
///  * Swipe the open card left or right: it flips between front and back
///    in 3D.
///  * Download is always visible under the card. The Horizontal | Vertical
///    switch is hidden for now (see [kShowCardLayoutSwitch]) — only the
///    horizontal card is shown.
///
/// Animations are driven by `Animation` objects around prebuilt,
/// repaint-isolated children, so nothing heavy is rebuilt per frame.
class HorizontalWalletPanel extends StatefulWidget {
  const HorizontalWalletPanel({super.key, this.startOpen = false});

  /// Start with the wallet already open (used when the member switches the
  /// card shape from inside the open wallet).
  final bool startOpen;

  @override
  State<HorizontalWalletPanel> createState() => _HorizontalWalletPanelState();
}

class _HorizontalWalletPanelState extends State<HorizontalWalletPanel>
    with TickerProviderStateMixin {
  final MemberCardController _controller = Get.find<MemberCardController>();

  final ProfileController _profile = Get.find<ProfileController>();

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
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

  // Intro: the cover slides in from the left.
  late final Animation<double> _introSlide = CurvedAnimation(
    parent: _intro,
    curve: const Interval(.1, 1, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _introFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, .4, curve: Curves.easeOut),
  );

  // Open: the cover slides out to the left, the card is revealed.
  late final Animation<double> _coverShift = CurvedAnimation(
    parent: _open,
    curve: const Interval(0, 1, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _coverFadeOut = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.55, 1, curve: Curves.easeIn)),
  );
  // A springy overshoot-and-settle pop as the cover peels away, like paper
  // unwrapping off the card, instead of a flat linear grow — paired with a
  // matching little rotational "settle" wobble (_cardTilt) so the card
  // looks like it was just set down rather than simply scaled up.
  late final Animation<double> _cardScale = Tween<double>(begin: 1, end: 1.045).animate(
    CurvedAnimation(parent: _open, curve: const Interval(.15, 1, curve: Curves.easeOutBack)),
  );
  late final Animation<double> _cardTilt = Tween<double>(begin: -.05, end: 0).animate(
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
    _open.forward();
  }

  void _closeWallet() {
    if (!_isOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = false);
    _flip.animateBack(0, duration: const Duration(milliseconds: 280));
    _open.reverse().whenComplete(() {
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

  /// One cover piece (back panel or front pocket). Both get the SAME pixel
  /// travel so the wallet moves as a single solid object. Slides in from
  /// the left on appear, out to the left on open; removed from the tree
  /// once fully open.
  Widget _coverPiece({required Widget child, required double travel}) {
    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _open]),
      child: FadeTransition(
        opacity: _introFade,
        child: FadeTransition(opacity: _coverFadeOut, child: child),
      ),
      builder: (context, cached) {
        if (_open.isCompleted) return const SizedBox.shrink();
        final shift = _coverShift.value;
        final dx = -(1 - _introSlide.value) * travel - shift * travel;

        // The cover peels away: it slides out to the left while swinging
        // open on its left edge, like a flap being lifted.
        return Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0009)
            ..translate(dx, 0.0)
            ..rotateY(-shift * .62),
          child: cached,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Read so the card rebuilds when the profile, the enum bundle, the
      // app language or the QR changes.
      _profile.memberDetails.value;
      _profile.profile.value;
      _profile.enumBundle.value;
      Get.find<LanguageController>().locale.value;

      final data = _controller.buildData(localized: true);

      return LayoutBuilder(
        builder: (context, constraints) {
          final optionsHeight = (kShowCardLayoutSwitch ? 110 : 58).px(context);
          final gap = 14.px(context);
          final gutter = 16.px(context);

          var stageWidth = constraints.maxWidth - gutter * 2;
          var cardWidth = stageWidth / 1.06;
          var cardHeight = cardWidth / horizontalCardAspectRatio;

          final maxCardHeight = (constraints.maxHeight - optionsHeight - gap) / 1.16;
          if (cardHeight > maxCardHeight) {
            cardHeight = maxCardHeight;
            cardWidth = cardHeight * horizontalCardAspectRatio;
            stageWidth = cardWidth * 1.06;
          }

          final stageHeight = cardHeight * 1.16;
          final coverHeight = cardHeight * 1.14;
          final coverWidth = cardWidth * .96;
          final travel = coverWidth + gutter + (constraints.maxWidth - stageWidth) / 2 + 12;

          final coverShape = BorderRadius.only(
            topLeft: Radius.circular(30.px(context)),
            bottomLeft: Radius.circular(30.px(context)),
            topRight: Radius.circular(38.px(context)),
            bottomRight: Radius.circular(38.px(context)),
          );

          final front = HorizontalCardFront(data: data);
          const back = HorizontalCardBack();

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: stageWidth,
                height: stageHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Wallet back panel (its right lip shows between the
                    // cover and the visible strip of the card).
                    Positioned(
                      left: 0,
                      top: (stageHeight - coverHeight) / 2 + cardHeight * .02,
                      width: cardWidth * .99,
                      height: coverHeight * .96,
                      child: _coverPiece(
                        travel: travel,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openWallet,
                          child: const WalletBack(),
                        ),
                      ),
                    ),
                    // Card.
                    Positioned(
                      right: 0,
                      top: (stageHeight - cardHeight) / 2,
                      width: cardWidth,
                      height: cardHeight,
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
                          // Clipped to the card's own rounding so the peel
                          // shadow never pokes out past the rounded corners.
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(cardWidth * 18 / 1050),
                            child: Stack(
                              children: [
                                _flipper(front, back),
                                // Paper-peel shadow trailing the departing cover.
                                CardRevealShadow(animation: _coverShift, axis: Axis.horizontal),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Front cover with the QR (covers ~90% of the card).
                    Positioned(
                      left: 0,
                      top: (stageHeight - coverHeight) / 2,
                      width: coverWidth,
                      height: coverHeight,
                      child: _coverPiece(
                        travel: travel,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openWallet,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: WalletPocket(
                                  qrView: _qr(120),
                                  shape: coverShape,
                                  border: Border(
                                    right: BorderSide(color: AppColors.accentGold.withOpacity(.85), width: 1.6),
                                  ),
                                ),
                              ),
                              Positioned.fill(child: WalletShine(animation: _shine, shape: coverShape)),
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
            ..setEntry(3, 2, .0011)
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
        // kShowCardLayoutSwitch) — only the horizontal card is shown, and it
        // is always what gets downloaded. Download is always there.
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
