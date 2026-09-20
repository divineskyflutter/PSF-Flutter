import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:psf_application/app/constants/app_assets.dart';

import '../data/member_card_data.dart';
import 'member_card_layout.dart';
import 'widgets/horizontal_card_faces.dart';
import 'widgets/vertical_card_faces.dart';

/// Builds the downloadable PDF for the printed-style card, in whichever
/// [MemberCardLayout] the member picked.
///
/// Instead of redrawing the card with PDF primitives (which can't shape
/// Gujarati/Hindi text without bundling fonts), the exact same card faces
/// shown in the app are rendered offscreen to images and placed on the page —
/// so the PDF is pixel-for-pixel what the member sees, in the language they
/// selected.
///
/// The cards sit on the page with a margin all round and a gap between them,
/// so they fit a screen or a print without touching the edges:
///
///  * Horizontal: front on top, back below (each 254 x 152 pt).
///  * Vertical: front and back side by side (each 153 x 255 pt).
class PrintedCardPdf {
  PrintedCardPdf._();

  static Future<Uint8List> build(MemberCardData data, MemberCardLayout layout) async {
    final spec = _CardSpec.of(layout);
    final images = await _renderFaces(data, spec);

    final doc = pw.Document(
      title: 'PSF Member Card',
      author: 'Parivar Suraksha Foundation',
    );

    final front = pw.Image(pw.MemoryImage(images[0]), width: spec.pdfCardWidth, height: spec.pdfCardHeight);
    final back = pw.Image(pw.MemoryImage(images[1]), width: spec.pdfCardWidth, height: spec.pdfCardHeight);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(spec.pageWidth, spec.pageHeight),
        margin: const pw.EdgeInsets.all(_CardSpec.margin),
        build: (context) => layout == MemberCardLayout.horizontal
            ? pw.Column(
                children: [
                  front,
                  pw.SizedBox(height: _CardSpec.gap),
                  back,
                ],
              )
            : pw.Row(
                children: [
                  front,
                  pw.SizedBox(width: _CardSpec.gap),
                  back,
                ],
              ),
      ),
    );

    return doc.save();
  }

  static Future<List<Uint8List>> _renderFaces(MemberCardData data, _CardSpec spec) async {
    // `Get.overlayContext` is the overlay's own context, so looking the
    // overlay up *from* it finds nothing — take the state straight from the
    // root navigator instead.
    final overlay = Get.key.currentState?.overlay;
    final overlayContext = overlay?.context;

    if (overlay == null || overlayContext == null) {
      throw StateError('No overlay available to render the card.');
    }

    // Make sure everything the faces draw is already decoded, so the
    // capture doesn't grab half-loaded images.
    final photoUrl = data.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        await precacheImage(
          ResizeImage(NetworkImage(photoUrl), width: 500),
          overlayContext,
        );
      } catch (_) {
        // A missing photo just leaves the frame empty.
      }
    }
    if (!overlayContext.mounted) throw StateError('Context is gone.');
    await precacheImage(const AssetImage(AppAssets.cardPaper), overlayContext);
    if (!overlayContext.mounted) throw StateError('Context is gone.');
    await precacheImage(const AssetImage(AppAssets.chairmanSignature), overlayContext);

    final frontKey = GlobalKey();
    final backKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        // Far off-screen: painted (so it can be captured) but never seen.
        left: -spec.logicalWidth * 3,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              RepaintBoundary(
                key: frontKey,
                child: SizedBox(
                  width: spec.logicalWidth,
                  height: spec.logicalHeight,
                  child: spec.layout == MemberCardLayout.horizontal
                      ? HorizontalCardFront(data: data)
                      : VerticalCardFront(data: data),
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: backKey,
                child: SizedBox(
                  width: spec.logicalWidth,
                  height: spec.logicalHeight,
                  child: spec.layout == MemberCardLayout.horizontal
                      ? const HorizontalCardBack()
                      : const VerticalCardBack(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(entry);

    try {
      // Let the faces lay out and paint, and the SVG emblem finish loading.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await WidgetsBinding.instance.endOfFrame;

      Future<Uint8List> grab(GlobalKey key) async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: spec.pixelRatio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return bytes!.buffer.asUint8List();
      }

      return [await grab(frontKey), await grab(backKey)];
    } finally {
      entry.remove();
    }
  }
}

/// Sizes for one layout: the logical size the faces are laid out at when
/// captured, the capture resolution, and the size of each face on the PDF.
class _CardSpec {
  const _CardSpec({
    required this.layout,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.pixelRatio,
    required this.pdfCardWidth,
    required this.pdfCardHeight,
  });

  /// Space between the page edge and the cards, and between the two cards.
  static const double margin = 16;
  static const double gap = 14;

  final MemberCardLayout layout;
  final double logicalWidth;
  final double logicalHeight;
  final double pixelRatio;
  final double pdfCardWidth;
  final double pdfCardHeight;

  double get pageWidth =>
      layout == MemberCardLayout.horizontal ? pdfCardWidth + margin * 2 : pdfCardWidth * 2 + gap + margin * 2;

  double get pageHeight =>
      layout == MemberCardLayout.horizontal ? pdfCardHeight * 2 + gap + margin * 2 : pdfCardHeight + margin * 2;

  static _CardSpec of(MemberCardLayout layout) {
    switch (layout) {
      case MemberCardLayout.horizontal:
        const width = 254.0;
        return _CardSpec(
          layout: layout,
          logicalWidth: 700,
          logicalHeight: 700 / horizontalCardAspectRatio,
          pixelRatio: 2.4,
          pdfCardWidth: width,
          pdfCardHeight: width / horizontalCardAspectRatio,
        );
      case MemberCardLayout.vertical:
        const width = 153.0;
        const height = width / verticalCardAspectRatio;
        return _CardSpec(
          layout: layout,
          logicalWidth: 420,
          logicalHeight: 420 / verticalCardAspectRatio,
          pixelRatio: 3,
          pdfCardWidth: width,
          pdfCardHeight: height,
        );
    }
  }
}
