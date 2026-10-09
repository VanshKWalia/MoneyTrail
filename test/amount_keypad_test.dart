import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/widgets/amount_keypad.dart';

void main() {
  testWidgets('keypad emits the pressed keys in order', (tester) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AmountKeypad(onKey: pressed.add)),
      ),
    );

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));

    expect(pressed, ['1', '2', '+', '3']);
  });
}
