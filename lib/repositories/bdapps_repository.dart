import '../models/subscription_result.dart';
import '../services/bdapps_api_service.dart';

class BdAppsRepository {
  final BdAppsApiService _apiService;

  BdAppsRepository({BdAppsApiService? apiService})
      : _apiService = apiService ?? BdAppsApiService();

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    return await _apiService.sendOtp(phoneNumber);
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp, {
    required String referenceNo,
  }) async {
    return await _apiService.verifyOtp(
      phoneNumber,
      otp,
      referenceNo: referenceNo,
    );
  }

  Future<SubscriptionResult> checkSubscription(String phoneNumber) async {
    return await _apiService.checkSubscription(phoneNumber);
  }

  Future<Map<String, dynamic>> unsubscribe(String phoneNumber) async {
    return await _apiService.unsubscribe(phoneNumber);
  }
}
