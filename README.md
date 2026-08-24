# BizHisab AI

> AI-powered smart business finance and accounting assistant for small businesses in Bangladesh.

BizHisab AI helps shop owners and entrepreneurs track daily income, expenses, customers, suppliers, and dues — then turns the numbers into clear reports and AI-driven insights. Built with Flutter for Android, iOS, and Web, backed by Firebase and a Python AI service.

---

## ✨ Features

### 📊 Dashboard
- Real-time today/month income, expense, and profit overview
- Customer & supplier due tracking at a glance
- Recent transactions feed with one-tap detail
- Greeting hero card with business-aware profit indicator

### 💸 Transactions
- Add income and expense entries with category, payment method, and notes
- Customer & supplier due ledger with partial-payment tracking
- Searchable transaction history with date filters

### 👥 Customers & Suppliers
- Contact directory with outstanding balance per party
- Tap-through to per-party transaction history
- Quick actions for adding dues and recording payments

### 📈 Reports
- Daily / weekly / monthly income vs. expense
- Category breakdowns and trend lines via `fl_chart`
- Export-ready summaries (extensible)

### 🤖 AI Insights
- Personalized financial recommendations
- Pattern detection across income, expense, and due cycles
- Beta — powered by the Python backend in `ai_backend/`

### 🌐 Localization
- Full Bangla (`bn`) and English (`en`) translations
- Locale-aware currency and date formatting

### ☁️ Cloud + Auth
- Firebase Authentication with email/password
- Cloud Firestore for real-time sync across devices
- Firebase Cloud Messaging for push notifications

---

## 🧱 Tech Stack

| Layer | Technology |
| --- | --- |
| Framework | Flutter 3.12+ (Material 3) |
| Language | Dart |
| State | `provider` |
| Routing | `go_router` |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| AI Service | Python (FastAPI-style) — see `ai_backend/` |
| Charts | `fl_chart` |
| i18n | `flutter_localizations` + ARB (`gen-l10n`) |
| Tests | `flutter_test` |

---

## 📁 Project Structure

```
bizhisab_ai/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── router.dart               # go_router configuration
│   ├── firebase_options.dart     # Firebase platform config
│   ├── core/                     # Shared theme, widgets, services
│   │   ├── theme/                # AppColors, typography
│   │   ├── widgets/              # Reusable UI primitives
│   │   ├── services/             # Cross-cutting services
│   │   └── utils/                # Formatters, helpers
│   ├── features/                 # Feature-first modules
│   │   ├── landing/              # Pre-auth landing page
│   │   ├── auth/                 # Sign-in / sign-up
│   │   ├── setup/                # First-run business setup
│   │   ├── shell/                # Authenticated app shell
│   │   ├── dashboard/            # Home dashboard
│   │   ├── transactions/         # Income & expense CRUD
│   │   ├── income/   expense/    # Type-specific flows
│   │   ├── customers/ suppliers/ # Party ledgers
│   │   ├── reports/              # Analytics
│   │   ├── ai/                   # AI insights surface
│   │   └── profile/              # User settings
│   ├── l10n/                     # ARB files + generated localizations
│   ├── models/                   # Domain models
│   ├── providers/                # Provider state classes
│   └── repositories/             # Data access layer
├── ai_backend/                   # Python AI microservice
│   ├── app/                      # FastAPI app + agents
│   ├── routes/  services/        # API + business logic
│   ├── smoke_test.py             # Local smoke checks
│   └── requirements.txt
├── functions/                    # Firebase Cloud Functions (TS)
├── android/  ios/  web/  windows/# Platform shells
├── test/                         # Unit & widget tests
├── assets/                       # Static images & icons
├── firebase.json                 # Firebase project config
├── firestore.rules               # Firestore security rules
└── pubspec.yaml                  # Dart dependencies
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK **^3.12.0**
- Dart (bundled with Flutter)
- Android Studio / Xcode for device builds
- Firebase CLI (`npm i -g firebase-tools`) for emulators & deploys
- Python **3.11+** (only if running the AI backend)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Configure Firebase
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Add Android, iOS, and Web apps to the project.
3. Download `google-services.json` → `android/app/`.
4. Generate `firebase_options.dart` via the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. Replace `ai_backend/service-account.json` with your project's service-account key.

### 3. Run the AI backend (optional, for insights)
```bash
cd ai_backend
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
python smoke_test.py            # Quick sanity check
uvicorn app.main:app --reload   # Serve on http://localhost:8000
```

### 4. Launch the app
```bash
flutter run                      # auto-select device
flutter run -d chrome            # web
flutter run -d <device-id>       # specific device
```

---

## 🧪 Tests

```bash
flutter test                      # All unit & widget tests
flutter analyze                   # Static analysis
```

Key test suites:
- `test/due_calculation_service_test.dart`
- `test/due_recalculation_coordinator_test.dart`
- `test/report_aggregator_test.dart`

---

## 🔐 Security

- Firestore rules live in `firestore.rules` — every read/write is scoped to the authenticated user's `businessId`.
- All API keys belong in `.gitignore`d local config files; never commit `service-account.json` or `google-services.json` to public branches.
- The AI backend expects authenticated requests via Firebase ID tokens.

---

## 🌍 Localization

Translations live in `lib/l10n/` as ARB files. To add or update strings:

```bash
flutter gen-l10n
```

Supported locales: **English (`en`)**, **Bangla (`bn`)**.

---

## 📦 Build & Release

| Target | Command |
| --- | --- |
| Android APK | `flutter build apk --release` |
| Android App Bundle | `flutter build appbundle --release` |
| iOS | `flutter build ios --release` |
| Web | `flutter build web --release` |
| Windows | `flutter build windows --release` |

---

## 🛣️ Roadmap

- [ ] Multi-business switcher
- [ ] Cloud Functions for scheduled due reminders
- [ ] Receipt OCR for fast transaction entry
- [ ] Export reports to PDF / Excel
- [ ] Offline-first sync queue
- [ ] Desktop-first dashboard layout

---

## 📄 License

This project is private and proprietary. All rights reserved.

---

## 👥 Maintainers

BizHisab AI — internal team.
For questions, open an issue or contact the project owner.
