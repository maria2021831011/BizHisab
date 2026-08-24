class SubscriptionResult {
  final bool success;
  final bool isActive;
  final String message;
  final String? expiryDate;
  final String? error;

  SubscriptionResult({
    required this.success,
    this.isActive = false,
    this.message = '',
    this.expiryDate,
    this.error,
  });

  factory SubscriptionResult.fromJson(Map<String, dynamic> json) {
    return SubscriptionResult(
      success: json['success'] ?? false,
      isActive: json['is_active'] ?? json['active'] ?? false,
      message: json['message'] ?? '',
      expiryDate: json['expiry_date'] ?? json['expiry'],
      error: json['error'],
    );
  }

  factory SubscriptionResult.failure(String error) {
    return SubscriptionResult(
      success: false,
      isActive: false,
      error: error,
    );
  }
}
