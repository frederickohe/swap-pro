import 'package:flutter/services.dart';
import 'package:swappro/barrel.dart';
import 'package:swappro/common_design/widgets/success_reveal_route.dart';

class SignupOtp extends StatefulWidget {
  final String phone;

  const SignupOtp({super.key, required this.phone});

  @override
  State<SignupOtp> createState() => _SignupOtpState();
}

class _SignupOtpState extends State<SignupOtp> {
  final TextEditingController codeController = TextEditingController();

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScreenLayout.metrics(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is SignupOtpVerified) {
              context.read<SuccessBloc>().add(
                    ShowSuccessEvent(
                      message: 'Account verified successfully!',
                      nextScreen: 'login',
                    ),
                  );
              Navigator.of(context).pushReplacement(
                SuccessRevealRoute(
                  child: const Success(delayEntrance: true),
                ),
              );
            }
            if (state is SignupOtpResent) {
              context.showAppSnackBar(
                state.message,
                variant: AppSnackBarVariant.success,
              );
            }
            if (state is AuthError &&
                (state.source == 'signup_otp' ||
                    state.source == 'signup_otp_resend')) {
              context.showAppSnackBar(state.message);
            }
          },
        ),
      ],
      child: Scaffold(
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
                      boldPart: 'Verify Phone',
                      fontSize: 32 * m.wScale,
                    ),
                    SizedBox(height: 20 * m.hScale),
                    Text(
                      'Enter the OTP sent to ${widget.phone}',
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
                      hint: '5-digit code',
                      icon: Icons.sms_outlined,
                      height: m.fieldHeight,
                      radius: m.fieldRadius,
                      enabled: !isLoading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                    ),
                    SizedBox(height: m.formGap),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              context.read<AuthBloc>().add(
                                    ResendSignupOtpEvent(phone: widget.phone),
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
                          final code = codeController.text.trim();
                          if (code.length != 5) {
                            context.showAppSnackBar(
                              'Enter the 5-digit code from your SMS',
                            );
                            return;
                          }
                          context.read<AuthBloc>().add(
                                VerifySignupOtpEvent(
                                  phone: widget.phone,
                                  otp: code,
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
