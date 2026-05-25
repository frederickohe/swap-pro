import 'package:flutter/services.dart';
import 'package:swappro/barrel.dart';

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
  final TextEditingController ghanaCardTenController = TextEditingController();
  final TextEditingController ghanaCardCheckController =
      TextEditingController();
  final FocusNode _ghanaCardTenFocusNode = FocusNode();
  final FocusNode _ghanaCardCheckFocusNode = FocusNode();

  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  bool _ghanaCardFocused = false;

  String get _pin => _pinControllers.map((c) => c.text).join();

  String get _ghanaCardValue {
    final ten = ghanaCardTenController.text.trim();
    final one = ghanaCardCheckController.text.trim();
    if (ten.isEmpty && one.isEmpty) return '';
    return 'GHA-$ten-$one';
  }

  static TextStyle _ghanaSegmentStyle() {
    return AppTypography.style(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _dark,
    );
  }

  double _ghanaTenFieldWidth(BuildContext context, double wScale) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = _ghanaSegmentStyle();
    final digits = ghanaCardTenController.text;
    final probe = digits.isEmpty ? '000' : digits;
    final painter = TextPainter(
      text: TextSpan(text: probe, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final maxPainter = TextPainter(
      text: TextSpan(text: '8888888888', style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return (painter.width + 28 * wScale).clamp(52.0 * wScale, maxPainter.width + 36 * wScale);
  }

  void _onGhanaTenChanged() => setState(() {});

  void _updateGhanaCardFocus() {
    final focused =
        _ghanaCardTenFocusNode.hasFocus || _ghanaCardCheckFocusNode.hasFocus;
    if (focused != _ghanaCardFocused) {
      setState(() => _ghanaCardFocused = focused);
    }
  }

  @override
  void initState() {
    super.initState();
    ghanaCardTenController.addListener(_onGhanaTenChanged);
    _ghanaCardTenFocusNode.addListener(_updateGhanaCardFocus);
    _ghanaCardCheckFocusNode.addListener(_updateGhanaCardFocus);
    for (final node in _pinFocusNodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    ghanaCardTenController.removeListener(_onGhanaTenChanged);
    _ghanaCardTenFocusNode.removeListener(_updateGhanaCardFocus);
    _ghanaCardCheckFocusNode.removeListener(_updateGhanaCardFocus);
    emailController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    companyController.dispose();
    ghanaCardTenController.dispose();
    ghanaCardCheckController.dispose();
    _ghanaCardTenFocusNode.dispose();
    _ghanaCardCheckFocusNode.dispose();
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
    context.read<AuthBloc>().add(
          SignupEvent(
            username: usernameController.text.trim(),
            phone: phoneController.text.trim(),
            email: emailController.text.trim(),
            password: _pin,
            company: companyController.text.trim(),
            ghanaCard: _ghanaCardValue,
          ),
        );
  }

  Widget _buildGhanaCardField({
    required double fieldHeight,
    required double fieldRadius,
    required bool enabled,
    required double wScale,
  }) {
    return AuthFormFieldShell(
      height: fieldHeight,
      radius: fieldRadius,
      icon: Icons.badge_outlined,
      focused: _ghanaCardFocused,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44 * wScale,
            child: Text(
              'GHA',
              textAlign: TextAlign.center,
              style: _ghanaSegmentStyle(),
            ),
          ),
          Text('-', style: _ghanaSegmentStyle().copyWith(color: Colors.black54)),
          SizedBox(
            width: _ghanaTenFieldWidth(context, wScale),
            child: TextField(
              controller: ghanaCardTenController,
              focusNode: _ghanaCardTenFocusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              style: _ghanaSegmentStyle(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                hintText: '0000000000',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                if (value.length == 10) {
                  _ghanaCardCheckFocusNode.requestFocus();
                }
              },
            ),
          ),
          Text('-', style: _ghanaSegmentStyle().copyWith(color: Colors.black54)),
          SizedBox(
            width: 28 * wScale,
            child: TextField(
              controller: ghanaCardCheckController,
              focusNode: _ghanaCardCheckFocusNode,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: _ghanaSegmentStyle(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: const InputDecoration(
                hintText: '0',
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

  Widget _buildPinRow({
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
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
                enabled: enabled,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: AppTypography.style(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _dark,
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
                      _pinFocusNodes[index + 1].requestFocus();
                    } else {
                      _pinFocusNodes[index].unfocus();
                    }
                  } else if (value.isEmpty && index > 0) {
                    _pinControllers[index - 1].clear();
                    _pinFocusNodes[index - 1].requestFocus();
                  }
                },
                onTap: () {
                  _pinControllers[index].selection = TextSelection.collapsed(
                    offset: _pinControllers[index].text.length,
                  );
                },
                onSubmitted: (_) {
                  if (index < 3) {
                    _pinFocusNodes[index + 1].requestFocus();
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

    return Scaffold(
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
                    child: SignupOtp(phone: phoneController.text.trim()),
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
                      icon: Icons.person_outline,
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
                      hint: 'Company',
                      icon: Icons.business_outlined,
                      height: fieldHeight,
                      radius: fieldRadius,
                      enabled: !isLoading,
                    ),
                    SizedBox(height: formGap),
                    _buildGhanaCardField(
                      fieldHeight: fieldHeight,
                      fieldRadius: fieldRadius,
                      enabled: !isLoading,
                      wScale: wScale,
                    ),
                    SizedBox(height: formGap),
                    AuthFormField(
                      controller: emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      height: fieldHeight,
                      radius: fieldRadius,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: formGap),
                    AuthFormFieldShell(
                      height: fieldHeight,
                      radius: fieldRadius,
                      icon: Icons.lock_outline,
                      focused: _pinFocusNodes.any((node) => node.hasFocus),
                      child: _buildPinRow(
                        enabled: !isLoading,
                        gap: formGap,
                      ),
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
