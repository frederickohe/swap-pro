import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Status and navigation bar styling derived from a screen background color.
abstract final class AppSystemUi {
  AppSystemUi._();

  /// Light backgrounds → dark icons; dark backgrounds → light icons.
  static SystemUiOverlayStyle forBackground(Color background) {
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final base = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return base.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: background,
      systemNavigationBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    );
  }
}
