import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  final String id;
  final String userId;
  final String name;
  final String businessType;
  final String ownerName;
  final String phone;
  final String address;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.userId,
    required this.name,
    required this.businessType,
    required this.ownerName,
    required this.phone,
    this.address = '',
    this.currency = 'BDT',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Business(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      businessType: data['businessType'] ?? '',
      ownerName: data['ownerName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      currency: data['currency'] ?? 'BDT',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'businessType': businessType,
      'ownerName': ownerName,
      'phone': phone,
      'address': address,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Business copyWith({
    String? id,
    String? userId,
    String? name,
    String? businessType,
    String? ownerName,
    String? phone,
    String? address,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
