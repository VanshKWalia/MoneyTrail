import 'package:flutter/material.dart';
import 'package:moneytrail/core/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    final savedTheme = _prefs.getString(_kTheme);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == savedTheme,
      orElse: () => ThemeMode.system,
    );
    _currency = Currency.byCode(_prefs.getString(_kCurrency));
    _budget = _prefs.getDouble(_kBudget) ?? 0;
  }

  static const _kTheme = 'theme_mode';
  static const _kCurrency = 'currency';
  static const _kBudget = 'monthly_budget';

  final SharedPreferences _prefs;
  late ThemeMode _themeMode;
  late Currency _currency;
  late double _budget;

  ThemeMode get themeMode => _themeMode;
  Currency get currency => _currency;

  /// 0 means "no budget set".
  double get monthlyBudget => _budget;
  bool get hasBudget => _budget > 0;

  String money(double v) => _currency.format(v);
  String moneyCompact(double v) => _currency.format(v, compact: true);

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setCurrency(Currency c) async {
    _currency = c;
    notifyListeners();
    await _prefs.setString(_kCurrency, c.code);
  }

  Future<void> setMonthlyBudget(double value) async {
    _budget = value < 0 ? 0 : value;
    notifyListeners();
    await _prefs.setDouble(_kBudget, _budget);
  }
}
