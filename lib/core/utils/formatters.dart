import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final DateFormat _dateOnly = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('dd MMM');
  static final DateFormat _time = DateFormat('hh:mm a');

  static String date(DateTime date) => _dateOnly.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);
  static String dayMonth(DateTime date) => _dayMonth.format(date);
  static String time(DateTime date) => _time.format(date);

  static String phone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+88')) {
      return cleaned.substring(3);
    }
    if (cleaned.startsWith('88')) {
      return cleaned.substring(2);
    }
    return cleaned;
  }

  static String percentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String compactNumber(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
