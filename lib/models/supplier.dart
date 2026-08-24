import 'package:cloud_firestore/cloud_firestore.dart';

class Supplier {
  final String id;
  final String businessId;
  final String userId;
  final String name;
  final String phone;
  final String address;
  final double totalPurchase;
  final double totalPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.name,
    this.phone = '',
    this.address = '',
    this.totalPurchase = 0,
    this.totalPaid = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalDue => totalPurchase - totalPaid;

  factory Supplier.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Supplier(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      totalPurchase: (data['totalPurchase'] ?? 0).toDouble(),
      totalPaid: (data['totalPaid'] ?? 0).toDouble(),
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
      'businessId': businessId,
      'userId': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'totalPurchase': totalPurchase,
      'totalPaid': totalPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Supplier copyWith({
    String? id,
    String? businessId,
    String? userId,
    String? name,
    String? phone,
    String? address,
    double? totalPurchase,
    double? totalPaid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      totalPaid: totalPaid ?? this.totalPaid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
