import 'models.dart';
import 'repositories.dart';
import 'repositories_extra.dart';

/// Mengisi database dengan data contoh yang realistis supaya dashboard
/// langsung "hidup" begitu user memilih opsi demo saat onboarding.
class DemoSeeder {
  final _accountRepo = AccountRepository();
  final _categoryRepo = CategoryRepository();
  final _transactionRepo = TransactionRepository();
  final _budgetRepo = BudgetRepository();
  final _savingGoalRepo = SavingGoalRepository();
  final _billRepo = BillRepository();
  final _tagRepo = TagRepository();

  Future<void> seed() async {
    final now = DateTime.now();

    // Akun
    final cash = await _accountRepo.insert(AccountModel(
        name: 'Cash', type: AccountType.cash, initialBalance: 500000, icon: 'wallet', color: '#167C5A', createdAt: now));
    final bca = await _accountRepo.insert(AccountModel(
        name: 'BCA', type: AccountType.bank, initialBalance: 4200000, icon: 'landmark', color: '#4F7CAC', createdAt: now));
    final gopay = await _accountRepo.insert(AccountModel(
        name: 'GoPay', type: AccountType.eWallet, initialBalance: 150000, icon: 'smartphone', color: '#159570', createdAt: now));

    // Kategori pengeluaran
    final catFood = await _categoryRepo.insert(const CategoryModel(
        name: 'Food', type: CategoryType.expense, icon: 'utensils', color: '#D95757'));
    final catTransport = await _categoryRepo.insert(const CategoryModel(
        name: 'Transport', type: CategoryType.expense, icon: 'car', color: '#D89A28'));
    final catShopping = await _categoryRepo.insert(const CategoryModel(
        name: 'Shopping', type: CategoryType.expense, icon: 'shoppingBag', color: '#8A6FD8'));
    final catBills = await _categoryRepo.insert(const CategoryModel(
        name: 'Bills & Utilities', type: CategoryType.expense, icon: 'zap', color: '#4F7CAC'));
    final catHealth = await _categoryRepo.insert(const CategoryModel(
        name: 'Health', type: CategoryType.expense, icon: 'heartPulse', color: '#DB6FA0'));

    // Kategori pemasukan
    final catSalary = await _categoryRepo.insert(const CategoryModel(
        name: 'Salary', type: CategoryType.income, icon: 'briefcase', color: '#159570'));
    final catBonus = await _categoryRepo.insert(const CategoryModel(
        name: 'Bonus', type: CategoryType.income, icon: 'gift', color: '#167C5A'));

    // Tag
    await _tagRepo.insert(const TagModel(name: 'Work'));
    await _tagRepo.insert(const TagModel(name: 'Family'));
    await _tagRepo.insert(const TagModel(name: 'Travel'));

    DateTime d(int daysAgo) => now.subtract(Duration(days: daysAgo));

    final demoTx = <TransactionModel>[
      TransactionModel(type: TransactionType.income, amount: 7000000, categoryId: catSalary, accountId: bca, date: d(14), note: 'Gaji bulanan', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 45000, categoryId: catFood, accountId: cash, date: d(0), note: 'Makan siang', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 350000, categoryId: catBills, accountId: bca, date: d(1), note: 'Internet rumah', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 25000, categoryId: catTransport, accountId: gopay, date: d(0), note: 'Grab', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 320000, categoryId: catShopping, accountId: bca, date: d(3), note: 'Belanja bulanan', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 150000, categoryId: catFood, accountId: cash, date: d(2), note: 'Makan malam keluarga', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 80000, categoryId: catHealth, accountId: cash, date: d(5), note: 'Vitamin', createdAt: now),
      TransactionModel(type: TransactionType.income, amount: 500000, categoryId: catBonus, accountId: bca, date: d(6), note: 'Bonus proyek', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 60000, categoryId: catTransport, accountId: gopay, date: d(7), note: 'Bensin', createdAt: now),
      TransactionModel(type: TransactionType.expense, amount: 210000, categoryId: catFood, accountId: cash, date: d(10), note: 'Groceries', createdAt: now),
    ];
    for (final tx in demoTx) {
      await _transactionRepo.insert(tx);
    }

    // Budget bulan berjalan
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    await _budgetRepo.insert(BudgetModel(
        categoryId: catFood, amount: 1500000, period: BudgetPeriod.monthly, startDate: firstDay, endDate: lastDay));
    await _budgetRepo.insert(BudgetModel(
        categoryId: catTransport, amount: 500000, period: BudgetPeriod.monthly, startDate: firstDay, endDate: lastDay));
    await _budgetRepo.insert(BudgetModel(
        categoryId: catShopping, amount: 800000, period: BudgetPeriod.monthly, startDate: firstDay, endDate: lastDay));

    // Target tabungan
    await _savingGoalRepo.insert(SavingGoalModel(
      name: 'Dana Darurat',
      targetAmount: 20000000,
      currentAmount: 6500000,
      deadline: DateTime(now.year + 1, now.month, now.day),
      icon: 'piggyBank',
      color: '#167C5A',
      description: 'Setara 6 bulan pengeluaran',
    ));
    await _savingGoalRepo.insert(SavingGoalModel(
      name: 'Liburan Bali',
      targetAmount: 8000000,
      currentAmount: 2100000,
      deadline: DateTime(now.year, now.month + 4, now.day),
      icon: 'plane',
      color: '#4F7CAC',
    ));

    // Tagihan
    await _billRepo.insert(BillModel(
        name: 'Internet', amount: 350000, dueDate: now.add(const Duration(days: 3)), categoryId: catBills, accountId: bca, isRecurring: true));
    await _billRepo.insert(BillModel(
        name: 'Listrik', amount: 420000, dueDate: now.add(const Duration(days: 6)), categoryId: catBills, accountId: bca, isRecurring: true));
    await _billRepo.insert(BillModel(
        name: 'Netflix', amount: 65000, dueDate: now.subtract(const Duration(days: 1)), categoryId: catBills, accountId: gopay, isRecurring: true));
  }
}
