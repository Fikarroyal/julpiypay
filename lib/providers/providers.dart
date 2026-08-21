import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/repositories_extra.dart';

// ---------------------------------------------------------------------------
// Repository instances (stateless, cukup singleton sederhana per provider)
// ---------------------------------------------------------------------------
final accountRepoProvider = Provider((ref) => AccountRepository());
final categoryRepoProvider = Provider((ref) => CategoryRepository());
final transactionRepoProvider = Provider((ref) => TransactionRepository());
final budgetRepoProvider = Provider((ref) => BudgetRepository());
final savingGoalRepoProvider = Provider((ref) => SavingGoalRepository());
final billRepoProvider = Provider((ref) => BillRepository());
final tagRepoProvider = Provider((ref) => TagRepository());
final recurringRepoProvider = Provider((ref) => RecurringRepository());
final profileRepoProvider = Provider((ref) => ProfileRepository());

/// Dinaikkan setiap kali ada mutasi data (create/update/delete) supaya
/// seluruh provider yang bergantung padanya otomatis refetch — inilah yang
/// membuat Dashboard "hidup" begitu transaksi berubah.
final refreshTickProvider = StateProvider<int>((ref) => 0);

void notifyDataChanged(WidgetRef ref) {
  ref.read(refreshTickProvider.notifier).state++;
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------
final accountsProvider = FutureProvider<List<AccountModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(accountRepoProvider).getAll();
});

final accountBalancesProvider = FutureProvider<Map<int, double>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(accountRepoProvider).getAllBalances();
});

final totalBalanceProvider = FutureProvider<double>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(accountRepoProvider).getTotalBalance();
});

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(categoryRepoProvider).getAll();
});

final categoriesByTypeProvider =
    FutureProvider.family<List<CategoryModel>, CategoryType>((ref, type) {
  ref.watch(refreshTickProvider);
  return ref.watch(categoryRepoProvider).getAll(type: type);
});

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------
final transactionsProvider =
    FutureProvider.family<List<TransactionModel>, TransactionFilter>((ref, filter) {
  ref.watch(refreshTickProvider);
  return ref.watch(transactionRepoProvider).getFiltered(filter);
});

final recentTransactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(transactionRepoProvider).getRecent(limit: 6);
});

// ---------------------------------------------------------------------------
// Budgets (dengan progress terhitung real dari transaksi)
// ---------------------------------------------------------------------------
class BudgetProgress {
  final BudgetModel budget;
  final CategoryModel category;
  final double spent;

  BudgetProgress({required this.budget, required this.category, required this.spent});

  double get remaining => budget.amount - spent;
  double get percent => budget.amount <= 0 ? 0 : spent / budget.amount;
}

final budgetProgressListProvider = FutureProvider<List<BudgetProgress>>((ref) async {
  ref.watch(refreshTickProvider);
  final budgets = await ref.watch(budgetRepoProvider).getAll();
  final categories = await ref.watch(categoryRepoProvider).getAll();
  final txRepo = ref.watch(transactionRepoProvider);
  final result = <BudgetProgress>[];
  for (final b in budgets) {
    final category = categories.firstWhere((c) => c.id == b.categoryId,
        orElse: () => const CategoryModel(name: '—', type: CategoryType.expense, icon: 'circleDollarSign', color: '#68756F'));
    final spent = await txRepo.sumByCategory(b.categoryId, start: b.startDate, end: b.endDate);
    result.add(BudgetProgress(budget: b, category: category, spent: spent));
  }
  return result;
});

// ---------------------------------------------------------------------------
// Saving goals
// ---------------------------------------------------------------------------
final savingGoalsProvider = FutureProvider<List<SavingGoalModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(savingGoalRepoProvider).getAll();
});

// ---------------------------------------------------------------------------
// Bills
// ---------------------------------------------------------------------------
final billsProvider = FutureProvider<List<BillModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(billRepoProvider).getAll();
});

final upcomingBillsProvider = FutureProvider<List<BillModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(billRepoProvider).getUpcoming(limit: 4);
});

// ---------------------------------------------------------------------------
// Tags
// ---------------------------------------------------------------------------
final tagsProvider = FutureProvider<List<TagModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(tagRepoProvider).getAll();
});

// ---------------------------------------------------------------------------
// Recurring transactions
// ---------------------------------------------------------------------------
final recurringProvider = FutureProvider<List<RecurringModel>>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(recurringRepoProvider).getAll();
});

