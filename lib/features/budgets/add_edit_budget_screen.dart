import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditBudgetScreen extends ConsumerStatefulWidget {
  const AddEditBudgetScreen({super.key, this.budgetId});
  final int? budgetId;

  @override
  ConsumerState<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends ConsumerState<AddEditBudgetScreen> {
  final _amountController = TextEditingController();
  int? _categoryId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  double _threshold = 0.8;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.budgetId != null;

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
    final budgets = await ref.read(budgetRepoProvider).getAll();
    final budget = budgets.where((b) => b.id == widget.budgetId).cast<BudgetModel?>().firstWhere((_) => true, orElse: () => null);
    if (budget == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _categoryId = budget.categoryId;
      _amountController.text = budget.amount.toStringAsFixed(0);
      _period = budget.period;
      _startDate = budget.startDate;
      _threshold = budget.notificationThreshold;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  DateTime _endDateFor(DateTime start, BudgetPeriod period) {
    switch (period) {
      case BudgetPeriod.weekly:
        return start.add(const Duration(days: 6));
      case BudgetPeriod.monthly:
        return DateTime(start.year, start.month + 1, start.day - 1);
      case BudgetPeriod.yearly:
        return DateTime(start.year + 1, start.month, start.day - 1);
    }
  }

  Future<void> _pickCategory() async {
    final categories = await ref.read(categoriesByTypeProvider(CategoryType.expense).future);
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
                trailing: _categoryId == c.id ? Icon(LucideIcons.check, color: context.colors.primary) : null,
                onTap: () => Navigator.pop(context, c.id),
              )),
        ],
      ),
    );
    if (selected != null) setState(() => _categoryId = selected);
  }

  Future<void> _save() async {
    if (_categoryId == null) {
      context.showSnack('Category is required', isError: true);
      return;
    }
    if (CurrencyFormatter.parse(_amountController.text) <= 0) {
      context.showSnack('Amount must be greater than 0', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = BudgetModel(
        id: widget.budgetId,
        categoryId: _categoryId!,
        amount: CurrencyFormatter.parse(_amountController.text),
        period: _period,
        startDate: _startDate,
        endDate: _endDateFor(_startDate, _period),
        notificationThreshold: _threshold,
      );
      if (_isEdit) {
        await ref.read(budgetRepoProvider).update(model);
      } else {
        await ref.read(budgetRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Budget updated' : 'Budget added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save budget: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final categoriesAsync = ref.watch(categoriesByTypeProvider(CategoryType.expense));
    final categories = categoriesAsync.valueOrNull ?? const [];
    final selectedCategory = categories.where((c) => c.id == _categoryId).cast<CategoryModel?>().firstWhere((_) => true, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit budget' : 'Add budget')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
          children: [
            Text('Category', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              onTap: _pickCategory,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    selectedCategory != null ? iconFromKey(selectedCategory.icon) : LucideIcons.tag,
                    size: 18,
                    color: selectedCategory != null ? colorFromHex(selectedCategory.color) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(selectedCategory?.name ?? 'Select category')),
                  const Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _amountController,
              label: 'Budget amount',
              keyboardType: TextInputType.number,
              prefixIcon: LucideIcons.banknote,
            ),
            const SizedBox(height: 20),
            Text('Period', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                AppChip(label: 'Weekly', selected: _period == BudgetPeriod.weekly, onTap: () => setState(() => _period = BudgetPeriod.weekly)),
                AppChip(label: 'Monthly', selected: _period == BudgetPeriod.monthly, onTap: () => setState(() => _period = BudgetPeriod.monthly)),
                AppChip(label: 'Yearly', selected: _period == BudgetPeriod.yearly, onTap: () => setState(() => _period = BudgetPeriod.yearly)),
              ],
            ),
            const SizedBox(height: 20),
            Text('Start date', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 18),
                  const SizedBox(width: 10),
                  Text(DateFormatter.short(_startDate)),
                  const Spacer(),
                  Text('ends ${DateFormatter.short(_endDateFor(_startDate, _period))}',
                      style: context.textStyles.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Notify me at ${(_threshold * 100).toStringAsFixed(0)}% used',
                style: context.textStyles.labelLarge),
            Slider(
              value: _threshold,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              activeColor: context.colors.primary,
              onChanged: (v) => setState(() => _threshold = v),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Save budget', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
