import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  Future<void> _runNow(BuildContext context, WidgetRef ref, RecurringModel r) async {
    await ref.read(transactionRepoProvider).insert(TransactionModel(
          type: r.type,
          amount: r.amount,
          categoryId: r.categoryId,
          accountId: r.accountId,
          date: DateTime.now(),
          note: r.note,
          isRecurring: true,
          createdAt: DateTime.now(),
        ));
    await ref.read(recurringRepoProvider).update(r.copyWith(nextDate: r.computeNextDate()));
    notifyDataChanged(ref);
    if (context.mounted) context.showSnack('Transaction recorded from recurring schedule');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete recurring transaction?',
      message: 'This will stop future automatic transactions. Past records stay unchanged.',
    );
    if (!confirmed) return;
    await ref.read(recurringRepoProvider).delete(id);
    notifyDataChanged(ref);
    if (context.mounted) context.showSnack('Recurring transaction deleted');
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
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Transactions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/recurring/add'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: recurringAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 10), child: SkeletonCard(height: 74))),
          ),
          error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
          data: (items) {
            if (items.isEmpty) {
              return EmptyState(
                icon: LucideIcons.repeat,
                title: 'No recurring transactions',
                message: 'Automate things like salary, rent, or subscriptions.',
                actionLabel: 'Add recurring',
                onAction: () => context.push('/recurring/add'),
              );
            }
            final categories = categoriesAsync.valueOrNull ?? const <CategoryModel>[];
            final accounts = accountsAsync.valueOrNull ?? const <AccountModel>[];
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = items[i];
                final category = categories.where((c) => c.id == r.categoryId).cast<CategoryModel?>().firstWhere((_) => true, orElse: () => null);
                final account = accounts.where((a) => a.id == r.accountId).cast<AccountModel?>().firstWhere((_) => true, orElse: () => null);
                final isExpense = r.type == TransactionType.expense;
                return AppCard(
                  onTap: () => context.push('/recurring/edit/${r.id}'),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: category != null ? iconFromKey(category.icon) : LucideIcons.repeat,
                        color: isExpense ? AppColors.expense : AppColors.income,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.note?.isNotEmpty == true ? r.note! : (category?.name ?? 'Transaction'),
                                style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('${_frequencyLabel(r.frequency)} · next ${DateFormatter.short(r.nextDate)} · ${account?.name ?? ''}',
                                style: context.textStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(CurrencyFormatter.formatSigned(r.amount, isExpense: isExpense),
                              style: AppTextStyles.amount(isExpense ? AppColors.expense : AppColors.income, size: 14)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _runNow(context, ref, r),
                                child: Text('Run now', style: TextStyle(color: context.colors.primary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => _delete(context, ref, r.id!),
                                child: const Text('Delete', style: TextStyle(color: AppColors.expense, fontSize: 11.5, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
