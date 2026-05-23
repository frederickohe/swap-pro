import 'package:swappro/barrel.dart';
import 'package:flutter/services.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController ghanaCardTenController = TextEditingController();
  final TextEditingController ghanaCardCheckController =
      TextEditingController();
  final TextEditingController _ghaPrefixController = TextEditingController(
    text: 'GHA',
  );
  final FocusNode _ghanaCardCheckFocusNode = FocusNode();

  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  String get _pin => _pinControllers.map((c) => c.text).join();

  String get _ghanaCardValue {
    final ten = ghanaCardTenController.text.trim();
    final one = ghanaCardCheckController.text.trim();
    if (ten.isEmpty && one.isEmpty) return '';
    return 'GHA-$ten-$one';
  }

  static TextStyle _ghanaTenStyle() {
    return GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w400);
  }

  /// Width for the middle Ghana Card segment: grows with typed digits, capped at 10-wide sample.
  double _ghanaTenFieldWidth(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = _ghanaTenStyle();
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
    return (painter.width + 28).clamp(52.0, maxPainter.width + 36);
  }

  void _onGhanaTenChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    ghanaCardTenController.addListener(_onGhanaTenChanged);
  }

  @override
  void dispose() {
    ghanaCardTenController.removeListener(_onGhanaTenChanged);
    emailController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    companyController.dispose();
    ghanaCardTenController.dispose();
    ghanaCardCheckController.dispose();
    _ghaPrefixController.dispose();
    _ghanaCardCheckFocusNode.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final n in _pinFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Widget _buildPinInput({required bool enabled}) {
    const gap = SizedBox(width: 16);
    final children = <Widget>[];
    for (var index = 0; index < 4; index++) {
      if (index > 0) {
        children.add(gap);
      }
      children.add(
        SizedBox(
          width: 52,
          child: TextField(
            controller: _pinControllers[index],
            focusNode: _pinFocusNodes[index],
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              counterText: '',
            ),
            onChanged: (val) {
              if (val.isNotEmpty) {
                if (index < 3) {
                  _pinFocusNodes[index + 1].requestFocus();
                } else {
                  _pinFocusNodes[index].unfocus();
                }
              } else if (val.isEmpty && index > 0) {
                // Handle backspace: move focus to previous field and clear it
                _pinControllers[index - 1].clear();
                _pinFocusNodes[index - 1].requestFocus();
              }
            },
            onTap: () {
              // If user taps a later box, keep caret at end
              _pinControllers[index].selection = TextSelection.collapsed(
                offset: _pinControllers[index].text.length,
              );
            },
            onSubmitted: (_) {
              if (index < 3) _pinFocusNodes[index + 1].requestFocus();
            },
            onEditingComplete: () {
              // no-op; prevents default "done" behavior moving focus oddly
            },
          ),
        ),
      );
    }
    return Center(
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            final bool isLoading = state is AuthLoading;
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 26,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                height: 35,
                                width: 35,
                                decoration: BoxDecoration(
                                  color: CustColors.mainCol,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CustColors.mainCol,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 50 * 0.35,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(height: 48),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Username',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextField(
                                controller: usernameController,
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Phone',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Company',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextField(
                                controller: companyController,
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Ghana Card',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      child: TextField(
                                        controller: _ghaPrefixController,
                                        readOnly: true,
                                        enableInteractiveSelection: false,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        decoration: const InputDecoration(
                                          border: UnderlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        right: 4,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        '-',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: _ghanaTenFieldWidth(context),
                                      child: TextField(
                                        controller: ghanaCardTenController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        decoration: const InputDecoration(
                                          border: UnderlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        onChanged: (v) {
                                          if (v.length == 10) {
                                            FocusScope.of(context).requestFocus(
                                              _ghanaCardCheckFocusNode,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4,
                                        right: 4,
                                        bottom: 12,
                                      ),
                                      child: Text(
                                        '-',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: TextField(
                                        controller: ghanaCardCheckController,
                                        focusNode: _ghanaCardCheckFocusNode,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(1),
                                        ],
                                        style: GoogleFonts.montserrat(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        decoration: const InputDecoration(
                                          border: UnderlineInputBorder(),
                                          counterText: '',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Email',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'PIN',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              _buildPinInput(enabled: !isLoading),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 52),
                      Center(
                        child: AppButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (_pin.length != 4) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a 4-digit PIN',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
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
                                },
                          buttonText: 'Sign Up',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Have an Account ?',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageTransition(
                                type: PageTransitionType.leftToRightWithFade,
                                childCurrent: widget,
                                duration: const Duration(milliseconds: 1000),
                                reverseDuration: const Duration(
                                  milliseconds: 1000,
                                ),
                                child: const Signin(),
                              ),
                            ); // Handle sign up navigation
                          },
                          child: Text(
                            'Log In',
                            style: GoogleFonts.montserrat(
                              color: CustColors.mainCol,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
