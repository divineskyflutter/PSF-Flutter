import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  ImagePickerUtil._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage({
    required ImageSource source,
    bool crop = true,
  }) async {
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

      final CroppedFile? croppedFile =
      await ImageCropper().cropImage(
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
}