import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swappro/common_design/app_typography.dart';
import 'package:swappro/common_design/widgets/auth_form_field.dart';

/// Four-box PIN input; stretches to parent width like [AuthFormField].
///
/// Uses one backing [TextField] so iOS backspace can delete every digit.
/// Separate per-box fields only receive a single empty-field delete event.
class AuthPinField extends StatefulWidget {
  const AuthPinField({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.enabled,
    required this.wScale,
    required this.hScale,
    this.obscureText = true,
    this.onChanged,
    this.onTapOutside,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final double wScale;
  final double hScale;
  final bool obscureText;
  final VoidCallback? onChanged;
  final TapRegionCallback? onTapOutside;

  static const double figmaGap = 10;
  static const double figmaPinH = 70;
  static const double figmaRadius = 10;
  static const double figmaBorderW = 0.8;
  static const int length = 4;

  static double gap(double wScale) => figmaGap * wScale;
  static double height(double hScale) => figmaPinH * hScale;
  static double radius(double wScale) => figmaRadius * wScale;

  static String join(List<TextEditingController> controllers) =>
      controllers.map((c) => c.text).join();

  static String digitsOf(String value) {
    final digits = StringBuffer();
    for (final unit in value.codeUnits) {
      if (unit >= 48 && unit <= 57) {
        digits.writeCharCode(unit);
        if (digits.length == length) break;
      }
    }
    return digits.toString();
  }

  @override
  State<AuthPinField> createState() => _AuthPinFieldState();
}

class _AuthPinFieldState extends State<AuthPinField> {
  late final TextEditingController _inputController;
  late final FocusNode _inputFocusNode;
  bool _syncingFromInput = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(
      text: AuthPinField.digitsOf(AuthPinField.join(widget.controllers)),
    );
    _inputFocusNode = FocusNode();
    _inputController.addListener(_onInputChanged);
    _inputFocusNode.addListener(_rebuild);
    for (final node in widget.focusNodes) {
      node.addListener(_onExternalFocus);
    }
  }

  @override
  void didUpdateWidget(AuthPinField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNodes != widget.focusNodes) {
      for (final node in oldWidget.focusNodes) {
        node.removeListener(_onExternalFocus);
      }
      for (final node in widget.focusNodes) {
        node.addListener(_onExternalFocus);
      }
    }
  }

  @override
  void dispose() {
    for (final node in widget.focusNodes) {
      node.removeListener(_onExternalFocus);
    }
    _inputController.removeListener(_onInputChanged);
    _inputFocusNode.removeListener(_rebuild);
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onExternalFocus() {
    if (!widget.enabled) return;
    if (widget.focusNodes.any((node) => node.hasFocus) &&
        !_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
    }
  }

  void _syncBoxControllers(String pin) {
    for (var i = 0; i < AuthPinField.length; i++) {
      final digit = i < pin.length ? pin[i] : '';
      if (widget.controllers[i].text == digit) continue;
      widget.controllers[i].value = TextEditingValue(
        text: digit,
        selection: TextSelection.collapsed(offset: digit.length),
      );
    }
  }

  void _onInputChanged() {
    if (_syncingFromInput) return;

    final pin = AuthPinField.digitsOf(_inputController.text);
    if (pin != _inputController.text) {
      _syncingFromInput = true;
      _inputController.value = TextEditingValue(
        text: pin,
        selection: TextSelection.collapsed(offset: pin.length),
      );
      _syncingFromInput = false;
    }

    _syncBoxControllers(pin);
    widget.onChanged?.call();

    if (pin.length == AuthPinField.length && _inputFocusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_inputController.text.length == AuthPinField.length) {
          _inputFocusNode.unfocus();
        }
      });
    }

    if (mounted) setState(() {});
  }

  void _focusInput() {
    if (!widget.enabled) return;
    _inputFocusNode.requestFocus();
    _inputController.selection = TextSelection.collapsed(
      offset: _inputController.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = AuthPinField.gap(widget.wScale);
    final height = AuthPinField.height(widget.hScale);
    final radius = AuthPinField.radius(widget.wScale);
    final pin = _inputController.text;
    final activeIndex = pin.length >= AuthPinField.length
        ? AuthPinField.length - 1
        : pin.length;

    final children = <Widget>[];
    for (var index = 0; index < AuthPinField.length; index++) {
      if (index > 0) children.add(SizedBox(width: gap));
      final digit = index < pin.length ? pin[index] : '';
      final showBorder =
          digit.isNotEmpty ||
          (_inputFocusNode.hasFocus && index == activeIndex);

      children.add(
        Expanded(
          child: SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AuthFormField.fieldFill,
                borderRadius: BorderRadius.circular(radius),
                border: showBorder
                    ? Border.all(
                        color: AuthFormField.dark,
                        width: AuthPinField.figmaBorderW,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  digit.isEmpty ? '' : (widget.obscureText ? '•' : digit),
                  style: AppTypography.style(
                    fontSize: AuthFormField.inputFontSize,
                    fontWeight: FontWeight.w500,
                    color: AuthFormField.dark,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        children: [
          IgnorePointer(child: Row(children: children)),
          Positioned.fill(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: false,
              showCursor: false,
              enableInteractiveSelection: false,
              style: const TextStyle(
                color: Colors.transparent,
                fontSize: 1,
                height: 1,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(AuthPinField.length),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
                isCollapsed: true,
              ),
              onTap: _focusInput,
              onTapOutside: widget.onTapOutside,
            ),
          ),
        ],
      ),
    );
  }
}
