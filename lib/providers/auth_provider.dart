import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../repositories/bdapps_repository.dart';
import '../services/firebase_auth_service.dart';

enum AuthState {
  initial,
  loading,
  unauthenticated,
  otpSent,
  otpVerifying,
  subscriptionChecking,
  subscriptionInactive,
  authenticated,
  settingUpBusiness,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final UserRepository _userRepository;
  final BdAppsRepository _bdAppsRepository;

  AuthState _state = AuthState.initial;
  AppUser? _user;
  String? _phoneNumber;
  String? _errorMessage;
  bool _isOtpResending = false;
  int _otpResendCountdown = 0;
  Timer? _countdownTimer;
  // Reference number returned by send_otp.php. Must be passed back to
  // verify_otp.php — BloodMate proves the server rejects any verify
  // request that doesn't include this field.
  String? _referenceNo;

  AuthState get state => _state;
  AppUser? get user => _user;
  String? get phoneNumber => _phoneNumber;
  String? get errorMessage => _errorMessage;
  bool get isOtpResending => _isOtpResending;
  int get otpResendCountdown => _otpResendCountdown;
  String? get referenceNo => _referenceNo;
  bool get isAuthenticated =>
      _state == AuthState.authenticated && _user != null;
  bool get hasActiveSubscription =>
      _user?.isSubscriptionActive == true;
  bool get hasBusiness => _user?.businessId != null;

  AuthProvider({
    FirebaseAuthService? authService,
    UserRepository? userRepository,
    BdAppsRepository? bdAppsRepository,
  })  : _authService = authService ?? FirebaseAuthService(),
        _userRepository = userRepository ?? UserRepository(),
        _bdAppsRepository = bdAppsRepository ?? BdAppsRepository();

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final appUser = await _userRepository.getUser(user.uid);
        if (appUser != null) {
          _user = appUser;
          _phoneNumber = appUser.mobileNumber;

          if (appUser.isSubscriptionActive) {
            _state = AuthState.authenticated;
          } else {
            _state = AuthState.subscriptionInactive;
          }
        } else {
          _state = AuthState.unauthenticated;
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final savedPhone = prefs.getString('phone_number');
        if (savedPhone != null) {
          _phoneNumber = savedPhone;
        }
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = 'Initialization error: ${e.toString()}';
    }

