import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'models.dart';
import '../core/utils.dart';

class AccountRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<AccountModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('accounts', orderBy: 'id ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<AccountModel?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AccountModel.fromMap(rows.first);
  }

  Future<int> insert(AccountModel account) async {
    final db = await _db;
    return db.insert('accounts', account.toMap());
  }

  Future<void> update(AccountModel account) async {
    final db = await _db;
    await db.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  /// Saldo berjalan = saldo awal + income - expense - transferKeluar + transferMasuk.
  Future<double> getBalance(int accountId) async {
    final db = await _db;
    final account = await getById(accountId);
    if (account == null) return 0;

    final income = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as v FROM transactions WHERE account_id = ? AND type = 'income'",
      [accountId],
    )) ?? 0;
    final expense = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as v FROM transactions WHERE account_id = ? AND type = 'expense'",
      [accountId],
    )) ?? 0;
    final transferOut = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as v FROM transactions WHERE account_id = ? AND type = 'transfer'",
      [accountId],
    )) ?? 0;
    final transferIn = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as v FROM transactions WHERE to_account_id = ? AND type = 'transfer'",
      [accountId],
    )) ?? 0;

    return account.initialBalance + income - expense - transferOut + transferIn;
  }

  Future<Map<int, double>> getAllBalances() async {
    final accounts = await getAll();
    final result = <int, double>{};
    for (final a in accounts) {
      result[a.id!] = await getBalance(a.id!);
    }
    return result;
  }

  Future<double> getTotalBalance() async {
    final balances = await getAllBalances();
    return balances.values.fold(0.0, (a, b) => a + b);
  }
}

class CategoryRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<CategoryModel>> getAll({CategoryType? type}) async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type.name] : null,
      orderBy: 'name ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }

  Future<int> insert(CategoryModel category) async {
    final db = await _db;
    return db.insert('categories', category.toMap());
  }

  Future<void> update(CategoryModel category) async {
    final db = await _db;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<bool> isUsed(int id) async {
    final db = await _db;
    final tx = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM transactions WHERE category_id = ?', [id])) ?? 0;
    final bud = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM budgets WHERE category_id = ?', [id])) ?? 0;
    return (tx + bud) > 0;
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

enum TransactionSort { newest, oldest, highest, lowest }

class TransactionFilter {
  final String? query;
  final TransactionType? type;
  final int? categoryId;
  final int? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final TransactionSort sort;
  final int? tagId;

  const TransactionFilter({
    this.query,
    this.type,
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.sort = TransactionSort.newest,
    this.tagId,
  });
}

class TransactionRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<int>> _tagsFor(Database db, int transactionId) async {
    final rows = await db.query('transaction_tags',
        where: 'transaction_id = ?', whereArgs: [transactionId]);
    return rows.map((e) => e['tag_id'] as int).toList();
  }

  Future<int> insert(TransactionModel transaction) async {
    final db = await _db;
    return db.transaction((txn) async {
      final id = await txn.insert('transactions', transaction.toMap());
      for (final tagId in transaction.tagIds) {
        await txn.insert('transaction_tags', {'transaction_id': id, 'tag_id': tagId});
      }
      return id;
    });
  }

  Future<void> update(TransactionModel transaction) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('transactions', transaction.toMap(),
          where: 'id = ?', whereArgs: [transaction.id]);
      await txn.delete('transaction_tags', where: 'transaction_id = ?', whereArgs: [transaction.id]);
      for (final tagId in transaction.tagIds) {
        await txn.insert('transaction_tags', {'transaction_id': transaction.id, 'tag_id': tagId});
      }
    });
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<TransactionModel?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final tags = await _tagsFor(db, id);
    return TransactionModel.fromMap(rows.first, tagIds: tags);
  }

  Future<List<TransactionModel>> getFiltered(TransactionFilter filter) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (filter.type != null) {
      where.add('type = ?');
      args.add(filter.type!.name);
    }
    if (filter.categoryId != null) {
      where.add('category_id = ?');
      args.add(filter.categoryId);
    }
    if (filter.accountId != null) {
      where.add('(account_id = ? OR to_account_id = ?)');
      args.addAll([filter.accountId, filter.accountId]);
    }
    if (filter.startDate != null) {
      where.add('date >= ?');
      args.add(DateFormatter.toDb(filter.startDate!));
    }
    if (filter.endDate != null) {
      where.add('date <= ?');
      args.add(DateFormatter.toDb(filter.endDate!));
    }
    if (filter.minAmount != null) {
      where.add('amount >= ?');
      args.add(filter.minAmount);
    }
    if (filter.maxAmount != null) {
      where.add('amount <= ?');
      args.add(filter.maxAmount);
    }
    if (filter.query != null && filter.query!.trim().isNotEmpty) {
      where.add('(note LIKE ? OR id IN ('
          'SELECT id FROM transactions WHERE category_id IN ('
          'SELECT id FROM categories WHERE name LIKE ?)))');
      args.addAll(['%${filter.query}%', '%${filter.query}%']);
    }
    if (filter.tagId != null) {
      where.add('id IN (SELECT transaction_id FROM transaction_tags WHERE tag_id = ?)');
      args.add(filter.tagId);
    }

    String orderBy;
    switch (filter.sort) {
      case TransactionSort.newest:
        orderBy = 'date DESC, id DESC';
        break;
      case TransactionSort.oldest:
        orderBy = 'date ASC, id ASC';
        break;
      case TransactionSort.highest:
        orderBy = 'amount DESC';
        break;
      case TransactionSort.lowest:
        orderBy = 'amount ASC';
        break;
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: orderBy,
    );

    final result = <TransactionModel>[];
    for (final row in rows) {
      final tags = await _tagsFor(db, row['id'] as int);
      result.add(TransactionModel.fromMap(row, tagIds: tags));
    }
    return result;
  }

  Future<List<TransactionModel>> getRecent({int limit = 5}) async {
    final db = await _db;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC', limit: limit);
    final result = <TransactionModel>[];
    for (final row in rows) {
      final tags = await _tagsFor(db, row['id'] as int);
      result.add(TransactionModel.fromMap(row, tagIds: tags));
    }
    return result;
  }

  Future<double> sumByType(TransactionType type, {DateTime? start, DateTime? end}) async {
    final db = await _db;
    final where = <String>['type = ?'];
    final args = <Object?>[type.name];
    if (start != null) {
      where.add('date >= ?');
      args.add(DateFormatter.toDb(start));
    }
    if (end != null) {
      where.add('date <= ?');
      args.add(DateFormatter.toDb(end));
    }
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) as v FROM transactions WHERE ${where.join(' AND ')}', args);
    return (rows.first['v'] as num).toDouble();
  }

  Future<double> sumByCategory(int categoryId, {DateTime? start, DateTime? end}) async {
    final db = await _db;
    final where = <String>['category_id = ?'];
    final args = <Object?>[categoryId];
    if (start != null) {
      where.add('date >= ?');
      args.add(DateFormatter.toDb(start));
    }
    if (end != null) {
      where.add('date <= ?');
      args.add(DateFormatter.toDb(end));
    }
    final rows = await db.rawQuery(
        'SELECT COALESCE(SUM(amount),0) as v FROM transactions WHERE ${where.join(' AND ')}', args);
    return (rows.first['v'] as num).toDouble();
  }

  /// Total pengeluaran per kategori dalam rentang tanggal — dipakai chart donut & laporan.
  Future<Map<int, double>> expenseByCategory({DateTime? start, DateTime? end}) =>
      categoryBreakdown(type: TransactionType.expense, start: start, end: end);

  /// Breakdown per kategori untuk tipe transaksi tertentu (income atau expense).
  Future<Map<int, double>> categoryBreakdown(
      {required TransactionType type, DateTime? start, DateTime? end}) async {
    final db = await _db;
    final where = <String>['type = ?', 'category_id IS NOT NULL'];
    final args = <Object?>[type.name];
    if (start != null) {
      where.add('date >= ?');
      args.add(DateFormatter.toDb(start));
    }
    if (end != null) {
      where.add('date <= ?');
      args.add(DateFormatter.toDb(end));
    }
    final rows = await db.rawQuery(
      'SELECT category_id, SUM(amount) as v FROM transactions WHERE ${where.join(' AND ')} GROUP BY category_id',
      args,
    );
    return {for (final r in rows) r['category_id'] as int: (r['v'] as num).toDouble()};
  }

  /// Cash flow harian dalam rentang tanggal — dipakai chart laporan.
  Future<Map<String, Map<String, double>>> cashFlowByDate(DateTime start, DateTime end) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT date, type, SUM(amount) as v FROM transactions
      WHERE date >= ? AND date <= ? AND type IN ('income','expense')
      GROUP BY date, type ORDER BY date ASC
    ''', [DateFormatter.toDb(start), DateFormatter.toDb(end)]);

    final result = <String, Map<String, double>>{};
    for (final r in rows) {
      final date = r['date'] as String;
      result.putIfAbsent(date, () => {'income': 0, 'expense': 0});
      result[date]![r['type'] as String] = (r['v'] as num).toDouble();
    }
    return result;
  }

  Future<bool> accountHasTransactions(int accountId) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM transactions WHERE account_id = ? OR to_account_id = ?',
      [accountId, accountId],
    )) ?? 0;
    return count > 0;
  }
}
