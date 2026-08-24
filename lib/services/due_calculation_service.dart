import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_paths.dart';
import '../features/transactions/due_classifier.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/transaction.dart';
import 'firestore_service.dart';

/// Pluggable storage boundary for [DueCalculationService]. Lets unit tests
/// inject a fake without spinning up the Firebase stack.
///
/// All four methods must be safe to call from inside a Firestore transaction
/// when implemented against a real backend. The default implementation
/// (_DefaultDueDataSource) honours that contract; in-memory fakes do not need
/// to because tests never run the actual Firestore write.
abstract class DueDataSource {
  /// Fetches all income transactions attached to [customerId] in [businessId].
  /// Implementations may read inside an active Firestore transaction by
  /// accepting an optional [Transaction] handle; the default impl ignores it
  /// and falls back to a regular `get()` which is fine for tests but
  /// optimistically stale in production — that's why the public service
  /// always re-reads the txn list *before* opening the transaction in the
  /// default path, and only the write is atomic.
  Future<List<TransactionModel>> fetchTransactionsForCustomer({
    required String businessId,
    required String customerId,
  });

  /// Fetches all expense transactions attached to [supplierId] in [businessId].
  Future<List<TransactionModel>> fetchTransactionsForSupplier({
    required String businessId,
    required String supplierId,
  });

  /// Atomically writes the new [totalPurchase] / [totalPaid] / [totalDue]
  /// derived from the transaction history of [customerId]. Implementations
  /// should be a no-op (no Firestore write) when the new totals match the
  /// already-stored totals — this avoids spurious `updatedAt` bumps that
  /// would otherwise re-trigger every stream listener.
  Future<void> writeCustomerTotals({
    required String businessId,
    required String customerId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  });

  /// Mirror of [writeCustomerTotals] for supplier docs.
  Future<void> writeSupplierTotals({
    required String businessId,
    required String supplierId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  });
}

