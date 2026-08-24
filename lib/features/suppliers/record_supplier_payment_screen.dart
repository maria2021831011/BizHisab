import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../models/supplier.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';

/// Mirrors `RecordPaymentScreen` (customers) but for suppliers.
///
/// Pushed via `/app/suppliers/:id/payment` from the supplier detail screen.
/// Pops `true` on a successful write so the caller can show a confirmation
/// SnackBar and let its streams refresh.
class RecordSupplierPaymentScreen extends StatefulWidget {
  final String supplierId;

  const RecordSupplierPaymentScreen({super.key, required this.supplierId});

  @override
  State<RecordSupplierPaymentScreen> createState() =>
      _RecordSupplierPaymentScreenState();
}

class _RecordSupplierPaymentScreenState
    extends State<RecordSupplierPaymentScreen> {
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

  Supplier? _findSupplier(SupplierProvider provider) {
    for (final s in provider.allSuppliers) {
      if (s.id == widget.supplierId) return s;
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

  Future<void> _submit(Supplier supplier, AppLocalizations l) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _enteredAmount;
    if (amount <= 0) {
      _showError(l.suppliersPaymentEnterValid);
      return;
    }

    // Block overpayment. A supplier payment can't exceed the supplier's
    // current due because it represents cash actually paid to settle the
    // debt.
    if (amount > supplier.totalDue) {
      _showError(
        l.suppliersPaymentExceedsBody(
          CurrencyFormatter.format(amount),
          CurrencyFormatter.format(supplier.totalDue),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final businessId = auth.user?.businessId;
    final userId = auth.user?.uid;
    if (businessId == null || userId == null) {
      _showError(l.suppliersPaymentNotSignedIn);
      return;
    }

    final provider = context.read<SupplierProvider>();
    provider.clearError();
    final id = await provider.recordPayment(
      supplierId: widget.supplierId,
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
      _showError(provider.errorMessage ?? l.suppliersPaymentFailed);
      return;
    }

    final transactionProvider = context.read<TransactionProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    // Recompute supplier totals from the transactions subcollection so the
    // dashboard tile reflects the new balance immediately. The recordPayment
    // call already incremented `totalPaid` directly; this re-derives both
    // `totalPurchase` and `totalPaid` from the source-of-truth transactions.
    try {
      await transactionProvider.recomputeSupplierDue(
        businessId: businessId,
        supplierId: widget.supplierId,
      );
    } catch (_) {
      // Non-fatal -- the stream will reconcile.
    }

    if (!mounted) return;

    // Refresh dashboard so the "Supplier Due" tile reflects the new balance
    // immediately (mirrors the customer flow).
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

  bool _hasUnsavedChanges() {
    return _enteredAmount > 0 || _noteController.text.trim().isNotEmpty;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges()) return true;
    final l = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.suppliersDiscardPaymentTitle),
        content: Text(l.suppliersDiscardPaymentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.suppliersKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.suppliersDiscard),
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
        appBar: AppBar(title: Text(l.suppliersRecordPayment)),

      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          final supplier = _findSupplier(provider);
          if (supplier == null) {
            return Center(child: Text(l.suppliersNotFound));
          }

          final entered = _enteredAmount;
          final previewTotalPaid = supplier.totalPaid + entered;
          final previewDue =
              (supplier.totalDue - entered).clamp(0.0, double.infinity).toDouble();
          final exceeds = entered > supplier.totalDue;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              // Re-build on every keystroke so the live "After this payment"
              // preview card tracks what the user is typing.
              onChanged: () => setState(() {}),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCard(supplier, l),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: l.suppliersPaymentAmountLabel,
                    hint: l.suppliersPaymentAmountHint,
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) {
                      final parsed = double.tryParse((v ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return l.suppliersPaymentEnterValid;
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
                    label: l.suppliersPaymentNoteLabel,
                    hint: l.suppliersPaymentNoteHint,
                    controller: _noteController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 20),
                  if (entered > 0) ...[
                    _buildAfterPaymentCard(
                      previewDue: previewDue,
                      previewTotalPaid: previewTotalPaid,
                      capAmount: supplier.totalDue,
                      exceeds: exceeds,
                      l: l,
                    ),
                    const SizedBox(height: 24),
                  ],
                  AppButton(
                    text: l.suppliersPaymentSave,
                    icon: Icons.check,
                    isLoading: provider.isSubmitting,
                    onPressed: () => _submit(supplier, l),
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

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------
  Widget _buildSummaryCard(Supplier supplier, AppLocalizations l) {
    final hasDue = supplier.totalDue > 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.supplierLight, width: 1.2),
      ),
      color: AppColors.supplierLight.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.supplier.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.supplier,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDue
                        ? l.suppliersPaymentCurrentDue
                        : l.suppliersPaymentCurrentDueSettled,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(supplier.totalDue),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: hasDue ? AppColors.supplier : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    supplier.name,
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
          labelText: l.suppliersPaymentDateLabel,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(dateFmt.format(_date)),
      ),
    );
  }

  Widget _buildMethodDropdown(AppLocalizations l) {
    // `Due` is excluded: a payment *is* the settlement of a due, so it can
    // never itself be tagged as due.
    final methods = TransactionModel.paymentMethodOptionsExcludingDue;
    if (!methods.contains(_paymentMethod)) {
      _paymentMethod = methods.first;
    }
    return DropdownButtonFormField<String>(
      initialValue: _paymentMethod,
      decoration: InputDecoration(
        labelText: l.suppliersPaymentMethodLabel,
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

  Widget _buildAfterPaymentCard({
    required double previewDue,
    required double previewTotalPaid,
    required double capAmount,
    required bool exceeds,
    required AppLocalizations l,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: exceeds
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.supplierLight.withValues(alpha: 0.5),
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
            exceeds ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: exceeds ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exceeds
                      ? l.suppliersPaymentExceedsDue
                      : l.suppliersPaymentAfterTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exceeds
                      ? l.suppliersPaymentExceedsHint(
                          CurrencyFormatter.format(capAmount),
                        )
                      : l.suppliersPaymentNewDue(
                          CurrencyFormatter.format(previewDue),
                        ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: exceeds ? AppColors.error : AppColors.success,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.suppliersPaymentTotalPaidAfter(
                    CurrencyFormatter.format(previewTotalPaid),
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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