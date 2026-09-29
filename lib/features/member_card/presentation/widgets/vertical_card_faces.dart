import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';

import '../../data/member_card_data.dart';
import '../../data/member_qr_image.dart';
import 'member_qr_view.dart';
import 'printed_card_style.dart';

/// Portrait proportions of the vertical printed-style card (width / height).
const double verticalCardAspectRatio = 540 / 900;

/// Design width the layout below is drawn at — every size is `f(value)`,
/// i.e. scaled by `cardWidth / 540`.
const double _designWidth = 540;

/// FRONT of the vertical member card — the same printed card as the
/// horizontal one, re-flowed for a portrait shape: cream paper, teal band
/// down the left edge, emblem, teal title bar with the tagline, the member's
/// photo with the member number and the chairman's signature beside it, and
/// Name / Address / Contact / DOB lines. Labels, title and tagline follow the
/// selected app language.
class VerticalCardFront extends StatelessWidget {
  const VerticalCardFront({super.key, required this.data});

  final MemberCardData data;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = constraints.maxWidth / _designWidth;
          double f(double v) => v * s;

          final hasPhoto = data.photoUrl?.isNotEmpty ?? false;
          final number = printedMemberNumber(data.memberNo);

          return CardShell(
            radius: f(22),
            child: DecoratedBox(
              decoration: printedCardPaper(),
              child: Stack(
                children: [
                  // Teal band down the left edge.
                  Positioned(left: 0, top: 0, bottom: 0, width: f(30), child: const ColoredBox(color: cardTeal)),

                  // Sanskrit line.
                  Positioned(
                    left: f(30),
                    right: 0,
                    top: f(20),
                    child: Text(
                      '॥ वसुधैव कुटुम्बकम् ॥',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cardInk, fontSize: f(22), fontWeight: FontWeight.w500),
                    ),
                  ),

                  // Emblem.
                  Positioned(
                    left: f(30),
                    right: 0,
                    top: f(54),
                    height: f(158),
                    child: SvgPicture.asset(AppAssets.logo, fit: BoxFit.contain),
                  ),

                  // Title bar.
                  Positioned(
                    left: f(30),
                    right: 0,
                    top: f(222),
                    height: f(96),
                    child: ColoredBox(
                      color: cardTeal,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(f(22), f(6), f(22), f(6)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'card_title'.tr,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: f(52),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: f(1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'card_tagline'.tr,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: f(26),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Photo in a teal frame.
                  Positioned(
                    left: f(56),
                    top: f(344),
                    width: f(196),
                    height: f(256),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: cardTeal, width: f(3)),
                      ),
                      child: hasPhoto
                          ? Image.network(
                              data.photoUrl!,
                              cacheWidth: 500,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            )
                          : const SizedBox(),
                    ),
                  ),

                  // Member number, beside the photo.
                  Positioned(
                    left: f(280),
                    right: f(28),
                    top: f(352),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        number,
                        maxLines: 1,
                        style: TextStyle(color: cardInk, fontSize: f(40), fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),

                  // Chairman's "Auth. Signature" block, beside the photo.
                  Positioned(
                    left: f(266),
                    top: f(600 - 250 / chairmanSignatureAspectRatio),
                    width: f(250),
                    height: f(250 / chairmanSignatureAspectRatio),
                    child: const ChairmanSignature(),
                  ),

                  // Fields.
                  Positioned(
                    left: f(56),
                    right: f(28),
                    top: f(636),
                    child: Column(
                      children: [
                        CardFieldRow(
                          label: 'card_label_name'.tr,
                          value: MemberCardData.orDash(data.name),
                          s: s,
                          rowHeight: 56,
                          labelWidth: 128,
                          labelSize: 30,
                          valueSize: 29,
                        ),
                        CardFieldRow(
                          label: 'address'.tr,
                          value: MemberCardData.orDash(data.address),
                          s: s,
                          lines: 2,
                          rowHeight: 76,
                          labelWidth: 128,
                          labelSize: 30,
                          multiLineValueSize: 25,
                        ),
                        CardFieldRow(
                          label: 'card_label_contact'.tr,
                          value: MemberCardData.orDash(data.mobile),
                          s: s,
                          rowHeight: 56,
                          labelWidth: 128,
                          labelSize: 30,
                          valueSize: 29,
                        ),
                        CardFieldRow(
                          label: 'card_label_dob'.tr,
                          value: MemberCardData.orDash(data.dateOfBirthNumeric),
                          s: s,
                          rowHeight: 56,
                          labelWidth: 128,
                          labelSize: 30,
                          valueSize: 29,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// BACK of the vertical member card — the printed card's back re-flowed for
/// a portrait shape: teal background, the member's own QR code (the same one
/// shown on the wallet's cover) on a cream panel with the registration
/// numbers, the founders' contact details down a timeline, the registered
/// office and the footer note.
class VerticalCardBack extends StatelessWidget {
  const VerticalCardBack({
    super.key,
    required this.qr,
    required this.isQrLoading,
    required this.hasQrError,
    required this.onQrRetry,
  });

  final MemberQrImage? qr;
  final bool isQrLoading;
  final bool hasQrError;
  final VoidCallback onQrRetry;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final s = constraints.maxWidth / _designWidth;
          double f(double v) => v * s;

          TextStyle white(double size, {FontWeight w = FontWeight.w500}) =>
              TextStyle(color: Colors.white, fontSize: f(size), fontWeight: w, height: 1.0);

          return CardShell(
            radius: f(22),
            child: ColoredBox(
              color: cardTeal,
              child: Stack(
                children: [
                  // Cream panel with the emblem.
                  Positioned(
                    left: f(110),
                    top: 0,
                    width: f(320),
                    height: f(304),
                    child: DecoratedBox(
                      decoration: printedCardPaper(
                        shape: BorderRadius.only(
                          bottomLeft: Radius.circular(f(46)),
                          bottomRight: Radius.circular(f(46)),
                        ),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: f(26)),
                          // Just the QR, filling the whole panel — the
                          // registration numbers (Reg.No./Lic No.) that
                          // used to sit under it were removed.
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                width: f(260),
                                height: f(260),
                                child: MemberQrView(
                                  qr: qr,
                                  isLoading: isQrLoading,
                                  hasError: hasQrError,
                                  onRetry: onQrRetry,
                                  size: f(260),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: f(18)),
                        ],
                      ),
                    ),
                  ),

                  // Heading.
                  Positioned(
                    left: f(30),
                    right: f(30),
                    top: f(332),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('FOUNDERS & DIRECTORS', style: white(32, w: FontWeight.w800)),
                      ),
                    ),
                  ),

                  // Timeline line.
                  Positioned(left: f(78.8), top: f(410), width: f(2.4), height: f(288), child: const ColoredBox(color: cardCream)),

                  // Timeline icons.
                  CardTimelineIcon(left: f(60), top: f(386), icon: Icons.person_rounded, s: s),
                  CardTimelineIcon(left: f(60), top: f(458), icon: Icons.person_rounded, s: s),
                  CardTimelineIcon(left: f(60), top: f(530), icon: Icons.location_on_rounded, s: s),
                  CardTimelineIcon(left: f(60), top: f(670), icon: Icons.mail_rounded, s: s),

                  // Founders.
                  Positioned(left: f(116), top: f(386), child: Text(cardFounders[0].$1, style: white(27))),
                  Positioned(left: f(116), top: f(419), child: Text(cardFounders[0].$2, style: white(27))),
                  Positioned(left: f(116), top: f(458), child: Text(cardFounders[1].$1, style: white(27))),
                  Positioned(left: f(116), top: f(491), child: Text(cardFounders[1].$2, style: white(27))),

                  // Address.
                  Positioned(
                    left: f(116),
                    top: f(532),
                    child: Text(
                      cardFounderAddress,
                      style: TextStyle(color: Colors.white, fontSize: f(27), fontWeight: FontWeight.w500, height: 1.25),
                    ),
                  ),

                  // Email.
                  Positioned(left: f(116), top: f(672), child: Text(cardEmail, style: white(27))),

                  // Divider + registered office.
                  Positioned(left: f(60), top: f(734), width: f(450), height: f(1.6), child: const ColoredBox(color: cardCream)),
                  Positioned(
                    left: f(20),
                    right: f(20),
                    top: f(746),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Reg. Office : 57, D.K. Nagar-2, Nr. Santoshi\nKrupa Society, Dabholi Char Rasta,\nKatargam, Surat - 395 004',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cardCream, fontSize: f(23), fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),
                  ),

                  // Footer note on a cream strip.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: f(864),
                    height: f(28),
                    child: ColoredBox(
                      color: cardCream,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: f(16)),
                            child: Text(
                              'card_footer_note'.tr,
                              maxLines: 1,
                              style: TextStyle(color: cardInk, fontSize: f(15), fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
