import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/customer.dart';
import '../../../models/transaction.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../l10n/gen/app_localizations.dart';

class RecordPaymentScreen extends StatefulWidget {
  final String customerId;

  const RecordPaymentScreen({super.key, required this.customerId});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _date = DateTime.now();
  String _paymentMethod = TransactionModel.paymentMethods.first;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  Customer? _findCustomer(CustomerProvider provider) {
    for (final c in provider.allCustomers) {
      if (c.id == widget.customerId) return c;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  bool _hasUnsavedChanges() {
    return _enteredAmount > 0 || _noteController.text.trim().isNotEmpty;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    if (!mounted) return true;
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

  Future<void> _submit(Customer customer, AppLocalizations l) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _enteredAmount;
    if (amount <= 0) {
      _showError(l.customersPaymentEnterValid);
      return;
    }

    // Block overpayment. A payment can't exceed the customer's current due
    // because it represents cash actually received to settle the debt.
    if (amount > customer.totalDue) {
      _showError(
        l.customersPaymentExceedsBody(
          CurrencyFormatter.format(amount),
          CurrencyFormatter.format(customer.totalDue),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final businessId = auth.user?.businessId;
    final userId = auth.user?.uid;
    if (businessId == null || userId == null) {
      _showError(l.customersPaymentNotSignedIn);
      return;
    }

    final provider = context.read<CustomerProvider>();
    final id = await provider.recordPayment(
      customerId: widget.customerId,
      businessId: businessId,
      userId: userId,
      amount: amount,
      date: _date,
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    if (!mounted) return;

    if (id == null) {
      _showError(provider.errorMessage ?? l.customersPaymentFailed);
      return;
    }

    // Recompute customer totals from the transactions subcollection so the
    // dashboard tile reflects the new balance immediately. The recordPayment
    // call already incremented `totalPaid` directly; this re-derives both
    // `totalPurchase` and `totalPaid` from the source-of-truth transactions.
    final transactionProvider = context.read<TransactionProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    try {
      await transactionProvider.recomputeCustomerDue(
        businessId: businessId,
        customerId: widget.customerId,
      );
    } catch (_) {
      // Non-fatal -- the stream will reconcile.
    }

    if (!mounted) return;

    // Refresh dashboard so the "Customer Due" tile reflects the new balance
    // immediately.
    try {
      await dashboardProvider.refresh(businessId);
    } catch (_) {
      // Non-fatal -- the dashboard will update on its own stream tick.
    }

    if (!mounted) return;
    context.pop(true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
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
        appBar: AppBar(title: Text(l.customersRecordPayment)),
        body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final customer = _findCustomer(provider);
          if (customer == null) {
            return Center(child: Text(l.customersNotFound));
          }

          final entered = _enteredAmount;
          final previewDue = (customer.totalDue - entered).clamp(0.0, double.infinity).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(customer, l),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: l.customersPaymentAmountLabel,
                    hint: l.customersPaymentAmountHint,
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return l.customersPaymentEnterValid;
                      }
                      return null;
                    },
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text('৳', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildDateField(l),
                  const SizedBox(height: 14),
                  _buildMethodDropdown(l),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: l.customersPaymentNoteLabel,
                    hint: l.customersPaymentNoteHint,
                    controller: _noteController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  if (entered > 0)
                    _buildAfterPaymentCard(previewDue, entered > customer.totalDue, l),
                  const SizedBox(height: 24),
                  AppButton(
                    text: l.customersPaymentSave,
                    icon: Icons.check,
                    isLoading: provider.isSubmitting,
                    onPressed: () => _submit(customer, l),
                  ),
                ],
              ),
            ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Customer customer, AppLocalizations l) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.dueLight, width: 1.2),
      ),
      color: AppColors.dueLight.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.due.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.due,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.customersPaymentCurrentDue,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(customer.totalDue),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.due,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(AppLocalizations l) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l.customersPaymentDateLabel,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(dateFmt.format(_date)),
      ),
    );
  }

  Widget _buildMethodDropdown(AppLocalizations l) {
    // `Due` is excluded: a payment *is* the settlement of a due, so it
    // can never itself be tagged as due.
    final methods = TransactionModel.paymentMethodOptionsExcludingDue;
    // Keep the current selection valid even if the list shrinks.
    if (!methods.contains(_paymentMethod)) {
      _paymentMethod = methods.first;
    }
    return DropdownButtonFormField<String>(
      initialValue: _paymentMethod,
      decoration: InputDecoration(
        labelText: l.customersPaymentMethodLabel,
        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
      ),
      items: [
        for (final m in methods)
          DropdownMenuItem(value: m, child: Text(m)),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _paymentMethod = v);
      },
    );
  }

  Widget _buildAfterPaymentCard(double previewDue, bool exceeds, AppLocalizations l) {
    final label = exceeds
        ? l.customersPaymentExceedsHint(
            CurrencyFormatter.format(previewDue > 0 ? previewDue + _enteredAmount - _enteredAmount : 0),
          )
        : l.customersPaymentAfterTitle;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: exceeds
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.incomeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: exceeds
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            exceeds
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
              color: exceeds ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exceeds ? l.customersPaymentExceedsDue : l.customersPaymentNewDue,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exceeds
                      ? CurrencyFormatter.format(previewDue > 0 ? previewDue : 0)
                      : CurrencyFormatter.format(previewDue),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: exceeds ? AppColors.error : AppColors.success,
                  ),
                ),
                if (exceeds) ...[
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}