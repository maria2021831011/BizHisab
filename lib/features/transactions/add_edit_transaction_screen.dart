import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/transaction.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final String? transactionId;

  const AddEditTransactionScreen({super.key, this.transactionId});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.income;
  String _category = 'Sales';
  String _paymentMethod = 'Cash';
  DateTime _date = DateTime.now();

  bool get _isEditing => widget.transactionId != null;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<String> get _categories =>
      _type == TransactionType.income
          ? TransactionModel.incomeCategories
          : TransactionModel.expenseCategories;

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final businessId = authProvider.user?.businessId;
    final userId = authProvider.user?.uid;

    if (businessId == null || userId == null) return;

    final now = DateTime.now();
    final amount = double.parse(_amountController.text.trim());

    if (_isEditing) {
      await transactionProvider.updateTransaction(
        businessId,
        widget.transactionId!,
        {
          'type': _type == TransactionType.income ? 'income' : 'expense',
          'amount': amount,
          'category': _category,
          'date': Timestamp.fromDate(_date),
          'paymentMethod': _paymentMethod,
          'note': _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        },
      );
    } else {
      final transaction = TransactionModel(
        id: '',
        userId: userId,
        businessId: businessId,
        type: _type,
        amount: amount,
        category: _category,
        date: _date,
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await transactionProvider.addTransaction(transaction);
    }

    if (mounted) {
      final l = AppLocalizations.of(context);
      if (transactionProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionProvider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? l.transactionsSuccessUpdate
                : l.transactionsSuccessAdd),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l.transactionsEditTitle : l.transactionsAddTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text(l.transactionsTypeIncome),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text(l.transactionsTypeExpense),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selected) {
                  setState(() {
                    _type = selected.first;
                    _category = _categories.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  selectedBackgroundColor: _type == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: l.transactionsAmountLabel,
                hint: l.transactionsAmountHint,
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.amount,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 12, right: 8),
                  child: Text(
                    '৳',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(labelText: l.transactionsCategoryLabel),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration:
                    InputDecoration(labelText: l.transactionsPaymentMethodLabel),
                items: TransactionModel.paymentMethods.map((method) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.transactionsDateLabel),
                subtitle: Text(
                  '${_date.day}/${_date.month}/${_date.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: l.transactionsNoteOptionalLabel,
                hint: l.transactionsNoteOptionalHint,
                controller: _noteController,
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 24),
              Consumer<TransactionProvider>(
                builder: (context, provider, _) {
                  return AppButton(
                    text: _isEditing ? l.transactionsEditButton : l.transactionsAddButton,
                    isLoading: provider.isLoading,
                    onPressed: _saveTransaction,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
