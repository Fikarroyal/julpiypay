import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AddEditBillScreen extends ConsumerStatefulWidget {
  const AddEditBillScreen({super.key, this.billId});
  final int? billId;

  @override
  ConsumerState<AddEditBillScreen> createState() => _AddEditBillScreenState();
}

class _AddEditBillScreenState extends ConsumerState<AddEditBillScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  int? _categoryId;
  int? _accountId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _isRecurring = false;
  bool _reminder = true;
  bool _saving = false;
  bool _loaded = false;

  bool get _isEdit => widget.billId != null;

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
    final bills = await ref.read(billRepoProvider).getAll();
    final bill = bills.where((b) => b.id == widget.billId).cast<BillModel?>().firstWhere((_) => true, orElse: () => null);
    if (bill == null) {
      if (mounted) context.pop();
      return;
    }
    setState(() {
      _nameController.text = bill.name;
      _amountController.text = bill.amount.toStringAsFixed(0);
      _categoryId = bill.categoryId;
      _accountId = bill.accountId;
      _dueDate = bill.dueDate;
      _isRecurring = bill.isRecurring;
      _reminder = bill.reminder;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
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
    if (_nameController.text.trim().isEmpty) {
      context.showSnack('Bill name is required', isError: true);
      return;
    }
    if (CurrencyFormatter.parse(_amountController.text) <= 0) {
      context.showSnack('Amount must be greater than 0', isError: true);
      return;
    }
    if (_accountId == null) {
      context.showSnack('Account is required', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = BillModel(
        id: widget.billId,
        name: _nameController.text.trim(),
        amount: CurrencyFormatter.parse(_amountController.text),
        dueDate: _dueDate,
        categoryId: _categoryId,
        accountId: _accountId!,
        isRecurring: _isRecurring,
        reminder: _reminder,
      );
      if (_isEdit) {
        await ref.read(billRepoProvider).update(model);
      } else {
        await ref.read(billRepoProvider).insert(model);
      }
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack(_isEdit ? 'Bill updated' : 'Bill added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Failed to save bill: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final categoriesAsync = ref.watch(categoriesByTypeProvider(CategoryType.expense));
    final accountsAsync = ref.watch(accountsProvider);
    final category = (categoriesAsync.valueOrNull ?? []).where((c) => c.id == _categoryId).cast<CategoryModel?>().firstWhere((_) => true, orElse: () => null);
    final account = (accountsAsync.valueOrNull ?? []).where((a) => a.id == _accountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit bill' : 'Add bill')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
          children: [
            AppTextField(controller: _nameController, label: 'Bill name', hint: 'e.g. Internet, Electricity'),
            const SizedBox(height: 20),
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              keyboardType: TextInputType.number,
              prefixIcon: LucideIcons.banknote,
            ),
            const SizedBox(height: 20),
            Text('Due date', style: context.textStyles.labelLarge),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Row(children: [const Icon(LucideIcons.calendar, size: 18), const SizedBox(width: 10), Text(DateFormatter.short(_dueDate))]),
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
                  Expanded(child: Text(category?.name ?? 'Select category (optional)')),
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
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              title: const Text('Recurring bill'),
              subtitle: const Text('Automatically rolls over to next month when paid'),
              activeColor: context.colors.primary,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reminder,
              onChanged: (v) => setState(() => _reminder = v),
              title: const Text('Reminder'),
              subtitle: const Text('Show this bill on the dashboard when it is due soon'),
              activeColor: context.colors.primary,
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Save bill', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
