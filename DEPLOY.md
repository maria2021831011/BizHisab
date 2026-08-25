# BizHisab AI — Production Deployment Guide

This document is the minimum-viable deployment for shipping the Flutter
Android app and the FastAPI AI backend. It does **not** change any UI,
endpoint, auth flow, or business logic.

> **Before you start**
> 1. Rotate the Groq API key. The previous key was stored in
>    `ai_backend/.env` on a developer machine and must be treated as
>    compromised. Generate a new key at
>    <https://console.groq.com/keys>.
> 2. Generate a fresh Firebase Admin service-account JSON for the
>    **production** Firebase project (different from any dev project).
>    Never commit it; mount it as a secret at runtime.
> 3. Pick a production hostname (e.g. `api.bizhisab.ai`). This guide
>    uses `api.bizhisab.ai` as a placeholder — replace it everywhere.

---

## 1. Architecture (unchanged)

```
Flutter (Android AAB)  ──HTTPS──▶  FastAPI on Fly/Render/Cloud Run/VPS
                                       │
                                       ├── Firebase Auth (ID-token verify)
                                       ├── Firestore (business data)
                                       └── Groq (LangChain-Groq via LangGraph)
```

The Flutter app signs in with Firebase Auth, gets an ID token, and sends
`Authorization: Bearer <idToken>` to FastAPI. The backend verifies the
token, runs the existing LangGraph pipeline, returns JSON, and persists
AI insights to Firestore. **Nothing in the request/response shape is
changing.**

---

## 2. Backend deployment

### 2.1 Choose a host

| Host        | Pros                                                          | Cons                                                                                                |
|-------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| Fly.io      | Free TLS, simple `fly.toml`, secret manager, fast cold start  | Small instance: 1 vCPU / 256 MB may be tight for `langgraph`; pick `shared-cpu-1x` / 1 GB or larger. |
| Render      | Managed HTTPS, easy secrets, free tier available              | Free tier sleeps after 15 min — first request is slow.                                              |
| Cloud Run   | Auto-scale, IAM, secrets via Secret Manager                   | Cold starts; must rebuild image.                                                                    |
| VPS (nginx) | Full control, no per-request cost                              | You manage TLS renewal (`certbot`) and process supervision.                                         |

Pick whichever you can run today; the FastAPI app itself is host-agnostic.

### 2.2 One-time host setup (Fly.io example — adapt for your host)

```bash
# Install the CLI once.
curl -L https://fly.io/install.sh | sh

# From the repo root:
fly launch --no-deploy --copy-config --name bizhisab-ai-api --region sin
```

Then write `fly.toml` (Fly will let you edit before first deploy):

```toml
app       = "bizhisab-ai-api"
primary_region = "sin"

[build]
  dockerfile = "Dockerfile"

[env]
  GROQ_MODEL                       = "openai/gpt-oss-20b"
  AI_RATE_LIMIT_REQUESTS           = "20"
  AI_RATE_LIMIT_WINDOW_SECONDS     = "60"
  AI_CORS_ORIGINS                  = "*"
  # The two env vars below are set as Fly secrets, NOT here.

[http_service]
  internal_port = 8000
  force_https  = true
  auto_stop_machines = false   # keep warm; AI calls are latency-sensitive
  auto_start_machines = true
  min_machines_running = 1
```

### 2.3 Backend Dockerfile (drop in `ai_backend/Dockerfile`)

```dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY app ./app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
```

The `--proxy-headers` flag is required so FastAPI picks up the
`X-Forwarded-Proto: https` that Fly's edge proxy sets; without it,
URL helpers in the API will emit `http://` redirects.

### 2.4 Environment variables (set as platform secrets — never in code)

| Var                          | Example / note                                               |
|------------------------------|--------------------------------------------------------------|
| `GROQ_API_KEY`               | `gsk_…`  (from console.groq.com — **rotate the previous key**) |
| `FIREBASE_CREDENTIALS_PATH`  | `/var/run/secrets/firebase.json` (path of mounted secret)    |
| `GROQ_MODEL`                 | `openai/gpt-oss-20b`                                         |
| `AI_RATE_LIMIT_REQUESTS`     | `20`                                                         |
| `AI_RATE_LIMIT_WINDOW_SECONDS` | `60`                                                       |
| `AI_CORS_ORIGINS`            | `*` for mobile; tighten to your web origin if you add one.  |

