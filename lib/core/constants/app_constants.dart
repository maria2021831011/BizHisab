class AppConstants {
  AppConstants._();

  static const String appName = 'BizHisab AI';
  static const String appNameBn = 'বিজনেস হিসাব AI';
  static const String appTagline = 'Smart Business Finance Assistant';
  static const String appTaglineBn = 'স্মার্ট ব্যবসায়িক আর্থিক সহকারী';

  static const String defaultCurrency = 'BDT';
  static const String defaultCurrencySymbol = '৳';

  static const int otpLength = 6;
  static const int resendOtpCooldownSeconds = 60;
  static const int otpExpiryMinutes = 5;

  static const int maxBusinessNameLength = 100;
  static const int maxNoteLength = 500;
  static const int maxSearchLength = 100;

  static const int dashboardRecentTransactionsLimit = 10;
  static const int searchDebounceMilliseconds = 500;

  /// Canonical business types shown in the setup + edit forms.
  /// Adding a new option here is safe — existing business documents
  /// store the raw string so older values still render correctly.
  static const List<String> businessTypes = <String>[
    'Grocery',
    'Clothing',
    'Restaurant/Food',
    'Online Seller',
    'Freelancer',
    'Service Business',
    'Other',
  ];

  /// Supported currencies. The first entry is treated as the default
  /// for every newly created business.
  static const List<String> currencies = <String>[
    'BDT',
    'USD',
    'INR',
    'EUR',
  ];

  /// Base URL for the FastAPI AI backend.
  ///
  /// PRODUCTION: must be HTTPS. Replace the placeholder below with your
  /// real production hostname (e.g. https://api.bizhisab.ai) before
  /// running `flutter build appbundle --release`.
  ///
  /// Local development uses `http://127.0.0.1:8000`. To switch back for
  /// dev builds, change this constant back to the localhost URL.
  ///
  /// Real Android device (dev):
  ///   1. Connect phone via USB with USB-debugging enabled.
  ///   2. Run `adb reverse tcp:8000 tcp:8000` so the device can reach
  ///      the dev machine's localhost through `127.0.0.1:8000`.
  ///   3. Start the backend on the host: `uvicorn app.main:app --port 8000`.
  ///
  /// Android emulator: use `http://10.0.2.2:8000` instead.
  /// iOS simulator / desktop: `http://127.0.0.1:8000` works directly.
  static const String aiBaseUrl = 'https://api.example.com';

  /// AI request timeout. Generous because Groq can be slow during peaks.
  static const Duration aiRequestTimeout = Duration(seconds: 30);
}
