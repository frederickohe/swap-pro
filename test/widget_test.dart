import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappro/barrel.dart';
import 'package:swappro/main.dart';

void main() {
  testWidgets('MyApp builds with required dependencies', (
    WidgetTester tester,
  ) async {
    final successBloc = SuccessBloc();
    final authBloc = AuthBloc(
      tokenService: TokenService(),
      successBloc: successBloc,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: authBloc),
          BlocProvider.value(value: successBloc),
          BlocProvider(create: (_) => ThemeBloc()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