// ---------------------------------------------------------------------------
// Profile
// ---------------------------------------------------------------------------
final profileProvider = FutureProvider<UserProfileModel?>((ref) {
  ref.watch(refreshTickProvider);
  return ref.watch(profileRepoProvider).get();
});

// ---------------------------------------------------------------------------
// Dashboard — ringkasan bulan berjalan
// ---------------------------------------------------------------------------
class DashboardSummary {
  final double totalBalance;
  final double income;
  final double expense;
  final double balanceLastMonth;

  DashboardSummary({
    required this.totalBalance,
    required this.income,
    required this.expense,
    required this.balanceLastMonth,
  });

  double get net => income - expense;
  double get monthChangePercent =>
      balanceLastMonth == 0 ? 0 : ((totalBalance - balanceLastMonth) / balanceLastMonth) * 100;
}

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  ref.watch(refreshTickProvider);
  final now = DateTime.now();
  final firstDay = DateTime(now.year, now.month, 1);
  final lastDay = DateTime(now.year, now.month + 1, 0);
  final txRepo = ref.watch(transactionRepoProvider);
  final accountRepo = ref.watch(accountRepoProvider);

  final income = await txRepo.sumByType(TransactionType.income, start: firstDay, end: lastDay);
  final expense = await txRepo.sumByType(TransactionType.expense, start: firstDay, end: lastDay);
  final totalBalance = await accountRepo.getTotalBalance();

  return DashboardSummary(
    totalBalance: totalBalance,
    income: income,
    expense: expense,
    balanceLastMonth: totalBalance - (income - expense),
  );
});

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------
enum ReportPeriod { thisWeek, thisMonth, months3, months6, thisYear }

DateTimeRange rangeForPeriod(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.thisWeek:
      final start = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(start: DateTime(start.year, start.month, start.day), end: now);
    case ReportPeriod.thisMonth:
      return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    case ReportPeriod.months3:
      return DateTimeRange(start: DateTime(now.year, now.month - 2, 1), end: now);
    case ReportPeriod.months6:
      return DateTimeRange(start: DateTime(now.year, now.month - 5, 1), end: now);
    case ReportPeriod.thisYear:
      return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
  }
}

class CategorySlice {
  final CategoryModel category;
  final double amount;
  CategorySlice(this.category, this.amount);
}

final categoryBreakdownProvider =
    FutureProvider.family<List<CategorySlice>, ReportPeriod>((ref, period) async {
  ref.watch(refreshTickProvider);
  final range = rangeForPeriod(period);
  final txRepo = ref.watch(transactionRepoProvider);
  final categories = await ref.watch(categoryRepoProvider).getAll();
  final breakdown = await txRepo.expenseByCategory(start: range.start, end: range.end);

  final slices = <CategorySlice>[];
  breakdown.forEach((catId, amount) {
    final category = categories.firstWhere((c) => c.id == catId,
        orElse: () => const CategoryModel(name: 'Lainnya', type: CategoryType.expense, icon: 'circleDollarSign', color: '#68756F'));
    slices.add(CategorySlice(category, amount));
  });
  slices.sort((a, b) => b.amount.compareTo(a.amount));
  return slices;
});

final incomeBreakdownProvider =
    FutureProvider.family<List<CategorySlice>, ReportPeriod>((ref, period) async {
  ref.watch(refreshTickProvider);
  final range = rangeForPeriod(period);
  final txRepo = ref.watch(transactionRepoProvider);
  final categories = await ref.watch(categoryRepoProvider).getAll();
  final breakdown =
      await txRepo.categoryBreakdown(type: TransactionType.income, start: range.start, end: range.end);

  final slices = <CategorySlice>[];
  breakdown.forEach((catId, amount) {
    final category = categories.firstWhere((c) => c.id == catId,
        orElse: () => const CategoryModel(name: 'Lainnya', type: CategoryType.income, icon: 'circleDollarSign', color: '#68756F'));
    slices.add(CategorySlice(category, amount));
  });
  slices.sort((a, b) => b.amount.compareTo(a.amount));
  return slices;
});

class PeriodSummary {
  final double income;
  final double expense;
  PeriodSummary(this.income, this.expense);
  double get net => income - expense;
  double get savingRate => income == 0 ? 0 : (net / income) * 100;
}

