/// Tiny recursive-descent parser for the calculator keypad.
///
/// Grammar (standard precedence, left associative):
///   expr   := term   (('+' | '-') term)*
///   term   := factor (('*' | '/') factor)*
///   factor := ('-' | '+') factor | number | '(' expr ')'
///
/// Written by hand (instead of a package) so the logic is unit-tested and
/// easy to explain.
class ExpressionEvaluator {
  ExpressionEvaluator._();

  /// Strict evaluation. Throws [FormatException] on malformed input.
  static double evaluate(String input) {
    final result = _Parser(_normalize(input)).parse();
    if (result.isNaN || result.isInfinite) {
      throw const FormatException('Result is not a finite number');
    }
    return result;
  }

  /// Returns null instead of throwing.
  static double? tryEvaluate(String input) {
    try {
      return evaluate(input);
    } on FormatException {
      return null;
    }
  }

  /// Live preview while typing: "12+" is treated as "12".
  static double? tryEvaluateLenient(String input) {
    final trimmed = input.replaceAll(RegExp(r'[+\-×÷*/.\s]+$'), '');
    if (trimmed.isEmpty) return null;
    return tryEvaluate(trimmed);
  }

  static String _normalize(String s) => s
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll('x', '*');
}

class _Parser {
  _Parser(this.s);

  final String s;
  int i = 0;

  double parse() {
    final v = _expr();
    _skip();
    if (i != s.length) {
      throw FormatException('Unexpected "${s[i]}" at position $i');
    }
    return v;
  }

  double _expr() {
    var v = _term();
    while (true) {
      _skip();
      if (_eat('+')) {
        v += _term();
      } else if (_eat('-')) {
        v -= _term();
      } else {
        return v;
      }
    }
  }

  double _term() {
    var v = _factor();
    while (true) {
      _skip();
      if (_eat('*')) {
        v *= _factor();
      } else if (_eat('/')) {
        final d = _factor();
        if (d == 0) throw const FormatException('Division by zero');
        v /= d;
      } else {
        return v;
      }
    }
  }

  double _factor() {
    _skip();
    if (_eat('-')) return -_factor();
    if (_eat('+')) return _factor();
    if (_eat('(')) {
      final v = _expr();
      _skip();
      if (!_eat(')')) throw const FormatException('Expected ")"');
      return v;
    }
    return _number();
  }

  double _number() {
    _skip();
    final start = i;
    while (i < s.length && (_isDigit(s.codeUnitAt(i)) || s[i] == '.')) {
      i++;
    }
    if (start == i) throw FormatException('Number expected at position $start');
    final v = double.tryParse(s.substring(start, i));
    if (v == null) throw FormatException('Invalid number "${s.substring(start, i)}"');
    return v;
  }

  bool _isDigit(int c) => c >= 48 && c <= 57;

  bool _eat(String c) {
    if (i < s.length && s[i] == c) {
      i++;
      return true;
    }
    return false;
  }

  void _skip() {
    while (i < s.length && s[i] == ' ') {
      i++;
    }
  }
}

/// Pure keypad logic: given the current text and a pressed key, returns the new
/// text. Keeping it out of the widget makes it trivially testable.
class ExpressionInput {
  ExpressionInput._();

  static const String backspace = '⌫';
  static const List<String> operators = ['+', '-', '×', '÷'];
  static const int maxLength = 24;

  static bool isOperator(String s) => operators.contains(s);

  static String press(String current, String key) {
    if (key == backspace) {
      return current.isEmpty ? current : current.substring(0, current.length - 1);
    }
    if (current.length >= maxLength) return current;

    if (isOperator(key)) {
      if (current.isEmpty) return current;
      final last = current[current.length - 1];
      if (isOperator(last)) {
        return current.substring(0, current.length - 1) + key;
      }
      if (last == '.') return '${current}0$key';
      return current + key;
    }

    if (key == '.') {
      final seg = _lastSegment(current);
      if (seg.contains('.')) return current;
      return seg.isEmpty ? '${current}0.' : '$current.';
    }

    if (key.length == 1 && key.codeUnitAt(0) >= 48 && key.codeUnitAt(0) <= 57) {
      final seg = _lastSegment(current);
      if (seg == '0') {
        return current.substring(0, current.length - 1) + key;
      }
      return current + key;
    }
    return current;
  }

  static String _lastSegment(String s) {
    var i = s.length;
    while (i > 0 && !isOperator(s[i - 1])) {
      i--;
    }
    return s.substring(i);
  }
}
