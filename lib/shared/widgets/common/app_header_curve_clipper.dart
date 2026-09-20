import 'package:flutter/widgets.dart';

/// Shared bottom-edge "swoop" clip used by every gradient header in the
/// app — the sub-page header ([AppSubPageHeader]), the Home header, and
/// available for any future header that wants the same curved silhouette
/// instead of a hard rectangle.
///
/// Deliberately a standalone copy of the curve math in
/// `features/auth/presentation/widgets/auth_header_clipper.dart` rather
/// than importing that file — feature folders (auth, home, profile, ...)
/// should not depend on each other, only on `shared/`.
///
/// By default the edge is low on the right and high on the left. With
/// [mirrored] the wave is flipped left-to-right (low on the left, high on
/// the right). [waveScale] shrinks the wave's amplitude (1 = full) — used
/// by the Home header so the same curve keeps its look at a smaller height.
class AppHeaderCurveClipper extends CustomClipper<Path> {
  const AppHeaderCurveClipper({this.mirrored = false, this.waveScale = 1});

  final bool mirrored;

  final double waveScale;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final k = waveScale;

    // Wave anchor points as (x fraction, y offset above the bottom edge),
    // listed left-to-right for the default orientation.
    final p0 = Offset(0, h - 45 * k);
    final c1 = Offset(w * 0.25, h + 5 * k);
    final p1 = Offset(w * 0.52, h - 20 * k);
    final c2 = Offset(w * 0.78, h - 48 * k);
    final p2 = Offset(w, h - 12 * k);

    Offset m(Offset o) => mirrored ? Offset(w - o.dx, o.dy) : o;

    final path = Path()..moveTo(0, 0);

    if (!mirrored) {
      path
        ..lineTo(p0.dx, p0.dy)
        ..quadraticBezierTo(c1.dx, c1.dy, p1.dx, p1.dy)
        ..quadraticBezierTo(c2.dx, c2.dy, p2.dx, p2.dy);
    } else {
      // Same curve traced right-to-left, so the path still runs left to
      // right along the bottom edge.
      path
        ..lineTo(m(p2).dx, m(p2).dy)
        ..quadraticBezierTo(m(c2).dx, m(c2).dy, m(p1).dx, m(p1).dy)
        ..quadraticBezierTo(m(c1).dx, m(c1).dy, m(p0).dx, m(p0).dy);
    }

    path
      ..lineTo(w, 0)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant AppHeaderCurveClipper oldClipper) =>
      oldClipper.mirrored != mirrored || oldClipper.waveScale != waveScale;
}