final periodSummaryProvider = FutureProvider.family<PeriodSummary, ReportPeriod>((ref, period) async {
  ref.watch(refreshTickProvider);
  final range = rangeForPeriod(period);
  final txRepo = ref.watch(transactionRepoProvider);
  final income = await txRepo.sumByType(TransactionType.income, start: range.start, end: range.end);
  final expense = await txRepo.sumByType(TransactionType.expense, start: range.start, end: range.end);
  return PeriodSummary(income, expense);
});

final cashFlowSeriesProvider =
    FutureProvider.family<Map<String, Map<String, double>>, ReportPeriod>((ref, period) async {
  ref.watch(refreshTickProvider);
  final range = rangeForPeriod(period);
  return ref.watch(transactionRepoProvider).cashFlowByDate(range.start, range.end);
});

// ---------------------------------------------------------------------------
// Financial insight — rule based, tanpa AI/API eksternal (sesuai spek).
// ---------------------------------------------------------------------------
enum InsightSeverity { info, warning, positive }

class FinancialInsight {
  final String message;
  final InsightSeverity severity;
  FinancialInsight(this.message, this.severity);
}

final insightsProvider = FutureProvider<List<FinancialInsight>>((ref) async {
  ref.watch(refreshTickProvider);
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  final lastMonthStart = DateTime(now.year, now.month - 1, 1);
  final lastMonthEnd = DateTime(now.year, now.month, 0);

  final txRepo = ref.watch(transactionRepoProvider);
  final categories = await ref.watch(categoryRepoProvider).getAll();
  final insights = <FinancialInsight>[];

  final thisMonthByCategory = await txRepo.expenseByCategory(start: thisMonthStart, end: now);
  final lastMonthByCategory =
      await txRepo.expenseByCategory(start: lastMonthStart, end: lastMonthEnd);

  for (final entry in thisMonthByCategory.entries) {
    final last = lastMonthByCategory[entry.key] ?? 0;
    if (last <= 0) continue;
    final change = ((entry.value - last) / last) * 100;
    if (change.abs() < 15) continue;
    final category = categories.firstWhere((c) => c.id == entry.key,
        orElse: () => const CategoryModel(name: 'Lainnya', type: CategoryType.expense, icon: 'circleDollarSign', color: '#68756F'));
    final direction = change > 0 ? 'meningkat' : 'menurun';
    insights.add(FinancialInsight(
      'Pengeluaran ${category.name} $direction ${change.abs().toStringAsFixed(0)}% dibanding bulan lalu.',
      change > 0 ? InsightSeverity.warning : InsightSeverity.positive,
    ));
  }

  final budgets = await ref.watch(budgetProgressListProvider.future);
  for (final b in budgets) {
    if (b.percent >= 1) {
      insights.add(FinancialInsight(
          'Budget ${b.category.name} sudah melebihi batas (${(b.percent * 100).toStringAsFixed(0)}%).',
          InsightSeverity.warning));
    } else if (b.percent >= b.budget.notificationThreshold) {
      insights.add(FinancialInsight(
          'Budget ${b.category.name} sudah mencapai ${(b.percent * 100).toStringAsFixed(0)}%.',
          InsightSeverity.warning));
    }
  }

  final income = await txRepo.sumByType(TransactionType.income, start: thisMonthStart, end: now);
  final expense = await txRepo.sumByType(TransactionType.expense, start: thisMonthStart, end: now);
  if (income > 0) {
    final savingRate = ((income - expense) / income) * 100;
    insights.add(FinancialInsight(
      'Saving rate bulan ini ${savingRate.toStringAsFixed(0)}%.',
      savingRate >= 20 ? InsightSeverity.positive : InsightSeverity.info,
    ));
  }

  return insights;
});

// ---------------------------------------------------------------------------
// Theme mode — persisten via SharedPreferences, langsung reaktif ke MaterialApp.
// ---------------------------------------------------------------------------
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }
  static const _key = 'julpiypay_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// ---------------------------------------------------------------------------
// Onboarding status — dicek oleh Splash untuk menentukan halaman awal.
// ---------------------------------------------------------------------------
class OnboardingStatusNotifier extends StateNotifier<bool?> {
  OnboardingStatusNotifier() : super(null) {
    _load();
  }
  static const _key = 'julpiypay_onboarding_complete';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = true;
  }
}

final onboardingStatusProvider = StateNotifierProvider<OnboardingStatusNotifier, bool?>(
  (ref) => OnboardingStatusNotifier(),
);
