import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../providers/auth_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final List<TextEditingController> _otpCtrls =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _otpNodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _isOtpStage = false;
  bool _isSending = false;
  bool _isVerifying = false;
  bool _autoVerifying = false;
  bool _isCheckingDirect = false;
  int _secondsLeft = 0;

  @override
  void dispose() {
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _otpCtrls.map((c) => c.text).join();

  Future<void> _startSubscription() async {
    setState(() => _isSending = true);
    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.sendSubscriptionOtp();
    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) {
      if (authProvider.state == AuthState.authenticated) {
        _routeAfterSubscribe(authProvider);
        return;
      }
      setState(() => _isOtpStage = true);
      _startResendTimer();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _otpNodes.first.requestFocus(),
      );
    }
  }

  void _startResendTimer() {
    setState(() => _secondsLeft = _resendSeconds);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _secondsLeft--);
      return mounted && _secondsLeft > 0 && _isOtpStage;
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= _otpLength) {
        for (int i = 0; i < _otpLength; i++) {
          _otpCtrls[i].text = digits[i];
        }
        _otpNodes.last.unfocus();
        _verifySubscriptionOtp();
        return;
      } else if (digits.isNotEmpty) {
        _otpCtrls[index].text = digits[0];
      }
    }
    if (value.isNotEmpty && index < _otpLength - 1) {
      _otpNodes[index + 1].requestFocus();
    }
    if (_code.length == _otpLength) {
      _verifySubscriptionOtp();
    }
    setState(() {});
  }

  Future<void> _verifySubscriptionOtp() async {
    if (_autoVerifying || _isVerifying) return;
    final code = _code;
    if (code.length != _otpLength) return;
    _autoVerifying = true;
    setState(() => _isVerifying = true);

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.verifySubscriptionOtp(code);

    _autoVerifying = false;
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (ok) {
      _routeAfterSubscribe(authProvider);
    } else {
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpNodes.first.requestFocus();
      setState(() {});
    }
  }

  Future<void> _resend() async {
    final l = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    setState(() => _isSending = true);
    final ok = await authProvider.sendSubscriptionOtp();
    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) {
      for (final c in _otpCtrls) {
        c.clear();
      }
      _otpNodes.first.requestFocus();
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.subscriptionResent),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Escape hatch: when the operator has charged the user but no OTP
  /// SMS arrived (BdApps de-duplicates within a session), ask the
  /// server directly whether the subscription is active. If it is,
  /// route the user straight to the dashboard.
  Future<void> _verifyDirectly() async {
    final l = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    setState(() => _isCheckingDirect = true);
    final ok = await authProvider.refreshSubscriptionStatus();
    if (!mounted) return;
    setState(() => _isCheckingDirect = false);
    if (ok) {
      _routeAfterSubscribe(authProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.subscriptionNotYetActive),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _routeAfterSubscribe(AuthProvider auth) {
    if (auth.hasBusiness) {
      context.go('/app/dashboard');
    } else {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final phone = authProvider.phoneNumber ?? '';
    final error = authProvider.errorMessage;

    return Scaffold(
      appBar: AppBar(title: Text(l.subscriptionTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(
                Icons.workspace_premium,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l.subscriptionBrand,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.subscriptionBlurb,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFeature(l.subscriptionFeatureTracking),
                      _buildFeature(l.subscriptionFeatureCustomers),
                      _buildFeature(l.subscriptionFeatureInsights),
                      _buildFeature(l.subscriptionFeatureReports),
                      _buildFeature(l.subscriptionFeatureChatbot),
                      _buildFeature(l.subscriptionFeatureCloud),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isOtpStage) ..._buildOtpSection(phone, error),
              if (!_isOtpStage) ..._buildSubscribeSection(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/auth/mobile'),
                child: Text(
                  l.authMobileChangeNumber,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSubscribeSection() {
    final l = AppLocalizations.of(context);
    return [
      AppButton(
        text: _isSending ? l.subscriptionSendingOtp : l.subscriptionSubscribe,
        isLoading: _isSending,
        onPressed: _isSending ? null : _startSubscription,
      ),
    ];
  }

  List<Widget> _buildOtpSection(String phone, String? error) {
    final l = AppLocalizations.of(context);
    return [
      Text(
        l.subscriptionEnterOtp,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        phone.isEmpty ? '' : l.authOtpSentTo(phone),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_otpLength, (i) {
          return SizedBox(
            width: 44,
            child: TextField(
              controller: _otpCtrls[i],
              focusNode: _otpNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (v) => _onOtpChanged(i, v),
            ),
          );
        }),
      ),
      const SizedBox(height: 12),
      if (error != null)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            error,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      const SizedBox(height: 12),
      AppButton(
        text: l.subscriptionConfirm,
        isLoading: _isVerifying,
        onPressed: _isVerifying ? null : _verifySubscriptionOtp,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: (_isVerifying || _isCheckingDirect) ? null : _verifyDirectly,
        icon: const Icon(Icons.verified_user_outlined, size: 18),
        label: Text(
          _isCheckingDirect
              ? l.subscriptionChecking
              : l.subscriptionAlreadyPaid,
          style: const TextStyle(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      const SizedBox(height: 4),
      Center(
        child: _secondsLeft > 0
            ? Text(
                l.subscriptionResendIn(_secondsLeft),
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
              )
            : TextButton(
                onPressed: _isSending ? null : _resend,
                child: Text(
                  _isSending ? l.subscriptionSendingOtp : l.subscriptionResendOtp,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    ];
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
