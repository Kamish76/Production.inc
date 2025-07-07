import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/game_state.dart';
import '../models/game_models.dart';

/// Service responsible for persisting and loading game state using SQLite
/// v1.4.8: Enhanced with migration system, backup, and performance optimizations
class GamePersistenceService {
  static const String _databaseName = 'production_inc_save.db';
  static const String _backupDatabaseName = 'production_inc_backup.db';
  static const int _databaseVersion = 3; // Updated for v1.4.10 queue system

  Database? _database;

  // Track what data has changed for incremental saves
  final Set<String> _dirtyTables = <String>{};
  final bool _isDirtyStateEnabled = true;

  /// Initialize database factory for desktop platforms if needed
  static void initializeDatabaseFactory() {
    // Only use FFI for desktop platforms (Windows, macOS, Linux)
    // Android and iOS have native SQLite support and should NOT use FFI
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        if (kDebugMode) {
          print('Using FFI database factory for desktop platform');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to initialize FFI database factory: $e');
        }
      }
    } else {
      if (kDebugMode) {
        print('Using default database factory for mobile/web platform');
      }
    }
  }

  /// Get singleton database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database with game tables and migration support
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/$_databaseName';

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _migrateTables,
        onOpen: _verifyDatabaseIntegrity,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Database initialization error: $e');
      }
      // Attempt recovery by creating backup and retry
      return await _recoverDatabase();
    }
  }

  /// Handle database migrations between versions
  Future<void> _migrateTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    try {
      if (kDebugMode) {
        print('Migrating database from version $oldVersion to $newVersion');
      }

      // Create backup before migration
      await _createDatabaseBackup();

      // Perform version-specific migrations
      for (int version = oldVersion + 1; version <= newVersion; version++) {
        await _migrateToVersion(db, version);
      }

      if (kDebugMode) {
        print('Database migration completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Database migration failed: $e');
      }
      rethrow;
    }
  }

  /// Perform migration to specific version
  Future<void> _migrateToVersion(Database db, int version) async {
    switch (version) {
      case 2:
        // v1.4.8 migrations - add integrity tracking columns
        await _migrateToVersion2(db);
        break;
      case 3:
        // v1.4.10 migrations - queue system and build preferences
        await _migrateToVersion3(db);
        break;
      default:
        if (kDebugMode) {
          print('No migration defined for version $version');
        }
    }
  }

  /// Migration to version 2 (v1.4.8)
  Future<void> _migrateToVersion2(Database db) async {
    // Add checksum column for data integrity
    try {
      await db.execute('''
        ALTER TABLE game_state ADD COLUMN 
        data_checksum TEXT DEFAULT NULL
      ''');
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (checksum): $e');
      }
    }

    // Add last backup timestamp
    try {
      await db.execute('''
        ALTER TABLE game_state ADD COLUMN 
        last_backup INTEGER DEFAULT 0
      ''');
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (backup): $e');
      }
    }
  }

  /// Migration to version 3 (v1.4.10)
  Future<void> _migrateToVersion3(Database db) async {
    try {
      // Add is_queued column to active_productions table
      await db.execute('''
        ALTER TABLE active_productions ADD COLUMN 
        is_queued INTEGER DEFAULT 0
      ''');
      if (kDebugMode) {
        print('Added is_queued column to active_productions');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (is_queued): $e');
      }
    }

    try {
      // Create build_quantity_preferences table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS build_quantity_preferences (
          product_id TEXT PRIMARY KEY,
          quantity INTEGER NOT NULL DEFAULT 1
        )
      ''');
      if (kDebugMode) {
        print('Created build_quantity_preferences table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (build_quantity_preferences): $e');
      }
    }
  }

  /// Create backup of existing database before major operations
  Future<void> _createDatabaseBackup() async {
    if (_database == null) return;

    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = '$dbPath/$_databaseName';
      final backupPath = '$dbPath/$_backupDatabaseName';

      // Copy current database to backup
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(backupPath);
        if (kDebugMode) {
          print('Database backup created successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Database backup failed: $e');
      }
    }
  }

  /// Recover database from backup or recreate
  Future<Database> _recoverDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final backupPath = '$dbPath/$_backupDatabaseName';
      final mainPath = '$dbPath/$_databaseName';

      // Try to restore from backup
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.copy(mainPath);
        if (kDebugMode) {
          print('Database restored from backup');
        }
        return await openDatabase(mainPath, version: _databaseVersion);
      }

      // If no backup, create fresh database
      if (kDebugMode) {
        print('Creating fresh database after recovery attempt');
      }
      return await openDatabase(
        mainPath,
        version: _databaseVersion,
        onCreate: _createTables,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Database recovery failed: $e');
      }
      rethrow;
    }
  }

  /// Verify database integrity on open
  Future<void> _verifyDatabaseIntegrity(Database db) async {
    try {
      // Quick integrity check
      final result = await db.rawQuery('PRAGMA integrity_check');
      if (result.isNotEmpty && result.first.values.first != 'ok') {
        if (kDebugMode) {
          print('Database integrity check failed');
        }
      }

      // Verify essential tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      const requiredTables = [
        'game_state',
        'materials',
        'products',
        'active_productions',
        'active_shipping_orders',
        'shipping_order_items',
        'shipping_history',
        'shipping_history_items',
        'build_quantity_preferences', // V1.4.10
      ];

      final existingTables = tables.map((t) => t['name'] as String).toSet();
      for (final table in requiredTables) {
        if (!existingTables.contains(table)) {
          throw Exception('Missing required table: $table');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Database verification failed: $e');
      }
      rethrow;
    }
  }

  /// Create all necessary tables for game state persistence
  Future<void> _createTables(Database db, int version) async {
    // Game state table - stores core game data with integrity tracking
    await db.execute('''
      CREATE TABLE game_state (
        id INTEGER PRIMARY KEY,
        money REAL NOT NULL,
        last_saved INTEGER NOT NULL,
        data_checksum TEXT DEFAULT NULL,
        last_backup INTEGER DEFAULT 0
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
        quantity INTEGER NOT NULL,
        is_queued INTEGER DEFAULT 0
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

    // Build quantity preferences table (V1.4.10)
    await db.execute('''
      CREATE TABLE build_quantity_preferences (
        product_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL DEFAULT 1
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
          'is_queued': task.isQueued ? 1 : 0,
        });
      }

      // Clear and save build quantity preferences
      await txn.delete('build_quantity_preferences');
      for (final entry in state.buildQuantityPreferences.entries) {
        await txn.insert('build_quantity_preferences', {
          'product_id': entry.key,
          'quantity': entry.value,
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
          isQueued: (row['is_queued'] as int?) == 1,
        ),
      );
    }

    // Load build quantity preferences
    final preferencesResult = await db.query('build_quantity_preferences');
    final buildQuantityPreferences = <String, int>{};
    for (final row in preferencesResult) {
      buildQuantityPreferences[row['product_id'] as String] =
          row['quantity'] as int;
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
      buildQuantityPreferences: buildQuantityPreferences,
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

  /// Mark a data type as dirty for incremental saves
  void markDirty(String dataType) {
    if (_isDirtyStateEnabled) {
      _dirtyTables.add(dataType);
    }
  }

  /// Enhanced save with incremental optimization
  Future<void> saveGameStateOptimized(
    GameState state, {
    bool forceFullSave = false,
  }) async {
    try {
      final db = await database;

      // Create backup before major operations
      if (forceFullSave) {
        await _createDatabaseBackup();
      }

      if (_isDirtyStateEnabled && !forceFullSave && _dirtyTables.isNotEmpty) {
        await _saveIncrementalChanges(db, state);
      } else {
        await _saveFullGameState(db, state);
      }

      // Clear dirty state after successful save
      _dirtyTables.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game state: $e');
      }
      // Fallback to original save method
      await saveGameState(state);
    }
  }

  /// Save only changed data for performance optimization
  Future<void> _saveIncrementalChanges(Database db, GameState state) async {
    await db.transaction((txn) async {
      // Always update core game state
      await txn.update(
        'game_state',
        {
          'money': state.money,
          'last_saved': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [1],
      );

      // Save only dirty tables
      if (_dirtyTables.contains('materials')) {
        await _saveMaterialsOptimized(txn, state.materials);
      }

      if (_dirtyTables.contains('products')) {
        await _saveProductsOptimized(txn, state.products);
      }

      if (_dirtyTables.contains('productions')) {
        await _saveProductionsOptimized(txn, state.activeProductions);
      }

      if (_dirtyTables.contains('shipping')) {
        await _saveShippingOptimized(
          txn,
          state.activeShippingOrders,
          state.shippingHistory,
        );
      }

      if (_dirtyTables.contains('preferences')) {
        await _saveBuildQuantityPreferencesOptimized(
          txn,
          state.buildQuantityPreferences,
        );
      }
    });

    if (kDebugMode) {
      print(
        'Incremental save completed for tables: ${_dirtyTables.join(", ")}',
      );
    }
  }

  /// Full save method (enhanced original)
  Future<void> _saveFullGameState(Database db, GameState state) async {
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

      await _saveMaterialsOptimized(txn, state.materials);
      await _saveProductsOptimized(txn, state.products);
      await _saveProductionsOptimized(txn, state.activeProductions);
      await _saveShippingOptimized(
        txn,
        state.activeShippingOrders,
        state.shippingHistory,
      );
      await _saveBuildQuantityPreferencesOptimized(
        txn,
        state.buildQuantityPreferences,
      );
    });
  }

  /// Optimized materials save
  Future<void> _saveMaterialsOptimized(
    Transaction txn,
    Map<String, int> materials,
  ) async {
    await txn.delete('materials');
    for (final entry in materials.entries) {
      if (entry.value > 0) {
        await txn.insert('materials', {
          'material_id': entry.key,
          'quantity': entry.value,
        });
      }
    }
  }

  /// Optimized products save
  Future<void> _saveProductsOptimized(
    Transaction txn,
    Map<String, int> products,
  ) async {
    await txn.delete('products');
    for (final entry in products.entries) {
      if (entry.value > 0) {
        await txn.insert('products', {
          'product_id': entry.key,
          'quantity': entry.value,
        });
      }
    }
  }

  /// Optimized productions save
  Future<void> _saveProductionsOptimized(
    Transaction txn,
    List<ProductionTask> productions,
  ) async {
    await txn.delete('active_productions');
    for (final task in productions) {
      await txn.insert('active_productions', {
        'id': task.id,
        'product_id': task.productId,
        'start_time': task.startTime.millisecondsSinceEpoch,
        'duration_seconds': task.durationSeconds,
        'quantity': task.quantity,
        'is_queued': task.isQueued ? 1 : 0,
      });
    }
  }

  /// Optimized shipping data save
  Future<void> _saveShippingOptimized(
    Transaction txn,
    List<ShippingOrder> orders,
    List<ShippingHistory> history,
  ) async {
    // Clear and save active shipping orders
    await txn.delete('shipping_order_items');
    await txn.delete('active_shipping_orders');
    for (final order in orders) {
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
        history.length > 100 ? history.sublist(history.length - 100) : history;

    for (final historyEntry in recentHistory) {
      await txn.insert('shipping_history', {
        'id': historyEntry.id,
        'completed_time': historyEntry.completedTime.millisecondsSinceEpoch,
        'total_revenue': historyEntry.totalRevenue,
      });

      // Save history items
      for (final item in historyEntry.items) {
        await txn.insert('shipping_history_items', {
          'history_id': historyEntry.id,
          'product_id': item.productId,
          'quantity': item.quantity,
        });
      }
    }
  }

  /// Optimized build quantity preferences save
  Future<void> _saveBuildQuantityPreferencesOptimized(
    Transaction txn,
    Map<String, int> buildQuantityPreferences,
  ) async {
    await txn.delete('build_quantity_preferences');
    for (final entry in buildQuantityPreferences.entries) {
      await txn.insert('build_quantity_preferences', {
        'product_id': entry.key,
        'quantity': entry.value,
      });
    }
  }
}
