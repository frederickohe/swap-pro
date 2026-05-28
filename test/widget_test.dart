import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappro/barrel.dart';
import 'package:swappro/main.dart';

void main() {
  testWidgets('MyApp builds with required dependencies', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeBloc(),
        child: MyApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
