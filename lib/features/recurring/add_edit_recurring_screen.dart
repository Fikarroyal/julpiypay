import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditRecurringScreen extends ConsumerStatefulWidget {
  const AddEditRecurringScreen({super.key, this.recurringId});
  final int? recurringId;

  @override
  ConsumerState<AddEditRecurringScreen> createState() => _AddEditRecurringScreenState();
}

class _AddEditRecurringScreenState extends ConsumerState<AddEditRecurringScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  int? _categoryId;
  int? _accountId;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _nextDate = DateTime.now();
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.recurringId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadExisting();
    } else {
      _loaded = true;
    }
  }

  Future<void> _loadExisting() async {
    final items = await ref.read(recurringRepoProvider).getAll();
    final r = items.where((e) => e.id == widget.recurringId).cast<RecurringModel?>().firstWhere((_) => true, orElse: () => null);
    if (r == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _type = r.type;
      _categoryId = r.categoryId;
      _accountId = r.accountId;
      _frequency = r.frequency;
      _nextDate = r.nextDate;
      _amountController.text = r.amount.toStringAsFixed(0);
      _noteController.text = r.note ?? '';
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final categories = await ref.read(categoriesByTypeProvider(
        _type == TransactionType.income ? CategoryType.income : CategoryType.expense).future);
    final selected = await showAppBottomSheet<int>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select category', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          ...categories.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: iconFromKey(c.icon), color: colorFromHex(c.color)),
                title: Text(c.name),
                onTap: () => Navigator.pop(context, c.id),
              )),
        ],
      ),
    );
    if (selected != null) setState(() => _categoryId = selected);
  }

  Future<void> _pickAccount() async {
    final accounts = await ref.read(accountsProvider.future);
    final selected = await showAppBottomSheet<int>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select account', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          ...accounts.map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: iconFromKey(a.icon), color: colorFromHex(a.color)),
                title: Text(a.name),
                onTap: () => Navigator.pop(context, a.id),
              )),
        ],
      ),
    );
    if (selected != null) setState(() => _accountId = selected);
  }

  Future<void> _save() async {
    if (CurrencyFormatter.parse(_amountController.text) <= 0) {
      context.showSnack('Amount must be greater than 0', isError: true);
      return;
    }
    if (_categoryId == null || _accountId == null) {
      context.showSnack('Category and account are required', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = RecurringModel(
        id: widget.recurringId,
        type: _type,
        amount: CurrencyFormatter.parse(_amountController.text),
        categoryId: _categoryId,
        accountId: _accountId!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        frequency: _frequency,
        nextDate: _nextDate,
      );
      if (_isEdit) {
        await ref.read(recurringRepoProvider).update(model);
      } else {
        await ref.read(recurringRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Recurring transaction updated' : 'Recurring transaction added');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _frequencyLabel(RecurringFrequency f) {
    switch (f) {
      case RecurringFrequency.daily:
        return 'Daily';
      case RecurringFrequency.weekly:
        return 'Weekly';
      case RecurringFrequency.monthly:
        return 'Monthly';
      case RecurringFrequency.yearly:
        return 'Yearly';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final categoriesAsync = ref.watch(categoriesByTypeProvider(
        _type == TransactionType.income ? CategoryType.income : CategoryType.expense));
    final accountsAsync = ref.watch(accountsProvider);
    final category = (categoriesAsync.valueOrNull ?? []).where((c) => c.id == _categoryId).cast<CategoryModel?>().firstWhere((_) => true, orElse: () => null);
    final account = (accountsAsync.valueOrNull ?? []).where((a) => a.id == _accountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit recurring' : 'Add recurring')),
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
                children: [TransactionType.income, TransactionType.expense].map((t) {
                  final selected = _type == t;
                  final color = t == TransactionType.income ? AppColors.income : AppColors.expense;
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
                        child: Text(t == TransactionType.income ? 'Income' : 'Expense',
                            style: TextStyle(color: selected ? color : context.textStyles.bodyMedium?.color, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              keyboardType: TextInputType.number,
              prefixIcon: LucideIcons.banknote,
            ),
            const SizedBox(height: 20),
            Text('Category', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickCategory,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(category != null ? iconFromKey(category.icon) : LucideIcons.tag, size: 18, color: category != null ? colorFromHex(category.color) : null),
                  const SizedBox(width: 10),
                  Expanded(child: Text(category?.name ?? 'Select category')),
                  const Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Account', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickAccount,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(account != null ? iconFromKey(account.icon) : LucideIcons.wallet, size: 18, color: account != null ? colorFromHex(account.color) : null),
                  const SizedBox(width: 10),
                  Expanded(child: Text(account?.name ?? 'Select account')),
                  const Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Frequency', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RecurringFrequency.values
                  .map((f) => AppChip(label: _frequencyLabel(f), selected: _frequency == f, onTap: () => setState(() => _frequency = f)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Next date', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _nextDate = picked);
              },
              child: Row(children: [const Icon(LucideIcons.calendar, size: 18), const SizedBox(width: 10), Text(DateFormatter.short(_nextDate))]),
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _noteController, label: 'Note', hint: 'e.g. Salary, Netflix, Rent', maxLines: 2),
            const SizedBox(height: 28),
            AppButton(label: 'Save recurring transaction', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
