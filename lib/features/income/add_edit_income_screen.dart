import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../models/customer.dart';
import '../../models/transaction.dart';
import '../transactions/due_classifier.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../repositories/transaction_repository.dart';
import '../../l10n/gen/app_localizations.dart';

/// Income-only add/edit form. Supports both creating new income and editing
/// existing income (when [incomeId] is provided). Validation enforces
/// amount > 0, category required, payment method required and date required.
///
/// On successful save, the dashboard is refreshed so today's / month's
/// totals reflect the change immediately. Submit-button is disabled while
/// [TransactionProvider.isSubmitting] is true (duplicate-submit guard).
class AddEditIncomeScreen extends StatefulWidget {
  final String? incomeId;

  const AddEditIncomeScreen({super.key, this.incomeId});

  @override
  State<AddEditIncomeScreen> createState() => _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends State<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _category = TransactionModel.incomeCategories.first;
  String _paymentMethod = TransactionModel.paymentMethods.first;
  DateTime _date = DateTime.now();
  String? _customerId;
  bool _isLoadingExisting = false;
  TransactionModel? _existing;

  bool get _isEditing => widget.incomeId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final businessId = auth.user?.businessId;
    if (businessId == null) return;

    // Start watching customers so the dropdown populates live.
    final customerProvider = context.read<CustomerProvider>();
    final stream = customerProvider.watchCustomers(businessId);
    stream.listen((customers) {
      customerProvider.setCustomers(customers);
    }).onError((_) {/* handled by provider */});

