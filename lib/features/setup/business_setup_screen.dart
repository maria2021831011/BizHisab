import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

/// First-run screen shown when a freshly-authenticated user has no
/// business yet. Saves a `businesses/{businessId}` document owned by
/// the Firebase Auth UID, links it back to the user, then redirects
/// to the dashboard.
class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedBusinessType = AppConstants.businessTypes.first;
  String _selectedCurrency = AppConstants.defaultCurrency;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _createBusiness() async {
    final l = AppLocalizations.of(context);
    final businessProvider = context.read<BusinessProvider>();
    if (businessProvider.isSubmitting) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.user?.uid;
    if (uid == null) {
      _showError(l.setupSessionExpired);
      return;
    }

    final businessId = await businessProvider.createBusiness(
      userId: uid,
      name: _nameController.text.trim(),
      businessType:
          _selectedBusinessType ?? AppConstants.businessTypes.first,
      ownerName: authProvider.user?.mobileNumber ?? '',
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      currency: _selectedCurrency,
    );

    if (!mounted) return;

    if (businessId != null) {
      await authProvider.completeBusinessSetup(businessId);
      if (!mounted) return;
      context.go('/app/dashboard');
    } else {
      _showError(
        businessProvider.errorMessage ?? l.setupSaveFailed,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 560 : double.infinity,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SetupHeader(),
                        const SizedBox(height: 24),
                        AppTextField(
                          label: l.setupBusinessName,
                          hint: l.setupBusinessNameHint,
                          controller: _nameController,
                          validator: Validators.businessName,
                          textCapitalization: TextCapitalization.words,
                          prefixIcon:
                              const Icon(Icons.store_mall_directory_outlined),
                        ),
                        const SizedBox(height: 16),
                        _BusinessTypeDropdown(
                          value: _selectedBusinessType,
                          onChanged: (v) =>
                              setState(() => _selectedBusinessType = v),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: l.setupPhoneOptional,
                          hint: l.setupPhoneHint,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.optionalPhone,
                          maxLength: 14,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: l.setupAddressOptional,
                          hint: l.setupAddressHint,
                          controller: _addressController,
                          textCapitalization: TextCapitalization.words,
                          maxLines: 2,
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 16),
                        _CurrencyDropdown(
                          value: _selectedCurrency,
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _selectedCurrency = v);
                          },
                        ),
                        const SizedBox(height: 32),
                        Consumer<BusinessProvider>(
                          builder: (context, biz, _) {
                            return AppButton(
                              text: l.setupSave,
                              isLoading: biz.isSubmitting,
                              onPressed: _createBusiness,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.setupPrivacyNote,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SetupHeader extends StatelessWidget {
  const _SetupHeader();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.business_center,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l.setupHeadline,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l.setupSub,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _BusinessTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _BusinessTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.setupBusinessType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: AppConstants.businessTypes
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t,
                  child: Text(t),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: (v) =>
              (v == null || v.isEmpty) ? l.setupBusinessTypeRequired : null,
        ),
      ],
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _CurrencyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.setupCurrency,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          items: AppConstants.currencies
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(_currencyLabel(c, l)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static String _currencyLabel(String code, AppLocalizations l) {
    switch (code) {
      case 'BDT':
        return l.currencyBdt;
      case 'USD':
        return l.currencyUsd;
      case 'INR':
        return l.currencyInr;
      case 'EUR':
        return l.currencyEur;
      default:
        return code;
    }
  }
}