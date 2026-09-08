import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swappro/common_design/widgets/auth_pin_field.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  testWidgets('backspace can clear every PIN digit', (tester) async {
    final controllers = List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());

    await tester.pumpWidget(
      wrap(
        AuthPinField(
          controllers: controllers,
          focusNodes: focusNodes,
          enabled: true,
          wScale: 1,
          hScale: 1,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(AuthPinField.join(controllers), '1234');

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    expect(AuthPinField.join(controllers), '123');

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(AuthPinField.join(controllers), '12');

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(AuthPinField.join(controllers), '1');

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(AuthPinField.join(controllers), '');
  });
}
