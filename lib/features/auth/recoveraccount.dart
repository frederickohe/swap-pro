import 'package:swappro/barrel.dart';

class RecoverAccount extends StatefulWidget {
  const RecoverAccount({super.key});

  @override
  State<RecoverAccount> createState() => _RecoverAccountState();
}

class _RecoverAccountState extends State<RecoverAccount> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScreenLayout.metrics(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailExists) {
          context.showAppSnackBar('Email verified. Sending reset code...');
          context.read<AuthBloc>().add(SendResetCodeEvent(email: state.email));
        } else if (state is ResetCodeSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCode(email: state.email),
            ),
          );
        } else if (state is AuthError && state.source == 'check_email') {
          context.showAppSnackBar(state.message);
        }
      },
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
                      boldPart: 'Reset PIN',
                      fontSize: 32 * m.wScale,
                    ),
                    SizedBox(height: 20 * m.hScale),
                    Text(
                      'Enter your email to receive a reset code',
                      style: AppTypography.style(
                        fontSize: 14 * m.wScale,
                        fontWeight: FontWeight.w400,
                        color: AuthScreenLayout.dark,
                        height: 20 / 14,
                      ),
                    ),
                    SizedBox(height: 40 * m.hScale),
                    AuthFormField(
                      controller: emailController,
                      hint: 'Email',
                      iconSvg: AuthIcons.emailFill,
                      height: m.fieldHeight,
                      radius: m.fieldRadius,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 48 * m.hScale),
                    Center(
                      child: AuthPrimaryButton(
                        label: 'Continue',
                        isLoading: isLoading,
                        width: m.buttonWidth,
                        height: m.buttonHeight,
                        radius: m.buttonRadius,
                        fontSize: 16 * m.wScale,
                        onPressed: () {
                          if (emailController.text.trim().isEmpty) {
                            context.showAppSnackBar('Please enter your email');
                            return;
                          }
                          context.read<AuthBloc>().add(
                                CheckEmailExistsEvent(
                                  email: emailController.text.trim(),
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
