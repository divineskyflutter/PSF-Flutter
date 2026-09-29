import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/member_card_data.dart';
import '../data/member_qr_image.dart';
import 'card_face_renderer.dart';
import 'member_card_layout.dart';
import 'widgets/horizontal_card_faces.dart' show horizontalCardAspectRatio;
import 'widgets/vertical_card_faces.dart' show verticalCardAspectRatio;

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

  static Future<Uint8List> build(
    MemberCardData data,
    MemberCardLayout layout, {
    MemberQrImage? qr,
    bool hasQrError = false,
  }) async {
    final spec = _CardSpec.of(layout);
    final images = await CardFaceRenderer.render(
      data: data,
      layout: layout,
      qr: qr,
      hasQrError: hasQrError,
      logicalWidth: spec.logicalWidth,
      logicalHeight: spec.logicalHeight,
      pixelRatio: spec.pixelRatio,
    );

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
