import 'package:flutter/cupertino.dart';

class AuthHeaderClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, 0);

    path.lineTo(
      0,
      size.height - 45,
    );

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

    path.lineTo(
      size.width,
      0,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
      covariant CustomClipper<Path> oldClipper,
      ) {
    return false;
  }
}