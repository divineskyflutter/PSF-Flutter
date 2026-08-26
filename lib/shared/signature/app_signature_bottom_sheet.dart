import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
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
      Get.snackbar(
        'Signature',
        'Please enter your signature',
      );

      return;
    }

    final Uint8List? data =
    await signatureController
        .toPngBytes();

    if (data == null) return;

    final directory =
    await getTemporaryDirectory();

    final file = File(
      '${directory.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    await file.writeAsBytes(data);

    Get.back(
      result: file,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Signature',
              style: TextStyle(
                fontSize: 20.px(context),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),

            SizedBox(
              height: 20.px(context),
            ),

            Container(
              height: 220.px(context),
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

            SizedBox(
              height: 16.px(context),
            ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      signatureController.clear();
                    },
                    child: const Text(
                      'Clear',
                    ),
                  ),
                ),

                SizedBox(
                  width: 12.px(context),
                ),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSignature,
                    child: const Text(
                      'Save Signature',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}