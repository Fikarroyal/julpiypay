import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});
  final int transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction detail'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 20),
            onPressed: () => context.push('/transactions/edit/$transactionId'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20),
            onPressed: () async {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Delete transaction?',
                message: 'This transaction will be permanently removed.',
              );
              if (!confirmed) return;
              await ref.read(transactionRepoProvider).delete(transactionId);
              notifyDataChanged(ref);
              if (context.mounted) {
                context.showSnack('Transaction deleted');
                context.pop();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<TransactionModel?>(
        future: ref.read(transactionRepoProvider).getById(transactionId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tx = snapshot.data;
          if (tx == null) {
            return const EmptyState(
              icon: LucideIcons.receipt,
              title: 'Transaction not found',
              message: 'This transaction may have been deleted.',
            );
          }
          return Consumer(builder: (context, ref, _) {
            final categories = ref.watch(categoriesProvider).valueOrNull ?? const <CategoryModel>[];
            final accounts = ref.watch(accountsProvider).valueOrNull ?? const <AccountModel>[];
            final tags = ref.watch(tagsProvider).valueOrNull ?? const [];

            final category = tx.categoryId == null
                ? null
                : categories.where((c) => c.id == tx.categoryId).cast<CategoryModel?>().firstWhere((_) => true, orElse: () => null);
            final account = accounts.where((a) => a.id == tx.accountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);
            final toAccount = tx.toAccountId == null
                ? null
                : accounts.where((a) => a.id == tx.toAccountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);
            final isExpense = tx.type == TransactionType.expense;
            final color = tx.type == TransactionType.transfer
                ? AppColors.info
                : (isExpense ? AppColors.expense : AppColors.income);
            final txTags = tags.where((t) => tx.tagIds.contains(t.id)).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      IconBadge(
                        icon: category != null ? iconFromKey(category.icon) : LucideIcons.arrowLeftRight,
                        color: category != null ? colorFromHex(category.color) : color,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tx.type == TransactionType.transfer
                            ? CurrencyFormatter.format(tx.amount)
                            : CurrencyFormatter.formatSigned(tx.amount, isExpense: isExpense),
                        style: AppTextStyles.amount(color, size: 30),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.type == TransactionType.transfer ? 'Transfer' : (category?.name ?? 'Uncategorized'),
                        style: context.textStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AppCard(
                  child: Column(
                    children: [
                      _DetailRow(label: 'Date', value: DateFormatter.full(tx.date)),
                      _divider(context),
                      _DetailRow(label: 'Time', value: DateFormatter.time(tx.date)),
                      _divider(context),
                      _DetailRow(
                          label: tx.type == TransactionType.transfer ? 'From account' : 'Account',
                          value: account?.name ?? ','),
                      if (toAccount != null) ...[
                        _divider(context),
                        _DetailRow(label: 'To account', value: toAccount.name),
                      ],
                      if (tx.note != null && tx.note!.isNotEmpty) ...[
                        _divider(context),
                        _DetailRow(label: 'Note', value: tx.note!),
                      ],
                    ],
                  ),
                ),
                if (txTags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Tags', style: context.textStyles.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: txTags.map((t) => AppChip(label: t.name, selected: true)).toList(),
                  ),
                ],
              ],
            );
          });
        },
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(height: 20, color: context.theme.dividerColor);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.textStyles.bodySmall),
        Flexible(
          child: Text(value,
              style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
