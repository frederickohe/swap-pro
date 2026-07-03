import 'package:swappro/barrel.dart';

class ThemeBloc extends Cubit<ThemeState> {
  ThemeBloc() : super(ThemeState(_defaultTheme()));

  static ThemeData _defaultTheme() {
    const scaffoldBackground = Colors.white;

    return AppTypography.applyTo(
      ThemeData(
        scaffoldBackgroundColor: scaffoldBackground,
        colorScheme: ColorScheme.light(
          primary: AppTypography.brandInk,
          secondary: AppTypography.brandGold,
          onPrimary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: scaffoldBackground,
          foregroundColor: AppTypography.brandInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: AppSystemUi.forBackground(scaffoldBackground),
        ),
      ),
    );
  }

  void refreshTheme() {
    emit(ThemeState(_defaultTheme()));
  }
}
