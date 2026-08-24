import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/customer.dart';
import '../models/customer_payment.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';

class CustomerRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CustomerRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<String> addCustomer(Customer customer) async {
    final docRef = await _firestore
        .collection(FirestorePaths.customers(customer.businessId))
        .add(customer.toMap());
    return docRef.id;
  }

  Future<void> updateCustomer(
      String businessId, String customerId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestoreService.updateDocument(
      FirestorePaths.customer(businessId, customerId),
      data,
    );
  }

  Future<void> deleteCustomer(String businessId, String customerId) async {
    await _firestoreService.deleteDocument(
      FirestorePaths.customer(businessId, customerId),
    );
  }

  Stream<List<Customer>> streamCustomers(String businessId) {
    return _firestoreService
        .streamCollection(
          FirestorePaths.customers(businessId),
          orderBy: 'name',
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromFirestore(doc))
            .toList());
  }

  Future<List<Customer>> searchCustomers(
      String businessId, String query) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.customers(businessId))
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => Customer.fromFirestore(doc))
        .toList();
  }

  Future<double> getTotalCustomerDue(String businessId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.customers(businessId))
        .get();

    double totalDue = 0;
    for (final doc in snapshot.docs) {
      final customer = Customer.fromFirestore(doc);
      totalDue += customer.totalDue;
    }
    return totalDue;
  }

  /// Records a payment received from [customerId].
  ///
  /// Three writes happen atomically inside a Firestore transaction so the
  /// customer ledger never gets out of sync with the income transaction:
  ///
  ///   1. Bumps `customers/{customerId}.totalPaid` (and `updatedAt`).
  ///   2. Inserts a new income `TransactionModel` (category 'Customer
  ///      Payment') so dashboards / reports see the cash inflow.
  ///   3. Inserts a `customers/{customerId}/payments/{paymentId}` doc for
  ///      per-customer payment history, with the transaction id linked back.
  ///
  /// Returns the new payment id (so callers can navigate or display it).
  Future<String> recordPayment({
    required String customerId,
    required String businessId,
    required String userId,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero');
    }

    final customerRef =
        _firestore.doc(FirestorePaths.customer(businessId, customerId));
    final transactionRef =
        _firestore.collection(FirestorePaths.transactions(businessId)).doc();
    final paymentRef = _firestore
        .collection(FirestorePaths.customerPayments(businessId, customerId))
        .doc();

    final now = DateTime.now();

    final transaction = TransactionModel(
      id: transactionRef.id,
      userId: userId,
      businessId: businessId,
      type: TransactionType.income,
      amount: amount,
      category: 'Customer Payment',
      date: date,
      paymentMethod: paymentMethod,
      customerId: customerId,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    final payment = CustomerPayment(
      id: paymentRef.id,
      businessId: businessId,
      customerId: customerId,
      userId: userId,
      amount: amount,
      date: date,
      paymentMethod: paymentMethod,
      note: note,
      transactionId: transactionRef.id,
      createdAt: now,
    );

    await _firestore.runTransaction((txn) async {
      final customerSnap = await txn.get(customerRef);
      if (!customerSnap.exists) {
        throw StateError('Customer not found');
      }
      final currentPaid =
          ((customerSnap.data() as Map<String, dynamic>)['totalPaid']
                  as num?)
              ?.toDouble() ??
              0;
      txn.update(customerRef, {
        'totalPaid': currentPaid + amount,
        'updatedAt': Timestamp.fromDate(now),
      });
      txn.set(transactionRef, transaction.toMap());
      txn.set(paymentRef, payment.toMap());
    });

    return paymentRef.id;
  }

  /// Streams every payment recorded against [customerId], newest first.
  Stream<List<CustomerPayment>> streamPayments({
    required String businessId,
    required String customerId,
  }) {
    return _firestoreService
        .streamCollection(
          FirestorePaths.customerPayments(businessId, customerId),
          orderBy: 'date',
          descending: true,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerPayment.fromFirestore(doc))
            .toList());
  }
}
