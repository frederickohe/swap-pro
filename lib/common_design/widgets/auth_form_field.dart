import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:swappro/common_design/app_typography.dart';

/// Auth screen text field — light fill, gold icon, thin black border when focused.
class AuthFormField extends StatefulWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.iconSvg,
    required this.height,
    required this.radius,
    required this.enabled,
    this.focusNode,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.onChanged,
    this.onSubmitted,
  }) : assert(icon != null || iconSvg != null);

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? iconSvg;
  final double height;
  final double radius;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const Color dark = Color(0xFF111111);
  static const Color gold = Color(0xFFC3B649);
  static const Color fieldFill = Color(0xFFF5F5F8);
  static const double inputFontSize = 14;
  static const double hintFontSize = 12;

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AuthFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChange);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
      _focused = _focusNode.hasFocus;
    }
  }

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      decoration: BoxDecoration(
        color: AuthFormField.fieldFill,
        borderRadius: BorderRadius.circular(widget.radius),
        border: _focused
            ? Border.all(color: AuthFormField.dark, width: 1)
            : null,
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _AuthFieldIcon(icon: widget.icon, iconSvg: widget.iconSvg),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              textAlign: widget.textAlign,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              style: AppTypography.style(
                fontSize: AuthFormField.inputFontSize,
                fontWeight: FontWeight.w400,
                color: AuthFormField.dark,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.style(
                  fontSize: AuthFormField.hintFontSize,
                  fontWeight: FontWeight.w400,
                  color: AuthFormField.dark,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps custom inline inputs (e.g. Ghana Card segments) with the same focus border.
class AuthFormFieldShell extends StatelessWidget {
  const AuthFormFieldShell({
    super.key,
    required this.height,
    required this.radius,
    required this.icon,
    required this.focused,
    required this.child,
  });

  final double height;
  final double radius;
  final IconData icon;
  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: height,
      decoration: BoxDecoration(
        color: AuthFormField.fieldFill,
        borderRadius: BorderRadius.circular(radius),
        border: focused
            ? Border.all(color: AuthFormField.dark, width: 1)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AuthFormField.gold),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AuthFieldIcon extends StatelessWidget {
  const _AuthFieldIcon({this.icon, this.iconSvg});

  final IconData? icon;
  final String? iconSvg;

  @override
  Widget build(BuildContext context) {
    if (iconSvg != null) {
      return Iconify(
        iconSvg!,
        size: 20,
        color: AuthFormField.gold,
      );
    }
    return Icon(icon, size: 20, color: AuthFormField.gold);
  }
}
