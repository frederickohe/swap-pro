import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swappro/common_design/app_typography.dart';
import 'package:swappro/config/glob_navigator.dart';

/// Figma "Item / Header - Error" — bottom banner used app-wide for feedback.
abstract final class AppSnackBar {
  AppSnackBar._();

  static const Color background = Color(0xFF73193A);

  static const double _figmaW = 430;
  static const double _figmaH = 932;
  static const double _barFigmaH = 160;
  static const double _horizontalPadFigma = 61.5;
  static const double _textTopFigma = 70;
  static const double _textLineHeightFigma = 20;
  static const double _cornerRadiusFigma = 10;

  static OverlayEntry? _barrierEntry;
  static OverlayEntry? _bannerEntry;
  static Timer? _autoDismissTimer;

  /// Shows a bottom message banner. Tap outside the banner to dismiss.
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    hide();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        NavigationService.navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final wScale = size.width / _figmaW;
    final hScale = size.height / _figmaH;
    final barHeight = _barFigmaH * hScale;
    final horizontalPad = _horizontalPadFigma * wScale;
    final textTop = _textTopFigma * hScale;
    final textLineHeight = _textLineHeightFigma * hScale;
    final radius = _cornerRadiusFigma * wScale;
    final bottomInset = mediaQuery.viewPadding.bottom;

    void dismiss() {
      _autoDismissTimer?.cancel();
      _autoDismissTimer = null;
      _barrierEntry?.remove();
      _bannerEntry?.remove();
      _barrierEntry = null;
      _bannerEntry = null;
    }

    _barrierEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          onTap: dismiss,
          behavior: HitTestBehavior.translucent,
        ),
      ),
    );

    _bannerEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size.width,
                constraints: BoxConstraints(minHeight: barHeight),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  textTop,
                  horizontalPad,
                  barHeight - textTop - textLineHeight,
                ),
                alignment: Alignment.center,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 14 * wScale,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: textLineHeight / (14 * wScale),
                  ),
                ),
              ),
              if (bottomInset > 0) SizedBox(height: bottomInset),
            ],
          ),
        ),
      ),
    );

    overlay.insert(_barrierEntry!);
    overlay.insert(_bannerEntry!);
    _autoDismissTimer = Timer(duration, dismiss);
  }

  static void hide() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _barrierEntry?.remove();
    _bannerEntry?.remove();
    _barrierEntry = null;
    _bannerEntry = null;
  }
}

extension AppSnackBarContext on BuildContext {
  void showAppSnackBar(String message, {Duration duration = const Duration(seconds: 4)}) {
    AppSnackBar.show(this, message, duration: duration);
  }
}
