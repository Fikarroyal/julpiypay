import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'models.dart';

class BudgetRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<BudgetModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('budgets', orderBy: 'start_date DESC');
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<int> insert(BudgetModel budget) async {
    final db = await _db;
    return db.insert('budgets', budget.toMap());
  }

  Future<void> update(BudgetModel budget) async {
    final db = await _db;
    await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }
}

class SavingGoalRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<SavingGoalModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('saving_goals', orderBy: 'deadline ASC');
    return rows.map(SavingGoalModel.fromMap).toList();
  }

  Future<int> insert(SavingGoalModel goal) async {
    final db = await _db;
    return db.insert('saving_goals', goal.toMap());
  }

  Future<void> update(SavingGoalModel goal) async {
    final db = await _db;
    await db.update('saving_goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('saving_goals', where: 'id = ?', whereArgs: [id]);
  }
}

class BillRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<BillModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('bills', orderBy: 'due_date ASC');
    return rows.map(BillModel.fromMap).toList();
  }

  Future<List<BillModel>> getUpcoming({int limit = 5}) async {
    final all = await getAll();
    final unpaid = all.where((b) => !b.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return unpaid.take(limit).toList();
  }

  Future<int> insert(BillModel bill) async {
    final db = await _db;
    return db.insert('bills', bill.toMap());
  }

  Future<void> update(BillModel bill) async {
    final db = await _db;
    await db.update('bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }
}

class TagRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<TagModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('tags', orderBy: 'name ASC');
    return rows.map(TagModel.fromMap).toList();
  }

  Future<int> insert(TagModel tag) async {
    final db = await _db;
    return db.insert('tags', tag.toMap());
  }

  Future<void> update(TagModel tag) async {
    final db = await _db;
    await db.update('tags', tag.toMap(), where: 'id = ?', whereArgs: [tag.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }
}

class RecurringRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<RecurringModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('recurring_transactions', orderBy: 'next_date ASC');
    return rows.map(RecurringModel.fromMap).toList();
  }

  Future<int> insert(RecurringModel recurring) async {
    final db = await _db;
    return db.insert('recurring_transactions', recurring.toMap());
  }

  Future<void> update(RecurringModel recurring) async {
    final db = await _db;
    await db.update('recurring_transactions', recurring.toMap(),
        where: 'id = ?', whereArgs: [recurring.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }
}

class ProfileRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<UserProfileModel?> get() async {
    final db = await _db;
    final rows = await db.query('user_profile', where: 'id = 1');
    if (rows.isEmpty) return null;
    return UserProfileModel.fromMap(rows.first);
  }

  Future<void> save(UserProfileModel profile) async {
    final db = await _db;
    final exists = await get();
    if (exists == null) {
      await db.insert('user_profile', profile.toMap());
    } else {
      await db.update('user_profile', profile.toMap(), where: 'id = 1');
    }
  }
}
