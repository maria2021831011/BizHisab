---
name: Fix all customer and transaction bugs
overview: "Repair all runtime bugs in the Customer + Transaction features: the untyped DateTime write that destroys the transaction stream, defensive reads for legacy broken-date docs, missing stream-to-provider plumbing in the legacy transaction list, the bottom-nav route pointing at the wrong screen, and the minor StreamBuilder flicker in the customer list."
todos:
  - id: 1
    content: "Bug 1: Fix raw DateTime write in add_edit_transaction_screen.dart"
    status: pending
  - id: 2
    content: "Bug 2: Add readDate helper to transaction.dart / customer.dart / customer_payment.dart"
    status: pending
  - id: 3
    content: "Bug 3: Push stream into TransactionProvider from transaction_list_screen.dart"
    status: pending
  - id: 4
    content: "Bug 4: Repoint /app/transactions route to TransactionsScreen"
    status: pending
  - id: 5
    content: "Bug 5: Replace customer_list_screen StreamBuilder with StreamSubscription"
    status: pending
  - id: 6
    content: Run flutter analyze + manual smoke test
    status: pending
isProject: false
---

## Plan: Fix all customer and transaction bugs

**TL;DR:** The Customer + Transaction features fail at runtime due to a cluster of bugs. The most destructive one is `add_edit_transaction_screen.dart` writing a raw `DateTime` instead of a Firestore `Timestamp` for the `date` field on edits — a single bad doc poisons every transaction stream. The other bugs compound it: legacy list screens never push stream data into providers, models throw on non-Timestamp dates, and the bottom-nav routes to a legacy screen instead of the polished history screen. This plan covers every fix in one pass.

**Steps**

1. **Bug 1 (root cause) — Stop writing raw `DateTime` in the legacy edit transaction screen.** In `lib/features/transactions/add_edit_transaction_screen.dart`, add `import 'package:cloud_firestore/cloud_firestore.dart';` and change line 67 `'date': _date` → `'date': Timestamp.fromDate(_date)`. After this, no new bad-date docs will be written.

2. **Bug 2 (defensive read) — Add a `readDate` helper to all three model classes that cast timestamps.** Replace every `(data['x'] as Timestamp).toDate()` with a helper that accepts `Timestamp`, `DateTime`, ISO `String`, and `int` epoch ms so legacy broken docs still deserialize instead of crashing the stream. Apply to `lib/models/transaction.dart`, `lib/models/customer.dart`, and `lib/models/customer_payment.dart`.

3. **Bug 3 — Push stream snapshots into `TransactionProvider` from the legacy list screen.** In `lib/features/transactions/transaction_list_screen.dart`, the `StreamBuilder` currently never calls `provider.setTransactions(...)`. The surrounding search/filter UI reads `provider.transactions` (empty). Add the same postFrameCallback pattern already used in `customer_list_screen.dart`.

4. **Bug 4 — Repoint the bottom-nav `/app/transactions` route at the polished history screen.** In `lib/router.dart` line 111, change the builder from `const TransactionListScreen()` to `const TransactionsScreen()`. The polished screen already has the summary header, date presets, type segment, category chips, and pagination; the legacy one is dead weight.

5. **Bug 5 (optional polish) — Eliminate the brief "No customers yet" flicker on the customer list.** In `lib/features/customers/customer_list_screen.dart`, replace the StreamBuilder-with-postFrameCallback with a `StreamSubscription` started in `initState` so `setCustomers` runs once per snapshot instead of being scheduled from inside a builder. Skip if scope is "critical only".

6. **Verification — run `flutter analyze` + manual smoke test.** Add a transaction, edit it, confirm the history list still renders. Add a customer, confirm the list populates without flicker. Record a payment, confirm the dashboard's Customer Due tile updates.

**Relevant files**
- `lib/features/transactions/add_edit_transaction_screen.dart` — add Firestore import, wrap date as Timestamp.
- `lib/models/transaction.dart` — add `static DateTime readDate(Object?)` and replace 3 casts.
- `lib/models/customer.dart` — same helper applied to `createdAt` / `updatedAt`.
- `lib/models/customer_payment.dart` — same helper applied to `date` / `createdAt`.
- `lib/features/transactions/transaction_list_screen.dart` — push stream snapshots into `TransactionProvider.setTransactions`.
- `lib/router.dart` — repoint `/app/transactions` to `TransactionsScreen`.
- `lib/features/customers/customer_list_screen.dart` — (optional) use `StreamSubscription` in `initState` to remove flicker.

**Diagrams**

```mermaid
flowchart LR
  A["Edit Transaction form (legacy)"] -->|"'date': _date"| B["Firestore doc.update"]
  B --> C["Doc stored as raw DateTime"]
  C --> D["streamTransactions snapshot"]
  D --> E["TransactionModel.fromFirestore"]
  E -->|"(data['date'] as Timestamp) throws"| F["Stream emits error"]
  F --> G["AppErrorWidget on every list"]
  H["Dashboard tiles"] -. depends on .- D

  X["Router /app/transactions"] -.->|"Bug 4: was TransactionListScreen"| Y["Legacy list (empty search/filter)"]
  X -.->|"Fixed: TransactionsScreen"| Z["Polished history"]
```

```mermaid
sequenceDiagram
  participant U as User
  participant Form as AddEditTransactionScreen
  participant Prov as TransactionProvider
  participant FS as Firestore
  participant List as TransactionListScreen
  U->>Form: edits date + amount
  Form->>Prov: updateTransaction(...)
  Prov->>FS: doc.update({'date': _date})  // raw DateTime
  FS-->>List: stream snapshot (broken)
  List->>List: fromFirestore TypeError
  List-->>U: "Failed to load" / empty
  Note over Prov: setTransactions never called →<br/>search/filter stays empty
```

**Verification**
1. `flutter analyze` → zero new issues.
2. Manual: add a transaction via the polished screen → appears in History within one second.
3. Manual: edit a transaction's date in the legacy screen → list still renders, no error overlay.
4. Manual: add a customer → list populates, no flicker, due tile stays accurate.
5. Manual: record a payment → dashboard "Customer Due" tile reflects the new balance.
