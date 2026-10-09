import 'package:flutter_test/flutter_test.dart';
import 'package:moneytrail/services/expression_evaluator.dart';

void main() {
  group('ExpressionEvaluator.evaluate', () {
    test('respects operator precedence', () {
      expect(ExpressionEvaluator.evaluate('2+3×4'), 14);
      expect(ExpressionEvaluator.evaluate('10-6÷2'), 7);
    });

    test('is left associative', () {
      expect(ExpressionEvaluator.evaluate('10-3-2'), 5);
      expect(ExpressionEvaluator.evaluate('100÷10÷2'), 5);
    });

    test('handles decimals, unary minus and parentheses', () {
      expect(ExpressionEvaluator.evaluate('1.5+2.25'), closeTo(3.75, 1e-9));
      expect(ExpressionEvaluator.evaluate('-5+10'), 5);
      expect(ExpressionEvaluator.evaluate('2×(3+4)'), 14);
    });

    test('accepts ascii operators too', () {
      expect(ExpressionEvaluator.evaluate('6*7'), 42);
      expect(ExpressionEvaluator.evaluate('8/2'), 4);
    });

    test('throws on malformed input', () {
      expect(() => ExpressionEvaluator.evaluate('2++'), throwsFormatException);
      expect(() => ExpressionEvaluator.evaluate('(2+3'), throwsFormatException);
      expect(() => ExpressionEvaluator.evaluate(''), throwsFormatException);
    });

    test('throws on division by zero', () {
      expect(() => ExpressionEvaluator.evaluate('5÷0'), throwsFormatException);
    });
  });

  group('tryEvaluateLenient', () {
    test('ignores trailing operators and dots while typing', () {
      expect(ExpressionEvaluator.tryEvaluateLenient('12+'), 12);
      expect(ExpressionEvaluator.tryEvaluateLenient('12×3-'), 36);
      expect(ExpressionEvaluator.tryEvaluateLenient('7.'), 7);
    });

    test('returns null for empty input', () {
      expect(ExpressionEvaluator.tryEvaluateLenient(''), isNull);
      expect(ExpressionEvaluator.tryEvaluateLenient('+'), isNull);
    });
  });

  group('ExpressionInput.press', () {
    String run(List<String> keys) =>
        keys.fold('', (acc, k) => ExpressionInput.press(acc, k));

    test('builds numbers and operators', () {
      expect(run(['1', '2', '+', '3']), '12+3');
    });

    test('ignores leading operators', () {
      expect(run(['+', '5']), '5');
    });

    test('replaces a repeated operator', () {
      expect(run(['5', '+', '×', '2']), '5×2');
    });

    test('allows only one dot per number', () {
      expect(run(['1', '.', '5', '.', '2']), '1.52');
      expect(run(['1', '.', '5', '+', '2', '.', '5']), '1.5+2.5');
    });

    test('prefixes zero for a lone dot', () {
      expect(run(['.', '5']), '0.5');
      expect(run(['4', '+', '.', '5']), '4+0.5');
    });

    test('collapses leading zeros', () {
      expect(run(['0', '0', '7']), '7');
    });

    test('backspace removes last char and is safe when empty', () {
      expect(run(['1', '2', ExpressionInput.backspace]), '1');
      expect(run([ExpressionInput.backspace]), '');
    });
  });
}
