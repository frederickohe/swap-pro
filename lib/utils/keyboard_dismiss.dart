import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swappro/utils/keyboard_dismiss_stub.dart'
    if (dart.library.html) 'package:swappro/utils/keyboard_dismiss_web.dart';

/// Dismisses the software keyboard, including the Flutter-web HTML overlay.
void dismissAppKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  blurDomTextInput();
}

/// Blurs text input whenever a route is pushed or popped so the keyboard
/// cannot stay open under another page (Flutter web).
class KeyboardDismissObserver extends NavigatorObserver {
  void _dismiss() {
    dismissAppKeyboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dismissAppKeyboard();
      Future<void>.delayed(const Duration(milliseconds: 80), dismissAppKeyboard);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _dismiss();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _dismiss();
  }
}
