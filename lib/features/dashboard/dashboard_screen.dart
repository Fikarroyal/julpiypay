import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../providers/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Good morning';
    if (hour < 15) return 'Good afternoon';
    if (hour < 19) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final billsAsync = ref.watch(upcomingBillsProvider);
    final breakdownAsync = ref.watch(categoryBreakdownProvider(ReportPeriod.thisMonth));
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => notifyDataChanged(ref),
          child: ListView(
            padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
            children: [
              profileAsync.when(
                data: (profile) => Text('${_greeting()}, ${profile?.displayName ?? 'there'}',
                    style: context.textStyles.headlineSmall),
                loading: () => const LoadingSkeleton(height: 26, width: 180),
                error: (_, __) => Text(_greeting(), style: context.textStyles.headlineSmall),
              ),
              const SizedBox(height: 4),
              Text('Your financial overview', style: context.textStyles.bodyMedium),
              const SizedBox(height: 20),

              summaryAsync.when(
                loading: () => const SkeletonCard(height: 120),
                error: (e, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
                data: (summary) => _BalanceCard(summary: summary),
              ),
              const SizedBox(height: 16),

              summaryAsync.maybeWhen(
                data: (summary) => _IncomeExpenseRow(summary: summary),
                orElse: () => Row(children: const [
                  Expanded(child: SkeletonCard(height: 70)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonCard(height: 70)),
                ]),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _QuickAddButton(
                      icon: LucideIcons.arrowDownLeft,
                      label: '+ Expense',
                      color: AppColors.expense,
                      onTap: () => context.push('/transactions/add', extra: TransactionType.expense),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAddButton(
                      icon: LucideIcons.arrowUpRight,
                      label: '+ Income',
                      color: AppColors.income,
                      onTap: () => context.push('/transactions/add', extra: TransactionType.income),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAddButton(
                      icon: LucideIcons.arrowLeftRight,
                      label: '+ Transfer',
                      color: AppColors.info,
                      onTap: () => context.push('/accounts/transfer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              SectionHeader(title: 'Spending overview'),
              const SizedBox(height: 12),
              breakdownAsync.when(
                loading: () => const SkeletonCard(height: 180),
                error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
                data: (slices) => slices.isEmpty
                    ? const AppCard(
                        child: EmptyState(
                          icon: LucideIcons.chartPie,
                          title: 'Belum ada pengeluaran',
                          message: 'Grafik akan muncul setelah kamu mencatat pengeluaran bulan ini.',
                        ),
                      )
                    : _SpendingDonut(slices: slices),
              ),
              const SizedBox(height: 28),

              SectionHeader(
                title: 'Recent transactions',
                action: 'See all',
                onAction: () => context.go('/home?tab=1'),
              ),
              const SizedBox(height: 8),
              recentAsync.when(
                loading: () => Column(children: List.generate(3, (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6), child: SkeletonCard(height: 60)))),
                error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return AppCard(
                      child: EmptyState(
                        icon: LucideIcons.receipt,
                        title: 'No transactions yet',
                        message: 'Start tracking your spending and income today.',
                        actionLabel: 'Add transaction',
                        onAction: () => context.push('/transactions/add'),
                      ),
                    );
                  }
                  final categories = categoriesAsync.valueOrNull ?? const <CategoryModel>[];
                  final accounts = accountsAsync.valueOrNull ?? const <AccountModel>[];
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      children: transactions
                          .map((t) => TransactionTile(
                                transaction: t,
                                category: t.categoryId == null
                                    ? null
                                    : categories.where((c) => c.id == t.categoryId).firstOrNull,
                                account: accounts.where((a) => a.id == t.accountId).firstOrNull,
                                onTap: () => context.push('/transactions/detail/${t.id}'),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              SectionHeader(
                title: 'Upcoming bills',
                action: 'See all',
                onAction: () => context.push('/bills'),
              ),
              const SizedBox(height: 8),
              billsAsync.when(
                loading: () => const SkeletonCard(height: 70),
                error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
                data: (bills) {
                  if (bills.isEmpty) {
                    return const AppCard(
                      child: EmptyState(
                        icon: LucideIcons.receiptText,
                        title: 'No bills yet',
                        message: 'Tagihan yang kamu tambahkan akan muncul di sini.',
                      ),
                    );
                  }
                  return Column(
                    children: bills
                        .map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _BillRow(bill: b),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final positive = summary.monthChangePercent >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Balance',
              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.format(summary.totalBalance),
              style: AppTextStyles.amount(Colors.white, size: 30)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(positive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  size: 15, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 4),
              Text(
                '${positive ? '+' : ''}${summary.monthChangePercent.toStringAsFixed(1)}% this month',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: StatCard(
                label: 'Income',
                value: CurrencyFormatter.format(summary.income),
                icon: LucideIcons.arrowUpRight,
                color: AppColors.income)),
        const SizedBox(width: 12),
        Expanded(
            child: StatCard(
                label: 'Expense',
                value: CurrencyFormatter.format(summary.expense),
                icon: LucideIcons.arrowDownLeft,
                color: AppColors.expense)),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(label,
              style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SpendingDonut extends StatelessWidget {
  const _SpendingDonut({required this.slices});
  final List<CategorySlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.amount);
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            height: 130,
            width: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: slices.take(6).map<PieChartSectionData>((s) {
                  return PieChartSectionData(
                    value: s.amount,
                    color: colorFromHex(s.category.color),
                    radius: 20,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slices.take(5).map<Widget>((s) {
                final percent = total == 0 ? 0.0 : s.amount / total * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorFromHex(s.category.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.category.name,
                            style: context.textStyles.bodySmall, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${percent.toStringAsFixed(0)}%',
                          style: context.textStyles.labelMedium),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill});
  final BillModel bill;

  @override
  Widget build(BuildContext context) {
    final status = bill.status;
    final color = status == BillStatus.overdue
        ? AppColors.expense
        : status == BillStatus.dueToday
            ? AppColors.warning
            : context.colors.primary;
    return AppCard(
      onTap: () => context.push('/bills'),
      child: Row(
        children: [
          IconBadge(icon: LucideIcons.receiptText, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name, style: context.textStyles.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(DateFormatter.dueLabel(bill.dueDate),
                    style: context.textStyles.bodySmall?.copyWith(color: color)),
              ],
            ),
          ),
          Text(CurrencyFormatter.format(bill.amount), style: AppTextStyles.amount(context.textStyles.bodyLarge!.color!, size: 14)),
        ],
      ),
    );
  }
}
