import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../models/transaction.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transaction_provider.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _searchController = TextEditingController();
  Stream<List<TransactionModel>>? _transactionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransactions();
    });
  }

  void _loadTransactions() {
    final authProvider = context.read<AuthProvider>();
    final businessId = authProvider.user?.businessId;
    if (businessId != null) {
      _transactionStream = context
          .read<TransactionProvider>()
          .watchTransactions(businessId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.transactionsHistoryTitle),
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.transactionsSearchTransactions,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                context.read<TransactionProvider>().setSearch(value);
              },
            ),
          ),
          _buildFilterChips(),
          Expanded(
            child: _transactionStream == null
                ? const LoadingWidget()
                : StreamBuilder<List<TransactionModel>>(
                    stream: _transactionStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return AppErrorWidget(
                          message: l.transactionsLoadFailedSubtitle,
                          actionText: l.transactionsRetry,
                          onAction: _loadTransactions,
                        );
                      }

                      if (!snapshot.hasData) {
                        return LoadingWidget(
                            message: l.transactionsLoading);
                      }

                      final transactions = snapshot.data!;
                      // Push into the provider after the frame so search /
                      // sort / filter controls can read the same dataset.
                      // Without this bridge the StreamBuilder alone populates
                      // the list while every surrounding selector sees an
                      // empty list.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        context
                            .read<TransactionProvider>()
                            .setTransactions(transactions);
                      });

                      return Consumer<TransactionProvider>(
                        builder: (context, provider, _) {
                          if (provider.transactions.isEmpty) {
                            return EmptyWidget(
                              message: l.transactionsEmptyTitle,
                              subtitle: l.transactionsEmptySubtitle,
                              icon: Icons.receipt_long_outlined,
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: provider.transactions.length,
                            itemBuilder: (context, index) {
                              final t = provider.transactions[index];
                              return _TransactionTile(
                                transaction: t,
                                onTap: () => context.push(
                                    '/app/transactions/${t.id}'),
                                onDelete: () =>
                                    _deleteTransaction(t),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final l = AppLocalizations.of(context);
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: Text(l.transactionsTypeAll),
                selected: provider.isLoading == false,
                onSelected: (_) {
                  provider.setTypeFilter(null);
                  provider.setCategoryFilter(null);
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l.transactionsTypeIncome),
                selected: false,
                onSelected: (_) => provider.setTypeFilter(
                  provider.isLoading ? null : TransactionType.income,
                ),
                selectedColor: AppColors.incomeLight,
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l.transactionsTypeExpense),
                selected: false,
                onSelected: (_) => provider.setTypeFilter(
                  provider.isLoading ? null : TransactionType.expense,
                ),
                selectedColor: AppColors.expenseLight,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.transactionsFilterTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Text(l.transactionsFilterType),
              const SizedBox(height: 8),
              Consumer<TransactionProvider>(
                builder: (context, provider, _) {
                  return RadioGroup<TransactionType?>(
                    groupValue: provider.typeFilter,
                    onChanged: (v) => provider.setTypeFilter(v),
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<TransactionType?>(
                            title: Text(l.transactionsTypeAll),
                            value: null,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<TransactionType?>(
                            title: Text(l.transactionsTypeIncome),
                            value: TransactionType.income,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<TransactionType?>(
                            title: Text(l.transactionsTypeExpense),
                            value: TransactionType.expense,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<TransactionProvider>().clearFilters();
                  Navigator.pop(context);
                },
                child: Text(l.transactionsFilterClear),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _deleteTransaction(TransactionModel transaction) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.transactionsDeleteConfirmTitle),
        content: Text(l.transactionsDeleteConfirmBody),
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

    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      final businessId = auth.user?.businessId;
      if (businessId != null) {
        await context
            .read<TransactionProvider>()
            .deleteTransaction(businessId, transaction.id);
      }
    }
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isIncome = transaction.type == TransactionType.income;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isIncome ? AppColors.incomeLight : AppColors.expenseLight,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? AppColors.income : AppColors.expense,
            size: 20,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${Formatters.date(transaction.date)} • ${transaction.paymentMethod}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text(l.commonEdit),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(l.commonDelete, style: const TextStyle(color: AppColors.error)),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onTap();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          child: Text(
            CurrencyFormatter.formatWithSign(
              isIncome ? transaction.amount : -transaction.amount,
            ),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
