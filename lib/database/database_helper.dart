import 'dart:io';

import '../models/expense.dart';
import '../models/income.dart';
import '../models/merchant_rule.dart';
import '../models/recurring_transaction.dart';
import '../models/household_member.dart';
import '../models/account.dart';
import '../models/goal.dart';
import '../models/app_user_record.dart';
import '../models/user_profile.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../utils/money_format.dart';
import '../models/bank_transaction.dart';
import '../models/user_feedback.dart';
import '../constants/default_categories.dart';
import '../utils/category_utils.dart';
import '../services/database_key_service.dart';
import '../services/database_migration_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static const String balanceBroughtForwardSource = 'Balance Brought Forward';

  DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    final password = await DatabaseKeyService.instance.getSqlCipherPassword();
    final dbFile = File(path);

    Map<String, dynamic>? legacyExport;
    if (await DatabaseMigrationService.isPlaintextSqliteFile(dbFile)) {
      legacyExport = await DatabaseMigrationService.exportPlaintextDatabase(path);
      await DatabaseMigrationService.archivePlaintextFile(dbFile);
    }

    final db = await openDatabase(
      path,
      password: password,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    if (legacyExport != null) {
      await _restoreAllDataOnDatabase(db, legacyExport);
    }

    return db;
  }

  Future<void> _restoreAllDataOnDatabase(
    Database db,
    Map<String, dynamic> data,
  ) async {
    await db.transaction((txn) async {
      for (final table in [
        'expenses',
        'income',
        'merchant_rules',
        'category_budgets',
        'recurring_transactions',
        'household_members',
        'accounts',
        'goals',
        'categories',
        'bank_transactions',
        'app_user',
      ]) {
        await txn.delete(table);
      }
      await _insertRows(txn, 'categories', data['categories']);
      await _insertRows(txn, 'household_members', data['household_members']);
      await _insertRows(txn, 'accounts', data['accounts']);
      await _insertRows(txn, 'expenses', data['expenses']);
      await _insertRows(txn, 'income', data['income']);
      await _insertRows(txn, 'merchant_rules', data['merchant_rules']);
      await _insertRows(txn, 'category_budgets', data['category_budgets']);
      await _insertRows(
        txn,
        'recurring_transactions',
        data['recurring_transactions'],
      );
      await _insertRows(txn, 'goals', data['goals']);
      await _insertRows(txn, 'bank_transactions', data['bank_transactions']);
      await _insertRows(txn, 'app_user', data['app_user']);
    });
    final members = await db.query('household_members');
    if (members.isEmpty) {
      await _seedDefaults(db);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await _createCoreTables(db);
    await _createFeatureTables(db);
    await _createFeedbackTable(db);
    await _createAppUserTable(db);
    await _seedDefaultCategories(db);
    await _seedDefaults(db);
  }

  Future<void> _createAppUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_user(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        householdName TEXT DEFAULT '',
        region TEXT NOT NULL,
        currency TEXT NOT NULL,
        primaryBankId TEXT DEFAULT '',
        authMethod TEXT NOT NULL DEFAULT 'pin',
        secretHash TEXT NOT NULL,
        biometricEnabled INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultCategories(Database db) async {
    for (final name in DefaultCategories.expenseCategories) {
      await db.insert(
        'categories',
        {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _createCoreTables(Database db) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expenseDate TEXT,
        category TEXT,
        item TEXT,
        amount REAL,
        paymentMethod TEXT,
        txnRef TEXT,
        memberId INTEGER,
        accountId INTEGER,
        isTransfer INTEGER DEFAULT 0,
        notes TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE income(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        incomeDate TEXT,
        month TEXT,
        category TEXT,
        source TEXT,
        amount REAL,
        paymentMethod TEXT,
        memberId INTEGER,
        accountId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE bank_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionDate TEXT,
        description TEXT,
        amount REAL,
        isDebit INTEGER,
        category TEXT,
        item TEXT,
        selected INTEGER,
        duplicate INTEGER
      )
    ''');
  }

  Future<void> _createFeatureTables(Database db) async {
    await db.execute('''
      CREATE TABLE merchant_rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT UNIQUE,
        category TEXT,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE category_budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT,
        category TEXT,
        amount REAL,
        UNIQUE(month, category)
      )
    ''');
    await db.execute('''
      CREATE TABLE recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item TEXT,
        amount REAL,
        category TEXT,
        isIncome INTEGER DEFAULT 0,
        dayOfMonth INTEGER DEFAULT 1,
        paymentMethod TEXT DEFAULT 'UPI',
        memberId INTEGER,
        accountId INTEGER,
        isActive INTEGER DEFAULT 1,
        lastGeneratedMonth TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE household_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        role TEXT DEFAULT 'Member',
        color TEXT DEFAULT '#64B5F6'
      )
    ''');
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        type TEXT DEFAULT 'Savings',
        isDefault INTEGER DEFAULT 0,
        bankId TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        targetAmount REAL,
        currentAmount REAL DEFAULT 0,
        deadline TEXT,
        linkedCategory TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');
  }

  Future<void> _createFeedbackTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_feedback(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        subject TEXT NOT NULL,
        message TEXT NOT NULL,
        userName TEXT DEFAULT '',
        userEmail TEXT DEFAULT '',
        userPhone TEXT DEFAULT '',
        appVersion TEXT DEFAULT '',
        status TEXT DEFAULT 'newFeedback',
        adminNotes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        syncedToServer INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('household_members', {
      'name': 'Self',
      'role': 'Primary',
      'color': '#64B5F6',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('accounts', {
      'name': 'Main Account',
      'type': 'Savings',
      'isDefault': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bank_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transactionDate TEXT,
          description TEXT,
          amount REAL,
          isDebit INTEGER,
          category TEXT,
          item TEXT,
          selected INTEGER,
          duplicate INTEGER
        )
      ''');
    }
    if (oldVersion < 7) {
      await _addColumnIfMissing(db, 'expenses', 'txnRef', "TEXT DEFAULT ''");
      await _addColumnIfMissing(db, 'expenses', 'memberId', 'INTEGER');
      await _addColumnIfMissing(db, 'expenses', 'accountId', 'INTEGER');
      await _addColumnIfMissing(
        db,
        'expenses',
        'isTransfer',
        'INTEGER DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'expenses',
        'notes',
        "TEXT DEFAULT ''",
      );
      await _addColumnIfMissing(db, 'income', 'memberId', 'INTEGER');
      await _addColumnIfMissing(db, 'income', 'accountId', 'INTEGER');
      await _createFeatureTables(db);
      await _seedDefaults(db);
    }
    if (oldVersion < 8) {
      await _createFeedbackTable(db);
    }
    if (oldVersion < 9) {
      await _addColumnIfMissing(db, 'accounts', 'bankId', "TEXT DEFAULT ''");
    }
    if (oldVersion < 10) {
      await _createAppUserTable(db);
    }
  }

  // ── App user (local auth account) ───────────────────────────────

  Future<bool> hasAppUser() async {
    final db = await database;
    final rows = await db.query('app_user', columns: ['id'], limit: 1);
    return rows.isNotEmpty;
  }

  Future<AppUserRecord?> getAppUser() async {
    final db = await database;
    final rows = await db.query('app_user', limit: 1);
    if (rows.isEmpty) return null;
    return AppUserRecord.fromMap(rows.first);
  }

  Future<void> upsertAppUser(AppUserRecord user) async {
    final db = await database;
    await db.insert(
      'app_user',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAppUser() async {
    final db = await database;
    await db.delete('app_user');
  }

  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  // ── Merchant rules ──────────────────────────────────────────────

  Future<int> upsertMerchantRule(String pattern, String category) async {
    final db = await database;
    final normalized = pattern.toLowerCase().trim();
    if (normalized.isEmpty) return 0;
    return db.insert(
      'merchant_rules',
      {
        'pattern': normalized,
        'category': category,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MerchantRule>> getMerchantRules() async {
    final db = await database;
    final rows = await db.query('merchant_rules', orderBy: 'pattern');
    return rows.map(MerchantRule.fromMap).toList();
  }

  Future<String?> matchMerchantRule(String text) async {
    final db = await database;
    final rules = await db.query('merchant_rules', orderBy: 'length(pattern) DESC');
    final lower = text.toLowerCase();
    for (final row in rules) {
      final pattern = row['pattern'] as String;
      if (lower.contains(pattern)) {
        return row['category'] as String;
      }
    }
    return null;
  }

  Future<int> deleteMerchantRule(int id) async {
    final db = await database;
    return db.delete('merchant_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ── Category budgets ────────────────────────────────────────────

  Future<void> setCategoryBudget(
    String month,
    String category,
    double amount,
  ) async {
    final db = await database;
    if (amount <= 0) {
      await db.delete(
        'category_budgets',
        where: 'month = ? AND category = ?',
        whereArgs: [month, category],
      );
      return;
    }
    await db.insert(
      'category_budgets',
      {'month': month, 'category': category, 'amount': roundMoney(amount)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, double>> getCategoryBudgets(String month) async {
    final db = await database;
    final rows = await db.query(
      'category_budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return {
      for (final row in rows)
        row['category'] as String: (row['amount'] as num).toDouble(),
    };
  }

  // ── Recurring ───────────────────────────────────────────────────

  Future<int> insertRecurring(RecurringTransaction r) async {
    final db = await database;
    return db.insert('recurring_transactions', r.toMap());
  }

  Future<List<RecurringTransaction>> getActiveRecurring() async {
    final db = await database;
    final rows = await db.query(
      'recurring_transactions',
      where: 'isActive = 1',
      orderBy: 'item',
    );
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<List<RecurringTransaction>> getAllRecurring() async {
    final db = await database;
    final rows = await db.query('recurring_transactions', orderBy: 'item');
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<int> updateRecurring(RecurringTransaction r) async {
    final db = await database;
    return db.update(
      'recurring_transactions',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  Future<int> deleteRecurring(int id) async {
    final db = await database;
    return db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markRecurringGenerated(int id, String month) async {
    final db = await database;
    await db.update(
      'recurring_transactions',
      {'lastGeneratedMonth': month},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> recurringExistsForMonth(
    RecurringTransaction r,
    String month,
  ) async {
    final db = await database;
    if (r.isIncome) {
      final result = await db.query(
        'income',
        where: "source = ? AND substr(incomeDate, 1, 7) = ?",
        whereArgs: [r.item, month],
      );
      return result.isNotEmpty;
    }
    final result = await db.query(
      'expenses',
      where: "item = ? AND substr(expenseDate, 1, 7) = ? AND notes = 'recurring'",
      whereArgs: [r.item, month],
    );
    return result.isNotEmpty;
  }

  Future<bool> hasRealMatchForRecurring(
    RecurringTransaction r,
    String month,
  ) async {
    final db = await database;
    if (r.isIncome) {
      final result = await db.query(
        'income',
        where:
            "substr(incomeDate, 1, 7) = ? AND lower(source) LIKE ?",
        whereArgs: [month, '%${r.item.toLowerCase()}%'],
      );
      return result.isNotEmpty;
    }
    final result = await db.query(
      'expenses',
      where:
          "substr(expenseDate, 1, 7) = ? AND (notes IS NULL OR notes != 'recurring') AND lower(item) LIKE ?",
      whereArgs: [month, '%${r.item.toLowerCase()}%'],
    );
    return result.isNotEmpty;
  }

  // ── Household members ───────────────────────────────────────────

  Future<int> insertMember(HouseholdMember m) async {
    final db = await database;
    return db.insert('household_members', m.toMap());
  }

  Future<List<HouseholdMember>> getMembers() async {
    final db = await database;
    final rows = await db.query('household_members', orderBy: 'name');
    return rows.map(HouseholdMember.fromMap).toList();
  }

  Future<int> updateMember(HouseholdMember member) async {
    final db = await database;
    return db.update(
      'household_members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return db.delete('household_members', where: 'id = ?', whereArgs: [id]);
  }

  // ── Accounts ────────────────────────────────────────────────────

  Future<int> insertAccount(Account a) async {
    final db = await database;
    return db.insert('accounts', a.toMap());
  }

  Future<int> updateAccount(Account a) async {
    if (a.id == null) return 0;
    final db = await database;
    return db.update(
      'accounts',
      a.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [a.id],
    );
  }

  Future<void> setupInitialAccountFromRegistration(UserProfile profile) async {
    final bankId = profile.primaryBankId ?? '';
    final accounts = await getAccounts();
    final accountName = profile.firstName.trim().isEmpty
        ? 'Main Account'
        : '${profile.firstName.trim()} Account';

    if (accounts.isEmpty) {
      await insertAccount(
        Account(
          name: accountName,
          type: 'Savings',
          isDefault: true,
          bankId: bankId.isEmpty ? null : bankId,
        ),
      );
      return;
    }

    final defaultAccount = await getDefaultAccount();
    if (defaultAccount?.id == null) return;

    await updateAccount(
      defaultAccount!.copyWith(
        name: defaultAccount.name == 'Main Account' ? accountName : defaultAccount.name,
        bankId: bankId.isEmpty ? defaultAccount.bankId : bankId,
      ),
    );
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'name');
    return rows.map(Account.fromMap).toList();
  }

  Future<Account?> getDefaultAccount() async {
    final accounts = await getAccounts();
    if (accounts.isEmpty) return null;
    for (final a in accounts) {
      if (a.isDefault) return a;
    }
    return accounts.first;
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ── Goals ───────────────────────────────────────────────────────

  Future<int> insertGoal(Goal g) async {
    final db = await database;
    return db.insert('goals', g.toMap());
  }

  Future<List<Goal>> getActiveGoals() async {
    final db = await database;
    final rows = await db.query(
      'goals',
      where: 'isActive = 1',
      orderBy: 'name',
    );
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> updateGoal(Goal g) async {
    final db = await database;
    return db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<int> deleteGoal(int id) async {
    final db = await database;
    return db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ── Backup / restore ────────────────────────────────────────────

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    return {
      'version': 10,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': await db.query('categories'),
      'expenses': await db.query('expenses'),
      'income': await db.query('income'),
      'merchant_rules': await db.query('merchant_rules'),
      'category_budgets': await db.query('category_budgets'),
      'recurring_transactions': await db.query('recurring_transactions'),
      'household_members': await db.query('household_members'),
      'accounts': await db.query('accounts'),
      'goals': await db.query('goals'),
      'bank_transactions': await db.query('bank_transactions'),
      'app_user': await db.query('app_user'),
    };
  }

  Future<void> restoreAllData(Map<String, dynamic> data) async {
    final db = await database;
    await _restoreAllDataOnDatabase(db, data);
  }

  Future<void> _insertRows(
    DatabaseExecutor txn,
    String table,
    dynamic rows,
  ) async {
    if (rows is! List) return;
    for (final row in rows) {
      if (row is Map) {
        await txn.insert(table, Map<String, dynamic>.from(row));
      }
    }
  }


  // ── Existing methods (updated) ──────────────────────────────────

  Future<bool> transactionExists(BankTransaction t) async {
    final db = await database;
    final dateStr = _formatTxnDate(t.date);
    final item = t.item.isEmpty ? t.description : t.item;

    if (t.isDebit) {
      final result = await db.query(
        'expenses',
        where: 'expenseDate=? AND amount=? AND item=?',
        whereArgs: [dateStr, t.amount, item],
      );
      return result.isNotEmpty;
    }

    final result = await db.query(
      'income',
      where: "incomeDate=? AND amount=? AND source=? AND source != 'Manual'",
      whereArgs: [dateStr, t.amount, item],
    );
    return result.isNotEmpty;
  }

  String _formatTxnDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  Future<List<Income>> getIncomeForMonth(String month) async {
    final db = await database;
    final result = await db.query(
      'income',
      where:
          "source != 'Manual' AND incomeDate != '' AND substr(incomeDate, 1, 7) = ?",
      whereArgs: [month],
      orderBy: 'incomeDate DESC, id DESC',
    );
    return result.map((json) => Income.fromMap(json)).toList();
  }

  Future<void> seedDefaultCategories() async {
    for (final name in DefaultCategories.expenseCategories) {
      await insertCategory(name);
    }
  }

  Future<void> ensureDefaultCategories() async {
    await seedDefaultCategories();
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('income');
    await db.delete('bank_transactions');
  }

  /// Deletes expenses, income, category budgets, and bank import rows for [month]
  /// (YYYY-MM) only. Does not touch other months, categories, or settings.
  Future<Map<String, int>> deleteMonthData(String month) async {
    final db = await database;

    final expensesDeleted = await db.delete(
      'expenses',
      where: "substr(expenseDate, 1, 7) = ?",
      whereArgs: [month],
    );

    final incomeDeleted = await db.delete(
      'income',
      where: "month = ? OR (incomeDate != '' AND substr(incomeDate, 1, 7) = ?)",
      whereArgs: [month, month],
    );

    final budgetsDeleted = await db.delete(
      'category_budgets',
      where: 'month = ?',
      whereArgs: [month],
    );

    final bankDeleted = await db.delete(
      'bank_transactions',
      where: "substr(transactionDate, 1, 7) = ?",
      whereArgs: [month],
    );

    return {
      'expenses': expensesDeleted,
      'income': incomeDeleted,
      'categoryBudgets': budgetsDeleted,
      'bankTransactions': bankDeleted,
    };
  }

  Future<void> resetDatabase() async {
    final db = await database;
    for (final table in [
      'expenses',
      'income',
      'bank_transactions',
      'merchant_rules',
      'category_budgets',
      'recurring_transactions',
      'goals',
    ]) {
      await db.delete(table);
    }
    await db.delete('categories');
    await db.delete('household_members');
    await db.delete('accounts');
    await seedDefaultCategories();
    await _seedDefaults(db);
  }

  Future<int> insertIncome(Income income) async {
    final db = await database;
    return db.insert('income', income.toMap());
  }

  Future<double> getImportedIncome(String month) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM income
      WHERE source NOT IN ('Manual', ?) AND incomeDate != ''
        AND substr(incomeDate, 1, 7) = ?
    ''',
      [balanceBroughtForwardSource, month],
    );
    if (result.isEmpty || result.first['total'] == null) return 0;
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getBalanceBroughtForwardAmount(String month) async {
    final db = await database;
    final result = await db.query(
      'income',
      where: 'month = ? AND source = ?',
      whereArgs: [month, balanceBroughtForwardSource],
    );
    if (result.isEmpty) return 0;
    return (result.first['amount'] as num).toDouble();
  }

  Future<void> upsertBalanceBroughtForward({
    required String month,
    required double amount,
    required String incomeDate,
  }) async {
    final db = await database;
    final existing = await db.query(
      'income',
      where: 'month = ? AND source = ?',
      whereArgs: [month, balanceBroughtForwardSource],
    );

    final row = {
      'incomeDate': incomeDate,
      'month': month,
      'category': 'Balance Brought Forward',
      'source': balanceBroughtForwardSource,
      'amount': roundMoney(amount),
      'paymentMethod': 'System',
    };

    if (existing.isEmpty) {
      await db.insert('income', row);
    } else {
      await db.update(
        'income',
        row,
        where: 'month = ? AND source = ?',
        whereArgs: [month, balanceBroughtForwardSource],
      );
    }
  }

  Future<void> deleteBalanceBroughtForward(String month) async {
    final db = await database;
    await db.delete(
      'income',
      where: 'month = ? AND source = ?',
      whereArgs: [month, balanceBroughtForwardSource],
    );
  }

  Future<double> getMonthLivingExpenses(String month) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where:
          "substr(expenseDate, 1, 7) = ? AND (isTransfer IS NULL OR isTransfer = 0)",
      whereArgs: [month],
    );

    var total = 0.0;
    for (final row in rows) {
      final category = row['category'] as String;
      if (CategoryUtils.isSavingsCategory(category)) continue;
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> getMonthInvestmentTotal(String month) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where:
          "substr(expenseDate, 1, 7) = ? AND (isTransfer IS NULL OR isTransfer = 0)",
      whereArgs: [month],
    );

    var total = 0.0;
    for (final row in rows) {
      final category = row['category'] as String;
      if (!CategoryUtils.isSavingsCategory(category)) continue;
      total += (row['amount'] as num).toDouble();
    }
    return total;
  }

  Future<double> calculateMonthBalance(String month) async {
    final manual = await getCurrentMonthIncome(month);
    final imported = await getImportedIncome(month);
    final broughtForward = await getBalanceBroughtForwardAmount(month);
    final spending = await getMonthLivingExpenses(month);
    final investments = await getMonthInvestmentTotal(month);
    return manual + imported + broughtForward - spending - investments;
  }

  Future<double> getTotalMonthIncome(String month) async {
    final manual = await getCurrentMonthIncome(month);
    final imported = await getImportedIncome(month);
    final broughtForward = await getBalanceBroughtForwardAmount(month);
    return manual + imported + broughtForward;
  }

  Future<List<Income>> getAllIncome() async {
    final db = await database;
    final result = await db.query('income', orderBy: 'id DESC');
    return result.map((json) => Income.fromMap(json)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'id DESC');
    return result.map(Expense.fromMap).toList();
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateIncome(
    int id,
    String source,
    double amount,
    String category,
  ) async {
    final db = await database;
    return db.update(
      'income',
      {'source': source, 'amount': roundMoney(amount), 'category': category},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateExpenseFull(Expense expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> updateExpense(int id, String item, double amount) async {
    final db = await database;
    return db.update(
      'expenses',
      {'item': item, 'amount': roundMoney(amount)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<void> insertManualIncome({
    required String month,
    required double amount,
    required String description,
  }) async {
    final normalized = roundMoney(amount);
    if (normalized <= 0) return;

    final source = description.trim();
    if (source.isEmpty) return;

    final db = await database;
    await db.insert('income', {
      'incomeDate': '',
      'month': month,
      'category': 'Income',
      'source': source,
      'amount': normalized,
      'paymentMethod': 'Manual',
    });
  }

  Future<List<Income>> getManualIncomeForMonth(String month) async {
    final db = await database;
    final result = await db.query(
      'income',
      where: "month = ? AND paymentMethod = 'Manual' AND amount > 0",
      whereArgs: [month],
      orderBy: 'id DESC',
    );
    return result.map(Income.fromMap).toList();
  }

  @Deprecated('Use insertManualIncome')
  Future<void> saveIncome(String month, double amount) async {
    await insertManualIncome(
      month: month,
      amount: amount,
      description: 'Manual',
    );
  }

  Future<double> getCurrentMonthIncome(String month) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM income
      WHERE month = ? AND paymentMethod = 'Manual'
      ''',
      [month],
    );
    if (result.isEmpty || result.first['total'] == null) return 0;
    return roundMoney((result.first['total'] as num).toDouble());
  }

  Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert(
      'categories',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name');
    return result.map((e) => e['name'] as String).toList();
  }

  Future<Map<String, double>> getMonthlyExpenseTotals() async {
    final db = await database;
    final expenses = await db.query('expenses');
    final monthlyTotals = <String, double>{};

    for (var expense in expenses) {
      final date = expense['expenseDate'] as String;
      if (date.length < 7) continue;
      final category = expense['category'] as String;
      if (CategoryUtils.isSavingsCategory(category)) continue;
      if ((expense['isTransfer'] as int? ?? 0) == 1) continue;

      final month = date.substring(0, 7);
      final amount = (expense['amount'] as num).toDouble();
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
    }

    final sortedKeys = monthlyTotals.keys.toList()..sort();
    return {for (final key in sortedKeys) key: monthlyTotals[key]!};
  }

  Future<Map<String, double>> getMemberSpending(String month) async {
    final db = await database;
    final rows = await db.query(
      'expenses',
      where:
          "substr(expenseDate, 1, 7) = ? AND (isTransfer IS NULL OR isTransfer = 0)",
      whereArgs: [month],
    );
    final totals = <String, double>{};
    final members = await getMembers();
    final memberNames = {for (final m in members) m.id!: m.name};

    for (final row in rows) {
      final category = row['category'] as String;
      if (CategoryUtils.isSavingsCategory(category)) continue;
      final memberId = row['memberId'] as int?;
      final name = memberNames[memberId] ?? 'Unassigned';
      final amount = (row['amount'] as num).toDouble();
      totals[name] = (totals[name] ?? 0) + amount;
    }
    return totals;
  }

  Future<int> insertBankTransaction(BankTransaction tx) async {
    final db = await database;
    return db.insert('bank_transactions', {
      'transactionDate': tx.date.toIso8601String(),
      'description': tx.description,
      'amount': tx.amount,
      'isDebit': tx.isDebit ? 1 : 0,
      'category': tx.category,
      'item': tx.item,
      'selected': tx.selected ? 1 : 0,
      'duplicate': tx.duplicate ? 1 : 0,
    });
  }

  Future<void> insertBankTransactions(
    List<BankTransaction> transactions,
  ) async {
    final db = await database;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert('bank_transactions', {
        'transactionDate': tx.date.toIso8601String(),
        'description': tx.description,
        'amount': tx.amount,
        'isDebit': tx.isDebit ? 1 : 0,
        'category': tx.category,
        'item': tx.item,
        'selected': tx.selected ? 1 : 0,
        'duplicate': tx.duplicate ? 1 : 0,
      });
    }
    await batch.commit(noResult: true);
  }

  // ── User feedback ───────────────────────────────────────────────

  Future<int> insertFeedback(UserFeedback feedback) async {
    final db = await database;
    return db.insert('user_feedback', feedback.toMap());
  }

  Future<List<UserFeedback>> getAllFeedback({FeedbackStatus? status}) async {
    final db = await database;
    final rows = await db.query(
      'user_feedback',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.storageKey] : null,
      orderBy: 'createdAt DESC',
    );
    return rows.map(UserFeedback.fromMap).toList();
  }

  Future<UserFeedback?> getFeedbackById(int id) async {
    final db = await database;
    final rows = await db.query(
      'user_feedback',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserFeedback.fromMap(rows.first);
  }

  Future<void> updateFeedback(UserFeedback feedback) async {
    if (feedback.id == null) return;
    final db = await database;
    await db.update(
      'user_feedback',
      feedback.toMap(),
      where: 'id = ?',
      whereArgs: [feedback.id],
    );
  }

  Future<void> updateFeedbackStatus(
    int id,
    FeedbackStatus status, {
    String? adminNotes,
  }) async {
    final existing = await getFeedbackById(id);
    if (existing == null) return;
    await updateFeedback(
      existing.copyWith(
        status: status,
        adminNotes: adminNotes ?? existing.adminNotes,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteFeedback(int id) async {
    final db = await database;
    await db.delete('user_feedback', where: 'id = ?', whereArgs: [id]);
  }
}
