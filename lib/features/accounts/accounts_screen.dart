import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, AccountModel account) async {
    final hasTransactions = await ref.read(transactionRepoProvider).accountHasTransactions(account.id!);
    if (!context.mounted) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${account.name}"?',
      message: hasTransactions
          ? 'This account has existing transactions. Deleting it will also remove those transactions.'
          : 'This account will be permanently removed.',
    );
    if (!confirmed) return;
    await ref.read(accountRepoProvider).delete(account.id!);
    notifyDataChanged(ref);
    if (context.mounted) context.showSnack('Account deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final totalAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeftRight, size: 20),
            tooltip: 'Transfer',
            onPressed: () => context.push('/accounts/transfer'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/accounts/add'),
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 100),
          children: [
            totalAsync.when(
              data: (total) => AppCard(
                color: context.colors.primary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total across all accounts',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(CurrencyFormatter.format(total), style: AppTextStyles.amount(Colors.white, size: 24)),
                      ],
                    ),
                    const IconBadge(icon: LucideIcons.wallet, color: Colors.white, size: 44),
                  ],
                ),
              ),
              loading: () => const SkeletonCard(height: 90),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            accountsAsync.when(
              loading: () => Column(children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 10), child: SkeletonCard(height: 74)))),
              error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return EmptyState(
                    icon: LucideIcons.wallet,
                    title: 'No accounts yet',
                    message: 'Add a cash wallet, bank, or e, wallet to start tracking.',
                    actionLabel: 'Add account',
                    onAction: () => context.push('/accounts/add'),
                  );
                }
                final balances = balancesAsync.valueOrNull ?? const <int, double>{};
                return Column(
                  children: accounts
                      .map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => context.push('/accounts/edit/${a.id}'),
                              child: Row(
                                children: [
                                  IconBadge(icon: iconFromKey(a.icon), color: colorFromHex(a.color)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.name, style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                                        Text(_accountTypeLabel(a.type), style: context.textStyles.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(balances[a.id] ?? a.initialBalance),
                                    style: AppTextStyles.amount(context.textStyles.bodyLarge!.color!, size: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 17),
                                    color: AppColors.expense,
                                    onPressed: () => _delete(context, ref, a),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _accountTypeLabel(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'Cash';
      case AccountType.bank:
        return 'Bank account';
      case AccountType.eWallet:
        return 'E, wallet';
      case AccountType.other:
        return 'Other';
    }
  }
}