Fly CLI example:

```bash
fly secrets set \
  GROQ_API_KEY="gsk_NEW_KEY" \
  FIREBASE_CREDENTIALS_PATH=/var/run/secrets/firebase.json

# Mount the service-account JSON.
fly secrets import <(echo '{"type":"service_account","project_id":"...",...}')
# Better: use `fly secrets set` with a base64'd file, or upload via the dashboard.
```

Deploy:

```bash
fly deploy
```

### 2.5 HTTPS

* **Fly / Render / Cloud Run**: HTTPS is automatic and terminates at the
  edge. Set `force_https` (Fly) or `auto_https` (Render). Free TLS certs.
* **VPS**: install `certbot --nginx -d api.bizhisab.ai` and renew via cron.

---

## 3. Firebase production configuration

All of these settings are in the Firebase Console
(<https://console.firebase.google.com>), project `bizhisab-ai-971a9` (or
your prod project if separate):

### 3.1 Authorized domains

**Authentication → Sign-in method → Authorized domains** → add:

* `bizhisab.ai` and any subdomain (`api.bizhisab.ai`)
* The custom domain that hosts your backend if different

> This is required for Firebase Auth to issue ID tokens to clients
> loading the app from your production URLs (relevant for web; harmless
> but necessary to add for mobile webview / desktop builds).

### 3.2 API keys

* Confirm the Firebase API key in `lib/firebase_options.dart` matches
  the **production** project's web/Android config.
* Restrict the API key in **Project settings → General → Your apps →
  Android app → API key → Settings** to your package id
  (`com.example.bizhisab_ai` or your renamed package) and the SHA-1 /
  SHA-256 of your release signing key.

### 3.3 Firestore rules & indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

The rules in `firestore.rules` are already locked-down by `userId`
ownership. **No change needed.** Just deploy.

### 3.4 Optional but recommended

* **App Check** — turn on App Check for Android (Play Integrity) and
  enable enforcement on the production Firebase Auth/Firestore. This
  blocks unauthorized clients even if they have a stolen ID token.
* **Auth throttle** — leave email/password throttling on the default
  (low) values for production.

---

## 4. Flutter (Android App Bundle) build

### 4.1 One-time: generate a release signing key

Generate ONCE, store the keystore in a safe place (1Password, Bitwarden,
encrypted USB). **Never commit the keystore or its passwords.**

```bash
keytool -genkeypair -v \
  -keystore ~/keystores/bizhisab-ai-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias bizhisab-ai \
  -storetype JKS
```

Create `android/key.properties` (do **not** commit it — add to
`android/.gitignore`):

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=bizhisab-ai
storeFile=/absolute/path/to/bizhisab-ai-release.jks
```

### 4.2 One-time: link the keystore in `android/app/build.gradle.kts`

Replace the TODO block:

```kotlin
// Before: signingConfig = signingConfigs.getByName("debug")
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: ""
            keyPassword = keystoreProperties["keyPassword"] as String? ?: ""
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String? ?: ""
        }
    }
    buildTypes {
        release {
            signingConfig = if (keystoreProperties["storeFile"] != null)
                signingConfigs.getByName("release")
            else signingConfigs.getByName("debug")  // fallback keeps local builds working
        }
    }
}
```

### 4.3 Update `aiBaseUrl`

In `lib/core/constants/app_constants.dart`, replace the placeholder:

```dart
static const String aiBaseUrl = 'https://api.bizhisab.ai';   // ← your real prod URL
```

Run `flutter pub get` afterwards.

### 4.4 Build the App Bundle

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The AAB is at:

```
build/app/outputs/bundle/release/app-release.aab
```

Upload to **Google Play Console → Your app → Release → Internal testing**
(or whichever track) → upload the `.aab` and submit.

> iOS is out of scope here because you only requested Android. The same
> FastAPI URL change in `app_constants.dart` (plus a future iOS build)
> covers iOS production.

---

## 5. Verify the deployment

### 5.1 Backend liveness (no auth)

```bash
curl -fsS https://api.bizhisab.ai/health
# Expected: {"status":"ok"}

