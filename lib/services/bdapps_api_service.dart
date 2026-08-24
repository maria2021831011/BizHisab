import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/bdapps_endpoints.dart';
import '../core/utils/validators.dart';
import '../models/subscription_result.dart';

/// BdApps API integration for BizHisab AI.
///
/// IMPORTANT: This service is intentionally aligned with BloodMate's
/// working pattern (`lib/services/blood_api_service.dart` in the
/// `bloodmate/` sibling project). BloodMate's send_otp / verify_otp /
/// check_subscription / unsubscribe endpoints are known to accept:
///   - POST field name: `user_mobile`  (NOT `phone`)
///   - Value: raw `01XXXXXXXXX`        (NOT `880XXXXXXXXXX`)
///   - Content-Type: application/x-www-form-urlencoded
///
/// Sending these PHP scripts the wrong field name or the country-code
/// prefixed number is what produces the "Invalid number format" error
/// that BizHisab users saw before this alignment was done.
class BdAppsApiService {
  final http.Client _client;

  BdAppsApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Convert any of `01XXXXXXXXX` / `+8801XXXXXXXXX` / `8801XXXXXXXXX`
  /// into the canonical `01XXXXXXXXX` local form. The BdApps PHP scripts
  /// (per BloodMate) expect the local 11-digit form, not 880-prefixed.
  String _normalize(String phoneNumber) {
    return Validators.toLocalBdPhone(phoneNumber);
  }

  /// Shared POST helper so every endpoint uses the same headers and
  /// the same form encoding (matches BloodMate exactly).
  Future<http.Response> _postForm(
    Uri url,
    Map<String, String> fields,
  ) {
    return _client
        .post(
          url,
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: fields,
        )
        .timeout(const Duration(seconds: 30));
  }

  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    try {
      final response = await _postForm(
        Uri.parse(BdAppsEndpoints.sendOtp),
        {'user_mobile': _normalize(phoneNumber)},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['statusCode'] == 'S1000' ||
              (data['success'] == true),
          'message': data['statusDetail']?.toString() ??
              data['message']?.toString() ??
              '',
          'referenceNo': data['referenceNo']?.toString(),
          'statusCode': data['statusCode']?.toString(),
          'statusDetail': data['statusDetail']?.toString(),
          'alreadySubscribed': data['alreadySubscribed'] == true,
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  /// Calls verify_otp.php. **Requires** [referenceNo] returned from a
  /// prior successful sendOtp() call — BloodMate's working pattern.
  /// BizHisab's previous version omitted referenceNo and the server
  /// silently rejected every verification, which is why the user
  /// always saw "Invalid OTP" right after typing the code.
  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp, {
    required String referenceNo,
  }) async {
    try {
      final response = await _postForm(
        Uri.parse(BdAppsEndpoints.verifyOtp),
        {
          'user_mobile': _normalize(phoneNumber),
          'Otp': otp,
          'referenceNo': referenceNo,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statusCode = data['statusCode']?.toString();
        final subStatus =
            data['subscriptionStatus']?.toString().toUpperCase();
        return {
          'success': statusCode == 'S1000' || subStatus == 'REGISTERED',
          'message': data['statusDetail']?.toString() ??
              data['message']?.toString() ??
              '',
          'subscriptionStatus': subStatus,
          'statusCode': statusCode,
          'statusDetail': data['statusDetail']?.toString(),
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  Future<SubscriptionResult> checkSubscription(String phoneNumber) async {
    try {
      final response = await _postForm(
        Uri.parse(BdAppsEndpoints.checkSubscription),
        {'user_mobile': _normalize(phoneNumber)},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          final decoded = jsonDecode(response.body);
          data = decoded is Map<String, dynamic>
              ? decoded
              : <String, dynamic>{};
        } catch (_) {
          data = <String, dynamic>{};
        }
        // BdApps returns subscriptionStatus "REGISTERED" when active.
        // E1951 = "User Already UnRegistered" — server says NOT subscribed.
        final statusCode = data['statusCode']?.toString();
        final subStatus =
            data['subscriptionStatus']?.toString().toUpperCase();
        final detail = (data['statusDetail']?.toString() ?? '').toLowerCase();
        final isActive = subStatus == 'REGISTERED' ||
            data['is_active'] == true ||
            data['active'] == true;
        final isExplicitlyUnregistered = statusCode == 'E1951' ||
            detail.contains('already unregistered') ||
            detail.contains('not registered');
        return SubscriptionResult(
          success: true,
          isActive: isActive && !isExplicitlyUnregistered,
          message: data['statusDetail']?.toString() ??
              data['message']?.toString() ??
              '',
          expiryDate: data['subscriptionExpiry']?.toString() ??
              data['expiry_date']?.toString() ??
              data['expiry']?.toString(),
        );
      } else {
        return SubscriptionResult.failure(
            'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return SubscriptionResult.failure('Network error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> unsubscribe(String phoneNumber) async {
    try {
      final response = await _postForm(
        Uri.parse(BdAppsEndpoints.unsubscribe),
        {'user_mobile': _normalize(phoneNumber)},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': data['statusCode'] == 'S1000' ||
              (data['success'] == true),
          'message': data['statusDetail']?.toString() ??
              data['message']?.toString() ??
              '',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }
}
