import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/customer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../l10n/gen/app_localizations.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final String? customerId;

  const AddEditCustomerScreen({super.key, this.customerId});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _initialized = false;

  bool get _isEditing => widget.customerId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _prefillFromCustomer(Customer customer) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address;
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<CustomerProvider>();
    final businessId = auth.user?.businessId;
    final userId = auth.user?.uid;

    if (businessId == null || userId == null) return;

    final now = DateTime.now();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (_isEditing) {
      await provider.updateCustomer(businessId, widget.customerId!, {
        'name': name,
        'phone': phone,
        'address': address,
      });
    } else {
      final customer = Customer(
        id: '',
        businessId: businessId,
        userId: userId,
        name: name,
        phone: phone,
        address: address,
        createdAt: now,
        updatedAt: now,
      );
      await provider.addCustomer(customer);
    }

    if (mounted) {
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        context.pop();
      }
    }
  }

  bool _hasUnsavedChanges() {
    if (_initialized && _isEditing) {
      // Editing pre-filled form — only prompt if any field diverged from the
      // original customer snapshot.
      // (No snapshot stored; conservatively treat touched state as a no-op
      // because pre-filled forms are common in this app.)
      return false;
    }
    return _nameController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.customersDiscardTitle),
        content: Text(l.customersDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.customersKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.customersDiscard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!context.mounted) return;
        if (await _confirmDiscard()) {
          if (!context.mounted) return;
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? l.customersEditCustomer : l.customersAdd),
        ),
        body: _isEditing
            ? Consumer<CustomerProvider>(
                builder: (context, provider, _) {
                  final customers = provider.customers;
                  Customer? existing;
                  for (final c in customers) {
                    if (c.id == widget.customerId) {
                      existing = c;
                      break;
                    }
                  }
                  if (existing == null) {
                    return Center(child: Text(l.customersNotFound));
                  }
                  _prefillFromCustomer(existing);
                  return _buildForm(provider, l);
                },
              )
            : _buildForm(context.read<CustomerProvider>(), l),
      ),
    );
  }

  Widget _buildForm(CustomerProvider provider, AppLocalizations l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l.customersFormNameLabel,
              hint: l.customersFormNameHint,
              controller: _nameController,
              validator: (v) => Validators.name(v, l.customersFormNameLabel),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: l.customersFormPhoneLabel,
              hint: '01XXXXXXXXX',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 11,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: l.customersFormAddressLabel,
              hint: l.customersFormAddressHint,
              controller: _addressController,
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: _isEditing ? l.customersUpdateCustomer : l.customersAdd,
              isLoading: provider.isLoading,
              onPressed: _saveCustomer,
            ),
          ],
        ),
      ),
    );
  }
}
