import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firestore_paths.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';

class TransactionRepository {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TransactionRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  Future<String> addTransaction(TransactionModel transaction) async {
    final docRef = await _firestore
        .collection(FirestorePaths.transactions(transaction.businessId))
        .add(transaction.toMap());
    return docRef.id;
  }

  Future<void> updateTransaction(
      String businessId, String transactionId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestoreService.updateDocument(
      FirestorePaths.transaction(businessId, transactionId),
      data,
    );
  }

  Future<void> deleteTransaction(String businessId, String transactionId) async {
    await _firestoreService.deleteDocument(
      FirestorePaths.transaction(businessId, transactionId),
    );
  }

  Future<TransactionModel?> getTransaction(
      String businessId, String transactionId) async {
    final doc = await _firestoreService.getDocument(
      FirestorePaths.transaction(businessId, transactionId),
    );
    if (doc.exists && doc.data() != null) {
      return TransactionModel.fromFirestore(doc);
    }
    return null;
  }

  Stream<List<TransactionModel>> streamTransactions(String businessId) {
    return _firestoreService
        .streamCollection(
          FirestorePaths.transactions(businessId),
          orderBy: 'date',
          descending: true,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }


  /// Streams transactions filtered by type (income or expense) under a business
  /// ordered by date descending. Used by [TransactionProvider.watchIncome]
  /// so the income list updates live without manual refresh.
  Stream<List<TransactionModel>> streamTransactionsByType(
    String businessId,
    TransactionType type,
  ) {
    return _firestoreService
        .streamCollection(
          FirestorePaths.transactions(businessId),
          orderBy: 'date',
          descending: true,
        )
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .where((t) => t.type == type)
            .toList());
  }

  /// Server-side paged query for the Transaction History screen.
  ///
  /// Applies the date range + optional type filter directly in Firestore so we
  /// never download rows outside the active window. Category filtering is
  /// intentionally kept client-side — the set of categories is small (a
  /// handful per business) and Firestore would otherwise need a composite
  /// index on `category + date`.
  ///
  /// Pagination uses [startAfterDocument] so successive pages only fetch the
  /// next slice, not the whole collection.
  Stream<List<TransactionModel>> streamTransactionsPaged({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
    int pageSize = 25,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _firestore
        .collection(FirestorePaths.transactions(businessId))
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (type != null) {
      // Apply type filter before orderBy/limit so the query plan stays valid.
      query = (query as Query<Map<String, dynamic>>)
          .where('type', isEqualTo: type == TransactionType.income ? 'income' : 'expense')
          .orderBy('date', descending: true)
          .limit(pageSize);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      final docs = snapshot.docs;
      return PageResult(
        items: docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList(),
        lastDocument: docs.isEmpty ? null : docs.last,
      );
    }).map((page) => page.items);
  }

  /// One-shot fetch for a page — used by [loadNextPage] so we can chain
  /// cursors without keeping a stream open between page loads.
  Future<PageResult> fetchTransactionsPage({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
    int pageSize = 25,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestorePaths.transactions(businessId))
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (type != null) {
      query = query.where(
        'type',
        isEqualTo: type == TransactionType.income ? 'income' : 'expense',
      );
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    return PageResult(
      items: docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList(),
      lastDocument: docs.isEmpty ? null : docs.last,
    );
  }

  /// Aggregated daily net flow for the visible window — used by the summary
  /// header so we can show income / expense totals without scanning the
  /// entire result set client-side. Sum is computed on the server via a
  /// separate small query for each type, capped at 1000 docs to stay safe.
  Future<({double totalIncome, double totalExpense, int count})>
      summarizeWindow({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final incomeSnap = await _firestore
        .collection(FirestorePaths.transactions(businessId))
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .where('type', isEqualTo: 'income')
        .limit(1000)
        .get();
    final expenseSnap = await _firestore
        .collection(FirestorePaths.transactions(businessId))
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .where('type', isEqualTo: 'expense')
        .limit(1000)
        .get();

    double income = 0;
    for (final d in incomeSnap.docs) {
      income += ((d.data()['amount'] as num?) ?? 0).toDouble();
    }
    double expense = 0;
    for (final d in expenseSnap.docs) {
      expense += ((d.data()['amount'] as num?) ?? 0).toDouble();
    }
    return (
      totalIncome: income,
      totalExpense: expense,
      count: incomeSnap.docs.length + expenseSnap.docs.length,
    );
  }

  Future<List<TransactionModel>> getTransactions(
    String businessId, {
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? category,
    int? limit,
  }) async {
    Query query = _firestore
        .collection(FirestorePaths.transactions(businessId));

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('date', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TransactionModel.fromFirestore(doc))
        .toList();
  }
}

/// Carrier for a single page result. Keeps the cursor (last document)
/// alongside the items so the provider can chain the next page without
/// re-querying.
class PageResult {
  final List<TransactionModel> items;
  final DocumentSnapshot? lastDocument;
  PageResult({required this.items, required this.lastDocument});
}

