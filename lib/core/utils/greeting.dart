import '../../l10n/gen/app_localizations.dart';

/// Time-of-day greeting helper.
///
/// Returns a culturally-appropriate greeting localized via [l].
/// Picks the bucket based on the local hour of [now] - tests can pass
/// any [DateTime].
String greetingFor(DateTime now, AppLocalizations l) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) {
    return l.dashboardGreetingMorning;
  } else if (hour >= 12 && hour < 17) {
    return l.dashboardGreetingAfternoon;
  } else if (hour >= 17 && hour < 21) {
    return l.dashboardGreetingEvening;
  }
  return l.dashboardGreetingNight;
}
