import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/customer.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customer_provider.dart';
import '../../../l10n/gen/app_localizations.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();
  Stream<List<Customer>>? _customerStream;
  StreamSubscription<List<Customer>>? _customerSub;
  Timer? _debounce;
  Object? _streamError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeCustomers());
  }

  void _subscribeCustomers() {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    _customerSub?.cancel();
    _streamError = null;
    setState(() {
      _customerStream =
          context.read<CustomerProvider>().watchCustomers(businessId);
    });
    _customerSub = _customerStream!.listen(
      (customers) {
        if (!mounted) return;
        context.read<CustomerProvider>().setCustomers(customers);
      },
      onError: (Object err) {
        if (!mounted) return;
        setState(() => _streamError = err);
      },
    );
  }

  Future<void> _refresh() async {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId != null) {
      await context.read<CustomerProvider>().watchCustomers(businessId).first;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMilliseconds),
      () {
        if (!mounted) return;
        context.read<CustomerProvider>().setSearch(value.trim());
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _customerSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.customersTitle),
        actions: [
          PopupMenuButton<CustomerSort>(
            tooltip: l.customersSort,
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              context.read<CustomerProvider>().setSort(sort);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: CustomerSort.nameAsc,
                child: Row(children: [
                  const Icon(Icons.sort_by_alpha, size: 18),
                  const SizedBox(width: 8),
                  Text(l.customersSortNameAsc),
                ]),
              ),
              PopupMenuItem(
                value: CustomerSort.dueDesc,
                child: Row(children: [
                  const Icon(Icons.priority_high, size: 18),
                  const SizedBox(width: 8),
                  Text(l.customersSortDueDesc),
                ]),
              ),
              PopupMenuItem(
                value: CustomerSort.recent,
                child: Row(children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Text(l.customersSortRecent),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l.customersSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CustomerProvider>().setSearch('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
            ),
          ),
          Consumer<CustomerProvider>(
            builder: (context, provider, _) {
              if (provider.totalDue <= 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.dueLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.due.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.due.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.due,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.customersTotalDueCard,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.format(provider.totalDue),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.due,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: _customerStream == null
                ? const LoadingWidget()
                : Builder(
                    builder: (context) {
                      if (_streamError != null) {
                        return AppErrorWidget(
                          message: l.customersLoadFailed,
                          actionText: l.commonRetry,
                          onAction: _subscribeCustomers,
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refresh,
                        child: Consumer<CustomerProvider>(
                          builder: (context, provider, _) {
                            if (provider.customers.isEmpty) {
                              final hasFilter =
                                  (provider.searchQuery ?? '').isNotEmpty;
                              return ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                            0.5,
                                    child: EmptyWidget(
                                      message: hasFilter
                                          ? l.customersSearchEmpty
                                          : l.customersEmpty,
                                      subtitle: hasFilter
                                          ? l.customersSearchEmptySubtitle
                                          : l.customersAddSubtitle,
                                      icon: hasFilter
                                          ? Icons.search_off
                                          : Icons.people_outline,
                                      actionText: hasFilter
                                          ? null
                                          : l.customersAdd,
                                      onAction: hasFilter
                                          ? null
                                          : () => context
                                              .push('/app/customers/add'),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return ListView.separated(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              itemCount: provider.customers.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final customer = provider.customers[index];
                                return _CustomerTile(
                                  customer: customer,
                                  onTap: () => context.push(
                                      '/app/customers/${customer.id}'),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/app/customers/add'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.customersAdd),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasDue = customer.totalDue > 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        customer.phone.isNotEmpty ? customer.phone : null,
                        if (customer.address.isNotEmpty) customer.address,
                      ].whereType<String>().join(' • '),
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
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hasDue
                        ? CurrencyFormatter.format(customer.totalDue)
                        : '৳0',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color:
                          hasDue ? AppColors.due : AppColors.success,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasDue
                          ? AppColors.dueLight
                          : AppColors.incomeLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasDue ? l.customersChipDue : l.customersChipSettled,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasDue ? AppColors.due : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
