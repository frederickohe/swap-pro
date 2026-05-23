import 'package:swappro/barrel.dart';

class CtaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? nextScreen;

  const CtaButton({super.key, this.onPressed, this.nextScreen});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed:
          onPressed ??
          () {
            if (nextScreen != null) {
              NavigationService.navigateTo(nextScreen!);
            }
          },
      style: ElevatedButton.styleFrom(
        backgroundColor: CustColors.mainCol,
        textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        fixedSize: Size(MediaQuery.of(context).size.width * 0.6, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40), // Rounded corners
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Padding
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text('Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
