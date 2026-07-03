import 'package:swappro/barrel.dart';
import 'package:swappro/utils/phone_utils.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  static const Color _dark = Color(0xFF111111);

  static const double _figmaW = 430;
  static const double _figmaH = 932;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController companyController = TextEditingController();

  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String get _pin => AuthPinField.join(_pinControllers);

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    companyController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final n in _pinFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _submitSignup() {
    if (_pin.length != 4) {
      context.showAppSnackBar('Please enter a 4-digit PIN');
      return;
    }
    final company = companyController.text.trim();
    context.read<AuthBloc>().add(
          SignupEvent(
            username: usernameController.text.trim(),
            phone: normalizePhone(phoneController.text.trim()),
            email: emailController.text.trim(),
            password: _pin,
            company: company.isEmpty ? null : company,
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
    final fieldHeight = 70 * hScale;
    final fieldRadius = 10 * wScale;
    final formGap = 12 * hScale;
    final buttonWidth = 277 * wScale;
    final buttonHeight = 62 * hScale;
    final buttonRadius = 10 * wScale;

    return AppScaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is Registered) {
                Navigator.of(context).pushReplacement(
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 1000),
                    reverseDuration: const Duration(milliseconds: 600),
                    child: SignupOtp(
                      phone: normalizePhone(phoneController.text.trim()),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  24 * hScale,
                  horizontalPad,
                  32 * hScale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
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
                    SizedBox(height: 38 * hScale),
                    Text(
                      'Sign Up',
                      style: AppTypography.style(
                        fontSize: 32 * wScale,
                        fontWeight: FontWeight.w600,
                        color: _dark,
                        height: 40 / 32,
                      ),
                    ),
                    SizedBox(height: 20 * hScale),
                    Text(
                      'Create your account to get started',
                      style: AppTypography.style(
                        fontSize: 14 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _dark,
                        height: 20 / 14,
                      ),
                    ),
                    SizedBox(height: 40 * hScale),
                    AuthFormField(
                      controller: usernameController,
                      hint: 'Username',
                      iconSvg: AuthIcons.rename16,
                      height: fieldHeight,
                      radius: fieldRadius,
                      enabled: !isLoading,
                    ),
                    SizedBox(height: formGap),
                    AuthFormField(
                      controller: phoneController,
                      hint: 'Phone',
                      icon: Icons.phone_outlined,
                      height: fieldHeight,
                      radius: fieldRadius,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: formGap),
                    AuthFormField(
                      controller: companyController,
                      hint: 'Company (optional)',
                      icon: Icons.business_outlined,
                      height: fieldHeight,
                      radius: fieldRadius,
                      enabled: !isLoading,
                    ),
                    SizedBox(height: formGap),
                    AuthFormField(
                      controller: emailController,
                      hint: 'Email',
                      iconSvg: AuthIcons.emailFill,
                      height: fieldHeight,
                      radius: fieldRadius,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: formGap),
                    Text(
                      'Pin',
                      style: AppTypography.style(
                        fontSize: 14 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _dark,
                      ),
                    ),
                    SizedBox(height: formGap),
                    AuthPinField(
                      controllers: _pinControllers,
                      focusNodes: _pinFocusNodes,
                      enabled: !isLoading,
                      wScale: wScale,
                      hScale: hScale,
                    ),
                    SizedBox(height: 48 * hScale),
                    Center(
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitSignup,
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
                                  'Sign Up',
                                  style: AppTypography.style(
                                    fontSize: 16 * wScale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32 * hScale),
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                PageTransition(
                                  type: PageTransitionType.leftToRightWithFade,
                                  child: const Signin(),
                                ),
                              );
                            },
                      child: Text(
                        'Already have an account? Sign In',
                        textAlign: TextAlign.center,
                        style: AppTypography.style(
                          fontSize: 14 * wScale,
                          fontWeight: FontWeight.w400,
                          color: _dark,
                          height: 22 / 14,
                        ),
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
