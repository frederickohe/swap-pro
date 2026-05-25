import 'package:swappro/barrel.dart';

/// Admin portal sign-in — Figma frame "Swap Pro Admin" (200:1779).
class AdminSignIn extends StatefulWidget {
  const AdminSignIn({super.key});

  @override
  State<AdminSignIn> createState() => _AdminSignInState();
}

class _AdminSignInState extends State<AdminSignIn> {
  static const Color _gold = Color(0xFFC3B649);

  /// Figma artboard: 1440 × 1024.
  static const double _figmaW = 1440;
  static const double _figmaH = 1024;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      return;
    }

    context.read<AuthBloc>().add(
          LoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final wScale = w / _figmaW;
    final hScale = h / _figmaH;

    final contentWidth = (430 * wScale).clamp(280.0, 430.0);
    final horizontalPad = ((w - contentWidth) / 2).clamp(16.0, w);

    final titleTop = 250 * hScale;
    final panelTop = 416 * hScale;
    final panelHeight = 396 * hScale;
    final panelRadius = 25 * wScale;

    final formWidth = 364 * wScale;
    final formLeft = horizontalPad + (contentWidth - formWidth) / 2;
    final formTop = 501 * hScale;
    final fieldHeight = 70 * hScale;
    final fieldRadius = 10 * wScale;
    final fieldGap = 49 * hScale;

    final buttonWidth = 277 * wScale;
    final buttonHeight = 62 * hScale;
    final buttonRadius = 10 * wScale;
    final buttonTop = formTop + fieldHeight + fieldGap + fieldHeight + 24 * hScale;

    final titleFontSize = (67 / 1024 * h).clamp(28.0, 48.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
              (route) => false,
            );
          } else if (state is AuthError && state.source == 'login') {
            context.showAppSnackBar(state.message);
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
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/img/splash.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: titleTop,
                      left: horizontalPad,
                      width: contentWidth,
                      child: Text(
                        'SwapPro Admin',
                        textAlign: TextAlign.center,
                        style: AppTypography.style(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Positioned(
                      top: panelTop,
                      left: horizontalPad,
                      width: contentWidth,
                      height: panelHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(panelRadius),
                        child: ColoredBox(
                          color: _gold.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Positioned(
                      top: formTop,
                      left: formLeft,
                      width: formWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthFormField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            height: fieldHeight,
                            radius: fieldRadius,
                            enabled: !isLoading,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: fieldGap),
                          AuthFormField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            height: fieldHeight,
                            radius: fieldRadius,
                            enabled: !isLoading,
                            obscureText: true,
                            onSubmitted: (_) => _submitLogin(),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: buttonTop,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AuthPrimaryButton(
                          label: 'Sign In',
                          onPressed: _submitLogin,
                          width: buttonWidth,
                          height: buttonHeight,
                          radius: buttonRadius,
                          fontSize: 16 * wScale,
                          isLoading: isLoading,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 24 * hScale,
                      left: horizontalPad,
                      child: AuthBackButton(
                        onTap: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
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
