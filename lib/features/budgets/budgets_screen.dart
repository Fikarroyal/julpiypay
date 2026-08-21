import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers/providers.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete budget?',
      message: 'This budget will be permanently removed.',
    );
    if (!confirmed) return;
    await ref.read(budgetRepoProvider).delete(id);
    notifyDataChanged(ref);
    if (context.mounted) context.showSnack('Budget deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetProgressListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/budgets/add'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: budgetsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(4, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12), child: SkeletonCard(height: 110))),
          ),
          error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
          data: (budgets) {
            if (budgets.isEmpty) {
              return EmptyState(
                icon: LucideIcons.walletCards,
                title: 'No budgets yet',
                message: 'Set a spending limit for a category to stay on track.',
                actionLabel: 'Add budget',
                onAction: () => context.push('/budgets/add'),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
              itemCount: budgets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final b = budgets[i];
                final danger = b.percent >= 1;
                final warning = b.percent >= 0.8 && !danger;
                return AppCard(
                  onTap: () => context.push('/budgets/edit/${b.budget.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBadge(icon: iconFromKey(b.category.icon), color: colorFromHex(b.category.color)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.category.name, style: context.textStyles.titleSmall),
                                Text(_periodLabel(b.budget.period), style: context.textStyles.bodySmall),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            color: AppColors.expense,
                            onPressed: () => _delete(context, ref, b.budget.id!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${CurrencyFormatter.format(b.spent)} / ${CurrencyFormatter.format(b.budget.amount)}',
                            style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text('${(b.percent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: danger ? AppColors.expense : (warning ? AppColors.warning : context.colors.primary),
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressStatusBar(percent: b.percent),
                      const SizedBox(height: 8),
                      Text(
                        danger
                            ? 'Over budget by ${CurrencyFormatter.format(b.spent - b.budget.amount)}'
                            : '${CurrencyFormatter.format(b.remaining)} remaining',
                        style: context.textStyles.bodySmall?.copyWith(
                            color: danger ? AppColors.expense : null),
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

  String _periodLabel(dynamic period) {
    final name = period.toString().split('.').last;
    switch (name) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return name;
    }
  }
}
