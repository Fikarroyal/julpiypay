import '../core/utils.dart';

enum TransactionType { income, expense, transfer }

TransactionType transactionTypeFromDb(String v) =>
    TransactionType.values.firstWhere((e) => e.name == v);

enum CategoryType { income, expense }

CategoryType categoryTypeFromDb(String v) =>
    CategoryType.values.firstWhere((e) => e.name == v);

enum BudgetPeriod { weekly, monthly, yearly }

BudgetPeriod budgetPeriodFromDb(String v) =>
    BudgetPeriod.values.firstWhere((e) => e.name == v);

enum RecurringFrequency { daily, weekly, monthly, yearly }

RecurringFrequency recurringFrequencyFromDb(String v) =>
    RecurringFrequency.values.firstWhere((e) => e.name == v);

enum AccountType { cash, bank, eWallet, other }

AccountType accountTypeFromDb(String v) =>
    AccountType.values.firstWhere((e) => e.name == v, orElse: () => AccountType.other);

class AccountModel {
  final int? id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final String icon;
  final String color;
  final DateTime createdAt;

  const AccountModel({
    this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  AccountModel copyWith({
    int? id,
    String? name,
    AccountType? type,
    double? initialBalance,
    String? icon,
    String? color,
  }) =>
      AccountModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        initialBalance: initialBalance ?? this.initialBalance,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.name,
        'initial_balance': initialBalance,
        'icon': icon,
        'color': color,
        'created_at': DateFormatter.toDb(createdAt),
      };

  factory AccountModel.fromMap(Map<String, dynamic> map) => AccountModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: accountTypeFromDb(map['type'] as String),
        initialBalance: (map['initial_balance'] as num).toDouble(),
        icon: map['icon'] as String,
        color: map['color'] as String,
        createdAt: DateFormatter.fromDb(map['created_at'] as String),
      );
}

class CategoryModel {
  final int? id;
  final String name;
  final CategoryType type;
  final String icon;
  final String color;
  final String? description;

  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.description,
  });

  CategoryModel copyWith({
    int? id,
    String? name,
    CategoryType? type,
    String? icon,
    String? color,
    String? description,
  }) =>
      CategoryModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.name,
        'icon': icon,
        'color': color,
        'description': description,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: categoryTypeFromDb(map['type'] as String),
        icon: map['icon'] as String,
        color: map['color'] as String,
        description: map['description'] as String?,
      );
}

class TransactionModel {
  final int? id;
  final TransactionType type;
  final double amount;
  final int? categoryId;
  final int accountId;
  final int? toAccountId; // untuk transfer
  final DateTime date;
  final String? note;
  final bool isRecurring;
  final int? recurringId;
  final DateTime createdAt;
  final List<int> tagIds;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.date,
    this.note,
    this.isRecurring = false,
    this.recurringId,
    required this.createdAt,
    this.tagIds = const [],
  });

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    int? categoryId,
    int? accountId,
    int? toAccountId,
    DateTime? date,
    String? note,
    bool? isRecurring,
    List<int>? tagIds,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        toAccountId: toAccountId ?? this.toAccountId,
        date: date ?? this.date,
        note: note ?? this.note,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringId: recurringId,
        createdAt: createdAt,
        tagIds: tagIds ?? this.tagIds,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'to_account_id': toAccountId,
        'date': DateFormatter.toDb(date),
        'note': note,
        'is_recurring': isRecurring ? 1 : 0,
        'recurring_id': recurringId,
        'created_at': DateFormatter.toDb(createdAt),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map, {List<int> tagIds = const []}) =>
      TransactionModel(
        id: map['id'] as int?,
        type: transactionTypeFromDb(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int?,
        accountId: map['account_id'] as int,
        toAccountId: map['to_account_id'] as int?,
        date: DateFormatter.fromDb(map['date'] as String),
        note: map['note'] as String?,
        isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
        recurringId: map['recurring_id'] as int?,
        createdAt: DateFormatter.fromDb(map['created_at'] as String),
        tagIds: tagIds,
      );
}

class BudgetModel {
  final int? id;
  final int categoryId;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double notificationThreshold; // 0..1

