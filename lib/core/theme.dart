import 'package:flutter/material.dart';

/// Central place for colours/theme so screens never hard-code palette values.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF600964);

  static const List<Color> chartPalette = [
    Color(0xFF7E57C2),
    Color(0xFFEF5350),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFF9E9E9E),
  ];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF14111A)
          : const Color(0xFFF7F4F9),
    );
  }

  static Color income(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF81C784)
          : const Color(0xFF2E7D32);

  static Color expense(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFEF9A9A)
          : const Color(0xFFC62828);
}
