import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's chosen app locale (English / বাংলা) across restarts
/// using [SharedPreferences]. The default is the device locale if it is
/// Bengali, otherwise English.
class LocaleProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_locale';

  /// Supported UI locales. Order matters: the first matching locale from
  /// `WidgetsBinding.platformDispatcher.locales` is selected on first run.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('bn'),
  ];

  Locale _locale = const Locale('en');
  bool _loaded = false;

  Locale get locale => _locale;

  /// True once [load] has finished reading from SharedPreferences.
  bool get loaded => _loaded;

  /// Load the persisted locale. Falls back to the device locale (or English)
  /// when no preference has been saved yet.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
      } else {
        // First run: pick Bengali if the device locale is Bengali, else English.
        final deviceLocales = WidgetsBinding
            .instance
            .platformDispatcher
            .locales;
        Locale match = const Locale('en');
        for (final l in deviceLocales) {
          if (l.languageCode == 'bn') {
            match = const Locale('bn');
            break;
          }
        }
        _locale = match;
      }
    } catch (_) {
      _locale = const Locale('en');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Switch the app locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale.languageCode);
    } catch (_) {
      // Persistence failure is non-fatal; the in-memory change still applies.
    }
  }
}