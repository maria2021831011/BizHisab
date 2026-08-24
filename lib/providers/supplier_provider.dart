import 'package:flutter/foundation.dart';

import '../models/supplier.dart';
import '../models/supplier_payment.dart';
import '../repositories/supplier_repository.dart';

/// Sorting options exposed to the supplier list UI.
enum SupplierSort { nameAsc, dueDesc, recent }

class SupplierProvider extends ChangeNotifier {
  final SupplierRepository _repository;

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _searchQuery;
  SupplierSort _sort = SupplierSort.nameAsc;

  // ---------------------------------------------------------------------------
  // Selectors
  // ---------------------------------------------------------------------------
  List<Supplier> get suppliers => _applySort(_applyFilter(_suppliers));
  List<Supplier> get allSuppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;
  SupplierSort get sort => _sort;

  List<Supplier> _applyFilter(List<Supplier> input) {
    if (_searchQuery == null || _searchQuery!.isEmpty) return input;
    final query = _searchQuery!.toLowerCase();
    return input
        .where((s) =>
            s.name.toLowerCase().contains(query) ||
            s.phone.toLowerCase().contains(query) ||
            s.address.toLowerCase().contains(query))
        .toList();
  }

  List<Supplier> _applySort(List<Supplier> input) {
    final list = List<Supplier>.from(input);
    switch (_sort) {
      case SupplierSort.nameAsc:
        list.sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SupplierSort.dueDesc:
        list.sort((a, b) {
          if (a.totalDue > 0 && b.totalDue <= 0) return -1;
          if (a.totalDue <= 0 && b.totalDue > 0) return 1;
          final byDue = b.totalDue.compareTo(a.totalDue);
          if (byDue != 0) return byDue;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
      case SupplierSort.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    return list;
  }

  /// Sum of every supplier's outstanding balance. Matches the dashboard tile
  /// so the list screen can show the same number the user sees on the
  /// dashboard.
  double get totalDue =>
      _suppliers.fold(0, (sum, s) => sum + (s.totalDue > 0 ? s.totalDue : 0));

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------
  SupplierProvider({SupplierRepository? repository})
      : _repository = repository ?? SupplierRepository();

  // ---------------------------------------------------------------------------
  // Streams + setters
  // ---------------------------------------------------------------------------
  Stream<List<Supplier>> watchSuppliers(String businessId) {
    return _repository.streamSuppliers(businessId);
  }

  Stream<List<SupplierPayment>> watchPayments({
    required String businessId,
    required String supplierId,
  }) {
    return _repository.streamSupplierPayments(businessId, supplierId);
  }

  void setSuppliers(List<Supplier> suppliers) {
    _suppliers = suppliers;
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

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(SupplierSort sort) {
    _sort = sort;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------
  Future<String?> addSupplier(Supplier supplier) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      final id = await _repository.addSupplier(supplier);
      _isSubmitting = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to add supplier: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSupplier(
      String businessId, String supplierId, Map<String, dynamic> data) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.updateSupplier(businessId, supplierId, data);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to update supplier: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(String businessId, String supplierId) async {
    try {
      _isSubmitting = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteSupplier(businessId, supplierId);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to delete supplier: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delegate atomic payment write-through to the repository. Returns the
  /// new payment id on success, `null` on failure (caller surfaces the
  /// `errorMessage`).
  Future<String?> recordPayment({
    required String supplierId,
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
        supplierId: supplierId,
        businessId: businessId,
        userId: userId,
        amount: amount,
        date: date,
        paymentMethod: paymentMethod,
        note: note,
      );
      _isSubmitting = false;
      notifyListeners();
      return paymentId;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to record supplier payment: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
}
