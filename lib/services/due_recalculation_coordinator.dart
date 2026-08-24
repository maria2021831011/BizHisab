import 'package:flutter/foundation.dart';

import '../features/transactions/due_classifier.dart';
import '../models/transaction.dart';
import 'due_calculation_service.dart';

/// Decides which customer / supplier totals need to be recomputed after a
/// transaction is added, edited or deleted, and delegates the actual work to
/// [DueCalculationService].
///
/// The coordinator is intentionally a thin layer so the rules ("which
/// entities are affected by this transaction?") live in one place that's
/// easy to read and unit-test.
///
/// Rules:
///   * If [newTransaction] affects a customer's due, recalc that customer.
///   * If [newTransaction] affects a supplier's due, recalc that supplier.
///   * If [previousTransaction] is provided and points at a *different*
///     customer / supplier than the new one, recalc the previous entity too
///     (otherwise editing a row's customerId would leak balance from the old
///     customer to the new).
///   * If [previousTransaction] is null (insert path) the new-transaction
///     rules are sufficient.
///   * Errors from the underlying service are swallowed + logged so the
///     coordinator never throws back into the provider / form.
class DueRecalculationCoordinator {
  DueRecalculationCoordinator({DueCalculationService? service})
      : _service = service ?? DueCalculationService();

  final DueCalculationService _service;

  /// Recompute after a write (add or update). Pass [previousTransaction]
  /// when updating so we can fix up the previous customer/supplier if their
  /// id was removed or changed.
  Future<void> recompute({
    required TransactionModel newTransaction,
    TransactionModel? previousTransaction,
  }) async {
    try {
      // New-side recalcs.
      if (isCustomerDueAffecting(newTransaction) &&
          newTransaction.customerId != null) {
        await _service.recalculateCustomerDue(
          businessId: newTransaction.businessId,
          customerId: newTransaction.customerId!,
        );
      }
      if (isSupplierDueAffecting(newTransaction) &&
          newTransaction.supplierId != null) {
        await _service.recalculateSupplierDue(
          businessId: newTransaction.businessId,
          supplierId: newTransaction.supplierId!,
        );
      }

      // Previous-side recalcs (edit path only). Only when the previous
      // entity differs from the new one — otherwise we'd redundantly
      // recalc the same customer / supplier twice.
      if (previousTransaction != null) {
        final prevCustomerChanged =
            isCustomerDueAffecting(previousTransaction) &&
                previousTransaction.customerId != null &&
                previousTransaction.customerId != newTransaction.customerId;
        final prevSupplierChanged =
            isSupplierDueAffecting(previousTransaction) &&
                previousTransaction.supplierId != null &&
                previousTransaction.supplierId != newTransaction.supplierId;

        if (prevCustomerChanged) {
          await _service.recalculateCustomerDue(
            businessId: previousTransaction.businessId,
            customerId: previousTransaction.customerId!,
          );
        }
        if (prevSupplierChanged) {
          await _service.recalculateSupplierDue(
            businessId: previousTransaction.businessId,
            supplierId: previousTransaction.supplierId!,
          );
        }
      }
    } catch (e, st) {
      debugPrint('DueRecalculationCoordinator.recompute failed: $e');
      debugPrintStack(stackTrace: st, maxFrames: 8);
    }
  }

  /// Dedicated overload for deletes — there is no "new" transaction, only a
  /// removed one whose customer/supplier balance may have been inflated by
  /// the now-gone row.
  Future<void> recomputeAfterDelete(TransactionModel removed) async {
    try {
      if (isCustomerDueAffecting(removed) && removed.customerId != null) {
        await _service.recalculateCustomerDue(
          businessId: removed.businessId,
          customerId: removed.customerId!,
        );
      }
      if (isSupplierDueAffecting(removed) && removed.supplierId != null) {
        await _service.recalculateSupplierDue(
          businessId: removed.businessId,
          supplierId: removed.supplierId!,
        );
      }
    } catch (e, st) {
      debugPrint('DueRecalculationCoordinator.recomputeAfterDelete failed: $e');
      debugPrintStack(stackTrace: st, maxFrames: 8);
    }
  }

  /// Public passthrough so callers (e.g. the record-payment form) can force
  /// a single customer recalc without going through the full coordinator.
  Future<void> recomputeCustomer({
    required String businessId,
    required String customerId,
  }) =>
      _service.recalculateCustomerDue(
        businessId: businessId,
        customerId: customerId,
      );

  /// Public passthrough for supplier recalc.
  Future<void> recomputeSupplier({
    required String businessId,
    required String supplierId,
  }) =>
      _service.recalculateSupplierDue(
        businessId: businessId,
        supplierId: supplierId,
      );
}