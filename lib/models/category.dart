import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String businessId;
  final String name;
  final String type;
  final bool isCustom;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    this.isCustom = false,
    required this.createdAt,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      isCustom: data['isCustom'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'type': type,
      'isCustom': isCustom,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
