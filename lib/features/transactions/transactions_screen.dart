import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../providers/providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  TransactionType? _typeFilter;
  int? _categoryFilter;
  int? _accountFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionSort _sort = TransactionSort.newest;
  String _query = '';

  TransactionFilter get _filter => TransactionFilter(
        query: _query.isEmpty ? null : _query,
        type: _typeFilter,
        categoryId: _categoryFilter,
        accountId: _accountFilter,
        startDate: _startDate,
        endDate: _endDate,
        sort: _sort,
      );

  bool get _hasAdvancedFilter =>
      _categoryFilter != null || _accountFilter != null || _startDate != null || _endDate != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilterSheet() async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    int? tempCategory = _categoryFilter;
    int? tempAccount = _accountFilter;
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;

    await showAppBottomSheet(
      context,
      child: StatefulBuilder(builder: (context, setSheetState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter transaksi', style: context.textStyles.titleLarge),
            const SizedBox(height: 18),
            Text('Category', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(
                  label: 'All',
                  selected: tempCategory == null,
                  onTap: () => setSheetState(() => tempCategory = null),
                ),
                ...categories.map((c) => AppChip(
                      label: c.name,
                      selected: tempCategory == c.id,
                      color: colorFromHex(c.color),
                      onTap: () => setSheetState(() => tempCategory = c.id),
                    )),
              ],
            ),
            const SizedBox(height: 18),
            Text('Account', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(
                  label: 'All',
                  selected: tempAccount == null,
                  onTap: () => setSheetState(() => tempAccount = null),
                ),
                ...accounts.map((a) => AppChip(
                      label: a.name,
                      selected: tempAccount == a.id,
                      onTap: () => setSheetState(() => tempAccount = a.id),
                    )),
              ],
            ),
            const SizedBox(height: 18),
            Text('Date range', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempStart ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setSheetState(() => tempStart = picked);
                    },
                    child: Text(tempStart == null ? 'Start date' : DateFormatter.short(tempStart!)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempEnd ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setSheetState(() => tempEnd = picked);
                    },
                    child: Text(tempEnd == null ? 'End date' : DateFormatter.short(tempEnd!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Reset',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => setSheetState(() {
                      tempCategory = null;
                      tempAccount = null;
                      tempStart = null;
                      tempEnd = null;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Apply',
                    onPressed: () {
                      setState(() {
                        _categoryFilter = tempCategory;
                        _accountFilter = tempAccount;
                        _startDate = tempStart;
                        _endDate = tempEnd;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<void> _openSortSheet() async {
    final labels = {
      TransactionSort.newest: 'Newest',
      TransactionSort.oldest: 'Oldest',
      TransactionSort.highest: 'Highest amount',
      TransactionSort.lowest: 'Lowest amount',
    };
    await showAppBottomSheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sort by', style: context.textStyles.titleLarge),
          const SizedBox(height: 12),
          ...labels.entries.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value),
                trailing: _sort == e.key ? Icon(LucideIcons.check, color: context.colors.primary) : null,
                onTap: () {
                  setState(() => _sort = e.key);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(TransactionModel transaction) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete transaction?',
      message: 'This transaction will be permanently removed.',
    );
    if (!confirmed) return;
    await ref.read(transactionRepoProvider).delete(transaction.id!);
    notifyDataChanged(ref);
    if (mounted) context.showSnack('Transaction deleted');
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider(_filter));
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/add'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 4, context.horizontalPadding, 12),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      hint: 'Search transaction',
                      prefixIcon: LucideIcons.search,
                      onTap: null,
                    ),
                  ),
                ],
              ),
            ),
            _SearchListener(controller: _searchController, onChanged: (v) => setState(() => _query = v)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AppChip(
                            label: 'All',
                            selected: _typeFilter == null,
                            onTap: () => setState(() => _typeFilter = null),
                          ),
                          const SizedBox(width: 8),
                          AppChip(
                            label: 'Income',
                            selected: _typeFilter == TransactionType.income,
                            color: AppColors.income,
                            onTap: () => setState(() => _typeFilter = TransactionType.income),
                          ),
                          const SizedBox(width: 8),
                          AppChip(
                            label: 'Expense',
                            selected: _typeFilter == TransactionType.expense,
                            color: AppColors.expense,
                            onTap: () => setState(() => _typeFilter = TransactionType.expense),
                          ),
                          const SizedBox(width: 8),
                          AppChip(
                            label: 'Transfer',
                            selected: _typeFilter == TransactionType.transfer,
                            color: AppColors.info,
                            onTap: () => setState(() => _typeFilter = TransactionType.transfer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openSortSheet,
                    icon: const Icon(LucideIcons.arrowUpDown, size: 20),
                    tooltip: 'Sort',
                  ),
                  IconButton(
                    onPressed: _openFilterSheet,
                    icon: Icon(LucideIcons.slidersHorizontal,
                        size: 20, color: _hasAdvancedFilter ? context.colors.primary : null),
                    tooltip: 'Filter',
                  ),
                ],
              ),
            ),
            Expanded(
              child: transactionsAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: List.generate(
                      6, (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonCard(height: 64))),
                ),
                error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const EmptyState(
                      icon: LucideIcons.receipt,
                      title: 'No transactions found',
                      message: 'Try adjusting your search or filters.',
                    );
                  }
                  final categories = categoriesAsync.valueOrNull ?? const <CategoryModel>[];
                  final accounts = accountsAsync.valueOrNull ?? const <AccountModel>[];

                  final groups = <String, List<TransactionModel>>{};
                  for (final t in transactions) {
                    final label = DateFormatter.groupLabel(t.date);
                    groups.putIfAbsent(label, () => []).add(t);
                  }

                  return ListView(
                    padding: EdgeInsets.fromLTRB(context.horizontalPadding, 4, context.horizontalPadding, 100),
                    children: groups.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(entry.key.toUpperCase(),
                                style: context.textStyles.labelSmall?.copyWith(letterSpacing: 0.5)),
                          ),
                          ...entry.value.map((t) => Slidable(
                                key: ValueKey(t.id),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.5,
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => context.push('/transactions/edit/${t.id}'),
                                      backgroundColor: AppColors.info,
                                      foregroundColor: Colors.white,
                                      icon: LucideIcons.pencil,
                                      label: 'Edit',
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    const SizedBox(width: 6),
                                    SlidableAction(
                                      onPressed: (_) => _confirmDelete(t),
                                      backgroundColor: AppColors.expense,
                                      foregroundColor: Colors.white,
                                      icon: LucideIcons.trash2,
                                      label: 'Delete',
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ],
                                ),
                                child: TransactionTile(
                                  transaction: t,
                                  category: t.categoryId == null
                                      ? null
                                      : categories.where((c) => c.id == t.categoryId).firstOrNull,
                                  account: accounts.where((a) => a.id == t.accountId).firstOrNull,
                                  onTap: () => context.push('/transactions/detail/${t.id}'),
                                ),
                              )),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Widget kecil untuk mendengarkan perubahan search field tanpa rebuild parent penuh.
class _SearchListener extends StatefulWidget {
  const _SearchListener({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchListener> createState() => _SearchListenerState();
}

class _SearchListenerState extends State<_SearchListener> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listen);
  }

  void _listen() => widget.onChanged(widget.controller.text);

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
