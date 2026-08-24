import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/supplier.dart';
import '../models/supplier_payment.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';

class SupplierRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SupplierRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<String> addSupplier(Supplier supplier) async {
    final docRef = await _firestore
        .collection(FirestorePaths.suppliers(supplier.businessId))
        .add(supplier.toMap());
    return docRef.id;
  }

  Future<void> updateSupplier(
      String businessId, String supplierId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestoreService.updateDocument(
      FirestorePaths.supplier(businessId, supplierId),
      data,
    );
  }

  Future<void> deleteSupplier(String businessId, String supplierId) async {
    await _firestoreService.deleteDocument(
      FirestorePaths.supplier(businessId, supplierId),
    );
  }

  Stream<List<Supplier>> streamSuppliers(String businessId) {
    return _firestoreService
        .streamCollection(
          FirestorePaths.suppliers(businessId),
          orderBy: 'name',
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => Supplier.fromFirestore(doc))
            .toList());
  }

  Future<List<Supplier>> searchSuppliers(
      String businessId, String query) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.suppliers(businessId))
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => Supplier.fromFirestore(doc))
        .toList();
  }

  Future<Supplier?> getSupplier(String businessId, String supplierId) async {
    final doc = await _firestore
        .collection(FirestorePaths.suppliers(businessId))
        .doc(supplierId)
        .get();
    if (!doc.exists) return null;
    return Supplier.fromFirestore(doc);
  }

  Future<double> getTotalSupplierDue(String businessId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.suppliers(businessId))
        .get();

    double totalDue = 0;
    for (final doc in snapshot.docs) {
      final supplier = Supplier.fromFirestore(doc);
      totalDue += supplier.totalDue;
    }
    return totalDue;
  }

  Stream<List<SupplierPayment>> streamSupplierPayments(
      String businessId, String supplierId) {
    return _firestoreService
        .streamCollection(
          FirestorePaths.supplierPayments(businessId, supplierId),
          orderBy: 'date',
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => SupplierPayment.fromFirestore(doc))
            .toList());
  }

  /// Records a supplier payment atomically.
  ///
  /// Three writes happen inside a Firestore transaction so the supplier
  /// ledger never gets out of sync with the expense transaction:
  ///   1. Increments `suppliers/{supplierId}.totalPaid` and bumps `updatedAt`.
  ///   2. Creates an `expense` TransactionModel tagged `Supplier Payment`
  ///      (this is the cash outflow — money we pay back to settle a supplier
  ///      purchase). It carries `supplierId` so the report layer can group
  ///      supplier payments correctly.
  ///   3. Inserts a `suppliers/{supplierId}/payments/{paymentId}` doc for the
  ///      payment-history stream, with `transactionId` linked back to the
  ///      expense transaction.
  ///
  /// Returns the new payment id.
  Future<String> recordPayment({
    required String supplierId,
    required String businessId,
    required String userId,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? note,
  }) async {
    final supplierRef = _firestore
        .collection(FirestorePaths.suppliers(businessId))
        .doc(supplierId);
    final transactionRef = _firestore
        .collection(FirestorePaths.transactions(businessId))
        .doc();
    final paymentRef = _firestore
        .collection(FirestorePaths.supplierPayments(businessId, supplierId))
        .doc();

    final transaction = TransactionModel(
      id: transactionRef.id,
      businessId: businessId,
      userId: userId,
      type: TransactionType.expense,
      amount: amount,
      category: 'Supplier Payment',
      date: date,
      paymentMethod: paymentMethod,
      note: note ?? '',
      supplierId: supplierId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final payment = SupplierPayment(
      id: paymentRef.id,
      businessId: businessId,
      supplierId: supplierId,
      userId: userId,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      note: note ?? '',
      transactionId: transactionRef.id,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((txn) async {
      final supplierSnap = await txn.get(supplierRef);
      if (!supplierSnap.exists) {
        throw StateError('Supplier not found');
      }

      final supplierData = supplierSnap.data();
      if (supplierData == null) {
        throw StateError('Supplier has no data');
      }
      final currentTotalPaid =
          (supplierData['totalPaid'] ?? 0).toDouble();

      txn.update(supplierRef, {
        'totalPaid': currentTotalPaid + amount,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      txn.set(transactionRef, transaction.toMap());
      txn.set(paymentRef, payment.toMap());
    });

    return paymentRef.id;
  }
}
