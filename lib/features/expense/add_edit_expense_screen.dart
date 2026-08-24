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
import '../../models/supplier.dart';
import '../../models/transaction.dart';
import '../transactions/due_classifier.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../repositories/transaction_repository.dart';
import '../../l10n/gen/app_localizations.dart';

/// Expense-only add/edit form. Supports both creating new expense and editing
/// existing expense (when [expenseId] is provided). Validation enforces
/// amount > 0, category required, payment method required and date required.
///
/// On successful save, the dashboard is refreshed so today's / month's
/// totals reflect the change immediately. Submit-button is disabled while
/// [TransactionProvider.isSubmitting] is true (duplicate-submit guard).
class AddEditExpenseScreen extends StatefulWidget {
  final String? expenseId;

  const AddEditExpenseScreen({super.key, this.expenseId});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _category = TransactionModel.expenseCategories.first;
  String _paymentMethod = TransactionModel.paymentMethods.first;
  DateTime _date = DateTime.now();
  String? _supplierId;
  bool _isLoadingExisting = false;
  TransactionModel? _existing;

  bool get _isEditing => widget.expenseId != null;

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

    // Start watching suppliers so the dropdown populates live.
    final supplierProvider = context.read<SupplierProvider>();
    final stream = supplierProvider.watchSuppliers(businessId);
    stream.listen((suppliers) {
      supplierProvider.setSuppliers(suppliers);
    }).onError((_) {/* handled by provider */});

