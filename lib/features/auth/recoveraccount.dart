import 'package:swappro/barrel.dart';
import 'package:swappro/utils/phone_utils.dart';

enum _RecoverMethod { email, phone }

class RecoverAccount extends StatefulWidget {
  const RecoverAccount({super.key});

  @override
  State<RecoverAccount> createState() => _RecoverAccountState();
}

class _RecoverAccountState extends State<RecoverAccount> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  _RecoverMethod _method = _RecoverMethod.email;

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_method == _RecoverMethod.email) {
      if (emailController.text.trim().isEmpty) {
        context.showAppSnackBar('Please enter your email');
        return;
      }
      context.read<AuthBloc>().add(
            CheckEmailExistsEvent(email: emailController.text.trim()),
          );
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      context.showAppSnackBar('Please enter your phone number');
      return;
    }
    context.read<AuthBloc>().add(
          CheckEmailExistsEvent(
            phone: normalizePhone(phoneController.text.trim()),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final m = AuthScreenLayout.metrics(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailExists) {
          context.showAppSnackBar(
            'Account verified. Sending reset code...',
            variant: AppSnackBarVariant.success,
          );
          if (_method == _RecoverMethod.phone) {
            context.read<AuthBloc>().add(
                  SendResetCodeEvent(
                    email: state.email,
                    phone: normalizePhone(phoneController.text.trim()),
                  ),
                );
          } else {
            context.read<AuthBloc>().add(
                  SendResetCodeEvent(email: state.email),
                );
          }
        } else if (state is ResetCodeSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCode(
                email: state.email,
                phone: state.phone,
              ),
            ),
          );
        } else if (state is AuthError &&
            (state.source == 'check_email' ||
                state.source == 'send_reset_code')) {
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
                      boldPart: 'Reset PIN',
                      fontSize: 32 * m.wScale,
                    ),
                    SizedBox(height: 20 * m.hScale),
                    Text(
                      'Enter your email or phone number to receive a reset code',
                      style: AppTypography.style(
                        fontSize: 14 * m.wScale,
                        fontWeight: FontWeight.w400,
                        color: AuthScreenLayout.dark,
                        height: 20 / 14,
                      ),
                    ),
                    SizedBox(height: 24 * m.hScale),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodChip(
                            label: 'Email',
                            selected: _method == _RecoverMethod.email,
                            enabled: !isLoading,
                            onTap: () {
                              setState(() => _method = _RecoverMethod.email);
                            },
                          ),
                        ),
                        SizedBox(width: 12 * m.wScale),
                        Expanded(
                          child: _MethodChip(
                            label: 'Phone',
                            selected: _method == _RecoverMethod.phone,
                            enabled: !isLoading,
                            onTap: () {
                              setState(() => _method = _RecoverMethod.phone);
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24 * m.hScale),
                    if (_method == _RecoverMethod.email)
                      AuthFormField(
                        controller: emailController,
                        hint: 'Email',
                        iconSvg: AuthIcons.emailFill,
                        height: m.fieldHeight,
                        radius: m.fieldRadius,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                      )
                    else
                      AuthFormField(
                        controller: phoneController,
                        hint: 'Phone number',
                        icon: Icons.phone_outlined,
                        height: m.fieldHeight,
                        radius: m.fieldRadius,
                        enabled: !isLoading,
                        keyboardType: TextInputType.phone,
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
                        onPressed: isLoading ? null : _submit,
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

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AuthScreenLayout.dark : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AuthScreenLayout.dark),
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AuthScreenLayout.dark,
          ),
        ),
      ),
    );
  }
}
