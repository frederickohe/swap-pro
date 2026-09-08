import 'package:flutter/material.dart';
import 'package:swappro/common_design/settings_screen_style.dart';
import 'package:swappro/common_design/widgets/user_avatar.dart';

/// Standard light-screen header: circular back (left), title (center), avatar (right).
/// Matches Figma "Your listings" — 50×50 back button and avatar.
class AppScreenTopBar extends StatelessWidget {
  const AppScreenTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showAvatar = true,
    this.padding = const EdgeInsets.fromLTRB(15, 8, 15, 0),
    this.scale = 1.0,
    this.centerTitle = true,
    this.titleStyle,
    this.lightScreen = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showAvatar;
  final EdgeInsetsGeometry padding;
  final double scale;
  final bool centerTitle;
  final TextStyle? titleStyle;

  /// White/light page (default) vs gold/green hero screens (white title, bordered avatar).
  final bool lightScreen;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final btnSize = SettingsScreenStyle.chromeButtonSize * s;
    final resolvedTrailing = trailing ??
        (showAvatar
            ? HeaderUserButton(size: btnSize)
            : SizedBox(width: btnSize, height: btnSize));

    final resolvedTitleStyle = titleStyle ??
        SettingsScreenStyle.headerTitleStyle().copyWith(fontSize: 20 * s);

    return Padding(
      padding: padding,
      child: SizedBox(
        height: SettingsScreenStyle.topBarHeight * s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SettingsScreenBackButton(
                onPressed: onBack,
                size: btnSize,
              ),
            ),
            if (centerTitle)
              Text(
                title,
                textAlign: TextAlign.center,
                style: resolvedTitleStyle,
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: btnSize + 12 * s, right: btnSize),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: resolvedTitleStyle,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: resolvedTrailing,
            ),
          ],
        ),
      ),
    );
  }
}
