import 'package:flutter/material.dart';
import 'package:swappro/utils/keyboard_dismiss.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final KeyboardDismissObserver keyboardDismissObserver =
      KeyboardDismissObserver();

  static void navigateTo(String routeName) {
    navigatorKey.currentState?.pushNamed(routeName);
  }

  static void navigateToAndRemoveUntil(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }
}
