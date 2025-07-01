import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../models/game_state.dart';
import '../models/game_models.dart';

/// Service responsible for persisting and loading game state using SQLite
class GamePersistenceService {
  static const String _databaseName = 'production_inc_save.db';
  static const int _databaseVersion = 1;

  Database? _database;

  /// Get singleton database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database with game tables
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_databaseName';

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  /// Create all necessary tables for game state persistence
  Future<void> _createTables(Database db, int version) async {
    // Game state table - stores core game data
    await db.execute('''
      CREATE TABLE game_state (
        id INTEGER PRIMARY KEY,
        money REAL NOT NULL,
        last_saved INTEGER NOT NULL
      )
    ''');

    // Materials inventory table
    await db.execute('''
      CREATE TABLE materials (
        material_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL
      )
    ''');

    // Products inventory table
    await db.execute('''
      CREATE TABLE products (
        product_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL
      )
    ''');

    // Active production tasks table
    await db.execute('''
      CREATE TABLE active_productions (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        duration_seconds REAL NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    // Active shipping orders table
    await db.execute('''
      CREATE TABLE active_shipping_orders (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        total_shipping_time REAL NOT NULL,
        total_revenue REAL NOT NULL
      )
    ''');

    // Shipping order items table (for multi-item orders)
    await db.execute('''
      CREATE TABLE shipping_order_items (
        order_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES active_shipping_orders (id)
      )
    ''');

    // Shipping history table
    await db.execute('''
      CREATE TABLE shipping_history (
        id TEXT PRIMARY KEY,
        completed_time INTEGER NOT NULL,
        total_revenue REAL NOT NULL
      )
    ''');

    // Shipping history items table
    await db.execute('''
      CREATE TABLE shipping_history_items (
        history_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (history_id) REFERENCES shipping_history (id)
      )
    ''');

    // Insert initial game state record
    await db.insert('game_state', {
      'id': 1,
      'money': 100.0, // Starting money
      'last_saved': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Save complete game state to database
  Future<void> saveGameState(GameState state) async {
    final db = await database;

    await db.transaction((txn) async {
      // Update core game state
      await txn.update(
        'game_state',
        {
          'money': state.money,
          'last_saved': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [1],
      );

      // Clear and save materials
      await txn.delete('materials');
      for (final entry in state.materials.entries) {
        if (entry.value > 0) {
          await txn.insert('materials', {
            'material_id': entry.key,
            'quantity': entry.value,
          });
        }
      }

      // Clear and save products
      await txn.delete('products');
      for (final entry in state.products.entries) {
        if (entry.value > 0) {
          await txn.insert('products', {
            'product_id': entry.key,
            'quantity': entry.value,
          });
        }
      }

      // Clear and save active productions
      await txn.delete('active_productions');
      for (final task in state.activeProductions) {
        await txn.insert('active_productions', {
          'id': task.id,
          'product_id': task.productId,
          'start_time': task.startTime.millisecondsSinceEpoch,
          'duration_seconds': task.durationSeconds,
          'quantity': task.quantity,
        });
      }

      // Clear and save active shipping orders
      await txn.delete('shipping_order_items');
      await txn.delete('active_shipping_orders');
      for (final order in state.activeShippingOrders) {
        await txn.insert('active_shipping_orders', {
          'id': order.id,
          'start_time': order.startTime.millisecondsSinceEpoch,
          'total_shipping_time': order.totalShippingTime,
          'total_revenue': order.totalRevenue,
        });

        // Save order items
        for (final item in order.items) {
          await txn.insert('shipping_order_items', {
            'order_id': order.id,
            'product_id': item.productId,
            'quantity': item.quantity,
          });
        }
      }

      // Clear and save shipping history (keep only last 100 entries for performance)
      await txn.delete('shipping_history_items');
      await txn.delete('shipping_history');
      final recentHistory =
          state.shippingHistory.length > 100
              ? state.shippingHistory.sublist(
                state.shippingHistory.length - 100,
              )
              : state.shippingHistory;

      for (final history in recentHistory) {
        await txn.insert('shipping_history', {
          'id': history.id,
          'completed_time': history.completedTime.millisecondsSinceEpoch,
          'total_revenue': history.totalRevenue,
        });

        // Save history items
        for (final item in history.items) {
          await txn.insert('shipping_history_items', {
            'history_id': history.id,
            'product_id': item.productId,
            'quantity': item.quantity,
          });
        }
      }
    });
  }

  /// Load complete game state from database
  Future<GameState> loadGameState() async {
    final db = await database;

    // Load core game state
    final gameStateResult = await db.query(
      'game_state',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (gameStateResult.isEmpty) {
      // Return default state if no save exists
      return const GameState();
    }

    final gameStateRow = gameStateResult.first;
    final money = gameStateRow['money'] as double;

    // Load materials
    final materialsResult = await db.query('materials');
    final materials = <String, int>{};
    for (final row in materialsResult) {
      materials[row['material_id'] as String] = row['quantity'] as int;
    }

    // Load products
    final productsResult = await db.query('products');
    final products = <String, int>{};
    for (final row in productsResult) {
      products[row['product_id'] as String] = row['quantity'] as int;
    }

    // Load active productions
    final productionsResult = await db.query('active_productions');
    final activeProductions = <ProductionTask>[];
    for (final row in productionsResult) {
      activeProductions.add(
        ProductionTask(
          id: row['id'] as String,
          productId: row['product_id'] as String,
          startTime: DateTime.fromMillisecondsSinceEpoch(
            row['start_time'] as int,
          ),
          durationSeconds: row['duration_seconds'] as double,
          quantity: row['quantity'] as int,
        ),
      );
    }

    // Load active shipping orders
    final shippingOrdersResult = await db.query('active_shipping_orders');
    final activeShippingOrders = <ShippingOrder>[];

    for (final orderRow in shippingOrdersResult) {
      final orderId = orderRow['id'] as String;

      // Load items for this order
      final itemsResult = await db.query(
        'shipping_order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );

      final items = <ShippingItem>[];
      for (final itemRow in itemsResult) {
        items.add(
          ShippingItem(
            productId: itemRow['product_id'] as String,
            quantity: itemRow['quantity'] as int,
          ),
        );
      }

      activeShippingOrders.add(
        ShippingOrder(
          id: orderId,
          items: items,
          startTime: DateTime.fromMillisecondsSinceEpoch(
            orderRow['start_time'] as int,
          ),
          totalShippingTime: orderRow['total_shipping_time'] as double,
          totalRevenue: orderRow['total_revenue'] as double,
        ),
      );
    }

    // Load shipping history
    final shippingHistoryResult = await db.query('shipping_history');
    final shippingHistory = <ShippingHistory>[];

    for (final historyRow in shippingHistoryResult) {
      final historyId = historyRow['id'] as String;

      // Load items for this history entry
      final itemsResult = await db.query(
        'shipping_history_items',
        where: 'history_id = ?',
        whereArgs: [historyId],
      );

      final items = <ShippingItem>[];
      for (final itemRow in itemsResult) {
        items.add(
          ShippingItem(
            productId: itemRow['product_id'] as String,
            quantity: itemRow['quantity'] as int,
          ),
        );
      }

      shippingHistory.add(
        ShippingHistory(
          id: historyId,
          items: items,
          completedTime: DateTime.fromMillisecondsSinceEpoch(
            historyRow['completed_time'] as int,
          ),
          totalRevenue: historyRow['total_revenue'] as double,
        ),
      );
    }

    return GameState(
      money: money,
      materials: materials,
      products: products,
      activeProductions: activeProductions,
      activeShippingOrders: activeShippingOrders,
      shippingHistory: shippingHistory,
    );
  }

  /// Check if a save file exists
  Future<bool> hasSaveData() async {
    final db = await database;
    final result = await db.query(
      'game_state',
      where: 'id = ?',
      whereArgs: [1],
    );
    return result.isNotEmpty;
  }

  /// Get the last save timestamp
  Future<DateTime?> getLastSaveTime() async {
    final db = await database;
    final result = await db.query(
      'game_state',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (result.isEmpty) return null;

    final timestamp = result.first['last_saved'] as int;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Reset/clear all game data (new game)
  Future<void> resetGameData() async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear all tables
      await txn.delete('materials');
      await txn.delete('products');
      await txn.delete('active_productions');
      await txn.delete('shipping_order_items');
      await txn.delete('active_shipping_orders');
      await txn.delete('shipping_history_items');
      await txn.delete('shipping_history');

      // Reset game state to defaults
      await txn.update(
        'game_state',
        {
          'money': 100.0, // Starting money
          'last_saved': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    });
  }

  /// Close database connection
  Future<void> dispose() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
