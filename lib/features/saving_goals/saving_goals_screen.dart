import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers/providers.dart';

class SavingGoalsScreen extends ConsumerWidget {
  const SavingGoalsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete saving goal?',
      message: 'This saving goal will be permanently removed.',
    );
    if (!confirmed) return;
    await ref.read(savingGoalRepoProvider).delete(id);
    notifyDataChanged(ref);
    if (context.mounted) context.showSnack('Saving goal deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingGoalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saving Goals')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/saving_goals/add'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: List.generate(3, (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12), child: SkeletonCard(height: 120))),
          ),
          error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
          data: (goals) {
            if (goals.isEmpty) {
              return EmptyState(
                icon: LucideIcons.piggyBank,
                title: 'No saving goals yet',
                message: 'Set a target to start saving toward something meaningful.',
                actionLabel: 'Add goal',
                onAction: () => context.push('/saving_goals/add'),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final g = goals[i];
                final color = colorFromHex(g.color);
                return AppCard(
                  onTap: () => context.push('/saving_goals/edit/${g.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBadge(icon: iconFromKey(g.icon), color: color),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.name, style: context.textStyles.titleSmall),
                                Text('Target by ${DateFormatter.short(g.deadline)}',
                                    style: context.textStyles.bodySmall),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16),
                            color: AppColors.expense,
                            onPressed: () => _delete(context, ref, g.id!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${CurrencyFormatter.format(g.currentAmount)} / ${CurrencyFormatter.format(g.targetAmount)}',
                              style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text('${(g.progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: g.progress,
                          minHeight: 8,
                          backgroundColor: context.theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
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
