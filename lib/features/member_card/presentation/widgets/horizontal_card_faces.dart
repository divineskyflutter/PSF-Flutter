import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';

import '../../data/member_card_data.dart';
import 'printed_card_style.dart';

/// Landscape ID-card proportions of the foundation's printed card
/// (width / height).
const double horizontalCardAspectRatio = 1050 / 630;

/// Design width the layout below is drawn at — every size is `f(value)`,
/// i.e. scaled by `cardWidth / 1050`, so the card looks identical at any
/// size (screen, PDF capture, ...).
const double _designWidth = 1050;

const _regOffice =
    'Reg. Office : 57, D.K. Nagar-2, Nr. Santoshi Krupa Society,\nDabholi Char Rasta, Katargam, Surat - 395 004';

/// FRONT of the printed-style member card: cream paper, a teal band down the
/// left edge, the foundation's emblem, a teal title bar with the tagline
/// under it, the member's photo in a teal frame, and Name / Address /
/// Contact / DOB lines, and the chairman's signature block at the bottom
/// right. Labels, title and tagline follow the selected app language.
class HorizontalCardFront extends StatelessWidget {
  const HorizontalCardFront({super.key, required this.data});

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
            radius: f(18),
            child: DecoratedBox(
                decoration: printedCardPaper(),
                child: Stack(
                  children: [
                    // Teal band down the left edge.
                    Positioned(left: 0, top: 0, bottom: 0, width: f(38), child: const ColoredBox(color: cardTeal)),

                    // Sanskrit line.
                    Positioned(
                      left: f(284),
                      right: 0,
                      top: f(18),
                      child: Text(
                        '॥ वसुधैव कुटुम्बकम् ॥',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cardInk, fontSize: f(23), fontWeight: FontWeight.w500),
                      ),
                    ),

                    // Emblem.
                    Positioned(
                      left: f(66),
                      top: f(28),
                      width: f(182),
                      height: f(200),
                      child: SvgPicture.asset(AppAssets.logo, fit: BoxFit.contain),
                    ),

                    // Title bar.
                    Positioned(
                      left: f(284),
                      right: 0,
                      top: f(57),
                      height: f(119),
                      child: ColoredBox(
                        color: cardTeal,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(f(34), f(6), f(50), f(6)),
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
                                      fontSize: f(64),
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
                                        fontSize: f(30),
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
                      left: f(84),
                      top: f(241),
                      width: f(230),
                      height: f(302),
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

                    // Member number under the photo.
                    Positioned(
                      left: f(84),
                      top: f(552),
                      right: f(600),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          number,
                          maxLines: 1,
                          style: TextStyle(color: cardInk, fontSize: f(36), fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),

                    // Chairman's "Auth. Signature" block, as on the printed card.
                    Positioned(
                      left: f(750),
                      top: f(464),
                      width: f(261),
                      height: f(261 / chairmanSignatureAspectRatio),
                      child: const ChairmanSignature(),
                    ),

                    // Fields.
                    Positioned(
                      left: f(337),
                      right: f(36),
                      top: f(250),
                      child: Column(
                        children: [
                          CardFieldRow(label: 'card_label_name'.tr, value: MemberCardData.orDash(data.name), s: s),
                          CardFieldRow(label: 'address'.tr, value: MemberCardData.orDash(data.address), s: s, lines: 2),
                          CardFieldRow(label: 'card_label_contact'.tr, value: MemberCardData.orDash(data.mobile), s: s),
                          CardFieldRow(
                            label: 'card_label_dob'.tr,
                            value: MemberCardData.orDash(data.dateOfBirthNumeric),
                            s: s,
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

/// BACK of the printed-style member card: teal background, the emblem on a
/// cream panel with the registration numbers, the founders' contact details
/// down a timeline, the registered office and the footer note.
class HorizontalCardBack extends StatelessWidget {
  const HorizontalCardBack({super.key});

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
            radius: f(18),
            child: ColoredBox(
                color: cardTeal,
                child: Stack(
                  children: [
                    // Cream panel with the emblem.
                    Positioned(
                      left: f(87),
                      top: 0,
                      width: f(315),
                      height: f(416),
                      child: DecoratedBox(
                        decoration: printedCardPaper(
                          shape: BorderRadius.only(
                            bottomLeft: Radius.circular(f(46)),
                            bottomRight: Radius.circular(f(46)),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: f(28)),
                            Expanded(
                              child: SizedBox(
                                width: f(270),
                                child: SvgPicture.asset(AppAssets.logo, fit: BoxFit.contain),
                              ),
                            ),
                            SizedBox(height: f(14)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: f(10)),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  cardCin,
                                  maxLines: 1,
                                  style: TextStyle(color: cardInk, fontSize: f(17), fontWeight: FontWeight.w700, height: 1.1),
                                ),
                              ),
                            ),
                            SizedBox(height: f(4)),
                            Text(cardLicence, style: TextStyle(color: cardInk, fontSize: f(17), fontWeight: FontWeight.w600, height: 1.1)),
                            SizedBox(height: f(20)),
                          ],
                        ),
                      ),
                    ),

                    // Heading.
                    Positioned(
                      left: f(500),
                      right: f(50),
                      top: f(50),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text('FOUNDERS & DIRECTORS', style: white(34, w: FontWeight.w800)),
                      ),
                    ),

                    // Timeline line.
                    Positioned(left: f(578), top: f(150), width: f(2.4), height: f(285), child: const ColoredBox(color: cardCream)),

                    // Timeline icons.
                    CardTimelineIcon(left: f(560), top: f(128), icon: Icons.person_rounded, s: s),
                    CardTimelineIcon(left: f(560), top: f(200), icon: Icons.person_rounded, s: s),
                    CardTimelineIcon(left: f(560), top: f(272), icon: Icons.location_on_rounded, s: s),
                    CardTimelineIcon(left: f(560), top: f(416), icon: Icons.mail_rounded, s: s),

                    // Founders.
                    Positioned(
                      left: f(614),
                      top: f(128),
                      child: Text(cardFounders[0].$1, style: white(28)),
                    ),
                    Positioned(
                      left: f(614),
                      top: f(162),
                      child: Text(cardFounders[0].$2, style: white(28)),
                    ),
                    Positioned(
                      left: f(614),
                      top: f(200),
                      child: Text(cardFounders[1].$1, style: white(28)),
                    ),
                    Positioned(
                      left: f(614),
                      top: f(234),
                      child: Text(cardFounders[1].$2, style: white(28)),
                    ),

                    // Address.
                    Positioned(
                      left: f(614),
                      top: f(274),
                      child: Text(
                        cardFounderAddress,
                        style: TextStyle(color: Colors.white, fontSize: f(28), fontWeight: FontWeight.w500, height: 1.27),
                      ),
                    ),

                    // Email.
                    Positioned(left: f(614), top: f(418), child: Text(cardEmail, style: white(28))),

                    // Divider + registered office.
                    Positioned(left: f(142), top: f(478), width: f(768), height: f(1.6), child: const ColoredBox(color: cardCream)),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: f(490),
                      child: Text(
                        _regOffice,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cardCream, fontSize: f(27), fontWeight: FontWeight.w500, height: 1.3),
                      ),
                    ),

                    // Footer note on a cream strip.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: f(566),
                      height: f(28),
                      child: ColoredBox(
                        color: cardCream,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: f(30)),
                              child: Text(
                                'card_footer_note'.tr,
                                maxLines: 1,
                                style: TextStyle(color: cardInk, fontSize: f(17), fontWeight: FontWeight.w800),
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
