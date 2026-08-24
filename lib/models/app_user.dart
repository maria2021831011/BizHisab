import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String mobileNumber;
  final bool isSubscriptionActive;
  final DateTime? subscriptionExpiry;
  final String? businessId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.mobileNumber,
    this.isSubscriptionActive = false,
    this.subscriptionExpiry,
    this.businessId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      mobileNumber: data['mobileNumber'] ?? '',
      isSubscriptionActive: data['isSubscriptionActive'] ?? false,
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? (data['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      businessId: data['businessId'],
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
      'mobileNumber': mobileNumber,
      'isSubscriptionActive': isSubscriptionActive,
      'subscriptionExpiry':
          subscriptionExpiry != null ? Timestamp.fromDate(subscriptionExpiry!) : null,
      'businessId': businessId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUser copyWith({
    String? uid,
    String? mobileNumber,
    bool? isSubscriptionActive,
    DateTime? subscriptionExpiry,
    String? businessId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isSubscriptionActive: isSubscriptionActive ?? this.isSubscriptionActive,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
