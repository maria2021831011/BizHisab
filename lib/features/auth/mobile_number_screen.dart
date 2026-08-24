import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../l10n/gen/app_localizations.dart';

class MobileNumberScreen extends StatefulWidget {
  const MobileNumberScreen({super.key});

  @override
  State<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends State<MobileNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _fieldError;
  bool _showFieldError = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_clearFieldErrorOnChange);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_clearFieldErrorOnChange);
    _phoneController.dispose();
    super.dispose();
  }

  void _clearFieldErrorOnChange() {
    if (_showFieldError) {
      setState(() {
        _showFieldError = false;
        _fieldError = null;
      });
    }
    // Also clear any API error already shown by AuthProvider
    final auth = context.read<AuthProvider>();
    if (auth.errorMessage != null) {
      auth.clearError();
    }
  }

  Future<void> _sendOtp() async {
    // Force-run validation so the user sees "Invalid number format"
    // right under the field, not just a SnackBar.
    _formKey.currentState!.validate();
    setState(() {
      _showFieldError = true;
      _fieldError = Validators.mobileNumber(_phoneController.text);
    });
    if (_fieldError != null) return;

    final phone = _phoneController.text.trim();
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.sendOtp(phone);

    if (!mounted) return;

    if (success) {
      // If BdApps reported alreadySubscribed OR the user is fully
      // authenticated, skip the OTP step and route them straight in.
      if (authProvider.isAuthenticated) {
        if (authProvider.hasBusiness) {
          context.go('/app/dashboard');
        } else {
          context.go('/setup');
        }
      } else {
        context.push('/auth/otp');
      }
    } else if (authProvider.errorMessage != null) {
      // Surface the server's error directly under the field as well,
      // so the user always sees the rejection reason next to the input.
      setState(() {
        _showFieldError = true;
        _fieldError = authProvider.errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.authMobileTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.phone_android,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l.authMobileHeadline,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l.authMobileSub,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _phoneController,
                  hint: '01XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text(
                      '+88 ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  validator: Validators.mobileNumber,
                  errorText: _showFieldError ? _fieldError : null,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                    _PhonePrefixFormatter(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.authMobileFormat,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return AppButton(
                      text: l.authMobileSendOtp,
                      isLoading: auth.state == AuthState.loading,
                      onPressed: _sendOtp,
                    );
                  },
                ),
                const SizedBox(height: 16),
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
      ),
    );
  }
}

/// Auto-prepend "0" if the user pastes / types a 10-digit local number
/// like "1712345678" so it becomes "01712345678" and matches the validator.
class _PhonePrefixFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    // If user typed 10 digits without a leading 0, add it.
    if (text.length == 10 && !text.startsWith('0')) {
      final fixed = '0$text';
      return TextEditingValue(
        text: fixed,
        selection: TextSelection.collapsed(offset: fixed.length),
      );
    }
    return newValue;
  }
}
