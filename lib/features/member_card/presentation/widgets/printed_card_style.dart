import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_assets.dart';

// Look and content shared by the horizontal and the vertical member card —
// both are the foundation's printed card, so colours, the founders' details
// and the paper texture live in one place.

const cardTeal = Color(0xFF087A72);
const cardCream = Color(0xFFECE3CB);
const cardPaperBase = Color(0xFFE9DFC6);
const cardInk = Color(0xFF1A1A18);

const cardFounders = [
  ('Bipin Ghoghari', '+91 8000 212 041'),
  ('Bharat Variya', '+91 98256 35110'),
];

const cardFounderAddress = 'B/29, Second Floor,\nDanev Ashish Society,\nChikuwadi Road,\nKatargam, Surat - 395 004';

const cardEmail = 'psk4mail@gmail.com';

const cardCin = 'Reg.No.(CIN): U94990GJ2025NPL167764';

const cardLicence = 'Lic No.:  173515';

/// Width / height of the chairman's signature block image.
const chairmanSignatureAspectRatio = 527 / 260;

BoxDecoration printedCardPaper({BorderRadius? shape}) => BoxDecoration(
      color: cardPaperBase,
      borderRadius: shape,
      image: const DecorationImage(
        image: AssetImage(AppAssets.cardPaper),
        fit: BoxFit.cover,
      ),
    );

/// `PSK` printed on the card, followed by the member number when there is
/// one (`-` until a real member number is assigned).
String printedMemberNumber(String memberNo) {
  final trimmed = memberNo.trim();
  if (trimmed.isEmpty) return 'PSK  -';
  if (trimmed.toUpperCase().startsWith('PSK')) return trimmed;
  return 'PSK  $trimmed';
}

/// The chairman's "Auth. Signature" block (signature + "Parivar Suraksha
/// Foundation (Chairman)"), taken from the printed card.
class ChairmanSignature extends StatelessWidget {
  const ChairmanSignature({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(AppAssets.chairmanSignature, fit: BoxFit.contain);
  }
}

/// Outer shell of a card face: rounded corners, soft shadow, content clipped.
class CardShell extends StatelessWidget {
  const CardShell({super.key, required this.radius, required this.child});

  final double radius;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: child),
    );
  }
}

/// One "Label : value" line on the card front. All sizes are in design
/// pixels and scaled by [s].
class CardFieldRow extends StatelessWidget {
  const CardFieldRow({
    super.key,
    required this.label,
    required this.value,
    required this.s,
    this.lines = 1,
    this.rowHeight = 62,
    this.labelWidth = 128,
    this.labelSize = 32,
    this.valueSize = 31,
  });

  final String label;

  final String value;

  final double s;

  /// How many lines [value] may wrap to before it's cut off with an
  /// ellipsis (e.g. 2 for Address) — never changes [valueSize]; every
  /// field on a card face reads at the same size regardless of how many
  /// lines its own value happens to need.
  final int lines;

  final double rowHeight;

  final double labelWidth;

  final double labelSize;

  final double valueSize;

  @override
  Widget build(BuildContext context) {
    double f(double v) => v * s;

    return SizedBox(
      height: f(rowHeight),
      child: Row(
        // Was `.start` — the label and the value are set in different font
        // sizes with different explicit line-height factors, so lining up
        // their top edges actually left the glyphs themselves sitting at
        // different heights (the value visibly higher than the label it's
        // next to). Centering both within the row lines up how they
        // actually look, not just their invisible bounding boxes.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: f(labelWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(color: cardInk, fontSize: f(labelSize), fontWeight: FontWeight.w900, height: 1.0),
              ),
            ),
          ),
          Text(':', style: TextStyle(color: cardInk, fontSize: f(labelSize), fontWeight: FontWeight.w900, height: 1.0)),
          SizedBox(width: f(14)),
          Expanded(
            child: Text(
              value,
              maxLines: lines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cardInk,
                fontSize: f(valueSize),
                height: lines > 1 ? 1.15 : 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Round icon on the back's founders timeline.
class CardTimelineIcon extends StatelessWidget {
  const CardTimelineIcon({super.key, required this.left, required this.top, required this.icon, required this.s});

  final double left;

  final double top;

  final IconData icon;

  final double s;

  @override
  Widget build(BuildContext context) {
    final size = 40 * s;

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cardTeal,
          shape: BoxShape.circle,
          border: Border.all(color: cardCream, width: 2.2 * s),
        ),
        child: Icon(icon, color: cardCream, size: 24 * s),
      ),
    );
  }
}
