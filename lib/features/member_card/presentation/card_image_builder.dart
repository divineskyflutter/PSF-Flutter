import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
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

    // Rendering the faces themselves needs the Flutter widget/rendering
    // pipeline, so it has to stay on the main isolate.
    final faces = await CardFaceRenderer.render(
      data: data,
      layout: layout,
      qr: qr,
      hasQrError: hasQrError,
      logicalWidth: spec.logicalWidth,
      logicalHeight: spec.logicalHeight,
      pixelRatio: spec.pixelRatio,
    );

    // Decoding/compositing/encoding the actual pixels, though, is plain
    // CPU-bound Dart work with no Flutter dependency — done via compute()
    // on a background isolate so it never blocks the main isolate (which
    // would otherwise freeze the download button's own spinner animation
    // for however long this takes).
    return compute(
      _composeImage,
      _ComposeArgs(
        frontBytes: faces[0],
        backBytes: faces[1],
        layout: layout,
        pixelRatio: spec.pixelRatio,
      ),
    );
  }
}

/// Everything [_composeImage] needs, bundled into one transferable object —
/// `compute()` sends this across to the background isolate.
class _ComposeArgs {
  const _ComposeArgs({
    required this.frontBytes,
    required this.backBytes,
    required this.layout,
    required this.pixelRatio,
  });

  final Uint8List frontBytes;
  final Uint8List backBytes;
  final MemberCardLayout layout;
  final double pixelRatio;
}

/// Runs on a background isolate (see `compute()` above) — must be a
/// top-level function for that, so it can't be a method on
/// [CardImageBuilder] itself.
Uint8List _composeImage(_ComposeArgs args) {
  final front = img.decodePng(args.frontBytes);
  final back = img.decodePng(args.backBytes);
  if (front == null || back == null) {
    throw StateError('Could not decode the rendered card faces.');
  }

  final margin = (CardImageBuilder._margin * args.pixelRatio).round();
  final gap = (CardImageBuilder._gap * args.pixelRatio).round();

  final canvasWidth = args.layout == MemberCardLayout.horizontal
      ? front.width + margin * 2
      : front.width + gap + back.width + margin * 2;
  final canvasHeight = args.layout == MemberCardLayout.horizontal
      ? front.height + gap + back.height + margin * 2
      : front.height + margin * 2;

  final canvas = img.Image(width: canvasWidth, height: canvasHeight);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

  img.compositeImage(canvas, front, dstX: margin, dstY: margin);

  if (args.layout == MemberCardLayout.horizontal) {
    img.compositeImage(canvas, back, dstX: margin, dstY: margin + front.height + gap);
  } else {
    img.compositeImage(canvas, back, dstX: margin + front.width + gap, dstY: margin);
  }

  return Uint8List.fromList(img.encodePng(canvas));
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
