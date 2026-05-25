import 'package:swappro/barrel.dart';

class ThemeBloc extends Cubit<ThemeState> {
  ThemeBloc() : super(ThemeState(_defaultTheme()));

  static ThemeData _defaultTheme() {
    return AppTypography.applyTo(
      ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
    );
  }

  void refreshTheme() {
    emit(ThemeState(_defaultTheme()));
  }
}
