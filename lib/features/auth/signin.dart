import 'package:swappro/barrel.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  static const Color _dark = Color(0xFF111111);

  static const double _figmaW = 430;
  static const double _figmaH = 932;

  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String get _pin => AuthPinField.join(_pinControllers);

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final n in _pinFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onPinChanged() {
    if (_pin.length == 4) {
      _submitLogin();
    }
  }

  void _submitLogin() {
    if (context.read<AuthBloc>().state is AuthLoading) {
      return;
    }
    if (_emailController.text.trim().isEmpty || _pin.length != 4) {
      return;
    }

    context.read<AuthBloc>().add(
          LoginEvent(
            email: _emailController.text.trim(),
            password: _pin,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final wScale = w / _figmaW;
    final hScale = h / _figmaH;

    final horizontalPad = 33 * wScale;
    final formWidth = 364 * wScale;
    final fieldHeight = 70 * hScale;
    final fieldRadius = 10 * wScale;
    final formGap = 12 * hScale;
    final titleTop = 162 * hScale;
    final formTop = 339 * hScale;
    final buttonTop = 618 * hScale;
    final registerTop = 839 * hScale;
    final buttonWidth = 277 * wScale;
    final buttonHeight = 62 * hScale;
    final buttonRadius = 10 * wScale;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const Home()),
              (route) => false,
            );
          } else if (state is AuthError && state.source == 'login') {
            context.showAppSnackBar(state.message);
          } else if (state is ServerUnreachable) {
            context.showAppSnackBar(
              'Cannot reach the server. Check your connection and try again.',
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              child: SizedBox(
                height: h,
                width: w,
                child: Stack(
                  children: [
                    Positioned(
                      top: 24 * hScale,
                      left: horizontalPad,
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                            color: _dark,
                            shape: BoxShape.circle,
                            border: Border.all(color: _dark, width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 17.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: titleTop,
                      left: horizontalPad,
                      right: horizontalPad,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthSplitTitle(
                            boldPart: 'Sign In',
                            fontSize: 32 * wScale,
                            color: _dark,
                          ),
                          SizedBox(height: 20 * hScale),
                          Text(
                            'Enter your email and PIN',
                            style: AppTypography.style(
                              fontSize: 14 * wScale,
                              fontWeight: FontWeight.w400,
                              color: _dark,
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: formTop,
                      left: horizontalPad,
                      child: SizedBox(
                        width: formWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthFormField(
                              controller: _emailController,
                              hint: 'Email',
                              iconSvg: AuthIcons.emailFill,
                              height: fieldHeight,
                              radius: fieldRadius,
                              enabled: !isLoading,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: formGap),
                            AuthPinField(
                              controllers: _pinControllers,
                              focusNodes: _pinFocusNodes,
                              enabled: !isLoading,
                              wScale: wScale,
                              hScale: hScale,
                              onChanged: _onPinChanged,
                            ),
                            SizedBox(height: formGap),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).push(
                                          PageTransition(
                                            type: PageTransitionType
                                                .rightToLeftWithFade,
                                            child: const RecoverAccount(),
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Forgot PIN?',
                                  style: AppTypography.style(
                                    fontSize: 12 * wScale,
                                    fontWeight: FontWeight.w400,
                                    color: _dark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: buttonTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: buttonWidth,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submitLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _dark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _dark.withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(buttonRadius),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    style: AppTypography.style(
                                      fontSize: 16 * wScale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: registerTop,
                      left: horizontalPad,
                      right: horizontalPad,
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  PageTransition(
                                    type: PageTransitionType
                                        .leftToRightWithFade,
                                    child: const Signup(),
                                  ),
                                );
                              },
                        child: Text(
                          "Don't have an account? Register",
                          textAlign: TextAlign.center,
                          style: AppTypography.style(
                            fontSize: 14 * wScale,
                            fontWeight: FontWeight.w400,
                            color: _dark,
                            height: 22 / 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
