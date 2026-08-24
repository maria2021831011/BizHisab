import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/customer_payment.dart';
import '../repositories/customer_repository.dart';

/// Sorting options exposed to the customer list UI.
enum CustomerSort { nameAsc, dueDesc, recent }

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository;

  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _searchQuery;
  CustomerSort _sort = CustomerSort.nameAsc;

  // ---------------------------------------------------------------------------
  // Selectors
  // ---------------------------------------------------------------------------
  List<Customer> get customers => _applySort(_applyFilter(_customers));
  List<Customer> get allCustomers => _customers;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  CustomerSort get sort => _sort;

  List<Customer> _applyFilter(List<Customer> input) {
    if (_searchQuery == null || _searchQuery!.isEmpty) return input;
    final query = _searchQuery!.toLowerCase();
    return input
        .where((c) =>
            c.name.toLowerCase().contains(query) ||
            c.phone.contains(query))
        .toList();
  }

  List<Customer> _applySort(List<Customer> input) {
    final list = List<Customer>.from(input);
    switch (_sort) {
      case CustomerSort.nameAsc:
        list.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case CustomerSort.dueDesc:
        list.sort((a, b) {
          if (a.totalDue > 0 && b.totalDue <= 0) return -1;
          if (a.totalDue <= 0 && b.totalDue > 0) return 1;
          final byDue = b.totalDue.compareTo(a.totalDue);
          if (byDue != 0) return byDue;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case CustomerSort.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    return list;
  }

  /// Sum of every customer's outstanding balance. Matches the dashboard
  /// tile so the list screen can show the same number the user sees on
  /// the dashboard.
  double get totalDue =>
      _customers.fold(0, (sum, c) => sum + (c.totalDue > 0 ? c.totalDue : 0));

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  CustomerProvider({CustomerRepository? repository})
      : _repository = repository ?? CustomerRepository();

  // ---------------------------------------------------------------------------
  // Streams + setters
  // ---------------------------------------------------------------------------
  Stream<List<Customer>> watchCustomers(String businessId) {
    return _repository.streamCustomers(businessId);
  }

  Stream<List<CustomerPayment>> watchPayments({
    required String businessId,
    required String customerId,
  }) {
    return _repository.streamPayments(
      businessId: businessId,
      customerId: customerId,
    );
  }

  void setCustomers(List<Customer> customers) {
    _customers = customers;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(CustomerSort sort) {
    _sort = sort;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------
  Future<String?> addCustomer(Customer customer) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      final id = await _repository.addCustomer(customer);
      return id;
    } catch (e) {
      _errorMessage = 'Failed to add customer: ${e.toString()}';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateCustomer(
      String businessId, String customerId, Map<String, dynamic> data) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.updateCustomer(businessId, customerId, data);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update customer: ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCustomer(String businessId, String customerId) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteCustomer(businessId, customerId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete customer: ${e.toString()}';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Records a payment against [customerId] atomically (bumps totalPaid +
  /// writes linked income transaction + writes a payment-history doc).
  ///
  /// Returns the new payment id on success, or `null` on failure (the
  /// human-readable error lives on [errorMessage]).
  Future<String?> recordPayment({
    required String customerId,
    required String businessId,
    required String userId,
    required double amount,
    required DateTime date,
    required String paymentMethod,
    String? note,
  }) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      final paymentId = await _repository.recordPayment(
        customerId: customerId,
        businessId: businessId,
        userId: userId,
        amount: amount,
        date: date,
        paymentMethod: paymentMethod,
        note: note,
      );
      return paymentId;
    } catch (e) {
      _errorMessage = 'Failed to record payment: ${e.toString()}';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
