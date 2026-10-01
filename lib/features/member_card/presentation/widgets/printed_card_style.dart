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

/// Shown in the member-photo frame instead of leaving it blank white — when
/// there's no photo on file yet, and as the fallback if the network image
/// fails to load. [size] is the frame's own already-scaled (`f(...)`)
/// width, so the icon scales down proportionally with the rest of the card.
class CardPhotoPlaceholder extends StatelessWidget {
  const CardPhotoPlaceholder({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: cardTeal.withOpacity(.08),
      child: Center(
        child: Icon(Icons.person_rounded, color: cardTeal.withOpacity(.45), size: size * .55),
      ),
    );
  }
}

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

/// Width (in the same design-pixel units [CardFieldRow.labelWidth] takes)
/// that fits the widest of [labels] at [fontSize]/[weight] with room to
/// spare — so whichever language is active, every label on the card renders
/// at full size (no [FittedBox] scale-down) and every row's colon lines up,
/// instead of a width tuned for English clipping a longer Hindi/Gujarati
/// label and both shrinking its font and crushing its gap before the colon.
double cardLabelWidth(List<String> labels, {required double fontSize, FontWeight weight = FontWeight.w900}) {
  var maxWidth = 0.0;
  for (final label in labels) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        // Must match the card's own Text widgets, which — via
        // DefaultTextStyle — inherit the app theme's fontFamily ('Inter',
        // see AppTheme.lightTheme). 'Inter' has no Devanagari/Gujarati
        // glyphs, so both this measurement and the real render fall back to
        // the system's Devanagari/Gujarati font — but only if both start
        // from the SAME nominal family. Leaving this unset measured against
        // Flutter's bare default instead, which resolved the fallback
        // slightly narrower than the real render and left "जन्म तिथि" still
        // clipped against its own colon.
        style: TextStyle(fontSize: fontSize, fontWeight: weight, fontFamily: 'Inter'),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (painter.width > maxWidth) maxWidth = painter.width;
  }
  return maxWidth + 10;
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
    // Was 31 — a 1px-smaller value than its label, combined with the
    // explicit `height: 1.0` both use, shifted the value's own alphabetic
    // baseline a couple of pixels off the label/colon's, even though
    // CrossAxisAlignment.baseline aligns baselines exactly: `height`
    // compresses each Text's leading proportionally to its OWN fontSize,
    // so two different font sizes produce two different baseline
    // offsets-from-top even when "baseline-aligned" to each other up the
    // tree. Matching the sizes removes the mismatch at its source instead
    // of fighting it with a manual nudge.
    this.valueSize = 32,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Only a genuinely wrapped 2nd line (not just "lines > 1 allows
        // it") gets the extra bottom gap below — measured directly against
        // the value's own actual available width, rather than guessing
        // from a line-height multiplier (which added the same extra space
        // between every line AND after the last one alike, each row's own
        // specific 2nd line still crowded the next row below it) or always
        // reserving it (which widened the gap even when the value fit on
        // one line).
        final valueAvailableWidth =
            constraints.maxWidth - f(labelWidth) - _colonWidth(f(labelSize)) - f(14);
        final wrapsToSecondLine = lines > 1 &&
            valueAvailableWidth > 0 &&
            _wrapsToMultipleLines(value, f(valueSize), valueAvailableWidth);

        // A MINIMUM, not a fixed height — [rowHeight] is sized for one
        // line, so every single-line row (Name/Contact/DOB, and Address
        // itself whenever the member's actual address happens to be short)
        // ends up exactly the same height and the gaps between rows stay
        // even. Only when [value] genuinely wraps to a 2nd line does the
        // row grow taller than that minimum, on its own, by exactly the
        // extra line's worth plus [_extraGapBelowWrappedValue] — instead of
        // every row reserving 2-line space all the time, which left a
        // visibly bigger gap under Address than between the other rows
        // even when it only needed 1 line.
        return Padding(
          // A small, fixed "mini gap" — only when the value genuinely
          // wrapped. Zero otherwise, so a 1-line value's row is completely
          // unaffected (no bigger gap than any other single-line row).
          padding: EdgeInsets.only(bottom: wrapsToSecondLine ? f(10) : 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: f(rowHeight)),
            child: Row(
              // CrossAxisAlignment.center (and before that, the FittedBox
              // this used to wrap the label in) both line up the three
              // children's *bounding boxes* — fine when they're all the
              // same script, but Devanagari/Gujarati glyphs sit at a
              // different position within their own line box than Latin
              // ones do (different font, via system fallback — 'Inter'
              // itself has neither script's glyphs). A label like "जन्म
              // तिथि" next to a plain ':' then centers two boxes whose
              // actual glyphs don't optically match, so the colon reads as
              // sitting lower than the label. `.baseline` instead asks
              // each child for its own real text baseline and lines those
              // up — the correct cross-script fix, not a box geometry
              // approximation.
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                SizedBox(
                  width: f(labelWidth),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: cardInk, fontSize: f(labelSize), fontWeight: FontWeight.w900, height: 1.0),
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
                      // A little extra leading between a wrapped value's
                      // own 2 lines (the gap *below* the 2nd line, before
                      // the next row, is handled above instead — height
                      // affects every line equally, including below the
                      // last one, which isn't where this needed tuning).
                      height: lines > 1 ? 1.15 : 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Width of a single ':' at [fontSize]/w900 — matches the colon
/// [CardFieldRow] itself renders, for [CardFieldRow]'s own wrap check.
double _colonWidth(double fontSize) {
  final painter = TextPainter(
    text: TextSpan(
      text: ':',
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: 'Inter'),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

/// Whether [text] actually needs more than one line at [fontSize]/w600
/// when constrained to [maxWidth] — used to decide whether a value
/// genuinely wrapped (see [CardFieldRow]), not just whether it was
/// *allowed* to.
bool _wrapsToMultipleLines(String text, double fontSize, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return painter.computeLineMetrics().length > 1;
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
