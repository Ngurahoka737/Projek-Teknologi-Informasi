import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  // ======================
  // INIT DATABASE
  // ======================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('debt_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
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

  // ======================
  // CRUD DEBTS
  // ======================

  Future<int> insertDebt(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('debts', row);
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
    required DateTime dueDate,
  }) async {
    final db = await database;

    await db.update(
      'debts',
      {
        'title': title,
        'totalAmount': totalAmount,
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
}
