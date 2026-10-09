import 'package:intl/intl.dart';

class Currency {
  const Currency(this.code, this.symbol, this.name, this.locale);

  final String code;
  final String symbol;
  final String name;
  final String locale;

  static const List<Currency> all = [
    Currency('INR', '₹', 'Indian Rupee', 'en_IN'),
    Currency('USD', '\$', 'US Dollar', 'en_US'),
    Currency('EUR', '€', 'Euro', 'en_US'),
    Currency('GBP', '£', 'Pound Sterling', 'en_US'),
  ];

  static Currency byCode(String? code) =>
      all.firstWhere((c) => c.code == code, orElse: () => all.first);

  /// Whole amounts render without decimals (₹1,200), others with two (₹1,200.50).
  String format(double value, {bool compact = false}) {
    if (compact) {
      final sign = value < 0 ? '-' : '';
      return '$sign$symbol${NumberFormat.compact().format(value.abs())}';
    }
    final isWhole = (value - value.roundToDouble()).abs() < 0.005;
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: isWhole ? 0 : 2,
    ).format(value);
  }
}
