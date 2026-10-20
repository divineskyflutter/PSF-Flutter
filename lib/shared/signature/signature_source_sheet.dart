import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// How the member wants to provide their signature.
enum SignatureSource { draw, gallery }

/// First step of adding a signature: pick between drawing it on screen
/// (the existing [AppSignatureBottomSheet] canvas) or taking an existing
/// signature image from the gallery. Pops with the chosen [SignatureSource],
/// or null if dismissed.
///
/// Same look as the registration's own camera/gallery source sheet
/// (`RegistrationController.showImageSourceSheet`) — including the 200 KB
/// note, since a gallery signature is held to the same size limit as every
/// other uploaded photo.
class SignatureSourceSheet extends StatelessWidget {
  const SignatureSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'signature_how_title'.tr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'image_size_limit_note'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.draw_outlined),
              title: Text('signature_draw_option'.tr),
              onTap: () => Get.back(result: SignatureSource.draw),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('signature_gallery_option'.tr),
              onTap: () => Get.back(result: SignatureSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}
