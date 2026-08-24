import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';
import '../../l10n/gen/app_localizations.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  // Prevent double-fire when both the auto-advance callback and the
  // Verify button press call _verifyOtp() for the same digit.
  bool _autoVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    if (_autoVerifying) return;
    final l = AppLocalizations.of(context);
    final otp = _getOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.authOtpIncomplete),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _autoVerifying = true;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(otp);
    _autoVerifying = false;

    if (mounted) {
      if (success) {
        if (authProvider.state == AuthState.authenticated) {
          if (authProvider.hasBusiness) {
            context.go('/app/dashboard');
          } else {
            context.go('/setup');
          }
        } else if (authProvider.state == AuthState.subscriptionInactive) {
          context.go('/auth/subscription');
        } else if (authProvider.state == AuthState.settingUpBusiness) {
          context.go('/setup');
        }
      } else if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final phoneNumber = context.read<AuthProvider>().phoneNumber ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.authOtpTitle),
      ),
      // `resizeToAvoidBottomInset: true` is the default; we explicitly
      // make the body scrollable so the 6 OTP fields + verify button +
      // error banner never overflow when the soft keyboard is open.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  l.authOtpHeadline,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l.authOtpSentTo(phoneNumber),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildOtpFields(),
                const SizedBox(height: 20),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return AppButton(
                      text: l.authOtpVerify,
                      isLoading: auth.state == AuthState.otpVerifying,
                      onPressed: _verifyOtp,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l.authOtpRequestFirst,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (auth.otpResendCountdown > 0)
                          Text(
                            l.authOtpResendIn(auth.otpResendCountdown),
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          TextButton(
                            onPressed: auth.isOtpResending
                                ? null
                                : () async {
                                    final success = await auth.resendOtp();
                                    if (context.mounted && success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(l.authOtpResentSuccess),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              auth.isOtpResending
                                  ? l.authOtpSending
                                  : l.authOtpResend,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.errorMessage != null) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          auth.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }

              if (_getOtp().length == 6) {
                _verifyOtp();
              }
            },
          ),
        );
      }),
    );
  }
}
