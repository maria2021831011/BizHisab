import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/business.dart';
import '../services/firestore_service.dart';

class BusinessRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BusinessRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<Business?> getBusiness(String businessId) async {
    final doc =
        await _firestoreService.getDocument(FirestorePaths.business(businessId));
    if (doc.exists && doc.data() != null) {
      return Business.fromFirestore(doc);
    }
    return null;
  }

  Stream<Business?> streamBusiness(String businessId) {
    return _firestoreService
        .streamDocument(FirestorePaths.business(businessId))
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return Business.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<String> createBusiness(Business business) async {
    final docRef = await _firestore.collection('businesses').add(business.toMap());
    return docRef.id;
  }

  Future<void> updateBusiness(
      String businessId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestoreService.updateDocument(
      FirestorePaths.business(businessId),
      data,
    );
  }
}
