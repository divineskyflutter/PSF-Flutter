import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:signature/signature.dart';

import '../../../app/constants/app_colors.dart';

class AppSignatureBottomSheet extends StatefulWidget {
  const AppSignatureBottomSheet({
    super.key,
  });

  @override
  State<AppSignatureBottomSheet> createState() =>
      _AppSignatureBottomSheetState();
}

class _AppSignatureBottomSheetState
    extends State<AppSignatureBottomSheet> {
  late SignatureController signatureController;

  @override
  void initState() {
    super.initState();

    signatureController =
        SignatureController(
          penStrokeWidth: 3,
          penColor: AppColors.primaryDark,
          exportBackgroundColor: Colors.white,
        );
  }

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (signatureController.isEmpty) {
      ToastUtil.error(
        'please_enter_your_signature'.tr,
        title: 'your_signature'.tr,
      );

      return;
    }

    final Uint8List? data =
    await signatureController
        .toPngBytes();

    if (data == null) return;

    // Crop down to just the drawn strokes' own bounding box, not the
    // whole (mostly blank) drawing pad — see _trimSignature's doc
    // comment for why this matters now that the pad is much larger (~75%
    // of screen height) than the old fixed 220px one.
    final trimmed = _trimSignature(data) ?? data;

    final directory =
    await getTemporaryDirectory();

    final file = File(
      '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(trimmed);

    Get.back(
      result: file,
    );
  }

  /// Crops the exported signature PNG down to the bounding box of the
  /// actually-drawn ink (plus a small margin), instead of leaving the
  /// entire drawing-pad canvas in the saved file. Without this, wherever
  /// the member happens to draw on the (now much bigger) pad is where the
  /// ink ends up sitting inside an otherwise blank white image — so
  /// anywhere this file is later shown small (the Preview screen, the
  /// downloaded PDF) the signature can appear shifted off to one side
  /// instead of starting at the left like it used to with the old, small,
  /// tightly-fitted pad. Returns null (caller falls back to the
  /// untrimmed bytes) if decoding fails or the canvas is entirely blank.
  Uint8List? _trimSignature(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) return null;

    // Anything noticeably darker than the pad's own white
    // exportBackgroundColor counts as ink.
    const whiteThreshold = 250;

    int? minX, minY, maxX, maxY;

    for (var y = 0; y < decoded.height; y++) {
      for (var x = 0; x < decoded.width; x++) {
        final pixel = decoded.getPixel(x, y);
        final isInk = pixel.a > 10 &&
            (pixel.r < whiteThreshold ||
                pixel.g < whiteThreshold ||
                pixel.b < whiteThreshold);

        if (!isInk) continue;

        minX = (minX == null || x < minX) ? x : minX;
        minY = (minY == null || y < minY) ? y : minY;
        maxX = (maxX == null || x > maxX) ? x : maxX;
        maxY = (maxY == null || y > maxY) ? y : maxY;
      }
    }

    if (minX == null || minY == null || maxX == null || maxY == null) {
      // Blank canvas — shouldn't reach here since signatureController.isEmpty
      // is already checked before this is called, but nothing to trim to.
      return null;
    }

    const margin = 12;
    final cropX = (minX - margin).clamp(0, decoded.width - 1);
    final cropY = (minY - margin).clamp(0, decoded.height - 1);
    final cropWidth =
        ((maxX + margin) - cropX + 1).clamp(1, decoded.width - cropX);
    final cropHeight =
        ((maxY + margin) - cropY + 1).clamp(1, decoded.height - cropY);

    final cropped = img.copyCrop(
      decoded,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    return Uint8List.fromList(img.encodePng(cropped));
  }

  @override
  Widget build(BuildContext context) {
    // Client's requirements doc: open this sheet using ~75% of the
    // screen so there's real room to sign, instead of the old fixed
    // 220px drawing pad that stayed the same tiny size on every device
    // regardless of screen height. The pad itself now expands to fill
    // whatever's left after the title/buttons, rather than being a
    // fixed height on its own.
    final sheetHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          padding: EdgeInsets.all(
            20.px(context),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(
                24.px(context),
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                'your_signature'.tr,
                style: TextStyle(
                  fontSize: 20.px(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),

              SizedBox(
                height: 20.px(context),
              ),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(
                      16.px(context),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      16.px(context),
                    ),
                    child: Signature(
                      controller: signatureController,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: 16.px(context),
              ),

              // Same size/shape as the wizard's own Next/Previous buttons
              // (see registration_form_steps_screen.dart's bottom bar) —
              // fixed 48px height with zeroed button padding (otherwise
              // the theme's own default vertical padding fights the fixed
              // height and clips the label) and a 22-radius pill shape,
              // with the label in a FittedBox so it always fits on one
              // line instead of wrapping/clipping on a narrow screen.
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.px(context),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () {
                          signatureController.clear();
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'clear'.tr,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 12.px(context),
                  ),

                  Expanded(
                    child: SizedBox(
                      height: 48.px(context),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _saveSignature,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'save_signature'.tr,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}