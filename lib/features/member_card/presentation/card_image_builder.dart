import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../data/member_card_data.dart';
import '../data/member_qr_image.dart';
import 'card_face_renderer.dart';
import 'member_card_layout.dart';
import 'widgets/horizontal_card_faces.dart' show horizontalCardAspectRatio;
import 'widgets/vertical_card_faces.dart' show verticalCardAspectRatio;

/// Builds a single downloadable PNG with both card faces on it (front, then
/// back) — the image counterpart of PrintedCardPdf, laid out the same way:
/// stacked for the horizontal card, side by side for the vertical one. Reuses
/// the exact same rendered card widgets, so it's pixel-for-pixel what the PDF
/// and the on-screen wallet show, in the language the member selected.
class CardImageBuilder {
  CardImageBuilder._();

  /// White margin around the two faces, and the gap between them — in the
  /// same logical pixels [_ImageSpec.pixelRatio] scales everything else by.
  static const double _margin = 24;
  static const double _gap = 20;

  static Future<Uint8List> build(
    MemberCardData data,
    MemberCardLayout layout, {
    MemberQrImage? qr,
    bool hasQrError = false,
  }) async {
    final spec = _ImageSpec.of(layout);
    final faces = await CardFaceRenderer.render(
      data: data,
      layout: layout,
      qr: qr,
      hasQrError: hasQrError,
      logicalWidth: spec.logicalWidth,
      logicalHeight: spec.logicalHeight,
      pixelRatio: spec.pixelRatio,
    );

    final front = img.decodePng(faces[0]);
    final back = img.decodePng(faces[1]);
    if (front == null || back == null) {
      throw StateError('Could not decode the rendered card faces.');
    }

    final margin = (_margin * spec.pixelRatio).round();
    final gap = (_gap * spec.pixelRatio).round();

    final canvasWidth = layout == MemberCardLayout.horizontal
        ? front.width + margin * 2
        : front.width + gap + back.width + margin * 2;
    final canvasHeight = layout == MemberCardLayout.horizontal
        ? front.height + gap + back.height + margin * 2
        : front.height + margin * 2;

    final canvas = img.Image(width: canvasWidth, height: canvasHeight);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    img.compositeImage(canvas, front, dstX: margin, dstY: margin);

    if (layout == MemberCardLayout.horizontal) {
      img.compositeImage(canvas, back, dstX: margin, dstY: margin + front.height + gap);
    } else {
      img.compositeImage(canvas, back, dstX: margin + front.width + gap, dstY: margin);
    }

    return Uint8List.fromList(img.encodePng(canvas));
  }
}

/// Logical render size + resolution for the combined image — deliberately
/// separate from PrintedCardPdf's own `_CardSpec` (a PDF page is measured
/// in points at print resolution; this is a plain PNG sized for viewing and
/// sharing on a phone).
class _ImageSpec {
  const _ImageSpec({
    required this.logicalWidth,
    required this.logicalHeight,
    required this.pixelRatio,
  });

  final double logicalWidth;
  final double logicalHeight;
  final double pixelRatio;

  static _ImageSpec of(MemberCardLayout layout) {
    switch (layout) {
      case MemberCardLayout.horizontal:
        return const _ImageSpec(
          logicalWidth: 1050,
          logicalHeight: 1050 / horizontalCardAspectRatio,
          pixelRatio: 2,
        );
      case MemberCardLayout.vertical:
        return const _ImageSpec(
          logicalWidth: 640,
          logicalHeight: 640 / verticalCardAspectRatio,
          pixelRatio: 2,
        );
    }
  }
}
