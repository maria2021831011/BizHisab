class BdAppsEndpoints {
  BdAppsEndpoints._();

  // BizHisab has its own BdApps subfolder registered separately from BloodMate.
  static const String baseUrl = 'https://bdappsdigitalapps.com/NADB26137/BizHisab';
  static const String sendOtp = '$baseUrl/send_otp.php';
  static const String verifyOtp = '$baseUrl/verify_otp.php';
  static const String checkSubscription = '$baseUrl/check_subscription.php';
  static const String unsubscribe = '$baseUrl/unsubscribe.php';
}
