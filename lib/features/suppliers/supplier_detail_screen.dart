import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/supplier.dart';
import '../../models/supplier_payment.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';

class SupplierDetailScreen extends StatefulWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  late final Stream<List<SupplierPayment>> _paymentsStream;
  late final Stream<List<TransactionModel>> _creditPurchasesStream;
  StreamSubscription<List<SupplierPayment>>? _paymentsSub;
  StreamSubscription<List<TransactionModel>>? _creditPurchasesSub;

  @override
  void initState() {
    super.initState();
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId != null) {
      _paymentsStream = context
          .read<SupplierProvider>()
          .watchPayments(businessId: businessId, supplierId: widget.supplierId);
      _creditPurchasesStream = context
          .read<TransactionProvider>()
          .watchTransactions(businessId);
    } else {
      _paymentsStream = const Stream.empty();
      _creditPurchasesStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _paymentsSub?.cancel();
    _creditPurchasesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.suppliersDetailTitle),
        actions: [
          IconButton(
            tooltip: l.commonEdit,
            onPressed: _editSupplier,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: l.commonDelete,
            onPressed: _deleteSupplier,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
      body: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          final suppliers = provider.allSuppliers;
          Supplier? supplier;
          for (final s in suppliers) {
            if (s.id == widget.supplierId) {
              supplier = s;
              break;
            }
          }

          if (supplier == null) {
            return Center(child: Text(l.suppliersNotFound));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(supplier),
                const SizedBox(height: 20),
                _buildStatCard(supplier, l),
                if (supplier.address.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAddressCard(supplier.address, l),
                ],
                const SizedBox(height: 20),
                _buildCreditPurchasesHistory(l),
                const SizedBox(height: 20),
                _buildPaymentHistory(l),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<SupplierProvider>(
        builder: (context, provider, _) {
          final suppliers = provider.allSuppliers;
          Supplier? supplier;
          for (final s in suppliers) {
            if (s.id == widget.supplierId) {
              supplier = s;
              break;
            }
          }
          if (supplier == null || supplier.totalDue <= 0) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppButton(
                text: l.suppliersRecordPayment,
                icon: Icons.payments_outlined,
                onPressed: () => _openRecordPayment(supplier!),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header / cards
  // ---------------------------------------------------------------------------
  Widget _buildHeader(Supplier supplier) {
    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.supplier.withValues(alpha: 0.1),
          child: Text(
            supplier.name.isNotEmpty
                ? supplier.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.supplier,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          supplier.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        if (supplier.phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            supplier.phone,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(Supplier supplier, AppLocalizations l) {
    final hasDue = supplier.totalDue > 0;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            _buildStatRow(
              l.suppliersTotalPurchase,
              CurrencyFormatter.format(supplier.totalPurchase),
              AppColors.textPrimary,
            ),
            const Divider(height: 1),
            _buildStatRow(
              l.suppliersTotalPaid,
              CurrencyFormatter.format(supplier.totalPaid),
              AppColors.success,
            ),
            const Divider(height: 1),
            _buildStatRow(
              hasDue ? l.suppliersDueBalance : l.customersChipSettled,
              CurrencyFormatter.format(supplier.totalDue),
              hasDue ? AppColors.supplier : AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(String address, AppLocalizations l) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.supplier.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.supplier,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.customersAddressLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPurchasesHistory(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l.suppliersCreditPurchases,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        StreamBuilder<List<TransactionModel>>(
          stream: _creditPurchasesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: LoadingWidget(message: l.suppliersLoadingCreditPurchases),
              );
            }
            if (snapshot.hasError) {
              return AppErrorWidget(
                message: snapshot.error.toString(),
                actionText: l.commonRetry,
                onAction: () => setState(() {}),
              );
            }
            final all = snapshot.data ?? const <TransactionModel>[];
            final creditPurchases = all
                .where((t) =>
                    t.type == TransactionType.expense &&
                    t.supplierId == widget.supplierId &&
                    t.paymentMethod == 'Due')
                .toList();
            if (creditPurchases.isEmpty) {
              return EmptyWidget(
                icon: Icons.shopping_bag_outlined,
                message: l.suppliersCreditPurchasesEmpty,
                subtitle: l.suppliersCreditPurchasesEmptySubtitle,
              );
            }
            return Column(
              children: [
                for (final t in creditPurchases) _buildCreditPurchaseTile(t),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreditPurchaseTile(TransactionModel t) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.supplier.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.supplier.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.supplier,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFmt.format(t.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      t.category,
                      if (t.note != null && t.note!.isNotEmpty) t.note!,
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '-${CurrencyFormatter.format(t.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.supplier,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l.suppliersPaymentHistory,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        StreamBuilder<List<SupplierPayment>>(
          stream: _paymentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: LoadingWidget(message: l.suppliersLoadingPayments),
              );
            }
            if (snapshot.hasError) {
              return AppErrorWidget(
                message: snapshot.error.toString(),
                actionText: l.commonRetry,
                onAction: () => setState(() {}),
              );
            }
            final payments = snapshot.data ?? const [];
            if (payments.isEmpty) {
              return EmptyWidget(
                icon: Icons.receipt_long_outlined,
                message: l.suppliersPaymentsEmpty,
                subtitle: l.suppliersPaymentsEmptySubtitle,
              );
            }
            return Column(
              children: [
                for (final p in payments) _buildPaymentTile(p),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentTile(SupplierPayment p) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.supplierLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.supplier.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: AppColors.supplier,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFmt.format(p.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      p.methodDisplayLabel,
                      if (p.note.isNotEmpty) p.note,
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '-${CurrencyFormatter.format(p.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.supplier,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  void _editSupplier() {
    context.push('/app/suppliers/${widget.supplierId}/edit');
  }

  void _openRecordPayment(Supplier supplier) {
    final l = AppLocalizations.of(context);
    context.push('/app/suppliers/${widget.supplierId}/payment').then((value) {
      if (value == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.suppliersPaymentRecorded)),
        );
      }
    });
  }

  Future<void> _deleteSupplier() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.suppliersDeleteTitle),
        content: Text(l.suppliersDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;

    await context
        .read<SupplierProvider>()
        .deleteSupplier(businessId, widget.supplierId);
    if (mounted) context.pop();
  }
}
