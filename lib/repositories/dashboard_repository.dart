import '../models/business.dart';
import '../models/transaction.dart';
import 'business_repository.dart';
import 'customer_repository.dart';
import 'supplier_repository.dart';
import 'transaction_repository.dart';

/// Thin pass-through layer that aggregates all dashboard-related queries.
///
/// The dashboard needs four things from the data layer:
///   * The [Business] document (for the greeting header)
///   * All transactions for the current month (for monthly totals and the
///     "Recent Transactions" list — the list is a sub-slice of the same
///     already-fetched set, so we don't pay for a second round-trip).
///   * Total customer due (sum of customer.totalDue across the business)
///   * Total supplier due (sum of supplier.totalDue across the business)
///
/// All four queries are scoped to the authenticated user's [businessId].
class DashboardRepository {
  final BusinessRepository _businessRepository;
  final TransactionRepository _transactionRepository;
  final CustomerRepository _customerRepository;
  final SupplierRepository _supplierRepository;

  DashboardRepository({
    BusinessRepository? businessRepository,
    TransactionRepository? transactionRepository,
    CustomerRepository? customerRepository,
    SupplierRepository? supplierRepository,
  })  : _businessRepository =
            businessRepository ?? BusinessRepository(),
        _transactionRepository =
            transactionRepository ?? TransactionRepository(),
        _customerRepository =
            customerRepository ?? CustomerRepository(),
        _supplierRepository =
            supplierRepository ?? SupplierRepository();

  Future<Business?> getBusiness(String businessId) {
    return _businessRepository.getBusiness(businessId);
  }

  /// Returns every transaction whose [TransactionModel.date] falls inside
  /// the inclusive range `[start, end]`. Bounded by both bounds so we never
  /// accidentally include next month's data when computing "current month".
  Future<List<TransactionModel>> getTransactionsInRange(
    String businessId, {
    required DateTime start,
    required DateTime end,
  }) {
    return _transactionRepository.getTransactions(
      businessId,
      startDate: start,
      endDate: end,
    );
  }

  Future<double> getTotalCustomerDue(String businessId) {
    return _customerRepository.getTotalCustomerDue(businessId);
  }

  Future<double> getTotalSupplierDue(String businessId) {
    return _supplierRepository.getTotalSupplierDue(businessId);
  }
}