    if (_isEditing) {
      setState(() => _isLoadingExisting = true);
      try {
        final repo = context.read<TransactionProvider>();
        final income = await _fetchIncome(repo, businessId);
        if (!mounted) return;
        if (income != null) {
          _existing = income;
          _amountController.text = income.amount.toStringAsFixed(0);
          _noteController.text = income.note ?? '';
          _category = income.category;
          _paymentMethod = income.paymentMethod;
          _date = income.date;
          _customerId = income.customerId;
          // Anything loaded from Firestore is treated as an explicit choice.
          _paymentMethodManuallySet = true;
        }
      } finally {
        if (mounted) setState(() => _isLoadingExisting = false);
      }
    }
  }

  Future<TransactionModel?> _fetchIncome(
    TransactionProvider provider,
    String businessId,
  ) async {
    // Access the underlying repository via a transient instance. We don't
    // add a public getter to avoid leaking the repo; this is the cleanest
    // way to read one document by id from the existing provider surface.
    final repo = TransactionRepository();
    return repo.getTransaction(businessId, widget.incomeId!);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Auto-tagging rules for the income form:
  ///
  /// - If a customer is selected and the category is `Sales`, treat this as a
  ///   credit sale — payment method becomes `Due` (the customer owes money).
  /// - If the category is `Customer Payment`, default the payment method to
  ///   `Cash` (most common path).
  /// - If the customer is cleared, reset the auto-tag so the user can pick
  ///   any payment method freely.
  ///
  /// This only updates [_paymentMethod] when the user has not manually
  /// overridden it away from a "neutral" value, so we don't clobber an
  /// explicit choice. The flag [_paymentMethodManuallySet] tracks that.
  bool _paymentMethodManuallySet = false;

  void _onCategoryChanged(String? v) {
    if (v == null) return;
    setState(() {
      _category = v;
      _paymentMethod = _suggestedPaymentMethod(
        category: v,
        customerId: _customerId,
        currentPaymentMethod: _paymentMethod,
      );
    });
  }

  void _onCustomerChanged(String? v) {
    setState(() {
      _customerId = v;
      _paymentMethod = _suggestedPaymentMethod(
        category: _category,
        customerId: v,
        currentPaymentMethod: _paymentMethod,
      );
    });
  }

  String _suggestedPaymentMethod({
    required String category,
    required String? customerId,
    required String currentPaymentMethod,
  }) {
    // Manual override: respect whatever the user picked.
    if (_paymentMethodManuallySet) return currentPaymentMethod;

    // Sales to a customer → credit sale, payment is "Due".
    if (category == kSalesCategory && customerId != null) {
      return kDuePaymentMethod;
    }

    // Customer Payment receipts default to Cash.
    if (category == kCustomerPaymentCategory) {
      return TransactionModel.paymentMethods.first;
    }

    // Customer cleared → release auto-tag so any method is allowed.
    if (customerId == null) {
      return currentPaymentMethod == kDuePaymentMethod
          ? TransactionModel.paymentMethods.first
          : currentPaymentMethod;
    }

    return currentPaymentMethod;
  }

  void _onPaymentMethodChanged(String? v) {
    if (v == null) return;
    setState(() {
      _paymentMethod = v;
      _paymentMethodManuallySet = true;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.income,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionProvider>();
    final dashboard = context.read<DashboardProvider>();
    final businessId = auth.user?.businessId;
    final userId = auth.user?.uid;
    if (businessId == null || userId == null) return;
    if (provider.isSubmitting) return;

    final amount = double.parse(_amountController.text.trim());
    final now = DateTime.now();
    final note = _noteController.text.trim();

    provider.clearError();

    bool ok;
    if (_isEditing && _existing != null) {
      final updated = _existing!.copyWith(
        amount: amount,
        category: _category,
        date: _date,
        paymentMethod: _paymentMethod,
        customerId: _customerId,
        note: note.isEmpty ? null : note,
        updatedAt: now,
      );
      ok = await provider.updateIncomeModel(
        updated,
        currentUserId: userId,
      );
    } else {
      final draft = TransactionModel(
        id: '',
        userId: userId,
        businessId: businessId,
        type: TransactionType.income,
        amount: amount,
        category: _category,
        date: _date,
        paymentMethod: _paymentMethod,
        customerId: _customerId,
        note: note.isEmpty ? null : note,
        createdAt: now,
        updatedAt: now,
      );
      final id = await provider.addIncome(draft);
      ok = id != null;
    }

    if (!mounted) return;
    final l = AppLocalizations.of(context);

    if (ok) {
      // Fire-and-forget dashboard refresh; the user is already popping.
      dashboard.refresh(businessId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? l.incomeFormSuccessUpdate
              : l.incomeFormSuccessAdd),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ??
              (_isEditing
                  ? l.incomeFormFailedUpdate
                  : l.incomeFormFailedAdd)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addNewCustomer() async {
    final created = await context.push<bool>('/app/customers/add');
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.incomeFormCustomerAdded),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  bool _hasUnsavedChanges() {
    return _amountController.text.trim().isNotEmpty ||
        _noteController.text.trim().isNotEmpty;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    if (!mounted) return true;
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.incomeFormDiscardTitle),
        content: Text(l.incomeFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.incomeFormKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.incomeFormDiscard),
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
          title: Text(_isEditing
              ? l.incomeFormEditTitle
              : l.incomeFormTitle),
          backgroundColor: AppColors.income,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderBanner(
                      icon: Icons.south_west_rounded,
                      title: _isEditing
                          ? l.incomeFormHeaderEdit
                          : l.incomeFormHeaderNew,
                      subtitle: l.incomeFormHeaderSubtitle,
                    ),
                    const SizedBox(height: 20),
                    _AmountField(
                      controller: _amountController,
                    ),
                    const SizedBox(height: 16),
                    _CategoryField(
                      value: _category,
                      onChanged: _onCategoryChanged,
                    ),
                    const SizedBox(height: 16),
                    _DateField(
                      date: _date,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    _PaymentMethodField(
                      value: _paymentMethod,
                      onChanged: _onPaymentMethodChanged,
                    ),
                    if (_paymentMethod == kDuePaymentMethod &&
                        _customerId != null)
                      const _CreditSaleHint(),
                    const SizedBox(height: 16),
                    _CustomerField(
                      customerId: _customerId,
                      onChanged: _onCustomerChanged,
                      onAddNew: _addNewCustomer,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: l.incomeFormNoteLabel,
                      hint: l.incomeFormNoteHint,
                      controller: _noteController,
                      maxLines: 3,
                      maxLength: AppConstants.maxNoteLength,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          Validators.maxLength(v, AppConstants.maxNoteLength,
                              l.incomeFormNoteValidator),
                    ),
                    const SizedBox(height: 24),
                    Consumer<TransactionProvider>(
                      builder: (context, provider, _) {
                        return AppButton(
                          text: _isEditing
                              ? l.incomeFormUpdateButton
                              : l.incomeFormSaveButton,
                          isLoading: provider.isSubmitting,
                          backgroundColor: AppColors.income,
                          icon: Icons.check_rounded,
                          onPressed: provider.isSubmitting ? null : _save,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _HeaderBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.incomeGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppTextField(
      label: l.incomeFormAmountLabel,
      hint: l.incomeFormAmountHint,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: Validators.amount,
      prefixIcon: const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Text(
          '৳',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
    );
  }
}

class _CategoryField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _CategoryField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.incomeFormCategoryLabel,
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: TransactionModel.incomeCategories
          .map((c) => DropdownMenuItem<String>(
                value: c,
                child: Text(c),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.isEmpty) ? l.incomeFormCategoryRequired : null,
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DateField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FormField<DateTime>(
      initialValue: date,
      validator: (_) => null,
      builder: (state) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: l.incomeFormDateLabel,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            Formatters.date(date),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _PaymentMethodField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l.incomeFormPaymentMethodLabel,
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      items: TransactionModel.paymentMethods
          .map((m) => DropdownMenuItem<String>(
                value: m,
                child: Text(m),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.isEmpty) ? l.incomeFormPaymentMethodRequired : null,
    );
  }
}

class _CustomerField extends StatelessWidget {
  final String? customerId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddNew;
  const _CustomerField({
    required this.customerId,
    required this.onChanged,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final customers = provider.allCustomers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: _matchCustomer(customers, customerId),
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.incomeFormCustomerLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.incomeFormCustomerNone),
                ),
                ...customers.map((c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(
                        c.name.isEmpty ? l.incomeFormCustomerUnnamed : c.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
              ],
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAddNew,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(l.incomeFormAddCustomer),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.income,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _matchCustomer(List<Customer> customers, String? id) {
    if (id == null) return null;
    for (final c in customers) {
      if (c.id == id) return c.id;
    }
    return null;
  }
}

/// Inline hint shown when a Sales row is tagged to a customer — i.e., it's
/// a credit sale and the customer's due balance will be bumped on save.
class _CreditSaleHint extends StatelessWidget {
  const _CreditSaleHint();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.incomeFormCreditSaleHint,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
