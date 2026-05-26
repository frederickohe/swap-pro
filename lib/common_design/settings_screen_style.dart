import 'package:flutter/material.dart';
import 'package:swappro/common_design/app_typography.dart';

/// Light account/settings screens — grey circle back button, gold chevron.
class SettingsScreenStyle {
  SettingsScreenStyle._();

  static const Color gold = Color(0xFFC3B649);
  static const Color backButtonBg = Color(0xFFF5F4F8);
  static const Color ink = Color(0xFF111111);
  static const Color menuText = Color(0xFF1C1C28);
  static const Color divider = Color(0xFFF6F6F6);
  static const Color subtleText = Color(0xFF787676);
  static const Color cardBorder = Color(0xFFECECF3);

  static TextStyle headerTitleStyle() => AppTypography.style(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static TextStyle menuTitleStyle() => AppTypography.style(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: menuText,
  );

  static TextStyle menuSubtitleStyle() => AppTypography.style(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: subtleText,
  );
}

class SettingsScreenBackButton extends StatelessWidget {
  const SettingsScreenBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: SettingsScreenStyle.backButtonBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: SettingsScreenStyle.gold,
        ),
      ),
    );
  }
}

class SettingsScreenHeader extends StatelessWidget {
  const SettingsScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBackPressed,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBackPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SettingsScreenBackButton(onPressed: onBackPressed),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: SettingsScreenStyle.headerTitleStyle(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox(width: 50, height: 50),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreenScaffold extends StatelessWidget {
  const SettingsScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.onBackPressed,
    this.floatingAction,
  });

  final String title;
  final Widget body;
  final Widget? trailing;
  final VoidCallback? onBackPressed;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsScreenHeader(
              title: title,
              trailing: trailing,
              onBackPressed: onBackPressed,
            ),
            Expanded(child: body),
            if (floatingAction != null) floatingAction!,
          ],
        ),
      ),
    );
  }
}

class SettingsMenuCard extends StatelessWidget {
  const SettingsMenuCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SettingsScreenStyle.cardBorder),
      ),
      child: child,
    );
  }
}

class SettingsMenuTile extends StatelessWidget {
  const SettingsMenuTile({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.trailing,
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: SettingsScreenStyle.divider,
            indent: 16,
            endIndent: 16,
          ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: SettingsScreenStyle.gold),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SettingsScreenStyle.menuTitleStyle()),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: SettingsScreenStyle.menuSubtitleStyle(),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: SettingsScreenStyle.menuText,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsToggleSwitch extends StatelessWidget {
  const SettingsToggleSwitch({
    super.key,
    required this.value,
    required this.enabled,
  });

  final bool value;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final trackColor = value
        ? SettingsScreenStyle.gold
        : SettingsScreenStyle.backButtonBg;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.55,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: trackColor,
          border: value
              ? null
              : Border.all(color: SettingsScreenStyle.cardBorder),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: SettingsScreenStyle.gold,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
