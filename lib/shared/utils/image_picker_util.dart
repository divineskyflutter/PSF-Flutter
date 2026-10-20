import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'toast_util.dart';

class ImagePickerUtil {
  ImagePickerUtil._();

  static final ImagePicker _picker = ImagePicker();

  // ============================================================
  // PICK IMAGE (with runtime permission)
  // ============================================================

  static Future<File?> pickImage({
    required ImageSource source,
    bool crop = true,
    // Sets the crop box's STARTING shape on Android — the member can
    // still freely drag it to any ratio afterward (lockAspectRatio stays
    // false below), this only saves them from having to resize it
    // themselves for a document photo that's naturally wider than tall
    // (Aadhaar/PAN card, passbook page). Left null (freeform, no default)
    // for anything that isn't a flat document scan, e.g. a face photo.
    CropAspectRatioPreset? aspectRatioPreset,
  }) async {
    // ── 1. Request the required permission ──────────────────────
    final granted = await _requestPermission(source);
    if (!granted) return null;

    // ── 2. Pick the image ───────────────────────────────────────
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return null;
      }

      final File imageFile = File(pickedFile.path);

      if (!crop) {
        return _finalizeImage(imageFile, source);
      }

      // ── 3. Crop (optional) ───────────────────────────────────
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            lockAspectRatio: false,
            initAspectRatio:
                aspectRatioPreset ?? CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile == null) {
        return null;
      }

      return _finalizeImage(File(croppedFile.path), source);
    } catch (e) {
      debugPrint('Image Picker Error: $e');
      return null;
    }
  }

  // ============================================================
  // SIZE LIMIT (always runs, right before the file is handed back)
  //
  // Every photo/document uploaded from the app must be under 200 KB.
  //   • Gallery: used exactly as picked, never re-encoded — what the
  //     member chose is what gets uploaded. If it's already over the
  //     limit, it's rejected outright (with a toast) rather than silently
  //     shrunk into something they didn't pick.
  //   • Camera: a fresh capture is essentially always far bigger than
  //     200 KB, and there's no other version of it to pick instead — so
  //     this compresses it down to fit, trying the steps below in order
  //     (highest quality first) and keeping the first one whose *output
  //     file* actually measures under the limit, so it only loses as much
  //     quality as it actually needs to. If nothing gets it under the
  //     limit, the photo is rejected the same way a too-big gallery pick
  //     is — never silently uploaded oversized.
  //
  // `imageQuality`/`compressQuality` on the picker/cropper above only
  // compress JPEG output — Android's own ImageResizer ignores that
  // setting for PNG, and image_cropper can hand back a PNG — so a camera
  // capture is always re-encoded to JPEG here regardless of what format
  // the picker/cropper produced.
  // ============================================================

  static const int _maxUploadBytes = 200 * 1024;

  static const List<_CompressStep> _compressSteps = [
    _CompressStep(quality: 90, minWidth: 1600, minHeight: 1200),
    _CompressStep(quality: 85, minWidth: 1280, minHeight: 960),
    _CompressStep(quality: 80, minWidth: 1024, minHeight: 768),
    _CompressStep(quality: 70, minWidth: 800, minHeight: 600),
    _CompressStep(quality: 60, minWidth: 640, minHeight: 480),
    _CompressStep(quality: 50, minWidth: 480, minHeight: 360),
  ];

  static Future<File?> _finalizeImage(File file, ImageSource source) async {
    if (source == ImageSource.gallery) {
      if (await file.length() <= _maxUploadBytes) return file;
      ToastUtil.error('image_too_large_error'.tr);
      return null;
    }

    try {
      final targetDir = await getTemporaryDirectory();

      for (final step in _compressSteps) {
        final targetPath =
            '${targetDir.path}/${DateTime.now().microsecondsSinceEpoch}.jpg';

        final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: step.quality,
          minWidth: step.minWidth,
          minHeight: step.minHeight,
          format: CompressFormat.jpeg,
        );

        if (compressed == null) continue;

        final compressedFile = File(compressed.path);
        if (!await compressedFile.exists()) continue;

        if (await compressedFile.length() <= _maxUploadBytes) {
          return compressedFile;
        }
      }
    } catch (e) {
      debugPrint('Image compression error: $e');
    }

    // Ran every step (or hit an error) and it's still over the limit —
    // never hand back an oversized file; the member sees this as a
    // cancelled pick, with the toast explaining why.
    ToastUtil.error('image_too_large_error'.tr);
    return null;
  }

  // ============================================================
  // PERMISSION HELPER
  // ============================================================

  static Future<bool> _requestPermission(ImageSource source) async {
    // Gallery needs no permission at all: image_picker opens the system
    // photo picker (Android) / PHPicker (iOS), which hands back only the
    // photo the member chose. Declaring and requesting broad photo/storage
    // access (READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE) just to pick one
    // picture is what Google Play's photo-and-video-permissions policy
    // rejects apps for.
    if (source == ImageSource.gallery) return true;

    // Camera is asked for here, at the moment the member taps "Camera" —
    // never up front at app start.
    return _checkAndRequest(
      permission: Permission.camera,
      deniedMessageKey: 'camera_permission_required',
    );
  }

  // ============================================================
  // Common permission flow, reused for every photo upload (camera and
  // gallery alike): request once, and — whatever the exact resulting
  // status — if the app still doesn't have access, always offer the
  // Cancel/Open Settings dialog rather than a dead-end message.
  //
  // This deliberately does NOT special-case `permanentlyDenied` vs a
  // plain `denied` result the way an earlier version did. In practice:
  //   • iOS only ever shows its native permission prompt once; every
  //     later call to request() returns a status with no UI at all, so
  //     treating a plain "denied" as unrecoverable-without-Settings is
  //     correct there from the very first refusal.
  //   • Android normally re-prompts on a first denial, but stops
  //     re-prompting (and may or may not flip the status to
  //     `permanentlyDenied`, depending on OS version/OEM) after the
  //     user has said no more than once.
  // Routing every non-granted outcome to the same dialog means the user
  // is never left stuck after a single tap that shows nothing but a
  // toast — Settings is always reachable.
  // ============================================================

  static Future<bool> _checkAndRequest({
    required Permission permission,
    required String deniedMessageKey,
  }) async {
    var status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    // Already permanently denied or platform-restricted (iOS parental
    // controls) — request() won't show any UI in either case, so go
    // straight to the Settings dialog instead of a no-op call.
    if (status.isPermanentlyDenied || status.isRestricted) {
      _showPermissionDeniedDialog(deniedMessageKey);
      return false;
    }

    // First (or not-yet-permanent) ask — this is what shows the native
    // OS permission prompt, when the OS is still willing to show one.
    status = await permission.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    // Still not granted after asking — offer the way to fix it instead
    // of a snackbar the user can't act on.
    _showPermissionDeniedDialog(deniedMessageKey);
    return false;
  }

  static void _showPermissionDeniedDialog(String deniedMessageKey) {
    Get.dialog(
      AlertDialog(
        title: Text('permission_required'.tr),
        content: Text(
          '${deniedMessageKey.tr} ${'enable_from_settings'.tr}',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: Text('open_settings'.tr),
          ),
        ],
      ),
    );
  }
}

/// One attempt in `ImagePickerUtil._compressSteps` — a resolution cap paired
/// with the JPEG quality to use at that resolution.
class _CompressStep {
  const _CompressStep({
    required this.quality,
    required this.minWidth,
    required this.minHeight,
  });

  final int quality;
  final int minWidth;
  final int minHeight;
}