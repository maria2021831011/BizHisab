class FirestorePaths {
  FirestorePaths._();

  static String user(String uid) => 'users/$uid';
  static String users() => 'users';

  static String business(String businessId) => 'businesses/$businessId';
  static String businesses() => 'businesses';

  static String transaction(String businessId, String transactionId) =>
      'businesses/$businessId/transactions/$transactionId';
  static String transactions(String businessId) =>
      'businesses/$businessId/transactions';

  static String customer(String businessId, String customerId) =>
      'businesses/$businessId/customers/$customerId';
  static String customers(String businessId) =>
      'businesses/$businessId/customers';

  static String customerPayments(String businessId, String customerId) =>
      'businesses/$businessId/customers/$customerId/payments';
  static String customerPayment(
          String businessId, String customerId, String paymentId) =>
      'businesses/$businessId/customers/$customerId/payments/$paymentId';

  static String supplier(String businessId, String supplierId) =>
      'businesses/$businessId/suppliers/$supplierId';
  static String suppliers(String businessId) =>
      'businesses/$businessId/suppliers';

  static String supplierPayments(String businessId, String supplierId) =>
      'businesses/$businessId/suppliers/$supplierId/payments';
  static String supplierPayment(
          String businessId, String supplierId, String paymentId) =>
      'businesses/$businessId/suppliers/$supplierId/payments/$paymentId';

  static String category(String businessId, String categoryId) =>
      'businesses/$businessId/categories/$categoryId';
  static String categories(String businessId) =>
      'businesses/$businessId/categories';

  static String aiInsight(String businessId, String insightId) =>
      'businesses/$businessId/ai_insights/$insightId';
  static String aiInsights(String businessId) =>
      'businesses/$businessId/ai_insights';
}