    notifyListeners();
  }

  void setPhoneNumber(String phone) {
    _phoneNumber = phone;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _phoneNumber = phoneNumber;
    _referenceNo = null;
    notifyListeners();

    try {
      final result = await _bdAppsRepository.sendOtp(phoneNumber);

      if (result['success'] == true) {
        _referenceNo = result['referenceNo']?.toString();
        // Special case: BdApps reports "alreadySubscribed" so we can skip
        // the OTP step entirely (matches BloodMate's behavior).
        if (result['alreadySubscribed'] == true) {
          await _persistPhone(phoneNumber);
          return await _signInToFirebase();
        }
        _state = AuthState.otpSent;
        _startResendCountdown();
        notifyListeners();
        return true;
      } else {
        // Special case: server returned "already registered" (E1351)
        // before the first OTP expired (matches BloodMate's flow).
        final statusCode = result['statusCode']?.toString();
        final msg = (result['message']?.toString() ?? '').toLowerCase();
        final detail =
            (result['statusDetail']?.toString() ?? '').toLowerCase();
        if (statusCode == 'E1351' ||
            msg.contains('already registered') ||
            detail.contains('already registered')) {
          await _persistPhone(phoneNumber);
          return await _signInToFirebase();
        }
        _state = AuthState.unauthenticated;
        _errorMessage = result['message'] ?? 'Failed to send OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_referenceNo == null) {
      _errorMessage = 'Please request OTP first';
      notifyListeners();
      return false;
    }
    _state = AuthState.otpVerifying;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _bdAppsRepository.verifyOtp(
        _phoneNumber!,
        otp,
        referenceNo: _referenceNo!,
      );

      if (result['success'] == true) {
        _referenceNo = null;
        return await _handleOtpVerificationSuccess();
      } else {
        _state = AuthState.otpSent;
        _errorMessage = result['message'] ?? 'Invalid OTP';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.otpSent;
      _errorMessage = 'Verification failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _handleOtpVerificationSuccess() async {
    _state = AuthState.subscriptionChecking;
    notifyListeners();

    try {
      final subscriptionResult =
          await _bdAppsRepository.checkSubscription(_phoneNumber!);

      if (subscriptionResult.success && subscriptionResult.isActive) {
        return await _signInToFirebase();
      } else {
        _state = AuthState.subscriptionInactive;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.subscriptionInactive;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _signInToFirebase() async {
    try {
      final uid = await _authService.getUid();
      if (uid == null) {
        _errorMessage = 'Authentication failed';
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      var appUser = await _userRepository.getUser(uid);

      if (appUser == null) {
        appUser = AppUser(
          uid: uid,
          mobileNumber: _phoneNumber!,
          isSubscriptionActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _userRepository.createUser(appUser);
      } else {
        await _userRepository.updateUser(uid, {
          'isSubscriptionActive': true,
          'mobileNumber': _phoneNumber,
        });
        appUser = appUser.copyWith(
          isSubscriptionActive: true,
          mobileNumber: _phoneNumber,
        );
      }

      _user = appUser;

      await _persistPhone(_phoneNumber!);

      if (appUser.businessId == null) {
        _state = AuthState.settingUpBusiness;
      } else {
        _state = AuthState.authenticated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sign-in failed: ${e.toString()}';
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_number', phone);
  }

  Future<bool> refreshSubscriptionStatus() async {
    if (_phoneNumber == null) return false;

    try {
      final result =
          await _bdAppsRepository.checkSubscription(_phoneNumber!);
      if (result.success && _user != null) {
        await _userRepository.updateUser(_user!.uid, {
          'isSubscriptionActive': result.isActive,
          'subscriptionExpiry': result.expiryDate,
        });
        _user = _user!.copyWith(
          isSubscriptionActive: result.isActive,
        );
        notifyListeners();
        return result.isActive;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> completeBusinessSetup(String businessId) async {
    if (_user != null) {
      await _userRepository.linkBusinessToUser(_user!.uid, businessId);
      _user = _user!.copyWith(businessId: businessId);
      _state = AuthState.authenticated;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // LOGOUT-FIX (Phase 9):
    //
    // DO NOT call `_authService.signOut()` here. The Firestore security rule
    // for /users/{uid} is `request.auth.uid == uid`, so the previous-session
    // user document is only readable by the Firebase Auth UID that originally
    // created it. If we sign out of Firebase Auth, the next `getUid()` call
    // falls back to `signInAnonymously()` and mints a NEW anonymous UID.
    // That new UID then fails to find any existing user record, so the code
    // path below creates a brand-new `users/{newUid}` doc with no businessId
    // and no subscription — i.e. a duplicate account every time the user
    // logs out and logs back in.
    //
    // By keeping the Firebase Auth anonymous session alive across "logout",
    // the next sign-in reuses the SAME anonymous UID. `_signInToFirebase`
    // therefore finds the existing `users/{uid}` doc (with its businessId
    // and subscription state) and routes the user straight back to their
    // previous dashboard without any duplicate account/profile/business.
    //
    // We only clear the LOCAL in-memory provider state so the UI returns to
    // the unauthenticated landing flow.
    _user = null;
    _phoneNumber = null;
    _referenceNo = null;
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    _countdownTimer?.cancel();

    // Keep `phone_number` in SharedPreferences so the mobile-number screen
    // can pre-fill the last-used number — this is intentional UX behaviour
    // and does NOT touch Firebase Auth or Firestore, so it cannot create a
    // duplicate account.

    notifyListeners();
  }

  /// Real subscription flow (mirrors BloodMate's SubscriptionProvider).
  /// Sends subscription OTP, stores the resulting referenceNo, and
  /// later verifies it via [verifySubscriptionOtp].
  Future<bool> sendSubscriptionOtp() async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number missing. Please log in again.';
      notifyListeners();
      return false;
    }
    _state = AuthState.subscriptionChecking;
    _errorMessage = null;
    _referenceNo = null;
    notifyListeners();

    try {
      final result = await _bdAppsRepository.sendOtp(_phoneNumber!);

      // Fast-path #1: server explicitly says the user is already
      // subscribed (paid subscription confirmed by check_subscription
      // or by the same response). Skip OTP entirely.
      if (result['alreadySubscribed'] == true) {
        await _markSubscribed();
        return true;
      }

      if (result['success'] == true) {
        _referenceNo = result['referenceNo']?.toString();

        // Fast-path #2: the success response came back without a
        // referenceNo — this happens on BizHisab when BdApps
        // de-duplicates the SMS (it only sends one OTP per session
        // per number). The user's payment was already charged, so
        // we just need to check whether the server now considers
        // them subscribed. This is the case where money has been
        // deducted but no OTP arrives and the screen used to hang.
        if (_referenceNo == null || _referenceNo!.isEmpty) {
          try {
            final sub =
                await _bdAppsRepository.checkSubscription(_phoneNumber!);
            if (sub.success && sub.isActive) {
              await _markSubscribed();
              return true;
            }
          } catch (_) {
            // fall through to OTP screen
          }
        }

        _state = AuthState.subscriptionInactive;
        notifyListeners();
        return true;
      }
      final statusCode = result['statusCode']?.toString();
      final msg = (result['message']?.toString() ?? '').toLowerCase();
      final detail =
          (result['statusDetail']?.toString() ?? '').toLowerCase();
      if (statusCode == 'E1351' ||
          msg.contains('already registered') ||
          detail.contains('already registered')) {
        await _markSubscribed();
        return true;
      }
      _state = AuthState.subscriptionInactive;
      _errorMessage = result['message'] ?? 'Failed to start subscription';
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.subscriptionInactive;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifySubscriptionOtp(String otp) async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number missing.';
      notifyListeners();
      return false;
    }
    if (_referenceNo == null) {
      _errorMessage = 'Please request subscription OTP first';
      notifyListeners();
      return false;
    }
    _state = AuthState.subscriptionChecking;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _bdAppsRepository.verifyOtp(
        _phoneNumber!,
        otp,
        referenceNo: _referenceNo!,
      );
      if (result['success'] == true) {
        _referenceNo = null;
        await _markSubscribed();
        return true;
      }
      _state = AuthState.subscriptionInactive;
      _errorMessage = result['message'] ?? 'Invalid OTP';
      notifyListeners();
      return false;
    } catch (e) {
      _state = AuthState.subscriptionInactive;
      _errorMessage = 'Verification failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> _markSubscribed() async {
    if (_phoneNumber == null) return;
    await _persistPhone(_phoneNumber!);
    // Re-use the existing Firebase sign-in path so we end up in
    // the same authenticated state, with isSubscriptionActive = true.
    await _signInToFirebase();
  }

  /// Cancel the user's active BdApps subscription.
  ///
  /// Flow (mirrors BloodMate's unsubscribe path):
  ///   1. Require the user to currently be signed-in (we need a uid).
  ///   2. Call the existing `BdAppsRepository.unsubscribe(phoneNumber)`
  ///      API. The server returns `{success: bool, message: ...}`.
  ///   3. ONLY if the server confirms success (`success == true`),
  ///      flip `isSubscriptionActive` to false in:
  ///         - the in-memory `_user` (so the UI updates immediately),
  ///         - the persisted `users/{uid}` Firestore doc (so the user
  ///           is no longer treated as subscribed on the next login /
  ///           app start).
  ///      On failure, leave everything unchanged and surface the
  ///      server's message via `_errorMessage`.
  ///
  /// This method does NOT touch OTP, login, account creation, business
  /// setup, dashboard data, or any other auth flow. It is purely a
  /// subscription-status reversal.
  Future<bool> unsubscribe() async {
    if (_user == null || _phoneNumber == null) {
      _errorMessage =
          'You must be signed in to manage your subscription.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _bdAppsRepository.unsubscribe(_phoneNumber!);

      if (result['success'] == true) {
        // Server confirmed cancellation — now, and only now, update
        // local + persisted state so the user is no longer treated as
        // subscribed on the next login.
        await _userRepository.updateUser(_user!.uid, {
          'isSubscriptionActive': false,
          'subscriptionExpiry': null,
        });
        _user = _user!.copyWith(
          isSubscriptionActive: false,
          subscriptionExpiry: null,
        );
        notifyListeners();
        return true;
      }

      // Server reported failure — keep the user as subscribed and
      // surface the server's message so the UI can show it.
      _errorMessage = result['message']?.toString() ??
          'Unsubscribe failed. Please try again.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage =
          'Unsubscribe failed. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  void _startResendCountdown() {
    _otpResendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpResendCountdown > 0) {
        _otpResendCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> resendOtp() async {
    if (_otpResendCountdown > 0 || _phoneNumber == null) return false;

    _isOtpResending = true;
    notifyListeners();

    final result = await sendOtp(_phoneNumber!);
    _isOtpResending = false;
    notifyListeners();
    return result;
  }
}
