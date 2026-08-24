import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String userId;
  final String businessId;
  final TransactionType type;
  final double amount;
  final String category;
  final DateTime date;
  final String paymentMethod;
  final String? customerId;
  final String? supplierId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.businessId,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod = 'Cash',
    this.customerId,
    this.supplierId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      businessId: data['businessId'] ?? '',
      type: data['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      date: readDate(data['date']),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      customerId: data['customerId'],
      supplierId: data['supplierId'],
      note: data['note'],
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }

  /// Defensive coercion of mixed-type date fields. Legacy docs may have been
  /// written as raw `DateTime`, ISO strings, or epoch millis before the
  /// `Timestamp.fromDate` contract was enforced. Falls back to `DateTime.now()`
  /// when the value is missing or unparseable so a single bad document cannot
  /// poison the entire collection stream.
  static DateTime readDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessId': businessId,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'customerId': customerId,
      'supplierId': supplierId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? businessId,
    TransactionType? type,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? customerId,
    String? supplierId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: customerId ?? this.customerId,
      supplierId: supplierId ?? this.supplierId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Income-side categories. Kept as a `const` list so the form dropdown can
  /// reference it without rebuilding per-render.
  static const List<String> incomeCategories = [
    'Sales',
    'Service',
    'Other Income',
    'Customer Payment',
  ];

  /// Expense-side categories (not surfaced in the income flow but kept on
  /// the model so the same enum drives expense work later). 'Supplier
  /// Payment' sits in position 2 because it's the canonical way to mark a
  /// cash outflow that settles an outstanding supplier purchase.
  static const List<String> expenseCategories = [
    'Purchase',
    'Supplier Payment',
    'Rent',
    'Salary',
    'Transport',
    'Utilities',
    'Marketing',
    'Packaging',
    'Internet',
    'Other',
  ];

  /// Canonical category for income rows that record money received against
  /// an outstanding customer due. Mirrors 'Supplier Payment' on the
  /// expense side. Defined here (not in the public list above) because it
  /// is only ever emitted by the Record Payment flow, never picked from a
  /// user dropdown.
  static const String customerPaymentCategory = 'Customer Payment';

  /// Canonical category for expense rows that record money paid back to a
  /// supplier to settle an outstanding purchase due.
  static const String supplierPaymentCategory = 'Supplier Payment';

  /// Payment method tag used for credit sales / purchases. Attaching a
  /// customer (or supplier) + category Sales (or Purchase) + paymentMethod
  /// Due is what causes the customer's (or supplier's) outstanding due to
  /// increase. Cash sales that happen to involve a known customer do not
  /// affect the due.
  static const String duePaymentMethod = 'Due';

  /// Payment methods shown in both income and expense forms.
  /// Order matters:
  ///   * The first entry ('Cash') is the default selection for non-credit
  ///     flows.
  ///   * 'Due' sits in position 2 so it's discoverable next to 'Cash' but
  ///     the default remains unchanged for regular income/expense forms.
  ///   * The Record Payment flows further filter this list to hide 'Due'
  ///     because payments cannot themselves be on due.
  static const List<String> paymentMethods = [
    'Cash',
    'Due',
    'Bank',
    'bKash',
    'Nagad',
    'Card',
    'Other',
  ];

  /// Payment methods that are valid for recording an actual payment that
  /// settles a due balance. Excludes 'Due' because a payment cannot be
  /// on-due itself.
  static const List<String> paymentMethodOptionsExcludingDue = [
    'Cash',
    'Bank',
    'bKash',
    'Nagad',
    'Card',
    'Other',
  ];
}
