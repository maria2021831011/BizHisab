import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String symbol = '৳'}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatWithDecimal(double amount, {String symbol = '৳'}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbol${formatter.format(amount)}';
  }

  static String formatShort(double amount, {String symbol = '৳'}) {
    if (amount >= 10000000) {
      return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String formatWithSign(double amount, {String symbol = '৳'}) {
    final prefix = amount >= 0 ? '+' : '';
    return '$prefix${format(amount, symbol: symbol)}';
  }
}
