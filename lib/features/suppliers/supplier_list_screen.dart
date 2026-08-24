import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../models/supplier.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final _searchController = TextEditingController();
  Stream<List<Supplier>>? _supplierStream;
  StreamSubscription<List<Supplier>>? _supplierSub;
  Timer? _debounce;
  Object? _streamError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeSuppliers());
  }

  void _subscribeSuppliers() {
    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null) return;
    _supplierSub?.cancel();
    _streamError = null;
    setState(() {
      _supplierStream =
          context.read<SupplierProvider>().watchSuppliers(businessId);
    });
    _supplierSub = _supplierStream!.listen(
      (suppliers) {
        if (!mounted) return;
        context.read<SupplierProvider>().setSuppliers(suppliers);
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
      await context.read<SupplierProvider>().watchSuppliers(businessId).first;
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMilliseconds),
      () {
        if (!mounted) return;
        context.read<SupplierProvider>().setSearch(value.trim());
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _supplierSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.suppliersTitle),
        actions: [
          PopupMenuButton<SupplierSort>(
            tooltip: l.suppliersSort,
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              context.read<SupplierProvider>().setSort(sort);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: SupplierSort.nameAsc,
                child: Row(children: [
                  const Icon(Icons.sort_by_alpha, size: 18),
                  const SizedBox(width: 8),
                  Text(l.suppliersSortNameAsc),
                ]),
              ),
              PopupMenuItem(
                value: SupplierSort.dueDesc,
                child: Row(children: [
                  const Icon(Icons.priority_high, size: 18),
                  const SizedBox(width: 8),
                  Text(l.suppliersSortDueDesc),
                ]),
              ),
              PopupMenuItem(
                value: SupplierSort.recent,
                child: Row(children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Text(l.suppliersSortRecent),
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
                hintText: l.suppliersSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SupplierProvider>().setSearch('');
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
          Consumer<SupplierProvider>(
            builder: (context, provider, _) {
              if (provider.totalDue <= 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.supplierLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.supplier.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.supplier.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.supplier,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.suppliersTotalDueCard,
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
                              color: AppColors.supplier,
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
            child: _supplierStream == null
                ? const LoadingWidget()
                : Builder(
                    builder: (context) {
                      if (_streamError != null) {
                        return AppErrorWidget(
                          message: l.suppliersLoadFailed,
                          actionText: l.commonRetry,
                          onAction: _subscribeSuppliers,
                        );
                      }
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _refresh,
                        child: Consumer<SupplierProvider>(
                          builder: (context, provider, _) {
                            if (provider.suppliers.isEmpty) {
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
                                          ? l.suppliersSearchEmpty
                                          : l.suppliersEmpty,
                                      subtitle: hasFilter
                                          ? l.suppliersSearchEmptySubtitle
                                          : l.suppliersAddSubtitle,
                                      icon: hasFilter
                                          ? Icons.search_off
                                          : Icons.local_shipping_outlined,
                                      actionText:
                                          hasFilter ? null : l.suppliersAdd,
                                      onAction: hasFilter
                                          ? null
                                          : () => context
                                              .push('/app/suppliers/add'),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 96),
                              itemCount: provider.suppliers.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final s = provider.suppliers[index];
                                final hasDue = s.totalDue > 0;
                                return Card(
                                  elevation: 0,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.divider
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => context
                                        .push('/app/suppliers/${s.id}'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: AppColors
                                                .supplier
                                                .withValues(alpha: 0.12),
                                            child: Text(
                                              s.name.isNotEmpty
                                                  ? s.name[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: AppColors.supplier,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  [
                                                    if (s.phone.isNotEmpty)
                                                      s.phone,
                                                    if (s.address.isNotEmpty)
                                                      s.address,
                                                  ].join(' • '),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                hasDue
                                                    ? CurrencyFormatter.format(
                                                        s.totalDue)
                                                    : '৳0',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: hasDue
                                                      ? AppColors.supplier
                                                      : AppColors.success,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: hasDue
                                                      ? AppColors.supplierLight
                                                      : AppColors.incomeLight,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10),
                                                ),
                                                child: Text(
                                                  hasDue
                                                      ? l.customersChipDue
                                                      : l.customersChipSettled,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: hasDue
                                                        ? AppColors.supplier
                                                        : AppColors.success,
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
        onPressed: () => context.push('/app/suppliers/add'),
        backgroundColor: AppColors.supplier,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l.suppliersAdd),
      ),
    );
  }
}

class AddEditSupplierScreen extends StatefulWidget {
  final String? supplierId;
  const AddEditSupplierScreen({super.key, this.supplierId});
  @override
  State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool get _isEditing => widget.supplierId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final provider = context.read<SupplierProvider>();
    final businessId = auth.user?.businessId;
    final userId = auth.user?.uid;
    if (businessId == null || userId == null) return;
    final now = DateTime.now();
    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    if (_isEditing) {
      final ok = await provider.updateSupplier(
          businessId, widget.supplierId!, data);
      if (!mounted) return;
      if (ok) {
        context.pop(true);
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      final supplier = Supplier(
        id: '',
        businessId: businessId,
        userId: userId,
        name: data['name'] as String,
        phone: data['phone'] as String,
        address: data['address'] as String,
        createdAt: now,
        updatedAt: now,
      );
      final id = await provider.addSupplier(supplier);
      if (!mounted) return;
      if (id != null) {
        context.pop(true);
      } else if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _hasUnsavedChanges() {
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
        title: Text(l.suppliersDiscardTitle),
        content: Text(l.suppliersDiscardBody),
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
        appBar: AppBar(
          title: Text(_isEditing ? l.suppliersEditSupplier : l.suppliersAdd),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l.suppliersFormNameLabel,
                  hint: l.suppliersFormNameHint,
                  controller: _nameController,
                  validator: (v) => Validators.name(v, l.suppliersFormNameLabel),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l.suppliersFormPhoneLabel,
                  hint: l.suppliersFormPhoneHint,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: l.suppliersAddress,
                  hint: l.customersFormAddressHint,
                  controller: _addressController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                Consumer<SupplierProvider>(
                  builder: (context, provider, _) {
                    return AppButton(
                      text: _isEditing
                          ? l.suppliersUpdateSupplier
                          : l.suppliersAdd,
                      isLoading: provider.isSubmitting,
                      onPressed: _saveSupplier,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
