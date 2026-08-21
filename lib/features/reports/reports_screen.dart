import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../core/widgets.dart';
import '../../providers/providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 5, vsync: this);
  ReportPeriod _period = ReportPeriod.thisMonth;

  String _periodLabel(ReportPeriod p) {
    switch (p) {
      case ReportPeriod.thisWeek:
        return 'This week';
      case ReportPeriod.thisMonth:
        return 'This month';
      case ReportPeriod.months3:
        return '3 months';
      case ReportPeriod.months6:
        return '6 months';
      case ReportPeriod.thisYear:
        return 'This year';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.textStyles.bodySmall?.color,
          indicatorColor: context.colors.primary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
            Tab(text: 'Cash Flow'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ReportPeriod.values
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppChip(
                              label: _periodLabel(p),
                              selected: _period == p,
                              onTap: () => setState(() => _period = p),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(period: _period),
                  _CategoryTab(period: _period, type: 'expense'),
                  _CategoryTab(period: _period, type: 'income'),
                  _CategoryTab(period: _period, type: 'expense_list'),
                  _CashFlowTab(period: _period),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.period});
  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(periodSummaryProvider(period));
    final insightsAsync = ref.watch(insightsProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(context.horizontalPadding, 8, context.horizontalPadding, 100),
      children: [
        summaryAsync.when(
          loading: () => const SkeletonCard(height: 140),
          error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
          data: (summary) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: StatCard(
                          label: 'Total income',
                          value: CurrencyFormatter.format(summary.income),
                          icon: LucideIcons.arrowUpRight,
                          color: AppColors.income)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                          label: 'Total expense',
                          value: CurrencyFormatter.format(summary.expense),
                          icon: LucideIcons.arrowDownLeft,
                          color: AppColors.expense)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: StatCard(
                          label: 'Net cash flow',
                          value: CurrencyFormatter.format(summary.net),
                          icon: LucideIcons.scale,
                          color: AppColors.info)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: StatCard(
                          label: 'Saving rate',
                          value: '${summary.savingRate.toStringAsFixed(0)}%',
                          icon: LucideIcons.piggyBank,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Insights'),
        const SizedBox(height: 12),
        insightsAsync.when(
          loading: () => const SkeletonCard(height: 100),
          error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
          data: (insights) {
            if (insights.isEmpty) {
              return const AppCard(
                child: EmptyState(
                  icon: LucideIcons.lightbulb,
                  title: 'Not enough data yet',
                  message: 'Insights appear once you have a bit more transaction history.',
                ),
              );
            }
            return Column(
              children: insights
                  .map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Row(
                            children: [
                              IconBadge(
                                icon: insight.severity == InsightSeverity.warning
                                    ? LucideIcons.triangleAlert
                                    : insight.severity == InsightSeverity.positive
                                        ? LucideIcons.trendingUp
                                        : LucideIcons.info,
                                color: insight.severity == InsightSeverity.warning
                                    ? AppColors.warning
                                    : insight.severity == InsightSeverity.positive
                                        ? AppColors.income
                                        : AppColors.info,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(insight.message, style: context.textStyles.bodyMedium)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.period, required this.type});
  final ReportPeriod period;
  final String type; // 'expense' | 'income' | 'expense_list'

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = type == 'income';
    final slicesAsync =
        isIncome ? ref.watch(incomeBreakdownProvider(period)) : ref.watch(categoryBreakdownProvider(period));

    return slicesAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(20), child: SkeletonCard(height: 220)),
      error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
      data: (slices) {
        if (slices.isEmpty) {
          return EmptyState(
            icon: LucideIcons.chartPie,
            title: 'No data yet',
            message: 'Nothing recorded for this period.',
          );
        }
        final total = slices.fold<double>(0, (sum, s) => sum + s.amount);
        return ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
          children: [
            AppCard(
              child: SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: slices.map((s) {
                      return PieChartSectionData(
                        value: s.amount,
                        color: colorFromHex(s.category.color),
                        radius: 26,
                        title: total == 0 ? '' : '${(s.amount / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...slices.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        IconBadge(icon: iconFromKey(s.category.icon), color: colorFromHex(s.category.color)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.category.name, style: context.textStyles.bodyLarge)),
                        Text(CurrencyFormatter.format(s.amount),
                            style: AppTextStyles.amount(context.textStyles.bodyLarge!.color!, size: 14)),
                      ],
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _CashFlowTab extends ConsumerWidget {
  const _CashFlowTab({required this.period});
  final ReportPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(cashFlowSeriesProvider(period));

    return seriesAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(20), child: SkeletonCard(height: 260)),
      error: (_, __) => ErrorState(onRetry: () => notifyDataChanged(ref)),
      data: (series) {
        if (series.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.chartNoAxesCombined,
            title: 'No data yet',
            message: 'Cash flow chart will appear once you record transactions.',
          );
        }
        final dates = series.keys.toList()..sort();
        final incomeSpots = <FlSpot>[];
        final expenseSpots = <FlSpot>[];
        for (var i = 0; i < dates.length; i++) {
          incomeSpots.add(FlSpot(i.toDouble(), series[dates[i]]!['income'] ?? 0));
          expenseSpots.add(FlSpot(i.toDouble(), series[dates[i]]!['expense'] ?? 0));
        }
        final maxY = [...incomeSpots, ...expenseSpots].map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);

        return ListView(
          padding: EdgeInsets.fromLTRB(context.horizontalPadding, 12, context.horizontalPadding, 100),
          children: [
            AppCard(
              child: SizedBox(
                height: 240,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY == 0 ? 100 : maxY * 1.2,
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: incomeSpots,
                        isCurved: true,
                        color: AppColors.income,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                      ),
                      LineChartBarData(
                        spots: expenseSpots,
                        isCurved: true,
                        color: AppColors.expense,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppColors.income, label: 'Income'),
                const SizedBox(width: 20),
                _LegendDot(color: AppColors.expense, label: 'Expense'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: context.textStyles.bodySmall),
      ],
    );
  }
}
