import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImagePickerUtil {
  ImagePickerUtil._();

  static final ImagePicker _picker = ImagePicker();

  // ============================================================
  // PICK IMAGE (with runtime permission)
  // ============================================================

  static Future<File?> pickImage({
    required ImageSource source,
    bool crop = true,
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
        return imageFile;
      }

      // ── 3. Crop (optional) ───────────────────────────────────
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile == null) {
        return null;
      }

      return File(croppedFile.path);
    } catch (e) {
      debugPrint('Image Picker Error: $e');
      return null;
    }
  }

  // ============================================================
  // PERMISSION HELPER
  // ============================================================

  static Future<bool> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return _checkAndRequest(
        permission: Permission.camera,
        deniedMessage: 'Camera permission is required to take a photo.',
      );
    }

    // Gallery / Photo Library
    if (Platform.isAndroid) {
      // Android 13+ uses READ_MEDIA_IMAGES; older versions use READ_EXTERNAL_STORAGE.
      // permission_handler maps Permission.photos to READ_MEDIA_IMAGES on SDK 33+
      // and to READ_EXTERNAL_STORAGE on older versions automatically.
      return _checkAndRequest(
        permission: Permission.photos,
        deniedMessage: 'Storage permission is required to pick a photo.',
      );
    }

    // iOS
    return _checkAndRequest(
      permission: Permission.photos,
      deniedMessage: 'Photo library permission is required to pick a photo.',
    );
  }

  static Future<bool> _checkAndRequest({
    required Permission permission,
    required String deniedMessage,
  }) async {
    var status = await permission.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(deniedMessage);
      return false;
    }

    // Request the permission
    status = await permission.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      _showPermanentlyDeniedDialog(deniedMessage);
      return false;
    }

    // Denied (but not permanently) — show snackbar
    Get.snackbar(
      'Permission Required',
      deniedMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    return false;
  }

  static void _showPermanentlyDeniedDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Permission Denied'),
        content: Text(
          '$message\n\nPlease enable it from Settings → App Permissions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}