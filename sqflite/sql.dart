import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton class to handle database operations.
/// This class manages the creation, initialization, and operations on the SQLite database.
class SqlDb {
  // Singleton instance of SqlDb
  static final SqlDb _instance = SqlDb._internal();

  // Database instance
  static Database? _db;

  // Factory constructor for the singleton pattern
  factory SqlDb() {
    return _instance;
  }

  // Private internal constructor
  SqlDb._internal();

  /// Returns the database instance, initializing it if necessary.
  Future<Database?> get db async {
    if (_db == null) {
      _db = await _initializeDb();
    }
    return _db;
  }

  /// Initializes the database and creates tables if they don't exist.
  /// This method opens the database and sets up the schema.
  Future<Database> _initializeDb() async {
    // Get the default database path
    final databasePath = await getDatabasesPath();
    // Define the path to the database file
    final path = join(databasePath, 'slice_master.db');

    // Open the database and create tables if necessary
    return await openDatabase(
      path,
      version: 2, // Update this version number when schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Deletes and recreates the database.
  /// This method can be used to reset the database schema.
  Future<void> deleteAndRecreateDatabase() async {
    // Get the default database path
    final databasePath = await getDatabasesPath();
    // Define the path to the database file
    final path = join(databasePath, 'slice_master.db');
    // Delete the existing database file
    await deleteDatabase(path);
  }

  /// Creates the database tables.
  /// This method is called when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // Create 'users' table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        login_status BOOLEAN NOT NULL,
        invoice_number INTEGER DEFAULT 0
      )
    ''');

    // Create 'pizzas' table
    await db.execute('''
      CREATE TABLE pizzas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        smallPrice REAL NOT NULL,
        mediumPrice REAL NOT NULL,
        largePrice REAL NOT NULL,
        image TEXT NOT NULL,
        username TEXT NOT NULL,
        FOREIGN KEY (username) REFERENCES users(username)
      )
    ''');

    // Create 'invoices' table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        total_amount REAL NOT NULL,
        discount REAL DEFAULT 0,
        items TEXT,
        username TEXT NOT NULL,
        FOREIGN KEY (username) REFERENCES users(username)
      )
    ''');

    debugPrint("Database and tables created successfully!");
  }

  /// Handles database schema upgrades.
  /// This method is called when the database version is incremented.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Rename old 'invoices' table
      await db.execute('ALTER TABLE invoices RENAME TO invoices_old');
      // Create new 'invoices' table with updated schema
      await db.execute('''
        CREATE TABLE invoices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_number INTEGER NOT NULL,
          customer_name TEXT NOT NULL,
          date TEXT NOT NULL,
          time TEXT NOT NULL,
          total_amount REAL NOT NULL,
          discount REAL DEFAULT 0,
          items TEXT,
          username TEXT NOT NULL,
          FOREIGN KEY (username) REFERENCES users(username)
        )
      ''');
      // Copy data from old table to new table
      await db.execute('''
        INSERT INTO invoices (
          id, invoice_number, customer_name, date, time, total_amount, discount, items, username
        )
        SELECT id, invoice_number, customer_name, date, time, total_amount, 0, items, username
        FROM invoices_old
      ''');
      // Drop old table
      await db.execute('DROP TABLE invoices_old');
    }
  }

  /// Saves an invoice into the database.
  /// [invoiceData] should contain the details of the invoice to be saved.
  Future<void> saveInvoice(Map<String, dynamic> invoiceData) async {
    final mydb = await db;
    await mydb?.insert('invoices', invoiceData);
  }

  /// Reads data from the database using a raw SQL query.
  /// [query] is the raw SQL query to be executed.
  /// Returns a list of maps where each map represents a row of the result.
  Future<List<Map<String, dynamic>>?> readData(String query) async {
    final mydb = await db;
    return await mydb?.rawQuery(query);
  }

  /// Inserts data into the database using a raw SQL query.
  /// [query] is the raw SQL query to be executed.
  /// Returns the ID of the inserted row.
  Future<int?> insertData(String query) async {
    final mydb = await db;
    return await mydb?.rawInsert(query);
  }

  /// Updates data in the database using a raw SQL query.
  /// [query] is the raw SQL query to be executed.
  /// Returns the number of rows affected.
  Future<int?> updateData(String query) async {
    final mydb = await db;
    return await mydb?.rawUpdate(query);
  }

  /// Deletes data from the database using a raw SQL query.
  /// [query] is the raw SQL query to be executed.
  /// Returns the number of rows deleted.
  Future<int?> deleteData(String query) async {
    final mydb = await db;
    return await mydb?.rawDelete(query);
  }

  /// Inserts a new user into the 'users' table.
  /// [username] is the user's username.
  /// [password] is the user's password.
  /// Returns the ID of the inserted row.
  Future<int?> insertUser(String username, String password) async {
    final mydb = await db;
    return await mydb?.insert('users', {
      'username': username,
      'password': password,
      'login_status': 0,
      'invoice_number': 0
    });
  }

  /// Retrieves a user by username and password.
  /// [username] is the user's username.
  /// [password] is the user's password.
  /// Returns a map containing the user's details if found, or null if not found.
  Future<Map<String, dynamic>?> getUser(String username, String password) async {
    final mydb = await db;
    final result = await mydb?.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    return result?.isNotEmpty == true ? result?.first : null;
  }

  /// Gets the next invoice number for a given username.
  /// [username] is the user's username.
  /// Returns the next invoice number if successful, or null if not found.
  Future<int?> getNextInvoiceNumber(String username) async {
    final mydb = await db;
    final result = await mydb?.query(
      'users',
      columns: ['invoice_number'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result != null && result.isNotEmpty) {
      int invoiceNumber = result.first['invoice_number'] as int;
      invoiceNumber++;
      final updateResponse = await mydb?.update(
        'users',
        {'invoice_number': invoiceNumber},
        where: 'username = ?',
        whereArgs: [username],
      );
      return updateResponse != null && updateResponse > 0 ? invoiceNumber : null;
    } else {
      debugPrint('No user found with username $username');
      return null;
    }
  }

  /// Initializes the database. 
  /// Call this method after creating the instance to ensure the database is set up.
  Future<void> initializeDatabase() async {
    await db;
  }
}
