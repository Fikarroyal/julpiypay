import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Lapisan akses database lokal Julpiypay. Semua data disimpan di device,
/// tidak pernah dikirim ke server manapun (lihat README bagian Privasi).
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<String> get dbPath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'julpiypay.db');
  }

  Future<Database> _open() async {
    final path = await dbPath;
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        final batch = db.batch();

        batch.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            initial_balance REAL NOT NULL DEFAULT 0,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        batch.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            description TEXT
          )
        ''');

        batch.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category_id INTEGER,
            account_id INTEGER NOT NULL,
            to_account_id INTEGER,
            date TEXT NOT NULL,
            note TEXT,
            is_recurring INTEGER NOT NULL DEFAULT 0,
            recurring_id INTEGER,
            created_at TEXT NOT NULL,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
            FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
            FOREIGN KEY (to_account_id) REFERENCES accounts (id) ON DELETE SET NULL
          )
        ''');

        batch.execute('''
          CREATE TABLE tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        ''');

        batch.execute('''
          CREATE TABLE transaction_tags (
            transaction_id INTEGER NOT NULL,
            tag_id INTEGER NOT NULL,
            PRIMARY KEY (transaction_id, tag_id),
            FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
            FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE
          )
        ''');

        batch.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            period TEXT NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            notification_threshold REAL NOT NULL DEFAULT 0.8,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
          )
        ''');

        batch.execute('''
          CREATE TABLE saving_goals (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            target_amount REAL NOT NULL,
            current_amount REAL NOT NULL DEFAULT 0,
            deadline TEXT NOT NULL,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            description TEXT
          )
        ''');

        batch.execute('''
          CREATE TABLE bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            due_date TEXT NOT NULL,
            category_id INTEGER,
            account_id INTEGER NOT NULL,
            is_recurring INTEGER NOT NULL DEFAULT 0,
            reminder INTEGER NOT NULL DEFAULT 1,
            is_paid INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
            FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
          )
        ''');

        batch.execute('''
          CREATE TABLE recurring_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category_id INTEGER,
            account_id INTEGER NOT NULL,
            note TEXT,
            frequency TEXT NOT NULL,
            next_date TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
            FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
          )
        ''');

        batch.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY,
            display_name TEXT NOT NULL,
            currency TEXT NOT NULL DEFAULT 'IDR',
            monthly_income_target REAL NOT NULL DEFAULT 0,
            saving_target_percent REAL NOT NULL DEFAULT 0,
            preferred_account_id INTEGER,
            financial_month_start INTEGER NOT NULL DEFAULT 1,
            theme_mode TEXT NOT NULL DEFAULT 'system',
            onboarding_complete INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await batch.commit(noResult: true);
      },
    );
  }

  /// Menutup & menghapus koneksi supaya bisa dibuka ulang setelah restore.
  Future<void> reset() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
