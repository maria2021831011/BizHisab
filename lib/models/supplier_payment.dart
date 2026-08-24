import 'package:cloud_firestore/cloud_firestore.dart';

/// One supplier payment, stored under
/// `businesses/{businessId}/suppliers/{supplierId}/payments/{paymentId}`
/// and linked back to the income `TransactionModel` recorded in the same
/// atomic write.
class SupplierPayment {
  final String id;
  final String businessId;
  final String supplierId;
  final String userId;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String note;
  final String transactionId;
  final DateTime createdAt;

  SupplierPayment({
    required this.id,
    required this.businessId,
    required this.supplierId,
    required this.userId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.note = '',
    required this.transactionId,
    required this.createdAt,
  });

  factory SupplierPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupplierPayment(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      supplierId: data['supplierId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: _readDate(data['date']),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      note: data['note'] ?? '',
      transactionId: data['transactionId'] ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'supplierId': supplierId,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'paymentMethod': paymentMethod,
      'note': note,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  SupplierPayment copyWith({
    String? id,
    String? businessId,
    String? supplierId,
    String? userId,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? note,
    String? transactionId,
    DateTime? createdAt,
  }) {
    return SupplierPayment(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      supplierId: supplierId ?? this.supplierId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get methodDisplayLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      case 'cheque':
        return 'Cheque';
      default:
        return paymentMethod.replaceAll('_', ' ');
    }
  }

  static DateTime _readDate(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.now();
  }
}
