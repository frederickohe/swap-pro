import 'package:swappro/barrel.dart';

class VerifyCode extends StatefulWidget {
  final String email;
  final String phone;

  const VerifyCode({
    super.key,
    this.email = '',
    this.phone = '',
  });

  @override
  State<VerifyCode> createState() => _VerifyCodeState();
}

class _VerifyCodeState extends State<VerifyCode> {
  final TextEditingController codeController = TextEditingController();

  String get _destinationLabel {
    if (widget.phone.isNotEmpty) return 'phone';
    return 'email';
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScreenLayout.metrics(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ResetCodeVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPassword(
                email: state.email,
                code: codeController.text.trim(),
              ),
            ),
          );
        } else if (state is AuthError && state.source == 'verify_code') {
          context.showAppSnackBar(state.message);
        }
      },
      child: AppScaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: BlocBuilder<AuthBloc, AuthState>(
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
                      boldPart: 'Verify Code',
                      fontSize: 32 * m.wScale,
                    ),
                    SizedBox(height: 20 * m.hScale),
                    Text(
                      'Enter the verification code sent to your $_destinationLabel',
                      style: AppTypography.style(
                        fontSize: 14 * m.wScale,
                        fontWeight: FontWeight.w400,
                        color: AuthScreenLayout.dark,
                        height: 20 / 14,
                      ),
                    ),
                    SizedBox(height: 40 * m.hScale),
                    AuthFormField(
                      controller: codeController,
                      hint: 'Verification code',
                      icon: Icons.pin_outlined,
                      height: m.fieldHeight,
                      radius: m.fieldRadius,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: m.formGap),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              context.read<AuthBloc>().add(
                                    SendResetCodeEvent(
                                      email: widget.email,
                                      phone: widget.phone,
                                    ),
                                  );
                            },
                      child: Text(
                        'Did not receive code? Resend',
                        style: AppTypography.style(
                          fontSize: 14 * m.wScale,
                          fontWeight: FontWeight.w400,
                          color: AuthScreenLayout.dark,
                        ),
                      ),
                    ),
                    SizedBox(height: 48 * m.hScale),
                    Center(
                      child: AuthPrimaryButton(
                        label: 'Verify',
                        isLoading: isLoading,
                        width: m.buttonWidth,
                        height: m.buttonHeight,
                        radius: m.buttonRadius,
                        fontSize: 16 * m.wScale,
                        onPressed: () {
                          if (codeController.text.trim().isEmpty) {
                            context.showAppSnackBar(
                              'Please enter the verification code',
                            );
                            return;
                          }
                          context.read<AuthBloc>().add(
                                VerifyResetCodeEvent(
                                  email: widget.email,
                                  phone: widget.phone,
                                  code: codeController.text.trim(),
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
      ),
    );
  }
}
