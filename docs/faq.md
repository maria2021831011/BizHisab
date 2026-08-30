# BizHisab AI — FAQ / BDApps Submission Template

App Name: BizHisab AI
App Id: [TBD – BDApps Registration]
Username: [TBD – BDApps Registration]
Contact details:
- Name: [TBD – BDApps Registration]
- Mobile No.: [TBD – BDApps Registration]
- Email: [TBD – BDApps Registration]
- Address: [TBD – BDApps Registration]

Project URL:
https://bizhisab-3.onrender.com/
(Flutter Web client hosted on Firebase Hosting; FastAPI AI backend on Render.)

Access Mode:
Website + Android App (OTP Based Subscription)

App Description:
BizHisab AI is a smart business-finance assistant available through both the
BizHisab website and the Android application.

The platform helps small-business owners in Bangladesh run their day-to-day
operations from a single mobile-first workspace:

1. Business Setup & Multi-business Support
2. Customers & Credit Ledger (dues, payments, history)
3. Transactions (sales, expenses, income tracking)
4. AI Insights (financial analyst, expense analyzer, sales trend, chatbot)
5. Reports (daily / weekly / monthly, customer statements, exportable)

Users can create one or more businesses, switch between them, manage
customers and their credit ledger, record transactions, view financial
reports, and ask the built-in AI assistant for plain-language insights on
their cashflow, top customers, overdue dues, and expenses.

How to Subscribe:
Website and Android App:
1. Visit the BizHisab website:
   https://bizhisab-3.onrender.com/
2. If you are a new user, create an account using the Sign Up option.
3. Log in to your BizHisab account.
4. Enter a valid Robi (018) or Airtel (016) mobile number from the
   subscription section.
5. Submit the mobile number.
6. An OTP will be sent to the submitted mobile number.
7. Enter and submit the received OTP.
8. After successful OTP verification, the subscription will be activated.
9. After successful subscription, the user can access the available
   subscription-enabled features through the BizHisab website and Android app.

SMS Subscription:
To subscribe through SMS, send:
START bizhisab
to 21213.

How to Unsubscribe:
Users can unsubscribe directly from the BizHisab website or Android app
dashboard.

Website:
1. Log in to the BizHisab website.
2. Open the Dashboard.
3. Go to the Subscription section.
4. Click the Unsubscribe option.
5. Confirm the unsubscribe request.
6. The subscription will be cancelled through the BDApps subscription system.

Android App:
1. Open the BizHisab Android App.
2. Log in to the account.
3. Open the Dashboard / Subscription section.
4. Click Unsubscribe.
5. Confirm the unsubscribe request.
6. The subscription will be cancelled through the BDApps subscription system.

SMS Unsubscription:
To unsubscribe through SMS, send:
STOP bizhisab
to 21213.

Host Address(es) [IP]:
[TBD – BDApps Registration]

Charge:
[TBD – BDApps Registration] BDT per day including VAT + SD + SC with
Auto Renewal.
This is a subscription-based website and Android application.

Offer Details:
The BizHisab AI platform provides the following major features:

Business Owner Features:
- User Registration and Login (Firebase Anonymous Auth, single-device
  account continuity)
