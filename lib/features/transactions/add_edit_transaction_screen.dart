import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  const AddEditTransactionScreen({super.key, this.transactionId, this.initialType});

  final int? transactionId;
  final TransactionType? initialType;

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  TransactionType _type = TransactionType.expense;
  int? _categoryId;
  int? _accountId;
  int? _toAccountId;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  Set<int> _tagIds = {};
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.expense;
    if (_isEdit) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final tx = await ref.read(transactionRepoProvider).getById(widget.transactionId!);
    if (tx == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _type = tx.type;
      _categoryId = tx.categoryId;
      _accountId = tx.accountId;
      _toAccountId = tx.toAccountId;
      _date = tx.date;
      _noteController.text = tx.note ?? '';
      _tagIds = tx.tagIds.toSet();
      _amountController.text = tx.amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Color get _typeColor => _type == TransactionType.expense
      ? AppColors.expense
      : _type == TransactionType.income
          ? AppColors.income
          : AppColors.info;

  Future<void> _pickCategory() async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final filtered = categories
        .where((c) => c.type == (_type == TransactionType.income ? CategoryType.income : CategoryType.expense))
        .toList();
    final selected = await showAppBottomSheet<int>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Select category', style: context.textStyles.titleLarge),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.push('/categories/add',
                      extra: _type == TransactionType.income ? CategoryType.income : CategoryType.expense);
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: LucideIcons.tag,
                title: 'No categories yet',
                message: 'Add a category first to categorize this transaction.',
              ),
            ),
          ...filtered.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: iconFromKey(c.icon), color: colorFromHex(c.color)),
                title: Text(c.name),
                trailing: _categoryId == c.id ? Icon(LucideIcons.check, color: context.colors.primary) : null,
                onTap: () => Navigator.pop(context, c.id),
              )),
        ],
      ),
    );
    if (selected != null) setState(() => _categoryId = selected);
  }

  Future<void> _pickAccount({required bool isDestination}) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final selected = await showAppBottomSheet<int>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isDestination ? 'Select destination account' : 'Select account',
              style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: LucideIcons.wallet,
                title: 'No accounts yet',
                message: 'Add an account first.',
              ),
            ),
          ...accounts.map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: iconFromKey(a.icon), color: colorFromHex(a.color)),
                title: Text(a.name),
                trailing: (isDestination ? _toAccountId : _accountId) == a.id
                    ? Icon(LucideIcons.check, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(context, a.id),
              )),
        ],
      ),
    );
    if (selected != null) {
      setState(() => isDestination ? _toAccountId = selected : _accountId = selected);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_amountController.text.trim().isEmpty || CurrencyFormatter.parse(_amountController.text) <= 0) {
      context.showSnack('Amount must be greater than 0', isError: true);
      return;
    }
    if (_accountId == null) {
      context.showSnack('Account is required', isError: true);
      return;
    }
    if (_type != TransactionType.transfer && _categoryId == null) {
      context.showSnack('Category is required', isError: true);
      return;
    }
    if (_type == TransactionType.transfer && (_toAccountId == null || _toAccountId == _accountId)) {
      context.showSnack('Choose a different destination account', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final amount = CurrencyFormatter.parse(_amountController.text);
      final combinedDate = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
      final model = TransactionModel(
        id: widget.transactionId,
        type: _type,
        amount: amount,
        categoryId: _type == TransactionType.transfer ? null : _categoryId,
        accountId: _accountId!,
        toAccountId: _type == TransactionType.transfer ? _toAccountId : null,
        date: combinedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: DateTime.now(),
        tagIds: _tagIds.toList(),
      );

      if (_isEdit) {
        await ref.read(transactionRepoProvider).update(model);
      } else {
        await ref.read(transactionRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Transaction updated' : 'Transaction added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save transaction: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final tagsAsync = ref.watch(tagsProvider);

    final categories = categoriesAsync.valueOrNull ?? const <CategoryModel>[];
    final accounts = accountsAsync.valueOrNull ?? const <AccountModel>[];
    final tags = tagsAsync.valueOrNull ?? const [];

    final selectedCategory = categories.where((c) => c.id == _categoryId).cast<CategoryModel?>().firstOrElseNull();
    final selectedAccount = accounts.where((a) => a.id == _accountId).cast<AccountModel?>().firstOrElseNull();
    final selectedToAccount = accounts.where((a) => a.id == _toAccountId).cast<AccountModel?>().firstOrElseNull();

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit transaction' : 'Add transaction')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.theme.dividerColor),
              ),
              child: Row(
                children: TransactionType.values.map((t) {
                  final selected = _type == t;
                  final label = t == TransactionType.expense
                      ? 'Expense'
                      : t == TransactionType.income
                          ? 'Income'
                          : 'Transfer';
                  final color = t == TransactionType.expense
                      ? AppColors.expense
                      : t == TransactionType.income
                          ? AppColors.income
                          : AppColors.info;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = t;
                        _categoryId = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(context.isDark ? 0.25 : 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(label,
                            style: TextStyle(
                                color: selected ? color : context.textStyles.bodyMedium?.color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
            AmountInput(controller: _amountController, color: _typeColor),
            const SizedBox(height: 28),

            if (_type != TransactionType.transfer) ...[
              _PickerRow(
                label: 'Category',
                value: selectedCategory?.name ?? 'Select category',
                icon: selectedCategory != null ? iconFromKey(selectedCategory.icon) : LucideIcons.tag,
                iconColor: selectedCategory != null ? colorFromHex(selectedCategory.color) : null,
                onTap: _pickCategory,
              ),
              const SizedBox(height: 12),
            ],
            _PickerRow(
              label: _type == TransactionType.transfer ? 'From account' : 'Account',
              value: selectedAccount?.name ?? 'Select account',
              icon: selectedAccount != null ? iconFromKey(selectedAccount.icon) : LucideIcons.wallet,
              iconColor: selectedAccount != null ? colorFromHex(selectedAccount.color) : null,
              onTap: () => _pickAccount(isDestination: false),
            ),
            if (_type == TransactionType.transfer) ...[
              const SizedBox(height: 12),
              _PickerRow(
                label: 'To account',
                value: selectedToAccount?.name ?? 'Select destination account',
                icon: selectedToAccount != null ? iconFromKey(selectedToAccount.icon) : LucideIcons.wallet,
                iconColor: selectedToAccount != null ? colorFromHex(selectedToAccount.color) : null,
                onTap: () => _pickAccount(isDestination: true),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerRow(
                    label: 'Date',
                    value: DateFormatter.short(_date),
                    icon: LucideIcons.calendar,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerRow(
                    label: 'Time',
                    value: _time.format(context),
                    icon: LucideIcons.clock,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _noteController,
              label: 'Note',
              hint: 'Optional',
              maxLines: 2,
            ),
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 20),
              Text('Tags', style: context.textStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...tags.map((t) => AppChip(
                        label: t.name,
                        selected: _tagIds.contains(t.id),
                        onTap: () => setState(() {
                          if (_tagIds.contains(t.id)) {
                            _tagIds.remove(t.id);
                          } else {
                            _tagIds.add(t.id!);
                          }
                        }),
                      )),
                  ActionChip(
                    avatar: const Icon(LucideIcons.plus, size: 14),
                    label: const Text('Add tag'),
                    onPressed: () => context.push('/tags'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            AppButton(label: 'Save transaction', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrElseNull<T> on Iterable<T> {
  T? firstOrElseNull() {
    for (final e in this) {
      return e;
    }
    return null;
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.textStyles.labelLarge),
        const SizedBox(height: 8),
        AppCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor ?? context.textStyles.bodySmall?.color),
              const SizedBox(width: 10),
              Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
              Icon(LucideIcons.chevronRight, size: 16, color: context.textStyles.bodySmall?.color),
            ],
          ),
        ),
      ],
    );
  }
}
