import 'package:flutter/services.dart';
import 'package:swappro/barrel.dart';

class ResetPassword extends StatefulWidget {
  final String email;
  final String code;

  const ResetPassword({super.key, required this.email, required this.code});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final List<TextEditingController> _newPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _newPinFocusNodes = List.generate(4, (_) => FocusNode());

  final List<TextEditingController> _confirmPinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _confirmPinFocusNodes =
      List.generate(4, (_) => FocusNode());

  String get _newPin => _newPinControllers.map((c) => c.text).join();
  String get _confirmPin => _confirmPinControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    for (final node in _newPinFocusNodes) {
      node.addListener(() => setState(() {}));
    }
    for (final node in _confirmPinFocusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _newPinControllers) {
      c.dispose();
    }
    for (final n in _newPinFocusNodes) {
      n.dispose();
    }
    for (final c in _confirmPinControllers) {
      c.dispose();
    }
    for (final n in _confirmPinFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Widget _buildPinRow({
    required List<TextEditingController> controllers,
    required List<FocusNode> focusNodes,
    required bool enabled,
    required double gap,
  }) {
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : gap / 2,
              right: index == 3 ? 0 : gap / 2,
            ),
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AuthScreenLayout.dark,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < 3) {
                    focusNodes[index + 1].requestFocus();
                  } else {
                    focusNodes[index].unfocus();
                  }
                } else if (value.isEmpty && index > 0) {
                  controllers[index - 1].clear();
                  focusNodes[index - 1].requestFocus();
                }
              },
              onTap: () {
                controllers[index].selection = TextSelection.collapsed(
                  offset: controllers[index].text.length,
                );
              },
              onSubmitted: (_) {
                if (index < 3) {
                  focusNodes[index + 1].requestFocus();
                }
              },
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScreenLayout.metrics(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError && state.source == 'reset_password') {
            context.showAppSnackBar(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                m.horizontalPad,
                24 * m.hScale,
                m.horizontalPad,
                32 * m.hScale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AuthBackButton(
                      onTap: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(height: 38 * m.hScale),
                  AuthSplitTitle(
                    boldPart: 'New Password',
                    fontSize: 32 * m.wScale,
                  ),
                  SizedBox(height: 20 * m.hScale),
                  Text(
                    'Create a new 4-digit PIN for your account',
                    style: AppTypography.style(
                      fontSize: 14 * m.wScale,
                      fontWeight: FontWeight.w400,
                      color: AuthScreenLayout.dark,
                      height: 20 / 14,
                    ),
                  ),
                  SizedBox(height: 40 * m.hScale),
                  Text(
                    'New PIN',
                    style: AppTypography.style(
                      fontSize: 14 * m.wScale,
                      fontWeight: FontWeight.w400,
                      color: AuthScreenLayout.dark,
                    ),
                  ),
                  SizedBox(height: m.formGap),
                  AuthFormFieldShell(
                    height: m.fieldHeight,
                    radius: m.fieldRadius,
                    icon: Icons.lock_outline,
                    focused: _newPinFocusNodes.any((node) => node.hasFocus),
                    child: _buildPinRow(
                      controllers: _newPinControllers,
                      focusNodes: _newPinFocusNodes,
                      enabled: !isLoading,
                      gap: m.formGap,
                    ),
                  ),
                  SizedBox(height: m.formGap * 2),
                  Text(
                    'Confirm PIN',
                    style: AppTypography.style(
                      fontSize: 14 * m.wScale,
                      fontWeight: FontWeight.w400,
                      color: AuthScreenLayout.dark,
                    ),
                  ),
                  SizedBox(height: m.formGap),
                  AuthFormFieldShell(
                    height: m.fieldHeight,
                    radius: m.fieldRadius,
                    icon: Icons.lock_outline,
                    focused:
                        _confirmPinFocusNodes.any((node) => node.hasFocus),
                    child: _buildPinRow(
                      controllers: _confirmPinControllers,
                      focusNodes: _confirmPinFocusNodes,
                      enabled: !isLoading,
                      gap: m.formGap,
                    ),
                  ),
                  SizedBox(height: 48 * m.hScale),
                  Center(
                    child: AuthPrimaryButton(
                      label: 'Reset Password',
                      isLoading: isLoading,
                      width: m.buttonWidth,
                      height: m.buttonHeight,
                      radius: m.buttonRadius,
                      fontSize: 16 * m.wScale,
                      onPressed: () {
                        if (_newPin.length != 4 || _confirmPin.length != 4) {
                          context.showAppSnackBar(
                            'Please enter and confirm your 4-digit PIN',
                          );
                          return;
                        }
                        if (_newPin != _confirmPin) {
                          context.showAppSnackBar('PINs do not match');
                          return;
                        }
                        context.read<AuthBloc>().add(
                              ResetPasswordEvent(
                                email: widget.email,
                                code: widget.code,
                                newPassword: _newPin,
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