curl -fsS https://api.bizhisab.ai/api/ai/health
# Expected: {"status":"ok","groq_configured":true,"firebase_configured":true}

curl -fsS https://api.bizhisab.ai/api/ai/diag
# Expected: "status":"ready", "groq_configured":true,
#           "firebase_admin_loaded":true, "gcp_project":"bizhisab-..."
```

### 5.2 Backend auth (Firebase ID token required)

```bash
TOKEN="..."   # paste a fresh ID token from your running app (see below)

curl -fsS https://api.bizhisab.ai/api/ai/auth-test \
  -H "Authorization: Bearer $TOKEN"
# Expected: {"authenticated":true,"uid":"...","endpoint":"/api/ai/auth-test"}
```

To grab a token from a Flutter debug session, temporarily add a button
that does:

```dart
print(await FirebaseAuth.instance.currentUser!.getIdToken());
```

### 5.3 End-to-end smoke test (must all pass on production)

| # | Step                                       | Expected                                                                                                                                          |
|---|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| 1 | Install AAB on a clean device              | App launches, lands on landing screen                                                                                                             |
| 2 | Sign up with email + password              | Account created in Firebase Auth (prod project)                                                                                                  |
| 3 | Logout                                     | Returns to landing; Firebase Auth session cleared                                                                                                 |
| 4 | Login again with same email/password       | Logged in, lands on setup if `businesses/{uid}` is missing, else on dashboard                                                                    |
| 5 | Send OTP / verify subscription via `bdappsdigitalapps.com` PHP endpoints | 200; subscription active; existing logic in `lib/core/constants/bdapps_endpoints.dart` unchanged |
| 6 | Dashboard loads                           | Today/month numbers render from Firestore                                                                                                        |
| 7 | Open AI screen → ask a Banglish question  | `/api/ai/chat` returns a `summary`/`keyFindings`/`recommendations` in ≤30 s; insight saved under `businesses/{uid}/ai_insights/{id}`            |
| 8 | Logout → login again                       | Behaves identically to step 4                                                                                                                    |

If step 7 fails with **401 unauthorized**, your Firebase ID-token
verifier in FastAPI is rejecting prod tokens — double-check that the
service-account JSON belongs to the **same** project as the API key in
`firebase_options.dart`.

If step 7 fails with **degraded** status, run the `/api/ai/diag` endpoint
above and follow the `hint_groq` / `hint_firebase` strings.

---

## 6. Endpoint inventory (unchanged)

| Method | Path                       | Auth      | Purpose                                            |
|--------|----------------------------|-----------|----------------------------------------------------|
| GET    | `/`                        | none      | service banner                                      |
| GET    | `/health`                  | none      | liveness                                           |
| GET    | `/docs`                    | none      | Swagger UI                                         |
| POST   | `/api/ai/chat`             | Bearer ID | chatbot (`requestType="chatbot"`, `question` req.) |
| POST   | `/api/ai/insight`          | Bearer ID | structured analyses                                |
| GET    | `/api/ai/auth-test`        | Bearer ID | smoke-test (returns uid)                           |
| GET    | `/api/ai/health`           | none      | status + `groq_configured`/`firebase_configured`   |
| GET    | `/api/ai/diag`             | none      | deep self-check                                    |

No new routes. No removed routes. No contract changes.

---

## 7. Secrets hygiene — recap

✅ `ai_backend/.env` and `ai_backend/service-account.json` are
   `.gitignore`d — verify with `git check-ignore ai_backend/.env`
   (should print the path).
✅ Groq key rotated after the previous exposure.
✅ Production `GROQ_API_KEY` and `FIREBASE_CREDENTIALS_PATH` live only
   in the host's secret manager — never in the repo, never in the
   Flutter APK, never on GitHub.
✅ `android/key.properties` and `*.jks` are gitignored.

Add (if missing) to `android/.gitignore`:

```
key.properties
*.jks
*.keystore
```

Add (if missing) to `ai_backend/.gitignore`:

```
.env
service-account.json
*-firebase-adminsdk-*.json
```
