import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../models/customer.dart';
import '../../models/customer_payment.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../l10n/gen/app_localizations.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late final Stream<List<CustomerPayment>> _paymentsStream;
  late final Stream<List<TransactionModel>> _creditSalesStream;
  StreamSubscription<List<CustomerPayment>>? _paymentsSub;
  StreamSubscription<List<TransactionModel>>? _creditSalesSub;

  @override
  void initState() {
    super.initState();
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId != null) {
      _paymentsStream = context
          .read<CustomerProvider>()
          .watchPayments(businessId: businessId, customerId: widget.customerId);
      _creditSalesStream = context.read<TransactionProvider>().watchTransactions(
        businessId,
      );
    } else {
      _paymentsStream = const Stream.empty();
      _creditSalesStream = const Stream.empty();
    }
  }

  @override
  void dispose() {
    _paymentsSub?.cancel();
    _creditSalesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.customersDetailTitle),
        actions: [
          IconButton(
            tooltip: l.commonEdit,
            onPressed: _editCustomer,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: l.commonDelete,
            onPressed: _deleteCustomer,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final customers = provider.allCustomers;
          Customer? customer;
          for (final c in customers) {
            if (c.id == widget.customerId) {
              customer = c;
              break;
            }
          }

          if (customer == null) {
            return Center(child: Text(l.customersNotFound));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(customer),
                const SizedBox(height: 20),
                _buildStatCard(customer, l),
                if (customer.address.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAddressCard(customer.address, l),
                ],
                const SizedBox(height: 20),
                _buildCreditSalesHistory(l),
                const SizedBox(height: 20),
                _buildPaymentHistory(l),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final customers = provider.allCustomers;
          Customer? customer;
          for (final c in customers) {
            if (c.id == widget.customerId) {
              customer = c;
              break;
            }
          }
          if (customer == null || customer.totalDue <= 0) {
            return const SizedBox.shrink();
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: AppButton(
                text: l.customersRecordPayment,
                icon: Icons.payments_outlined,
                onPressed: () => _openRecordPayment(customer!),
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
  Widget _buildHeader(Customer customer) {
    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            customer.name.isNotEmpty
                ? customer.name[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          customer.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        if (customer.phone.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            customer.phone,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(Customer customer, AppLocalizations l) {
    final hasDue = customer.totalDue > 0;
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
              l.customersTotalPurchase,
              CurrencyFormatter.format(customer.totalPurchase),
              AppColors.textPrimary,
            ),
            const Divider(height: 1),
            _buildStatRow(
              l.customersTotalPaid,
              CurrencyFormatter.format(customer.totalPaid),
              AppColors.success,
            ),
            const Divider(height: 1),
            _buildStatRow(
              hasDue ? l.customersDueBalance : l.customersChipSettled,
              CurrencyFormatter.format(customer.totalDue),
              hasDue ? AppColors.due : AppColors.success,
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
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: AppColors.primary,
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

  Widget _buildCreditSalesHistory(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l.customersCreditSales,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        StreamBuilder<List<TransactionModel>>(
          stream: _creditSalesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: LoadingWidget(message: l.customersLoadingCreditSales),
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
            // Source-of-truth: credit sales = income + this customer + Due.
            final creditSales = all
                .where((t) =>
                    t.type == TransactionType.income &&
                    t.customerId == widget.customerId &&
                    t.paymentMethod == 'Due')
                .toList();
            if (creditSales.isEmpty) {
              return EmptyWidget(
                icon: Icons.shopping_cart_outlined,
                message: l.customersCreditSalesEmpty,
                subtitle: l.customersCreditSalesEmptySubtitle,
              );
            }
            return Column(
              children: [
                for (final t in creditSales) _buildCreditSaleTile(t),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreditSaleTile(TransactionModel t) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.due.withValues(alpha: 0.08),
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
                color: AppColors.due.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.due,
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
              '+${CurrencyFormatter.format(t.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.due,
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
            l.customersPaymentHistory,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        StreamBuilder<List<CustomerPayment>>(
          stream: _paymentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: LoadingWidget(message: l.customersLoadingPayments),
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
                message: l.customersPaymentsEmpty,
                subtitle: l.customersPaymentsEmptySubtitle,
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

  Widget _buildPaymentTile(CustomerPayment p) {
    final dateFmt = DateFormat('dd MMM yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.incomeLight,
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
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: AppColors.success,
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
                      p.paymentMethod,
                      if (p.note != null && p.note!.isNotEmpty) p.note!,
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
              '+${CurrencyFormatter.format(p.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
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
  void _editCustomer() {
    context.push('/app/customers/${widget.customerId}/edit');
  }

  void _openRecordPayment(Customer customer) {
    final l = AppLocalizations.of(context);
    context.push('/app/customers/${widget.customerId}/payment').then((value) {
      if (value == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.customersPaymentRecorded)),
        );
      }
    });
  }

  Future<void> _deleteCustomer() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.customersDeleteTitle),
        content: Text(l.customersDeleteBody),
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
        .read<CustomerProvider>()
        .deleteCustomer(businessId, widget.customerId);
    if (mounted) context.pop();
  }
}
