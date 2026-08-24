import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setDocument(
      String path, Map<String, dynamic> data, {bool merge = true}) async {
    await _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(
      String path, Map<String, dynamic> data) async {
    await _firestore.doc(path).update(data);
  }

  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }

  Future<DocumentSnapshot> getDocument(String path) async {
    return await _firestore.doc(path).get();
  }

  Future<QuerySnapshot> getCollection(
    String path, {
    List<Query<Object Function(Object)>>? Function(Query<Object> q)? queryBuilder,
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    Query query = _firestore.collection(path);

    if (queryBuilder != null) {
      query = queryBuilder(query as Query<Object Function(Object)>) as Query;
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  Stream<DocumentSnapshot> streamDocument(String path) {
    return _firestore.doc(path).snapshots();
  }

  Stream<QuerySnapshot> streamCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(path);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  Future<QuerySnapshot> getCollectionWithFilters(
    String path, {
    required List<QueryFilter> filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore.collection(path);

    for (final filter in filters) {
      query = query.where(filter.field, isEqualTo: filter.value);
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  Future<void> batchWrite(List<BatchOperation> operations) async {
    final batch = _firestore.batch();
    for (final op in operations) {
      switch (op.type) {
        case BatchOperationType.set:
          batch.set(_firestore.doc(op.path), op.data!);
          break;
        case BatchOperationType.update:
          batch.update(_firestore.doc(op.path), op.data!);
          break;
        case BatchOperationType.delete:
          batch.delete(_firestore.doc(op.path));
          break;
      }
    }
    await batch.commit();
  }
}

class QueryFilter {
  final String field;
  final dynamic value;

  QueryFilter({required this.field, required this.value});
}

enum BatchOperationType { set, update, delete }

class BatchOperation {
  final BatchOperationType type;
  final String path;
  final Map<String, dynamic>? data;

  BatchOperation({required this.type, required this.path, this.data});
}
