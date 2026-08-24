import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../models/business.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';

/// Edit an existing business document. Pre-fills the form from
/// [BusinessProvider.business]. On save, calls
/// [BusinessProvider.updateBusinessModel] which performs a defence-
/// in-depth ownership check before writing back to Firestore.
class BusinessProfileEditScreen extends StatefulWidget {
  const BusinessProfileEditScreen({super.key});

  @override
  State<BusinessProfileEditScreen> createState() =>
      _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState
    extends State<BusinessProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  String? _selectedBusinessType;
  String? _selectedCurrency;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  void _hydrateFrom(Business b) {
    if (_initialised) return;
    _nameController.text = b.name;
    _phoneController.text = b.phone;
    _addressController.text = b.address;
    // Fall back to first option if the stored value is no longer in
    // the canonical list (forward-compatible for old data).
    _selectedBusinessType = AppConstants.businessTypes.contains(b.businessType)
        ? b.businessType
        : AppConstants.businessTypes.first;
    _selectedCurrency = AppConstants.currencies.contains(b.currency)
        ? b.currency
        : AppConstants.defaultCurrency;
    _initialised = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final businessProvider = context.read<BusinessProvider>();
    if (businessProvider.isSubmitting) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final current = businessProvider.business;
    final uid = authProvider.user?.uid;

    if (current == null) {
      _showError('No business to update.');
      return;
    }
    if (uid == null) {
      _showError('Session expired. Please log in again.');
      return;
    }

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      businessType:
          _selectedBusinessType ?? AppConstants.businessTypes.first,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      currency: _selectedCurrency ?? AppConstants.defaultCurrency,
    );

    final ok = await businessProvider.updateBusinessModel(
      updated,
      currentUserId: uid,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else {
      _showError(
        businessProvider.errorMessage ?? 'Failed to update business.',
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
    return Consumer<BusinessProvider>(
      builder: (context, biz, _) {
        final current = biz.business;
        if (current == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Business')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No business loaded. Pull to refresh on the profile '
                  'screen and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        _hydrateFrom(current);

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Business')),
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Business Name',
                              controller: _nameController,
                              validator: Validators.businessName,
                              textCapitalization: TextCapitalization.words,
                              prefixIcon: const Icon(
                                Icons.store_mall_directory_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _BusinessTypeDropdown(
                              value: _selectedBusinessType,
                              onChanged: (v) =>
                                  setState(() => _selectedBusinessType = v),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Phone (Optional)',
                              hint: '01XXXXXXXXX',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: Validators.optionalPhone,
                              maxLength: 14,
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Address (Optional)',
                              controller: _addressController,
                              textCapitalization: TextCapitalization.words,
                              maxLines: 2,
                              prefixIcon:
                                  const Icon(Icons.location_on_outlined),
                            ),
                            const SizedBox(height: 16),
                            _CurrencyDropdown(
                              value: _selectedCurrency ??
                                  AppConstants.defaultCurrency,
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _selectedCurrency = v);
                              },
                            ),
                            const SizedBox(height: 32),
                            Consumer<BusinessProvider>(
                              builder: (context, bp, _) {
                                return AppButton(
                                  text: 'Save Changes',
                                  isLoading: bp.isSubmitting,
                                  onPressed: _save,
                                );
                              },
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
      },
    );
  }
}

class _BusinessTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _BusinessTypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Business Type',
          style: TextStyle(
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
              (v == null || v.isEmpty) ? 'Business type is required' : null,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
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
                  child: Text(_currencyLabel(c)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static String _currencyLabel(String code) {
    switch (code) {
      case 'BDT':
        return 'BDT (৳) — Bangladeshi Taka';
      case 'USD':
        return 'USD (\$) — US Dollar';
      case 'INR':
        return 'INR (₹) — Indian Rupee';
      case 'EUR':
        return 'EUR (€) — Euro';
      default:
        return code;
    }
  }
}