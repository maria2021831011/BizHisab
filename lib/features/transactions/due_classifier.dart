/// Pure predicates that decide whether a given [TransactionModel] should
/// contribute to a customer's or supplier's outstanding due.
///
/// Kept as free functions (not a class) so they can be imported cheaply by
/// both the recalculation coordinator and the income/expense forms without
/// dragging in any Firebase dependency. Pure functions → trivially
/// unit-testable.
library;

import '../../models/transaction.dart';

/// Canonical category used for "money received from a customer to settle
/// their outstanding due". Duplicated on [TransactionModel] for callers
/// that don't want to depend on it; kept here so the classifier file has
/// no hidden string literals.
const String kCustomerPaymentCategory = 'Customer Payment';

/// Canonical category used for "money paid back to a supplier to settle
/// their outstanding due".
const String kSupplierPaymentCategory = 'Supplier Payment';

/// Canonical payment-method tag for credit transactions.
const String kDuePaymentMethod = 'Due';

/// Canonical category for a customer credit sale.
const String kSalesCategory = 'Sales';

/// Canonical category for a supplier credit purchase.
const String kPurchaseCategory = 'Purchase';

/// Returns true when [t] should increase or decrease a customer's
/// outstanding due.
///
/// Two shapes qualify:
///   * Credit sale: type=income, category='Sales', paymentMethod='Due',
///     customerId set. Increases due.
///   * Customer payment: type=income, category='Customer Payment',
///     customerId set. Decreases due.
///
/// Any cash sale that happens to have a customerId attached — i.e.
/// paymentMethod != 'Due' — does NOT touch the customer's due.
bool isCustomerDueAffecting(TransactionModel t) {
  if (t.customerId == null || t.customerId!.isEmpty) return false;
  if (t.type != TransactionType.income) return false;

  final isCreditSale = t.category == kSalesCategory &&
      t.paymentMethod == kDuePaymentMethod;
  final isPayment = t.category == kCustomerPaymentCategory;

  return isCreditSale || isPayment;
}

/// Returns true when [t] should increase or decrease a supplier's
/// outstanding due.
///
/// Mirror of [isCustomerDueAffecting] for the expense side:
///   * Credit purchase: type=expense, category='Purchase',
///     paymentMethod='Due', supplierId set. Increases due.
///   * Supplier payment: type=expense, category='Supplier Payment',
///     supplierId set. Decreases due.
bool isSupplierDueAffecting(TransactionModel t) {
  if (t.supplierId == null || t.supplierId!.isEmpty) return false;
  if (t.type != TransactionType.expense) return false;

  final isCreditPurchase = t.category == kPurchaseCategory &&
      t.paymentMethod == kDuePaymentMethod;
  final isPayment = t.category == kSupplierPaymentCategory;

  return isCreditPurchase || isPayment;
}

/// Returns true when [t] is an income row that should *increase* the
/// customer's due (a credit sale). Returns false for payments.
bool isCustomerCreditSale(TransactionModel t) {
  return t.customerId != null &&
      t.customerId!.isNotEmpty &&
      t.type == TransactionType.income &&
      t.category == kSalesCategory &&
      t.paymentMethod == kDuePaymentMethod;
}

/// Returns true when [t] is an expense row that should *increase* the
/// supplier's due (a credit purchase). Returns false for payments.
bool isSupplierCreditPurchase(TransactionModel t) {
  return t.supplierId != null &&
      t.supplierId!.isNotEmpty &&
      t.type == TransactionType.expense &&
      t.category == kPurchaseCategory &&
      t.paymentMethod == kDuePaymentMethod;
}

/// Returns true when [t] is an income row that should *decrease* the
/// customer's due (a customer payment).
bool isCustomerPaymentTransaction(TransactionModel t) {
  return t.customerId != null &&
      t.customerId!.isNotEmpty &&
      t.type == TransactionType.income &&
      t.category == kCustomerPaymentCategory;
}

/// Returns true when [t] is an expense row that should *decrease* the
/// supplier's due (a supplier payment).
bool isSupplierPaymentTransaction(TransactionModel t) {
  return t.supplierId != null &&
      t.supplierId!.isNotEmpty &&
      t.type == TransactionType.expense &&
      t.category == kSupplierPaymentCategory;
}
