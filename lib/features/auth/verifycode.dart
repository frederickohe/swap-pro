import 'package:swappro/barrel.dart';

class VerifyCode extends StatefulWidget {
  final String email;

  const VerifyCode({super.key, required this.email});

  @override
  State<VerifyCode> createState() => _VerifyCodeState();
}

class _VerifyCodeState extends State<VerifyCode> {
  final TextEditingController codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ResetCodeVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResetPassword(email: state.email, code: codeController.text),
            ),
          );
        }
      },
      child: Scaffold(
        // ... your existing scaffold code
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Centered text
                  Center(
                    child: Text(
                      'Verify Code',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),

                  // Back button positioned on the left
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset('assets/img/bot.png'),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0),
                child: Text(
                  'Enter Code',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    hintText: '',
                    border: UnderlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Did Not Receeve Code? Resend Code',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: AppButton(
                  onPressed: () {
                    if (codeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter the verification code'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      VerifyResetCodeEvent(
                        email: widget.email,
                        code: codeController.text,
                      ),
                    );
                  },
                  buttonText: 'VerifyCode',
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Center(
                child: Text(
                  'Dont have an Account ?',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageTransition(
                        type: PageTransitionType.rightToLeftWithFade,
                        childCurrent: const Signup(),
                        duration: const Duration(milliseconds: 1000),
                        reverseDuration: const Duration(milliseconds: 600),
                        child: const Signup(),
                      ),
                    );
                  },
                  child: Text(
                    'Verify',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
