import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;
  String _dbFileName = 'debt_manager_guest.db';

  DBService._init();

  Future<void> configureForUser(String? uid) async {
    final sanitizedUid = _sanitizeUid(uid);
    final nextFileName = sanitizedUid == null || sanitizedUid.isEmpty
        ? 'debt_manager_guest.db'
        : 'debt_manager_$sanitizedUid.db';

    if (nextFileName == _dbFileName) return;

    await _database?.close();
    _database = null;
    _dbFileName = nextFileName;
  }

  String? _sanitizeUid(String? uid) {
    if (uid == null) return null;
    return uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  // ======================
  // INIT DATABASE
  // ======================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbFileName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // ======================
  // CREATE TABLE
  // ======================

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        totalAmount REAL,
        months INTEGER,
        monthlyAmount REAL,
        schedule TEXT,
        dueDay INTEGER,
        dueDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER,
        amount REAL,
        date TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE debts ADD COLUMN months INTEGER DEFAULT 1');
      await db.execute(
        'ALTER TABLE debts ADD COLUMN monthlyAmount REAL DEFAULT 0',
      );
      await db.execute('ALTER TABLE debts ADD COLUMN dueDay INTEGER DEFAULT 1');

      await db.execute(
        'UPDATE debts SET monthlyAmount = totalAmount WHERE monthlyAmount = 0',
      );
      await db.execute(
        "UPDATE debts SET dueDay = CAST(strftime('%d', dueDate) AS INTEGER) WHERE dueDate IS NOT NULL",
      );
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE debts ADD COLUMN schedule TEXT');
    }
  }

  // ======================
  // CRUD DEBTS
  // ======================

  Future<int> insertDebt(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('debts', row);
  }

  Future<void> upsertDebt(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert('debts', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllDebts() async {
    final db = await instance.database;
    return await db.query('debts', orderBy: 'id DESC');
  }

  Future<int> deleteDebt(int id) async {
    final db = await instance.database;

    await db.delete('payments', where: 'debtId = ?', whereArgs: [id]);

    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateDebt({
    required int id,
    required String title,
    required double totalAmount,
    required int months,
    required double monthlyAmount,
    required List<double>? monthlySchedule,
    required int dueDay,
    required DateTime dueDate,
  }) async {
    final db = await database;

    await db.update(
      'debts',
      {
        'title': title,
        'totalAmount': totalAmount,
        'months': months,
        'monthlyAmount': monthlyAmount,
        'schedule': monthlySchedule == null
            ? null
            : jsonEncode(monthlySchedule),
        'dueDay': dueDay,
        'dueDate': dueDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ======================
  // CRUD PAYMENTS
  // ======================

  Future<int> insertPayment(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('payments', row);
  }

  Future<void> upsertPayment(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert(
      'payments',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePayment(int id) async {
    final db = await database;

    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPaymentsByDebt(int debtId) async {
    final db = await instance.database;

    return await db.query(
      'payments',
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
  }

  Future<void> clearAll() async {
    final db = await database;

    await db.delete('payments');
    await db.delete('debts');
  }
}