  const BudgetModel({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.notificationThreshold = 0.8,
  });

  BudgetModel copyWith({
    int? id,
    int? categoryId,
    double? amount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    double? notificationThreshold,
  }) =>
      BudgetModel(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        notificationThreshold: notificationThreshold ?? this.notificationThreshold,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'amount': amount,
        'period': period.name,
        'start_date': DateFormatter.toDb(startDate),
        'end_date': DateFormatter.toDb(endDate),
        'notification_threshold': notificationThreshold,
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        period: budgetPeriodFromDb(map['period'] as String),
        startDate: DateFormatter.fromDb(map['start_date'] as String),
        endDate: DateFormatter.fromDb(map['end_date'] as String),
        notificationThreshold: (map['notification_threshold'] as num).toDouble(),
      );
}

class SavingGoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String icon;
  final String color;
  final String? description;

  const SavingGoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.icon,
    required this.color,
    this.description,
  });

  double get progress => targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  SavingGoalModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? color,
    String? description,
  }) =>
      SavingGoalModel(
        id: id ?? this.id,
        name: name ?? this.name,
        targetAmount: targetAmount ?? this.targetAmount,
        currentAmount: currentAmount ?? this.currentAmount,
        deadline: deadline ?? this.deadline,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        description: description ?? this.description,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': DateFormatter.toDb(deadline),
        'icon': icon,
        'color': color,
        'description': description,
      };

  factory SavingGoalModel.fromMap(Map<String, dynamic> map) => SavingGoalModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        targetAmount: (map['target_amount'] as num).toDouble(),
        currentAmount: (map['current_amount'] as num).toDouble(),
        deadline: DateFormatter.fromDb(map['deadline'] as String),
        icon: map['icon'] as String,
        color: map['color'] as String,
        description: map['description'] as String?,
      );
}

enum BillStatus { upcoming, dueToday, overdue, paid }

class BillModel {
  final int? id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final int? categoryId;
  final int accountId;
  final bool isRecurring;
  final bool reminder;
  final bool isPaid;

  const BillModel({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.categoryId,
    required this.accountId,
    this.isRecurring = false,
    this.reminder = true,
    this.isPaid = false,
  });

  BillStatus get status {
    if (isPaid) return BillStatus.paid;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(today)) return BillStatus.overdue;
    if (due.isAtSameMomentAs(today)) return BillStatus.dueToday;
    return BillStatus.upcoming;
  }

  BillModel copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    int? categoryId,
    int? accountId,
    bool? isRecurring,
    bool? reminder,
    bool? isPaid,
  }) =>
      BillModel(
        id: id ?? this.id,
        name: name ?? this.name,
        amount: amount ?? this.amount,
        dueDate: dueDate ?? this.dueDate,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        isRecurring: isRecurring ?? this.isRecurring,
        reminder: reminder ?? this.reminder,
        isPaid: isPaid ?? this.isPaid,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'amount': amount,
        'due_date': DateFormatter.toDb(dueDate),
        'category_id': categoryId,
        'account_id': accountId,
        'is_recurring': isRecurring ? 1 : 0,
        'reminder': reminder ? 1 : 0,
        'is_paid': isPaid ? 1 : 0,
      };

  factory BillModel.fromMap(Map<String, dynamic> map) => BillModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        amount: (map['amount'] as num).toDouble(),
        dueDate: DateFormatter.fromDb(map['due_date'] as String),
        categoryId: map['category_id'] as int?,
        accountId: map['account_id'] as int,
        isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
        reminder: (map['reminder'] as int? ?? 1) == 1,
        isPaid: (map['is_paid'] as int? ?? 0) == 1,
      );
}

class TagModel {
  final int? id;
  final String name;

  const TagModel({this.id, required this.name});

  Map<String, dynamic> toMap() => {if (id != null) 'id': id, 'name': name};

  factory TagModel.fromMap(Map<String, dynamic> map) =>
      TagModel(id: map['id'] as int?, name: map['name'] as String);
}

class RecurringModel {
  final int? id;
  final TransactionType type;
  final double amount;
  final int? categoryId;
  final int accountId;
  final String? note;
  final RecurringFrequency frequency;
  final DateTime nextDate;
  final bool isActive;

