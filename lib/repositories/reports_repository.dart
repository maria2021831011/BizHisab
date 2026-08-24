import '../models/transaction.dart';
import 'customer_repository.dart';
import 'supplier_repository.dart';
import 'transaction_repository.dart';

/// Snapshot of all the inputs the Reports screen needs for one window.
///
/// Returned as a record so the provider can destructure cleanly and the
/// `Future.wait` calls below can run in parallel.
typedef ReportAggregateSource = ({
  List<TransactionModel> transactions,
  double customerDue,
  double supplierDue,
});

/// Thin wrapper that fetches the three streams the Reports screen depends on
/// (transactions in range, total customer outstanding, total supplier
/// outstanding) in parallel and hands them back to the provider.
///
/// Kept as a separate class so the screen → provider → repository → firestore
/// layering matches the existing Dashboard pattern.
class ReportsRepository {
  ReportsRepository({
    TransactionRepository? transactionRepository,
    CustomerRepository? customerRepository,
    SupplierRepository? supplierRepository,
  })  : _transactions = transactionRepository ?? TransactionRepository(),
        _customers = customerRepository ?? CustomerRepository(),
        _suppliers = supplierRepository ?? SupplierRepository();

  final TransactionRepository _transactions;
  final CustomerRepository _customers;
  final SupplierRepository _suppliers;

  /// Loads the raw inputs for one window. The provider then runs them through
  /// the pure [ReportAggregator] to build a [ReportData].
  Future<ReportAggregateSource> aggregate(
    String businessId, {
    required DateTime start,
    required DateTime end,
  }) {
    return Future.wait([
      _transactions.getTransactions(businessId,
          startDate: start, endDate: end),
      _customers.getTotalCustomerDue(businessId),
      _suppliers.getTotalSupplierDue(businessId),
    ]).then((results) {
      return (
        transactions: results[0] as List<TransactionModel>,
        customerDue: results[1] as double,
        supplierDue: results[2] as double,
      );
    });
  }
}