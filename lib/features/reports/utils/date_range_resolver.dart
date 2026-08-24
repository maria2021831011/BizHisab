import '../models/report_data.dart';

/// Computes inclusive `[start, end]` date windows for each report period.
///
/// Every window clamps the upper bound to `now` so the user can't see
/// future-dated totals, and rounds the lower bound to local midnight so
/// Firestore `where('date', isGreaterThanOrEqualTo:)` matches the day boundary
/// exactly.
class DateRangeResolver {
  const DateRangeResolver._();

  static (DateTime, DateTime) resolve(
    ReportPeriod period, {
    DateTime? now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final reference = now ?? DateTime.now();
    switch (period) {
      case ReportPeriod.daily:
        return (
          DateTime(reference.year, reference.month, reference.day),
          _endOfDay(reference),
        );
      case ReportPeriod.weekly:
        // Trailing 7 days, ending today. Lower bound is local midnight 6 days
        // ago so the window spans 7 calendar days inclusive of today.
        final today = DateTime(reference.year, reference.month, reference.day);
        return (
          today.subtract(const Duration(days: 6)),
          _endOfDay(reference),
        );
      case ReportPeriod.monthly:
        final start = DateTime(reference.year, reference.month, 1);
        return (start, _endOfMonth(reference));
      case ReportPeriod.custom:
        return _normalizeCustom(customStart, customEnd, reference);
    }
  }

  static (DateTime, DateTime) _normalizeCustom(
    DateTime? start,
    DateTime? end,
    DateTime reference,
  ) {
    if (start == null || end == null) {
      // Fall back to current month if the user opens the custom dialog and
      // dismisses without picking anything. The screen will reset the picker
      // rather than show an empty window.
      final startOfMonth = DateTime(reference.year, reference.month, 1);
      return (startOfMonth, _endOfMonth(reference));
    }

    DateTime s = DateTime(start.year, start.month, start.day);
    DateTime e = _endOfDay(end);

    // Reorder if user picked end < start. We don't want to throw — silently
    // normalising gives a better UX than a hard error.
    if (e.isBefore(s)) {
      final tmp = s;
      s = e;
      e = _endOfDay(tmp);
    }

    // Clamp upper bound to today so future-dated custom ranges don't show
    // negative-time windows that Firestore happily returns empty.
    final todayEnd = _endOfDay(reference);
    if (e.isAfter(todayEnd)) e = todayEnd;

    return (s, e);
  }

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static DateTime _endOfMonth(DateTime reference) {
    final nextMonth = (reference.month == 12)
        ? DateTime(reference.year + 1, 1, 1)
        : DateTime(reference.year, reference.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }
}
