import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_assets.dart';

import '../data/member_card_data.dart';
import '../data/member_qr_image.dart';
import 'member_card_layout.dart';
import 'widgets/horizontal_card_faces.dart';
import 'widgets/vertical_card_faces.dart';

/// Renders a member card's front and back faces to PNG bytes, off-screen —
/// the exact same widgets the member sees on the wallet card, captured via
/// `RenderRepaintBoundary` the same way a screenshot would. Shared by the PDF
/// download and the image download, so both are pixel-for-pixel identical to
/// what's on screen, in the language the member selected.
class CardFaceRenderer {
  CardFaceRenderer._();

  static Future<List<Uint8List>> render({
    required MemberCardData data,
    required MemberCardLayout layout,
    required MemberQrImage? qr,
    required bool hasQrError,
    required double logicalWidth,
    required double logicalHeight,
    required double pixelRatio,
  }) async {
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

    final qrBytes = qr?.bytes;
    final qrUrl = qr?.url;
    if (qrBytes != null) {
      try {
        await precacheImage(MemoryImage(qrBytes), overlayContext);
      } catch (_) {
        // Falls back to MemberQrView's own "unavailable" state below.
      }
    } else if (qrUrl != null && qrUrl.isNotEmpty) {
      try {
        await precacheImage(NetworkImage(qrUrl), overlayContext);
      } catch (_) {
        // Falls back to MemberQrView's own "unavailable" state below.
      }
    }
    if (!overlayContext.mounted) throw StateError('Context is gone.');

    final frontKey = GlobalKey();
    final backKey = GlobalKey();

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        // Far off-screen: painted (so it can be captured) but never seen.
        left: -logicalWidth * 3,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              RepaintBoundary(
                key: frontKey,
                child: SizedBox(
                  width: logicalWidth,
                  height: logicalHeight,
                  child: layout == MemberCardLayout.horizontal
                      ? HorizontalCardFront(data: data)
                      : VerticalCardFront(data: data),
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: backKey,
                child: SizedBox(
                  width: logicalWidth,
                  height: logicalHeight,
                  child: layout == MemberCardLayout.horizontal
                      ? HorizontalCardBack(
                          qr: qr,
                          isQrLoading: false,
                          hasQrError: hasQrError,
                          onQrRetry: () {},
                        )
                      : VerticalCardBack(
                          qr: qr,
                          isQrLoading: false,
                          hasQrError: hasQrError,
                          onQrRetry: () {},
                        ),
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
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        return bytes!.buffer.asUint8List();
      }

      return [await grab(frontKey), await grab(backKey)];
    } finally {
      entry.remove();
    }
  }
}
