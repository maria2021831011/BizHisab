import 'package:flutter/material.dart';
import '../models/business.dart';
import '../repositories/business_repository.dart';

/// Translates raw [Exception] / [Error] objects from the Firestore
/// stack into friendly English strings safe to show to the user.
String _userFacingError(Object error, String action) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('networkerror') ||
      raw.contains('failed host lookup') ||
      raw.contains('no address associated with hostname')) {
    return 'Network error. Please check your internet connection and try again.';
  }
  if (raw.contains('permission-denied') || raw.contains('permission_denied')) {
    return 'You do not have permission to $action this business.';
  }
  if (raw.contains('timeout')) {
    return 'The request timed out. Please try again.';
  }
  return 'Failed to $action. Please try again.';
}

class BusinessProvider extends ChangeNotifier {
  final BusinessRepository _repository;

  Business? _business;
  bool _isLoading = false;
  /// True while a **submit** is in flight (create / update). Lighter
  /// reads like [loadBusiness] keep the button enabled but set
  /// [isLoading] so skeleton states still work.
  bool _isSubmitting = false;
  String? _errorMessage;

  Business? get business => _business;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasBusiness => _business != null;

  BusinessProvider({BusinessRepository? repository})
      : _repository = repository ?? BusinessRepository();

  /// Clears the last error message. Call from screen-level Retry
  /// handlers so the user can retry without seeing the previous error.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadBusiness(String businessId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _business = await _repository.getBusiness(businessId);
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _userFacingError(e, 'load');
      notifyListeners();
    }
  }

  Stream<Business?> streamBusiness(String businessId) {
    return _repository.streamBusiness(businessId);
  }

  /// Creates a new business owned by [userId]. Returns the new
  /// Firestore document id, or `null` on failure (check
  /// [errorMessage] for the reason).
  ///
  /// Guarded by [_isSubmitting] so a rapid double-tap on the form
  /// button cannot create duplicate businesses.
  Future<String?> createBusiness({
    required String userId,
    required String name,
    required String businessType,
    required String ownerName,
    required String phone,
    String address = '',
    String currency = 'BDT',
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final business = Business(
        id: '',
        userId: userId,
        name: name,
        businessType: businessType,
        ownerName: ownerName,
        phone: phone,
        address: address,
        currency: currency,
        createdAt: now,
        updatedAt: now,
      );

      final businessId = await _repository.createBusiness(business);
      _business = business.copyWith(id: businessId);
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return businessId;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingError(e, 'create');
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing business document by id with a partial
  /// field map. Prefer the strongly-typed [updateBusinessModel] from
  /// the edit screen.
  Future<bool> updateBusiness(
      String businessId, Map<String, dynamic> data) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateBusiness(businessId, data);
      _business = await _repository.getBusiness(businessId);
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingError(e, 'update');
      notifyListeners();
      return false;
    }
  }

  /// Strongly-typed update path used by the profile edit screen.
  /// Performs an additional ownership check: refuses to update if
  /// the business being edited does not belong to [currentUserId].
  Future<bool> updateBusinessModel(
    Business updated, {
    required String currentUserId,
  }) async {
    if (_isSubmitting) return false;

    // Defence-in-depth: the repository will only succeed if Firestore
    // rules pass, but we double-check here to give a friendlier error.
    if (updated.userId != currentUserId) {
      _errorMessage = 'You can only edit your own business.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final patched = updated.copyWith(updatedAt: DateTime.now());
      await _repository.updateBusiness(
        patched.id,
        patched.toMap(),
      );
      _business = patched;
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _isLoading = false;
      _errorMessage = _userFacingError(e, 'update');
      notifyListeners();
      return false;
    }
  }
}