    if (_isEditing) {
      setState(() => _isLoadingExisting = true);
      try {
        final repo = TransactionRepository();
        final expense = await repo.getTransaction(businessId, widget.expenseId!);
        if (!mounted) return;
        if (expense != null) {
          _existing = expense;
          _amountController.text = expense.amount.toStringAsFixed(0);
          _noteController.text = expense.note ?? '';
          _category = expense.category;
          _paymentMethod = expense.paymentMethod;
          _date = expense.date;
          _supplierId = expense.supplierId;
          // Loaded record is an explicit user choice; preserve the value.
          _paymentMethodManuallySet = true;
        }
      } finally {
        if (mounted) setState(() => _isLoadingExisting = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Auto-tagging rules for the expense form (mirror of the income form):
  ///
  /// - If a supplier is selected and the category is `Purchase`, treat this as
  ///   a credit purchase — payment method becomes `Due` (we owe the supplier).
  /// - If the category is `Supplier Payment`, default the payment method to
  ///   `Cash` (most common path).
  /// - If the supplier is cleared, release the auto-tag so any method works.
  bool _paymentMethodManuallySet = false;

  void _onCategoryChanged(String? v) {
    if (v == null) return;
    setState(() {
      _category = v;
      _paymentMethod = _suggestedPaymentMethod(
        category: v,
        supplierId: _supplierId,
        currentPaymentMethod: _paymentMethod,
      );
    });
  }

  void _onSupplierChanged(String? v) {
    setState(() {
      _supplierId = v;
      _paymentMethod = _suggestedPaymentMethod(
        category: _category,
        supplierId: v,
        currentPaymentMethod: _paymentMethod,
      );
    });
  }

  String _suggestedPaymentMethod({
    required String category,
    required String? supplierId,
    required String currentPaymentMethod,
  }) {
    if (_paymentMethodManuallySet) return currentPaymentMethod;

    // Purchase from a supplier → credit purchase, payment is "Due".
    if (category == kPurchaseCategory && supplierId != null) {
      return kDuePaymentMethod;
    }

    // Supplier Payment refunds default to Cash.
    if (category == kSupplierPaymentCategory) {
      return TransactionModel.paymentMethods.first;
    }

    // Supplier cleared → release auto-tag so any method is allowed.
    if (supplierId == null) {
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
            primary: AppColors.expense,
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
        supplierId: _supplierId,
        note: note.isEmpty ? null : note,
        updatedAt: now,
      );
      ok = await provider.updateExpenseModel(
        updated,
        currentUserId: userId,
      );
    } else {
      final draft = TransactionModel(
        id: '',
        userId: userId,
        businessId: businessId,
        type: TransactionType.expense,
        amount: amount,
        category: _category,
        date: _date,
        paymentMethod: _paymentMethod,
        supplierId: _supplierId,
        note: note.isEmpty ? null : note,
        createdAt: now,
        updatedAt: now,
      );
      final id = await provider.addExpense(draft);
      ok = id != null;
    }

    if (!mounted) return;
    final l = AppLocalizations.of(context);

    if (ok) {
      // Fire-and-forget dashboard refresh; the user is already popping.
      // The dashboard recalculates Today's/Monthly Expense + Profit
      // (income - expense) from the underlying transactions collection,
      // so no manual profit counter has to be updated.
      dashboard.refresh(businessId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? l.expenseFormSuccessUpdate
              : l.expenseFormSuccessAdd),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ??
              (_isEditing
                  ? l.expenseFormFailedUpdate
                  : l.expenseFormFailedAdd)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addNewSupplier() async {
    final created = await context.push<bool>('/app/suppliers/add');
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.expenseFormSupplierAdded),
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
        title: Text(l.expenseFormDiscardTitle),
        content: Text(l.expenseFormDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.expenseFormKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.expenseFormDiscard),
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
              ? l.expenseFormEditTitle
              : l.expenseFormTitle),
          backgroundColor: AppColors.expense,
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
                        icon: Icons.north_east_rounded,
                        title: _isEditing
                            ? l.expenseFormHeaderEdit
                            : l.expenseFormHeaderNew,
                        subtitle: l.expenseFormHeaderSubtitle,
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
                          _supplierId != null)
                        const _CreditPurchaseHint(),
                      const SizedBox(height: 16),
                      _SupplierField(
                        supplierId: _supplierId,
                        onChanged: _onSupplierChanged,
                        onAddNew: _addNewSupplier,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: l.expenseFormNoteLabel,
                        hint: l.expenseFormNoteHint,
                        controller: _noteController,
                        maxLines: 3,
                        maxLength: AppConstants.maxNoteLength,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) =>
                            Validators.maxLength(v, AppConstants.maxNoteLength,
                                l.expenseFormNoteValidator),
                      ),
                      const SizedBox(height: 24),
                      Consumer<TransactionProvider>(
                        builder: (context, provider, _) {
                          return AppButton(
                            text: _isEditing
                                ? l.expenseFormUpdateButton
                                : l.expenseFormSaveButton,
                            isLoading: provider.isSubmitting,
                            backgroundColor: AppColors.expense,
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
        gradient: AppColors.expenseGradient,
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
      label: l.expenseFormAmountLabel,
      hint: l.expenseFormAmountHint,
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
        labelText: l.expenseFormCategoryLabel,
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: TransactionModel.expenseCategories
          .map((c) => DropdownMenuItem<String>(
                value: c,
                child: Text(c),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.isEmpty) ? l.expenseFormCategoryRequired : null,
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
            labelText: l.expenseFormDateLabel,
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
        labelText: l.expenseFormPaymentMethodLabel,
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
          (v == null || v.isEmpty) ? l.expenseFormPaymentMethodRequired : null,
    );
  }
}

class _SupplierField extends StatelessWidget {
  final String? supplierId;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddNew;
  const _SupplierField({
    required this.supplierId,
    required this.onChanged,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) {
        final suppliers = provider.allSuppliers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: _matchSupplier(suppliers, supplierId),
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.expenseFormSupplierLabel,
                prefixIcon: const Icon(Icons.local_shipping_outlined),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l.expenseFormSupplierNone),
                ),
                ...suppliers.map((s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(
                        s.name.isEmpty ? l.expenseFormSupplierUnnamed : s.name,
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
                label: Text(l.expenseFormAddSupplier),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.expense,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _matchSupplier(List<Supplier> suppliers, String? id) {
    if (id == null) return null;
    for (final s in suppliers) {
      if (s.id == id) return s.id;
    }
    return null;
  }
}

/// Inline hint shown when a Purchase row is tagged to a supplier — i.e., it's
/// a credit purchase and the supplier's due balance will be bumped on save.
class _CreditPurchaseHint extends StatelessWidget {
  const _CreditPurchaseHint();

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
                l.expenseFormCreditPurchaseHint,
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
