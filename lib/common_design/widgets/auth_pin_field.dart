import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swappro/common_design/app_typography.dart';
import 'package:swappro/common_design/widgets/auth_form_field.dart';

/// Four-box PIN input; stretches to parent width like [AuthFormField].
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
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final double wScale;
  final double hScale;
  final bool obscureText;
  final VoidCallback? onChanged;

  static const double figmaGap = 10;
  static const double figmaPinH = 70;
  static const double figmaRadius = 10;
  static const double figmaBorderW = 0.8;

  static double gap(double wScale) => figmaGap * wScale;
  static double height(double hScale) => figmaPinH * hScale;
  static double radius(double wScale) => figmaRadius * wScale;

  static String join(List<TextEditingController> controllers) =>
      controllers.map((c) => c.text).join();

  @override
  State<AuthPinField> createState() => _AuthPinFieldState();
}

class _PinBackspaceFormatter extends TextInputFormatter {
  _PinBackspaceFormatter({
    required this.index,
    required this.controllers,
    required this.focusNodes,
  });

  final int index;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty &&
        oldValue.text.isEmpty &&
        index > 0 &&
        controllers[index].text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controllers[index].text.isNotEmpty) return;
        focusNodes[index - 1].requestFocus();
        controllers[index - 1].clear();
      });
    }
    return newValue;
  }
}

class _AuthPinFieldState extends State<AuthPinField> {
  @override
  void initState() {
    super.initState();
    for (final node in widget.focusNodes) {
      node.addListener(_rebuild);
    }
    for (final c in widget.controllers) {
      c.addListener(_rebuild);
    }
  }

  @override
  void didUpdateWidget(AuthPinField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllers != widget.controllers ||
        oldWidget.focusNodes != widget.focusNodes) {
      for (final node in oldWidget.focusNodes) {
        node.removeListener(_rebuild);
      }
      for (final c in oldWidget.controllers) {
        c.removeListener(_rebuild);
      }
      for (final node in widget.focusNodes) {
        node.addListener(_rebuild);
      }
      for (final c in widget.controllers) {
        c.addListener(_rebuild);
      }
    }
  }

  @override
  void dispose() {
    for (final node in widget.focusNodes) {
      node.removeListener(_rebuild);
    }
    for (final c in widget.controllers) {
      c.removeListener(_rebuild);
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _focusPreviousAndClear(int index) {
    if (index <= 0) return;
    widget.focusNodes[index - 1].requestFocus();
    widget.controllers[index - 1].clear();
    widget.onChanged?.call();
  }

  void _focusPinCell(int index) {
    if (!widget.enabled) return;
    final controller = widget.controllers[index];
    final focusNode = widget.focusNodes[index];
    focusNode.requestFocus();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  KeyEventResult _handleBackspaceKey(int index, TextEditingController controller) {
    if (controller.text.isEmpty && index > 0) {
      _focusPreviousAndClear(index);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final gap = AuthPinField.gap(widget.wScale);
    final height = AuthPinField.height(widget.hScale);
    final radius = AuthPinField.radius(widget.wScale);

    final children = <Widget>[];
    for (var index = 0; index < 4; index++) {
      if (index > 0) children.add(SizedBox(width: gap));
      final controller = widget.controllers[index];
      final focusNode = widget.focusNodes[index];
      final showBorder =
          focusNode.hasFocus || controller.text.isNotEmpty;

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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _focusPinCell(index),
                child: SizedBox.expand(
                  child: Center(
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.backspace) {
                          return _handleBackspaceKey(index, controller);
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: widget.enabled,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.number,
                        obscureText: widget.obscureText,
                        style: AppTypography.style(
                          fontSize: AuthFormField.inputFontSize,
                          fontWeight: FontWeight.w500,
                          color: AuthFormField.dark,
                          height: 1,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                          _PinBackspaceFormatter(
                            index: index,
                            controllers: widget.controllers,
                            focusNodes: widget.focusNodes,
                          ),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          isCollapsed: true,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 3) {
                              widget.focusNodes[index + 1].requestFocus();
                            } else {
                              focusNode.unfocus();
                            }
                          }
                          widget.onChanged?.call();
                        },
                        onTap: () => _focusPinCell(index),
                        onSubmitted: (_) {
                          if (index < 3) {
                            widget.focusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    ),
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
      child: Row(children: children),
    );
  }
}
