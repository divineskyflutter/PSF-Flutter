import 'package:flutter/material.dart';

extension ResponsiveDouble on double {
  /// Responsive pixel size.
  ///
  /// Based on a 390px reference mobile width.
  /// Also works on tablets and larger screens.
  double px(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    const referenceWidth = 390.0;

    final scale = width / referenceWidth;

    // Prevent extremely small/large scaling.
    final clampedScale = scale.clamp(0.85, 1.35);

    return this * clampedScale;
  }
}

extension ResponsiveInt on int {
  double px(BuildContext context) {
    return toDouble().px(context);
  }
}

extension DeviceType on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < 600;

  bool get isTablet =>
      screenWidth >= 600 && screenWidth < 1200;

  bool get isDesktop => screenWidth >= 1200;

  DeviceTypeEnum get deviceType {
    if (screenWidth < 600) {
      return DeviceTypeEnum.mobile;
    }

    if (screenWidth < 1200) {
      return DeviceTypeEnum.tablet;
    }

    return DeviceTypeEnum.desktop;
  }
}

enum DeviceTypeEnum {
  mobile,
  tablet,
  desktop,
}