  const RecurringModel({
    this.id,
    required this.type,
    required this.amount,
    this.categoryId,
    required this.accountId,
    this.note,
    required this.frequency,
    required this.nextDate,
    this.isActive = true,
  });

  RecurringModel copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    int? categoryId,
    int? accountId,
    String? note,
    RecurringFrequency? frequency,
    DateTime? nextDate,
    bool? isActive,
  }) =>
      RecurringModel(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        note: note ?? this.note,
        frequency: frequency ?? this.frequency,
        nextDate: nextDate ?? this.nextDate,
        isActive: isActive ?? this.isActive,
      );

  DateTime computeNextDate() {
    switch (frequency) {
      case RecurringFrequency.daily:
        return nextDate.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return nextDate.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
      case RecurringFrequency.yearly:
        return DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
    }
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type.name,
        'amount': amount,
        'category_id': categoryId,
        'account_id': accountId,
        'note': note,
        'frequency': frequency.name,
        'next_date': DateFormatter.toDb(nextDate),
        'is_active': isActive ? 1 : 0,
      };

  factory RecurringModel.fromMap(Map<String, dynamic> map) => RecurringModel(
        id: map['id'] as int?,
        type: transactionTypeFromDb(map['type'] as String),
        amount: (map['amount'] as num).toDouble(),
        categoryId: map['category_id'] as int?,
        accountId: map['account_id'] as int,
        note: map['note'] as String?,
        frequency: recurringFrequencyFromDb(map['frequency'] as String),
        nextDate: DateFormatter.fromDb(map['next_date'] as String),
        isActive: (map['is_active'] as int? ?? 1) == 1,
      );
}

class UserProfileModel {
  final int id;
  final String displayName;
  final String currency;
  final double monthlyIncomeTarget;
  final double savingTargetPercent;
  final int? preferredAccountId;
  final int financialMonthStart; // tanggal 1-28
  final String themeMode; // light / dark / system
  final bool onboardingComplete;

  const UserProfileModel({
    this.id = 1,
    required this.displayName,
    this.currency = 'IDR',
    required this.monthlyIncomeTarget,
    required this.savingTargetPercent,
    this.preferredAccountId,
    this.financialMonthStart = 1,
    this.themeMode = 'system',
    this.onboardingComplete = false,
  });

  UserProfileModel copyWith({
    String? displayName,
    String? currency,
    double? monthlyIncomeTarget,
    double? savingTargetPercent,
    int? preferredAccountId,
    int? financialMonthStart,
    String? themeMode,
    bool? onboardingComplete,
  }) =>
      UserProfileModel(
        id: id,
        displayName: displayName ?? this.displayName,
        currency: currency ?? this.currency,
        monthlyIncomeTarget: monthlyIncomeTarget ?? this.monthlyIncomeTarget,
        savingTargetPercent: savingTargetPercent ?? this.savingTargetPercent,
        preferredAccountId: preferredAccountId ?? this.preferredAccountId,
        financialMonthStart: financialMonthStart ?? this.financialMonthStart,
        themeMode: themeMode ?? this.themeMode,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'currency': currency,
        'monthly_income_target': monthlyIncomeTarget,
        'saving_target_percent': savingTargetPercent,
        'preferred_account_id': preferredAccountId,
        'financial_month_start': financialMonthStart,
        'theme_mode': themeMode,
        'onboarding_complete': onboardingComplete ? 1 : 0,
      };

  factory UserProfileModel.fromMap(Map<String, dynamic> map) => UserProfileModel(
        id: map['id'] as int,
        displayName: map['display_name'] as String,
        currency: map['currency'] as String,
        monthlyIncomeTarget: (map['monthly_income_target'] as num).toDouble(),
        savingTargetPercent: (map['saving_target_percent'] as num).toDouble(),
        preferredAccountId: map['preferred_account_id'] as int?,
        financialMonthStart: map['financial_month_start'] as int,
        themeMode: map['theme_mode'] as String,
        onboardingComplete: (map['onboarding_complete'] as int? ?? 0) == 1,
      );
}
