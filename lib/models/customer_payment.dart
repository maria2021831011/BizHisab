import 'package:cloud_firestore/cloud_firestore.dart';

/// A single payment received from a customer, stored as a sub-document under
/// `businesses/{businessId}/customers/{customerId}/payments/{paymentId}`.
///
/// `transactionId` links back to the income transaction written alongside
/// the payment so dashboards and the transaction history stay in sync.
class CustomerPayment {
  final String id;
  final String businessId;
  final String customerId;
  final String userId;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String? note;
  final String? transactionId;
  final DateTime createdAt;

  CustomerPayment({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.userId,
    required this.amount,
    required this.date,
    this.paymentMethod = 'Cash',
    this.note,
    this.transactionId,
    required this.createdAt,
  });

  factory CustomerPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerPayment(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      customerId: data['customerId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: readDate(data['date']),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      note: data['note'],
      transactionId: data['transactionId'],
      createdAt: readDate(data['createdAt']),
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
      'businessId': businessId,
      'customerId': customerId,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'note': note,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}