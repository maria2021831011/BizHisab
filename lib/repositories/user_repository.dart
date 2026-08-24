import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/app_user.dart';
import '../services/firestore_service.dart';

class UserRepository {
  final FirestoreService _firestoreService;

  UserRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestoreService.getDocument(FirestorePaths.user(uid));
    if (doc.exists && doc.data() != null) {
      return AppUser.fromFirestore(doc);
    }
    return null;
  }

  Stream<AppUser?> streamUser(String uid) {
    return _firestoreService
        .streamDocument(FirestorePaths.user(uid))
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<void> createUser(AppUser user) async {
    await _firestoreService.setDocument(
      FirestorePaths.user(user.uid),
      user.toMap(),
    );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestoreService.updateDocument(
      FirestorePaths.user(uid),
      data,
    );
  }

  Future<void> linkBusinessToUser(String uid, String businessId) async {
    await _firestoreService.updateDocument(
      FirestorePaths.user(uid),
      {
        'businessId': businessId,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );
  }
}
