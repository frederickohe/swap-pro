import 'package:swappro/barrel.dart';

class Success extends StatefulWidget {
  const Success({super.key});

  @override
  State<Success> createState() => _SuccessState();
}

class _SuccessState extends State<Success> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SuccessBloc, SuccessState>(
        listener: (context, state) {
          // Handle navigation when success state changes
          if (state is SuccessDisplaying) {
            // You can add navigation logic here if needed
          }
        },
        child: BlocBuilder<SuccessBloc, SuccessState>(
          builder: (context, state) {
            // Extract message and nextScreen based on state
            String displayMessage = 'Account creation was successful!';
            String? nextScreen;

            if (state is SuccessDisplaying) {
              displayMessage = state.message;
              nextScreen = state.nextScreen;
            }

            return Center(
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.width * 0.1),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.width * 0.2),
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Image.asset(
                          'assets/icons/success.png',
                          fit: BoxFit.cover,
                          width: 50,
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width * 0.2),
                      Text(
                        displayMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width * 0.5),
                  CtaButton(
                    onPressed: () {
                      context.read<SuccessBloc>().add(ClearSuccessEvent());

                      final userEmail = state is SuccessDisplaying
                          ? state.userEmail
                          : '';

                      if (nextScreen == 'login') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const Signin(),
                          ),
                        );
                      } else if (nextScreen == 'welcome') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const Welcome(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
