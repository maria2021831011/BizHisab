# BizHisab AI — Backend

Python FastAPI service that powers the AI layer of the BizHisab AI Flutter
app. It authenticates users via Firebase ID tokens, reads their Firestore
data, computes a deterministic financial summary in Python, then uses
LangGraph + Groq (free tier) to translate that summary into natural
language.

> **Free-first.** No Firebase Blaze, no Cloud Functions, no paid AI API.
> Groq free tier only. If the quota is exceeded the service returns a
> friendly error; it does **not** fall back to a paid provider.

---

## 1. What the backend does

```
Flutter  ──Bearer ID token──▶  FastAPI  ──(firebase-admin)──▶  Firestore
                                            │
                                            ▼
                                Financial Summary (Python-only)
                                            │
                                            ▼
                              LangGraph workflow (5 nodes)
                                            │
                                            ▼
                              Groq (openai/gpt-oss-20b, configurable via GROQ_MODEL)
                                            │
                                            ▼
                            Structured JSON  ──▶  Flutter  ──▶  Firestore
                                                saved as ai_insights
```

### Routes

| Method | Path             | Auth        | Purpose                                                         |
|--------|------------------|-------------|-----------------------------------------------------------------|
| POST   | `/api/ai/chat`   | Bearer ID   | Open-ended chatbot (`requestType="chatbot"`, `question` required) |
| POST   | `/api/ai/insight`| Bearer ID   | One of the canned analyses: financial_analyst, expense_analyzer, profit_analyzer, revenue_analyzer, recommendation |
| GET    | `/api/ai/health` | None        | Liveness probe (does **not** touch Groq / Firestore)             |
| GET    | `/`              | None        | Service name + version                                          |
| GET    | `/docs`          | None        | Swagger UI                                                      |

### LangGraph workflow

```
START
  └─▶ authenticate
        └─▶ load_data
              └─▶ analyze_request
                    └─▶ groq_call
                          └─▶ validate_response
                                └─▶ END
```

Every node mutates `AiState` (a `TypedDict`). The graph is compiled once
and reused across requests.

---

## 2. Local setup

### a. Create a virtual environment

```bash
cd ai_backend
python -m venv .venv

# Windows
.\.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate
```

### b. Install dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### c. Configure Firebase Admin credentials

1. Open the Firebase Console → **Project settings → Service accounts**.
2. Click **Generate new private key** and download the JSON file.
3. Save it as `ai_backend/service-account.json` (the path referenced by
   `.env.example`).
4. **Do not commit this file** — it is already in `.gitignore`.

### d. Configure the Groq API key

1. Sign up at https://console.groq.com (free tier is enough).
2. Generate an API key at https://console.groq.com/keys.
3. Copy `.env.example` to `.env` and paste the key:

```
GROQ_API_KEY=gsk_...
FIREBASE_CREDENTIALS_PATH=./service-account.json
```

### e. Start the server

```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Visit:

- Swagger UI: <http://localhost:8000/docs>
- Health:    <http://localhost:8000/api/ai/health>

---

## 3. Hooking up the Flutter app

The Flutter app needs a base URL to call this server.

| Environment                  | `aiBaseUrl`             |
|------------------------------|-------------------------|
| **Android emulator**         | `http://10.0.2.2:8000`  |
| Android physical device      | `http://<your-LAN-IP>:8000` |
| iOS simulator                | `http://localhost:8000`  |
| Desktop / production         | `https://your-deploy.example` |

The default lives in `lib/core/constants/app_constants.dart`
(`AppConstants.aiBaseUrl`). When the FastAPI backend is offline the app
keeps working — only the AI screens show a friendly "AI service
unavailable" message; Dashboard / Income / Expense / Customers /
Suppliers / Reports are unaffected.

---

## 4. Manual smoke test

```bash
# 1) Mint a Firebase ID token from your running Flutter app (e.g. via
#    `print(FirebaseAuth.instance.currentUser!.getIdToken())` in a debug
#    screen) and export it:
export TOKEN=...

# 2) Health check (no auth)
curl http://localhost:8000/api/ai/health

# 3) Insight
curl -X POST http://localhost:8000/api/ai/insight \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"businessId":"YOUR_BIZ_ID","requestType":"financial_analyst"}'

# 4) Chat (Banglish)
curl -X POST http://localhost:8000/api/ai/chat \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"businessId":"YOUR_BIZ_ID","requestType":"chatbot","question":"Amar ei mashe profit koto?"}'
```

The response is always JSON shaped like:

```json
{
  "summary": "...",
  "keyFindings": ["...", "..."],
  "recommendations": ["..."],
  "confidence": "high"
}
```

---

## 5. Test matrix

The FastAPI service is exercised manually and via the Flutter UI. Covered
scenarios:

| # | Scenario                          | Expected                                            |
|---|-----------------------------------|-----------------------------------------------------|
| 1 | No transactions                   | `confidence: "low"`, "not enough data" summary      |
| 2 | One transaction                   | `confidence: "medium"`                              |
| 3 | Multiple transactions             | `confidence: "high"` once previous-period exists     |
| 4 | Current vs previous month         | Deltas in `keyFindings`                             |
| 5 | Increased expense                 | `expenseChangePct > 0` reflected                    |
| 6 | Decreased profit                  | `profitChangePct < 0` reflected                     |
| 7 | Customer due > 0                  | `customer_due_total > 0` appears in summary         |
| 8 | Supplier due > 0                  | `supplier_due_total > 0` appears in summary         |
| 9 | Bangla / Banglish question        | Response in the same language                       |
|10 | English question                  | Response in English                                 |
|11 | Invalid Firebase token            | `401 unauthorized`                                  |
|12 | Unauthorized businessId           | `403 forbidden`                                     |
|13 | Groq failure (network, 5xx)       | `502 upstream_error`                                |
|14 | Groq free-tier rate-limit / quota | `429` + `AI service limit reached…`                 |
|15 | Malformed Groq response           | `502 upstream_error` + retry-able                   |
|16 | FastAPI offline                   | Flutter shows "AI service unavailable"              |
|17 | Cross-user data isolation         | Other uid's businessId always returns `403`         |

Rate limiting defaults to **20 requests per 60-second window per UID**
(configurable via `AI_RATE_LIMIT_REQUESTS` and
`AI_RATE_LIMIT_WINDOW_SECONDS`).

---

## 6. Security notes

* Flutter sends **only** the Firebase ID token. The UID is read from the
  verified token in FastAPI; the Flutter-supplied `businessId` is then
  matched against an ownership document before any Firestore read.
* Customers' phone numbers, addresses, names and supplier PII **never**
  reach Groq — the summary contains only aggregate monetary fields plus
  category totals.
* No Firebase Admin credentials are bundled with Flutter.
* `.env` and `service-account.json` are git-ignored.

---

## 7. Folder layout

```
ai_backend/
├── app/
│   ├── main.py                # FastAPI app
│   ├── config.py              # env loading
│   ├── firebase.py            # firebase-admin init
│   ├── models.py              # Pydantic request/response models
│   ├── routes/
│   │   └── ai_routes.py       # /api/ai/chat, /api/ai/insight, /health
│   ├── services/
│   │   ├── firestore_service.py
│   │   └── financial_service.py
│   └── agents/
│       ├── state.py           # LangGraph state TypedDict
│       ├── graph.py           # graph builder + run_workflow
│       ├── nodes.py           # authenticate, load_data, …
│       └── prompts.py         # system + per-feature prompts
├── requirements.txt
├── .env.example
└── .gitignore
```