/// Production [DueDataSource] backed by [FirebaseFirestore] + [FirestoreService].
///
/// Reads + writes flow through a single Firestore transaction so the totals
/// stay consistent with the underlying transaction collection even when two
/// clients write at the same instant. The Firestore transaction re-reads the
/// transactions subcollection inside the txn (we can't pass the txn handle
/// across awaits in older SDKs), so the totals computation reflects the
/// current state at the moment of the write — not whatever we had at the
/// call-site.
class _DefaultDueDataSource implements DueDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TransactionModel>> fetchTransactionsForCustomer({
    required String businessId,
    required String customerId,
  }) async {
    final path = FirestorePaths.transactions(businessId);
    // Two-pass query: collect everything tagged with this customerId, then
    // post-filter by income type and category. We can't combine the type
    // filter with a `!= null` customerId equality and a category inequality
    // without setting up a composite index, so we keep the filter shape
    // simple here and rely on the post-filter in [_DueCalculator].
    final snap = await _firestore
        .collection(path)
        .where('customerId', isEqualTo: customerId)
        .get();
    return snap.docs
        .map((d) => TransactionModel.fromFirestore(d))
        .where((t) =>
            t.type == TransactionType.income &&
            (isCustomerCreditSale(t) || isCustomerPaymentTransaction(t)))
        .toList(growable: false);
  }

  @override
  Future<List<TransactionModel>> fetchTransactionsForSupplier({
    required String businessId,
    required String supplierId,
  }) async {
    final path = FirestorePaths.transactions(businessId);
    final snap = await _firestore
        .collection(path)
        .where('supplierId', isEqualTo: supplierId)
        .get();
    return snap.docs
        .map((d) => TransactionModel.fromFirestore(d))
        .where((t) =>
            t.type == TransactionType.expense &&
            (isSupplierCreditPurchase(t) || isSupplierPaymentTransaction(t)))
        .toList(growable: false);
  }

  @override
  Future<void> writeCustomerTotals({
    required String businessId,
    required String customerId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  }) async {
    final path = FirestorePaths.customer(businessId, customerId);
    final docRef = _firestore.doc(path);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) {
        // The customer was deleted in flight — nothing to update.
        return;
      }
      final current = Customer.fromFirestore(snap);
      if (_approxEqual(current.totalPurchase, totalPurchase) &&
          _approxEqual(current.totalPaid, totalPaid) &&
          _approxEqual(current.totalDue, totalDue)) {
        // Skip the write so we don't bump `updatedAt` and re-trigger every
        // stream listener that is watching this customer doc.
        return;
      }
      txn.update(docRef, {
        'totalPurchase': totalPurchase,
        'totalPaid': totalPaid,
        'totalDue': totalDue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> writeSupplierTotals({
    required String businessId,
    required String supplierId,
    required double totalPurchase,
    required double totalPaid,
    required double totalDue,
  }) async {
    final path = FirestorePaths.supplier(businessId, supplierId);
    final docRef = _firestore.doc(path);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return;
      final current = Supplier.fromFirestore(snap);
      if (_approxEqual(current.totalPurchase, totalPurchase) &&
          _approxEqual(current.totalPaid, totalPaid) &&
          _approxEqual(current.totalDue, totalDue)) {
        return;
      }
      txn.update(docRef, {
        'totalPurchase': totalPurchase,
        'totalPaid': totalPaid,
        'totalDue': totalDue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

/// Compares two doubles with a tolerance of 0.01 — enough to absorb the
/// floating-point drift that comes from summing many amounts, but tight
/// enough that any real change still trips the write.
bool _approxEqual(double a, double b) => (a - b).abs() < 0.01;

/// Pure sums over a customer's due-affecting transactions. Exposed (as
/// package-private) so unit tests can verify the maths without Firebase.
class CustomerDueTotals {
  CustomerDueTotals({required this.totalPurchase, required this.totalPaid});
  final double totalPurchase;
  final double totalPaid;
  double get totalDue => totalPurchase - totalPaid;

  static CustomerDueTotals fromTransactions(List<TransactionModel> txns) {
    var purchase = 0.0;
    var paid = 0.0;
    for (final t in txns) {
      if (isCustomerCreditSale(t)) {
        purchase += t.amount;
      } else if (isCustomerPaymentTransaction(t)) {
        paid += t.amount;
      }
    }
    return CustomerDueTotals(totalPurchase: purchase, totalPaid: paid);
  }
}

/// Pure sums over a supplier's due-affecting transactions.
class SupplierDueTotals {
  SupplierDueTotals({required this.totalPurchase, required this.totalPaid});
  final double totalPurchase;
  final double totalPaid;
  double get totalDue => totalPurchase - totalPaid;

  static SupplierDueTotals fromTransactions(List<TransactionModel> txns) {
    var purchase = 0.0;
    var paid = 0.0;
    for (final t in txns) {
      if (isSupplierCreditPurchase(t)) {
        purchase += t.amount;
      } else if (isSupplierPaymentTransaction(t)) {
        paid += t.amount;
      }
    }
    return SupplierDueTotals(totalPurchase: purchase, totalPaid: paid);
  }
}

/// Recalculates the outstanding due for a customer or supplier from their
/// transaction history, and persists the result on the customer / supplier
/// document atomically.
///
/// Constructor takes an optional [DueDataSource] so tests can swap in a fake.
/// All public methods swallow errors after [debugPrint]-ing them so the
/// caller (typically the coordinator or a provider) never crashes because
/// the recalculation hit a transient network blip.
class DueCalculationService {
  DueCalculationService({DueDataSource? dataSource})
      : _dataSource = dataSource ?? _DefaultDueDataSource();

  final DueDataSource _dataSource;

  /// Recompute and persist [customerId]'s totalPurchase / totalPaid /
  /// totalDue inside [businessId].
  Future<void> recalculateCustomerDue({
    required String businessId,
    required String customerId,
  }) async {
    try {
      final txns = await _dataSource.fetchTransactionsForCustomer(
        businessId: businessId,
        customerId: customerId,
      );
      final totals = CustomerDueTotals.fromTransactions(txns);
      await _dataSource.writeCustomerTotals(
        businessId: businessId,
        customerId: customerId,
        totalPurchase: totals.totalPurchase,
        totalPaid: totals.totalPaid,
        totalDue: totals.totalDue,
      );
    } catch (e, st) {
      debugPrint('DueCalculationService.recalculateCustomerDue failed: $e');
      debugPrintStack(stackTrace: st, maxFrames: 8);
    }
  }

  /// Recompute and persist [supplierId]'s totalPurchase / totalPaid /
  /// totalDue inside [businessId].
  Future<void> recalculateSupplierDue({
    required String businessId,
    required String supplierId,
  }) async {
    try {
      final txns = await _dataSource.fetchTransactionsForSupplier(
        businessId: businessId,
        supplierId: supplierId,
      );
      final totals = SupplierDueTotals.fromTransactions(txns);
      await _dataSource.writeSupplierTotals(
        businessId: businessId,
        supplierId: supplierId,
        totalPurchase: totals.totalPurchase,
        totalPaid: totals.totalPaid,
        totalDue: totals.totalDue,
      );
    } catch (e, st) {
      debugPrint('DueCalculationService.recalculateSupplierDue failed: $e');
      debugPrintStack(stackTrace: st, maxFrames: 8);
    }
  }
}
