import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _fromId;
  int? _toId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickAccount({required bool isTo}) async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final selected = await showAppBottomSheet<int>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isTo ? 'Transfer to' : 'Transfer from', style: context.textStyles.titleLarge),
          const SizedBox(height: 8),
          ...accounts.map((a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IconBadge(icon: iconFromKey(a.icon), color: colorFromHex(a.color)),
                title: Text(a.name),
                trailing: (isTo ? _toId : _fromId) == a.id
                    ? Icon(LucideIcons.check, color: context.colors.primary)
                    : null,
                onTap: () => Navigator.pop(context, a.id),
              )),
        ],
      ),
    );
    if (selected != null) setState(() => isTo ? _toId = selected : _fromId = selected);
  }

  Future<void> _swap() async {
    setState(() {
      final temp = _fromId;
      _fromId = _toId;
      _toId = temp;
    });
  }

  Future<void> _save() async {
    if (CurrencyFormatter.parse(_amountController.text) <= 0) {
      context.showSnack('Amount must be greater than 0', isError: true);
      return;
    }
    if (_fromId == null || _toId == null) {
      context.showSnack('Choose both accounts', isError: true);
      return;
    }
    if (_fromId == _toId) {
      context.showSnack('Source and destination must be different', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final model = TransactionModel(
        type: TransactionType.transfer,
        amount: CurrencyFormatter.parse(_amountController.text),
        accountId: _fromId!,
        toAccountId: _toId!,
        date: _date,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(transactionRepoProvider).insert(model);
      notifyDataChanged(ref);
      if (mounted) {
        context.showSnack('Transfer successful');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnack('Transfer failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull ?? const <AccountModel>[];
    final from = accounts.where((a) => a.id == _fromId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);
    final to = accounts.where((a) => a.id == _toId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 40),
          children: [
            AmountInput(controller: _amountController, color: AppColors.info),
            const SizedBox(height: 28),
            AppCard(
              child: Column(
                children: [
                  _AccountPickTile(label: 'From', account: from, onTap: () => _pickAccount(isTo: false)),
                  Center(
                    child: IconButton(
                      onPressed: _swap,
                      icon: const Icon(LucideIcons.arrowUpDown, size: 18),
                    ),
                  ),
                  _AccountPickTile(label: 'To', account: to, onTap: () => _pickAccount(isTo: true)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date', style: context.textStyles.labelLarge),
                const SizedBox(height: 8),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormatter.short(_date)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(controller: _noteController, label: 'Note', hint: 'Optional', maxLines: 2),
            const SizedBox(height: 32),
            AppButton(label: 'Transfer', icon: LucideIcons.arrowLeftRight, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _AccountPickTile extends StatelessWidget {
  const _AccountPickTile({required this.label, required this.account, required this.onTap});
  final String label;
  final AccountModel? account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(
              icon: account != null ? iconFromKey(account!.icon) : LucideIcons.wallet,
              color: account != null ? colorFromHex(account!.color) : AppColors.info,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textStyles.bodySmall),
                  Text(account?.name ?? 'Select account',
                      style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 16, color: context.textStyles.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
