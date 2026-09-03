// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Flutter web keeps a hidden HTML input focused after route changes, which
/// leaves the mobile keyboard stuck on screen.
void blurDomTextInput() {
  html.document.activeElement?.blur();
  for (final node in html.document.querySelectorAll('input, textarea')) {
    if (node is html.Element) {
      node.blur();
    }
  }
}