- Business Profile Management (multi-business per account)
- Business Type & Currency Selection (BDT / USD / INR / EUR)
- Customer Management (add, edit, delete, ledger)
- Credit Sales & Due Tracking (per-customer running balance)
- Payment Recording (partial payments, full settlement)
- Transaction History (sales, expenses, income)
- Daily / Weekly / Monthly Reports
- Customer Statement / Ledger Report
- Data Export (CSV / PDF)
- Dashboard Summary (today's sales, dues, top customers)
- AI Insights (Financial Analyst, Expense Analyzer, Sales Trend,
  Cashflow Forecast, Customer Insight)
- AI Chat (natural-language Q&A about the user's own business data)
- Subscription Management
- User Dashboard
- Multi-language Support (English / Bengali)

How to Use (User Manual):
1. Visit the BizHisab website:
   https://bizhisab-3.onrender.com/
2. Create a new account using Sign Up.
3. Log in using the registered account.
4. Complete the required business profile information.
5. Enter a Robi (018) or Airtel (016) mobile number for subscription.
6. Submit the mobile number.
7. Enter the OTP received on the mobile number.
8. Submit the OTP and complete verification.
9. After successful subscription, access the appropriate dashboard.

Business Owner:
10. Add the first business from the Setup screen (name, type, currency).
11. Add customers from the Customers screen.
12. Record sales on credit (creates a due automatically).
13. Record payments against a customer (reduces the due).
14. Open Transactions to review all sales / payments / expenses.
15. Open Reports for daily / weekly / monthly summaries.
16. Open AI Insight for an automated analysis of the business.
17. Use AI Chat to ask "who owes me the most?", "what were expenses last
    week?", "summarise this month" and similar questions.
18. Manage account and subscription information from the Dashboard.
19. Unsubscribe directly from the Dashboard when required.
20. Add a second business from the Business switcher if needed.

Subscription Management:
Users can manage their BizHisab subscription through both the website and
Android application.
After successful subscription, the user can access the applicable
subscription-enabled features.
Users can check and manage their subscription from their Dashboard.
Unsubscription is available directly from the Dashboard of both the website
and Android application.
Users can also unsubscribe through SMS by sending:
STOP bizhisab
to 21213.

---

## Frequently Asked Questions

Q1. What is BizHisab AI?
A smart business-finance assistant for small-business owners in Bangladesh.
It replaces paper ledgers with a mobile-first app that handles customers,
credit (dues), payments, transactions, reports, and an AI assistant that
answers plain-language questions about the user's own data.

Q2. Is BizHisab AI free?
Basic customer / transaction / report features are free. The AI Insights
and AI Chat features require an active BDApps subscription (Robi / Airtel
OTP, or SMS START bizhisab to 21213).

Q3. Which platforms are supported?
Flutter Web (hosted on Firebase Hosting) and Android (release APK). The
production APK talks directly to https://bizhisab-3.onrender.com — no
localhost, no adb reverse.

Q4. How do I subscribe on the website?
Log in → Dashboard → Subscription → enter a Robi (018) or Airtel (016)
number → submit OTP received by SMS → subscription activates.

Q5. How do I subscribe by SMS?
Send: START bizhisab to 21213.

Q6. How do I unsubscribe?
Website / Android: Dashboard → Subscription → Unsubscribe → Confirm.
SMS: STOP bizhisab to 21213.

Q7. How do I add a new business?
From the Dashboard, open the business switcher and choose "Add business".
The first business is created during onboarding.

Q8. Can I have more than one business on one account?
Yes. Switch between businesses from the business switcher in the side menu.
Each business has its own customers, transactions, and reports.

Q9. How is "due" calculated?
For every customer, due = total credit sales − total payments received.
The figure is recomputed by DueCalculationService after every transaction
and is also enforced server-side by Firestore rules.

Q10. What is AI Insight?
A one-tap analysis of your business. It looks at your last 30 days of
transactions and returns a summary, key findings, and recommendations
covering cashflow, overdue dues, top customers, and expense breakdown.

Q11. What is AI Chat?
A free-text Q&A box where you can ask things like "who owes me the most?",
"what were my expenses last week?", or "summarise this month". Answers are
based only on your own data.

Q12. Why am I getting "You do not have access to this business"?
The AI backend verifies that the Firebase UID in your ID token owns the
businessId in the request. If you recently reinstalled the app or switched
devices, the auto-repair flow will recreate the ownership subdoc on next
login. If the issue persists, open AI Insight → tap "Ownership diag" — the
app will tell you which of the three ownership checks failed.

Q13. Is my data safe?
Yes. All data lives in your own Firebase project under your UID. The
backend verifies the Firebase ID token on every AI request and only
returns data for the authenticated user. No passwords, OTPs, or API keys
are stored on the device.

Q14. Can I export my data?
Yes. From the Reports screen you can export the daily / weekly / monthly
summary and customer statements as CSV / PDF.

Q15. Does the app work offline?
Yes. Local reads and writes are cached. AI features require an internet
connection because they call the deployed FastAPI backend.

Q16. Which mobile operators are supported?
Robi (018) and Airtel (016). Other operators are not eligible for the
BDApps subscription.

Q17. Will I be charged automatically?
Yes — the subscription auto-renews daily until you unsubscribe via the
Dashboard or by SMS.

Q18. How do I change my language?
Settings → Language → English / Bengali.

Q19. How do I delete my account?
Settings → Account → Delete account. This removes your Firebase Auth
session; business data remains in Firestore under your UID until you
explicitly delete it from the dashboard.

Q20. Where can I get support?
Use the in-app Help / Feedback link in the Dashboard, or email the
address listed in the BDApps registration contact details.