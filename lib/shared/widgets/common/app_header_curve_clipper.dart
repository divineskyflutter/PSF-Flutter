import 'package:flutter/widgets.dart';

/// Shared bottom-edge "swoop" clip used by every gradient header in the
/// app — the sub-page header ([AppSubPageHeader]), the collapsing Home
/// header ([AppHomeSliverHeader]), and available for any future header
/// that wants the same curved silhouette instead of a hard rectangle.
///
/// Deliberately a standalone copy of the curve math in
/// `features/auth/presentation/widgets/auth_header_clipper.dart` rather
/// than importing that file — feature folders (auth, home, profile, ...)
/// should not depend on each other, only on `shared/`.
class AppHeaderCurveClipper extends CustomClipper<Path> {
  const AppHeaderCurveClipper();

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);

    path.lineTo(0, size.height - 45);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height + 5,
      size.width * 0.52,
      size.height - 20,
    );

    path.quadraticBezierTo(
      size.width * 0.78,
      size.height - 48,
      size.width,
      size.height - 12,
    );

    path.lineTo(size.width, 0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
