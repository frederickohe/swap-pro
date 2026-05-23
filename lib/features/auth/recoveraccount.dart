import 'package:swappro/barrel.dart';

class RecoverAccount extends StatefulWidget {
  const RecoverAccount({super.key});
  @override
  State<RecoverAccount> createState() => _RecoverAccountState();
}

class _RecoverAccountState extends State<RecoverAccount> {
  final TextEditingController emailController = TextEditingController();
  bool _emailVerified = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is EmailExists) {
          setState(() => _emailVerified = true);
          // Show dialog or message that email exists and code will be sent
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email verified. Sending reset code...')),
          );
          // Automatically send the reset code
          context.read<AuthBloc>().add(SendResetCodeEvent(email: state.email));
        } else if (state is ResetCodeSent) {
          // Navigate to VerifyCode screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCode(email: state.email),
            ),
          );
        } else if (state is AuthError && state.source == 'check_email') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
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
                      'Verify Email',
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
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0),
                child: Text(
                  'Email',
                  style: GoogleFonts.montserrat(
                    color: const Color.fromARGB(255, 12, 12, 12),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: '',
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: AppButton(
                  onPressed: () {
                    if (emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter your email'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      CheckEmailExistsEvent(email: emailController.text),
                    );
                  },
                  buttonText: 'Verify',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
