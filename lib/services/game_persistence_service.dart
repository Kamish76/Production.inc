import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/game_state.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';

/// Service responsible for persisting and loading game state using SQLite
/// v1.4.8: Enhanced with migration system, backup, and performance optimizations
class GamePersistenceService {
    static String _databaseName = 'production_inc_save.db';
  static const String _backupDatabaseName = 'production_inc_backup.db';
  static const int _databaseVersion =
      9; // Updated for Phase 4: R&D Lab & Technology Tree

  Database? _database;

  // Track what data has changed for incremental saves
  final Set<String> _dirtyTables = <String>{};
  final bool _isDirtyStateEnabled = true;

  /// Initialize database factory for desktop platforms if needed
  /// Optionally specify a unique database name for test isolation
  static void initializeDatabaseFactory({String? testDatabaseName}) {
    if (testDatabaseName != null) {
      _databaseName = testDatabaseName;
    } else {
      _databaseName = 'production_inc_save.db';
    }
    // Only use FFI for desktop platforms (Windows, macOS, Linux)
    // Android and iOS have native SQLite support and should NOT use FFI
    // Also use FFI for test environment
    if (!kIsWeb &&
        (Platform.isWindows ||
            Platform.isMacOS ||
            Platform.isLinux ||
            Platform.environment.containsKey('FLUTTER_TEST'))) {
      try {
        sqfliteFfiInit();
      } catch (e) {
        if (kDebugMode) {
          print('sqfliteFfiInit notice: $e');
        }
      }
      try {
        databaseFactory = databaseFactoryFfi;
        if (kDebugMode) {
          print('Using FFI database factory for desktop/test platform');
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
      if (!kIsWeb &&
          (Platform.isWindows ||
              Platform.isMacOS ||
              Platform.isLinux ||
              Platform.environment.containsKey('FLUTTER_TEST'))) {
        try {
          sqfliteFfiInit();
        } catch (_) {}
        try {
          databaseFactory = databaseFactoryFfi;
        } catch (_) {}
      }
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
      case 4:
        // v1.4.11 migrations - buy/sell quantity preferences
        await _migrateToVersion4(db);
        break;
      case 5:
        // v1.4.18 migrations - product unlock system
        await _migrateToVersion5(db);
        break;
      case 6:
        // v1.5.0 Phase 2 migrations - auto-build system
        await _migrateToVersion6(db);
        break;
      case 7:
        // v1.5.0 Phase 1 migrations - factory tier progression system
        await _migrateToVersion7(db);
        break;
      case 8:
        // v1.5.0 Phase 2 migrations - B2B corporate contracts & fleet system
        await _migrateToVersion8(db);
        break;
      case 9:
        // Phase 4 migrations - R&D Lab & Technology Tree
        await _migrateToVersion9(db);
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

  /// Migration to version 4 (v1.4.11)
  Future<void> _migrateToVersion4(Database db) async {
    try {
      // Create buy_quantity_preferences table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS buy_quantity_preferences (
          material_id TEXT PRIMARY KEY,
          quantity INTEGER NOT NULL DEFAULT 1
        )
      ''');
      if (kDebugMode) {
        print('Created buy_quantity_preferences table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (buy_quantity_preferences): $e');
      }
    }

    try {
      // Create sell_quantity_preferences table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sell_quantity_preferences (
          product_id TEXT PRIMARY KEY,
          quantity INTEGER NOT NULL DEFAULT 1
        )
      ''');
      if (kDebugMode) {
        print('Created sell_quantity_preferences table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (sell_quantity_preferences): $e');
      }
    }
  }

  /// Migration to version 5 (v1.4.18)
  Future<void> _migrateToVersion5(Database db) async {
    try {
      // Create unlocked_products table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS unlocked_products (
          product_id TEXT PRIMARY KEY,
          unlocked_time INTEGER NOT NULL
        )
      ''');
      if (kDebugMode) {
        print('Created unlocked_products table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (unlocked_products): $e');
      }
    }
  }

  /// Migration to version 6 (v1.5.0 Phase 2)
  Future<void> _migrateToVersion6(Database db) async {
    if (kDebugMode) {
      print('Starting migration to version 6 (auto-buy system)');
    }

    // Check if columns already exist by querying table info
    final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
    final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();
    
    if (kDebugMode) {
      print('Existing game_state columns: ${existingColumns.join(", ")}');
    }

    // Add auto-buy fields to game_state table if they don't exist
    if (!existingColumns.contains('auto_buy_machines_owned')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          auto_buy_machines_owned INTEGER DEFAULT 0
        ''');
        if (kDebugMode) {
          print('Added column: auto_buy_machines_owned');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (auto_buy_machines_owned): $e');
        }
      }
    }

    if (!existingColumns.contains('auto_buy_enabled')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          auto_buy_enabled INTEGER DEFAULT 0
        ''');
        if (kDebugMode) {
          print('Added column: auto_buy_enabled');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (auto_buy_enabled): $e');
        }
      }
    }

    if (!existingColumns.contains('auto_buy_last_tick')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          auto_buy_last_tick INTEGER
        ''');
        if (kDebugMode) {
          print('Added column: auto_buy_last_tick');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (auto_buy_last_tick): $e');
        }
      }
    }

    if (!existingColumns.contains('auto_buy_resource_capacity')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          auto_buy_resource_capacity INTEGER DEFAULT 10
        ''');
        if (kDebugMode) {
          print('Added column: auto_buy_resource_capacity');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (auto_buy_resource_capacity): $e');
        }
      }
    }

    try {
      // Create auto_build_machines table (tier-based machine ownership)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auto_build_machines (
          tier TEXT PRIMARY KEY,
          machine_count INTEGER NOT NULL DEFAULT 0
        )
      ''');
      if (kDebugMode) {
        print('Created auto_build_machines table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (auto_build_machines): $e');
      }
    }

    try {
      // Create auto_build_enabled table (tier-based enabled status)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auto_build_enabled (
          tier TEXT PRIMARY KEY,
          enabled INTEGER NOT NULL DEFAULT 0
        )
      ''');
      if (kDebugMode) {
        print('Created auto_build_enabled table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (auto_build_enabled): $e');
      }
    }

    try {
      // Create auto_build_last_tick table (tier-based last tick times)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auto_build_last_tick (
          tier TEXT PRIMARY KEY,
          last_tick INTEGER
        )
      ''');
      if (kDebugMode) {
        print('Created auto_build_last_tick table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (auto_build_last_tick): $e');
      }
    }

    try {
      // Create auto_build_capacity table (tier-based product capacity)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS auto_build_capacity (
          tier TEXT PRIMARY KEY,
          capacity INTEGER NOT NULL DEFAULT 10
        )
      ''');
      if (kDebugMode) {
        print('Created auto_build_capacity table');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration warning (auto_build_capacity): $e');
      }
    }
  }

  /// Migration to version 7 (v1.5.0 Phase 1: Factory Tiers)
  Future<void> _migrateToVersion7(Database db) async {
    if (kDebugMode) {
      print('Starting migration to version 7 (factory tier system)');
    }

    final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
    final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

    if (!existingColumns.contains('factory_tier')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          factory_tier INTEGER NOT NULL DEFAULT 1
        ''');
        if (kDebugMode) {
          print('Added column: factory_tier');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (factory_tier): $e');
        }
      }
    }
  }

  /// Migration to version 8 (v1.5.0 Phase 2: B2B Corporate Contracts & Logistics Fleet)
  Future<void> _migrateToVersion8(Database db) async {
    if (kDebugMode) {
      print('Starting migration to version 8 (B2B corporate contracts & fleet system)');
    }

    final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
    final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

    if (!existingColumns.contains('fleet_tier')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          fleet_tier INTEGER NOT NULL DEFAULT 1
        ''');
        if (kDebugMode) {
          print('Added column: fleet_tier');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (fleet_tier): $e');
        }
      }
    }

    // Corporate contracts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS corporate_contracts (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        target_product_id TEXT NOT NULL,
        required_quantity INTEGER NOT NULL,
        delivered_quantity INTEGER NOT NULL DEFAULT 0,
        cash_reward REAL NOT NULL,
        rep_reward INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Corporate client reputation table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS client_reputation (
        client_id TEXT PRIMARY KEY,
        reputation INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// Migration to version 9 (Phase 4: R&D Lab & Technology Tree)
  Future<void> _migrateToVersion9(Database db) async {
    if (kDebugMode) {
      print('Starting migration to version 9 (R&D Lab & Technology Tree)');
    }

    final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
    final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

    if (!existingColumns.contains('research_points')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          research_points INTEGER NOT NULL DEFAULT 0
        ''');
        if (kDebugMode) {
          print('Added column: research_points');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (research_points): $e');
        }
      }
    }

    if (!existingColumns.contains('overclock_active')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          overclock_active INTEGER NOT NULL DEFAULT 0
        ''');
        if (kDebugMode) {
          print('Added column: overclock_active');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (overclock_active): $e');
        }
      }
    }

    if (!existingColumns.contains('maintenance_wear')) {
      try {
        await db.execute('''
          ALTER TABLE game_state ADD COLUMN 
          maintenance_wear REAL NOT NULL DEFAULT 1.0
        ''');
        if (kDebugMode) {
          print('Added column: maintenance_wear');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration warning (maintenance_wear): $e');
        }
      }
    }

    // Researched technologies table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS researched_technologies (
        tech_id TEXT PRIMARY KEY,
        level INTEGER NOT NULL DEFAULT 0
      )
    ''');
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
        'buy_quantity_preferences', // V1.4.11
        'sell_quantity_preferences', // V1.4.11
      ];

      final existingTables = tables.map((t) => t['name'] as String).toSet();
      for (final table in requiredTables) {
        if (!existingTables.contains(table)) {
          throw Exception('Missing required table: $table');
        }
      }

      // Verify game_state has required columns for auto-buy (v1.5.0)
      final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
      final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();
      
      final requiredAutoColumns = {
        'auto_buy_machines_owned',
        'auto_buy_enabled',
        'auto_buy_last_tick',
        'auto_buy_resource_capacity',
      };
      
      bool missingColumns = false;
      for (final column in requiredAutoColumns) {
        if (!existingColumns.contains(column)) {
          missingColumns = true;
          if (kDebugMode) {
            print('Database verification: Missing column $column, will attempt fix');
          }
        }
      }
      
      // If columns are missing, run migration 6 to add them
      if (missingColumns) {
        if (kDebugMode) {
          print('Applying schema fix for auto-buy columns...');
        }
        await _migrateToVersion6(db);
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
        last_backup INTEGER DEFAULT 0,
        auto_buy_machines_owned INTEGER DEFAULT 0,
        auto_buy_enabled INTEGER DEFAULT 0,
        auto_buy_last_tick INTEGER,
        auto_buy_resource_capacity INTEGER DEFAULT 10,
        factory_tier INTEGER NOT NULL DEFAULT 1,
        fleet_tier INTEGER NOT NULL DEFAULT 1,
        research_points INTEGER NOT NULL DEFAULT 0,
        overclock_active INTEGER NOT NULL DEFAULT 0,
        maintenance_wear REAL NOT NULL DEFAULT 1.0
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

    // Buy quantity preferences table (V1.4.11)
    await db.execute('''
      CREATE TABLE buy_quantity_preferences (
        material_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Sell quantity preferences table (V1.4.11)
    await db.execute('''
      CREATE TABLE sell_quantity_preferences (
        product_id TEXT PRIMARY KEY,
        quantity INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Unlocked products table (V1.4.18)
    await db.execute('''
      CREATE TABLE unlocked_products (
        product_id TEXT PRIMARY KEY,
        unlocked_time INTEGER NOT NULL
      )
    ''');

    // Auto-build machines table (V1.5.0 Phase 2)
    await db.execute('''
      CREATE TABLE auto_build_machines (
        tier TEXT PRIMARY KEY,
        machine_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Auto-build enabled table (V1.5.0 Phase 2)
    await db.execute('''
      CREATE TABLE auto_build_enabled (
        tier TEXT PRIMARY KEY,
        enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Auto-build last tick table (V1.5.0 Phase 2)
    await db.execute('''
      CREATE TABLE auto_build_last_tick (
        tier TEXT PRIMARY KEY,
        last_tick INTEGER
      )
    ''');

    // Auto-build capacity table (V1.5.0 Phase 2)
    await db.execute('''
      CREATE TABLE auto_build_capacity (
        tier TEXT PRIMARY KEY,
        capacity INTEGER NOT NULL DEFAULT 10
      )
    ''');

    // Corporate contracts table (Phase 2)
    await db.execute('''
      CREATE TABLE corporate_contracts (
        id TEXT PRIMARY KEY,
        client_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        target_product_id TEXT NOT NULL,
        required_quantity INTEGER NOT NULL,
        delivered_quantity INTEGER NOT NULL DEFAULT 0,
        cash_reward REAL NOT NULL,
        rep_reward INTEGER NOT NULL,
        expires_at INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Corporate client reputation table (Phase 2)
    await db.execute('''
      CREATE TABLE client_reputation (
        client_id TEXT PRIMARY KEY,
        reputation INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Researched technologies table (Phase 4)
    await db.execute('''
      CREATE TABLE researched_technologies (
        tech_id TEXT PRIMARY KEY,
        level INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert initial game state record
    await db.insert('game_state', {
      'id': 1,
      'money': 100.0, // Starting money
      'last_saved': DateTime.now().millisecondsSinceEpoch,
      'factory_tier': 1,
      'fleet_tier': 1,
      'research_points': 0,
      'overclock_active': 0,
      'maintenance_wear': 1.0,
    });
  }

  /// Save complete game state to database
  Future<void> saveGameState(GameState state) async {
    final db = await database;

    await db.transaction((txn) async {
      await _saveCoreGameState(txn, state);
      await _saveMaterials(txn, state);
      await _saveProducts(txn, state);
      await _saveActiveProductions(txn, state);
      await _saveQuantityPreferences(txn, state);
      await _saveUnlockedProducts(txn, state);
      await _saveAutoBuildData(txn, state);
      await _saveShippingData(txn, state);
      await _saveContracts(txn, state);
      await _saveReputation(txn, state);
      await _saveTechnologies(txn, state);
    });
  }

  /// Save core game state (money, last saved time, auto-buy state, fleet tier, research)
  Future<void> _saveCoreGameState(DatabaseExecutor txn, GameState state) async {
    await txn.update(
      'game_state',
      {
        'money': state.money,
        'last_saved': DateTime.now().millisecondsSinceEpoch,
        'auto_buy_machines_owned': state.autoBuyMachinesOwned,
        'auto_buy_enabled': state.autoBuyEnabled ? 1 : 0,
        'auto_buy_last_tick': state.lastAutoBuyTick?.millisecondsSinceEpoch,
        'auto_buy_resource_capacity': state.autoBuyResourceCapacity,
        'factory_tier': state.factoryTier,
        'fleet_tier': state.fleetTier,
        'research_points': state.researchPoints,
        'overclock_active': state.overclockActive ? 1 : 0,
        'maintenance_wear': state.maintenanceWear,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// Save materials inventory
  Future<void> _saveMaterials(DatabaseExecutor txn, GameState state) async {
    await txn.delete('materials');
    for (final entry in state.materials.entries) {
      if (entry.value > 0) {
        await txn.insert('materials', {
          'material_id': entry.key,
          'quantity': entry.value,
        });
      }
    }
  }

  /// Save products inventory
  Future<void> _saveProducts(DatabaseExecutor txn, GameState state) async {
    await txn.delete('products');
    for (final entry in state.products.entries) {
      if (entry.value > 0) {
        await txn.insert('products', {
          'product_id': entry.key,
          'quantity': entry.value,
        });
      }
    }
  }

  /// Save active production tasks
  Future<void> _saveActiveProductions(
    DatabaseExecutor txn,
    GameState state,
  ) async {
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
  }

  /// Save all quantity preferences (build, buy, sell)
  Future<void> _saveQuantityPreferences(
    DatabaseExecutor txn,
    GameState state,
  ) async {
    // Save build quantity preferences
    await txn.delete('build_quantity_preferences');
    for (final entry in state.buildQuantityPreferences.entries) {
      await txn.insert('build_quantity_preferences', {
        'product_id': entry.key,
        'quantity': entry.value,
      });
    }

    // Save buy quantity preferences (V1.4.11)
    await txn.delete('buy_quantity_preferences');
    for (final entry in state.buyQuantityPreferences.entries) {
      await txn.insert('buy_quantity_preferences', {
        'material_id': entry.key,
        'quantity': entry.value,
      });
    }

    // Save sell quantity preferences (V1.4.11)
    await txn.delete('sell_quantity_preferences');
    for (final entry in state.sellQuantityPreferences.entries) {
      await txn.insert('sell_quantity_preferences', {
        'product_id': entry.key,
        'quantity': entry.value,
      });
    }
  }

  /// Save unlocked products (V1.4.18)
  Future<void> _saveUnlockedProducts(
    DatabaseExecutor txn,
    GameState state,
  ) async {
    await txn.delete('unlocked_products');
    for (final productId in state.unlockedProducts) {
      await txn.insert('unlocked_products', {
        'product_id': productId,
        'unlocked_time': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Save auto-build data (v1.5.0 Phase 2)
  Future<void> _saveAutoBuildData(DatabaseExecutor txn, GameState state) async {
    // Save machine counts
    await txn.delete('auto_build_machines');
    for (final entry in state.autoBuildMachinesOwned.entries) {
      if (entry.value > 0) {
        await txn.insert('auto_build_machines', {
          'tier': entry.key,
          'machine_count': entry.value,
        });
      }
    }

    // Save enabled status
    await txn.delete('auto_build_enabled');
    for (final entry in state.autoBuildEnabled.entries) {
      await txn.insert('auto_build_enabled', {
        'tier': entry.key,
        'enabled': entry.value ? 1 : 0,
      });
    }

    // Save last tick times
    await txn.delete('auto_build_last_tick');
    for (final entry in state.lastAutoBuildTick.entries) {
      if (entry.value != null) {
        await txn.insert('auto_build_last_tick', {
          'tier': entry.key,
          'last_tick': entry.value!.millisecondsSinceEpoch,
        });
      }
    }

    // Save capacity settings
    await txn.delete('auto_build_capacity');
    for (final entry in state.autoBuildProductCapacity.entries) {
      await txn.insert('auto_build_capacity', {
        'tier': entry.key,
        'capacity': entry.value,
      });
    }
  }

  /// Save shipping data (active orders and history)
  Future<void> _saveShippingData(DatabaseExecutor txn, GameState state) async {
    await _saveActiveShippingOrders(txn, state);
    await _saveShippingHistory(txn, state);
  }

  /// Save active shipping orders
  Future<void> _saveActiveShippingOrders(
    DatabaseExecutor txn,
    GameState state,
  ) async {
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
  }

  /// Save shipping history (limited to last 100 entries for performance)
  Future<void> _saveShippingHistory(
    DatabaseExecutor txn,
    GameState state,
  ) async {
    await txn.delete('shipping_history_items');
    await txn.delete('shipping_history');

    final maxEntries = LimitsConstants.maxShippingHistoryEntries;
    final recentHistory =
        state.shippingHistory.length > maxEntries
            ? state.shippingHistory.sublist(
              state.shippingHistory.length - maxEntries,
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
  }

  /// Load complete game state from database
  Future<GameState> loadGameState() async {
    final db = await database;

    // Load core game state first
    final gameStateResult = await db.query(
      'game_state',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (gameStateResult.isEmpty) {
      // Return default state if no save exists
      return const GameState(
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
    }

    final money = gameStateResult.first['money'] as double;
    
    // Load auto-buy state from game_state table
    final row = gameStateResult.first;
    final autoBuyMachinesOwned = (row['auto_buy_machines_owned'] as int?) ?? 0;
    final autoBuyEnabled = ((row['auto_buy_enabled'] as int?) ?? 0) == 1;
    final autoBuyLastTickMs = row['auto_buy_last_tick'] as int?;
    final autoBuyLastTick = autoBuyLastTickMs != null 
        ? DateTime.fromMillisecondsSinceEpoch(autoBuyLastTickMs) 
        : null;
    final autoBuyResourceCapacity = (row['auto_buy_resource_capacity'] as int?) ?? 10;
    final factoryTier = (row['factory_tier'] as int?) ?? 1;
    final fleetTier = (row['fleet_tier'] as int?) ?? 1;
    final researchPoints = (row['research_points'] as int?) ?? 0;
    final overclockActive = ((row['overclock_active'] as int?) ?? 0) == 1;
    final maintenanceWear = (row['maintenance_wear'] as num?)?.toDouble() ?? 1.0;

    // Load all game components in parallel where possible
    final materials = await _loadMaterials(db);
    final products = await _loadProducts(db);
    final activeProductions = await _loadActiveProductions(db);
    final quantityPreferences = await _loadQuantityPreferences(db);
    final unlockedProducts = await _loadUnlockedProducts(db);
    final activeShippingOrders = await _loadActiveShippingOrders(db);
    final shippingHistory = await _loadShippingHistory(db);
    final autoBuildData = await _loadAutoBuildData(db);
    final corporateContracts = await _loadContracts(db);
    final clientReputation = await _loadReputation(db);
    final techLevels = await _loadTechnologies(db);

    return GameState(
      money: money,
      materials: materials,
      products: products,
      activeProductions: activeProductions,
      activeShippingOrders: activeShippingOrders,
      shippingHistory: shippingHistory,
      buildQuantityPreferences: quantityPreferences.build,
      buyQuantityPreferences: quantityPreferences.buy,
      sellQuantityPreferences: quantityPreferences.sell,
      unlockedProducts: unlockedProducts,
      autoBuyMachinesOwned: autoBuyMachinesOwned,
      autoBuyEnabled: autoBuyEnabled,
      lastAutoBuyTick: autoBuyLastTick,
      autoBuyResourceCapacity: autoBuyResourceCapacity,
      autoBuildMachinesOwned: autoBuildData.machines,
      autoBuildEnabled: autoBuildData.enabled,
      lastAutoBuildTick: autoBuildData.lastTick,
      autoBuildProductCapacity: autoBuildData.capacity,
      factoryTier: factoryTier,
      fleetTier: fleetTier,
      corporateContracts: corporateContracts,
      clientReputation: clientReputation,
      researchPoints: researchPoints,
      techLevels: techLevels,
      overclockActive: overclockActive,
      maintenanceWear: maintenanceWear,
    );
  }

  /// Load materials inventory from database
  Future<Map<String, int>> _loadMaterials(Database db) async {
    final materialsResult = await db.query('materials');
    final materials = <String, int>{};
    for (final row in materialsResult) {
      materials[row['material_id'] as String] = row['quantity'] as int;
    }
    return materials;
  }

  /// Load products inventory from database
  Future<Map<String, int>> _loadProducts(Database db) async {
    final productsResult = await db.query('products');
    final products = <String, int>{};
    for (final row in productsResult) {
      products[row['product_id'] as String] = row['quantity'] as int;
    }
    return products;
  }

  /// Load active production tasks from database
  Future<List<ProductionTask>> _loadActiveProductions(Database db) async {
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
    return activeProductions;
  }

  /// Load all quantity preferences from database
  Future<
    ({Map<String, int> build, Map<String, int> buy, Map<String, int> sell})
  >
  _loadQuantityPreferences(Database db) async {
    // Load build quantity preferences
    final preferencesResult = await db.query('build_quantity_preferences');
    final buildQuantityPreferences = <String, int>{};
    for (final row in preferencesResult) {
      buildQuantityPreferences[row['product_id'] as String] =
          row['quantity'] as int;
    }

    // Load buy quantity preferences (V1.4.11)
    final buyPreferencesResult = await db.query('buy_quantity_preferences');
    final buyQuantityPreferences = <String, int>{};
    for (final row in buyPreferencesResult) {
      buyQuantityPreferences[row['material_id'] as String] =
          row['quantity'] as int;
    }

    // Load sell quantity preferences (V1.4.11)
    final sellPreferencesResult = await db.query('sell_quantity_preferences');
    final sellQuantityPreferences = <String, int>{};
    for (final row in sellPreferencesResult) {
      sellQuantityPreferences[row['product_id'] as String] =
          row['quantity'] as int;
    }

    return (
      build: buildQuantityPreferences,
      buy: buyQuantityPreferences,
      sell: sellQuantityPreferences,
    );
  }

  /// Load unlocked products set from database (V1.4.18)
  Future<Set<String>> _loadUnlockedProducts(Database db) async {
    final unlockedProductsResult = await db.query('unlocked_products');
    final unlockedProducts = <String>{};
    for (final row in unlockedProductsResult) {
      unlockedProducts.add(row['product_id'] as String);
    }
    return unlockedProducts;
  }

  /// Load auto-build data from database (v1.5.0 Phase 2)
  Future<({
    Map<String, int> machines,
    Map<String, bool> enabled,
    Map<String, DateTime?> lastTick,
    Map<String, int> capacity,
  })> _loadAutoBuildData(Database db) async {
    final machines = <String, int>{};
    final enabled = <String, bool>{};
    final lastTick = <String, DateTime?>{};
    final capacity = <String, int>{};

    // Load machine counts
    final machinesResult = await db.query('auto_build_machines');
    for (final row in machinesResult) {
      machines[row['tier'] as String] = row['machine_count'] as int;
    }

    // Load enabled status
    final enabledResult = await db.query('auto_build_enabled');
    for (final row in enabledResult) {
      enabled[row['tier'] as String] = (row['enabled'] as int) == 1;
    }

    // Load last tick times
    final lastTickResult = await db.query('auto_build_last_tick');
    for (final row in lastTickResult) {
      final tickTime = row['last_tick'] as int?;
      lastTick[row['tier'] as String] = tickTime != null
          ? DateTime.fromMillisecondsSinceEpoch(tickTime)
          : null;
    }

    // Load capacity settings
    final capacityResult = await db.query('auto_build_capacity');
    for (final row in capacityResult) {
      capacity[row['tier'] as String] = row['capacity'] as int;
    }

    return (
      machines: machines,
      enabled: enabled,
      lastTick: lastTick,
      capacity: capacity,
    );
  }

  /// Load active shipping orders from database
  Future<List<ShippingOrder>> _loadActiveShippingOrders(Database db) async {
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

    return activeShippingOrders;
  }

  /// Load shipping history from database
  Future<List<ShippingHistory>> _loadShippingHistory(Database db) async {
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

    return shippingHistory;
  }

  /// Save corporate contracts
  Future<void> _saveContracts(DatabaseExecutor txn, GameState state) async {
    await txn.delete('corporate_contracts');
    for (final contract in state.corporateContracts) {
      await txn.insert('corporate_contracts', contract.toMap());
    }
  }

  /// Save client reputation
  Future<void> _saveReputation(DatabaseExecutor txn, GameState state) async {
    await txn.delete('client_reputation');
    for (final entry in state.clientReputation.entries) {
      await txn.insert('client_reputation', {
        'client_id': entry.key,
        'reputation': entry.value,
      });
    }
  }

  /// Load corporate contracts from database
  Future<List<CorporateContract>> _loadContracts(Database db) async {
    final result = await db.query('corporate_contracts');
    return result.map((row) => CorporateContract.fromMap(row)).toList();
  }

  /// Load client reputation from database
  Future<Map<String, int>> _loadReputation(Database db) async {
    final result = await db.query('client_reputation');
    final map = <String, int>{};
    for (final row in result) {
      map[row['client_id'] as String] = (row['reputation'] as int?) ?? 0;
    }
    return map;
  }

  /// Save researched technologies (Phase 4)
  Future<void> _saveTechnologies(DatabaseExecutor txn, GameState state) async {
    await txn.delete('researched_technologies');
    for (final entry in state.techLevels.entries) {
      await txn.insert('researched_technologies', {
        'tech_id': entry.key,
        'level': entry.value,
      });
    }
  }

  /// Load researched technologies from database (Phase 4)
  Future<Map<String, int>> _loadTechnologies(Database db) async {
    final result = await db.query('researched_technologies');
    final map = <String, int>{};
    for (final row in result) {
      map[row['tech_id'] as String] = (row['level'] as int?) ?? 0;
    }
    return map;
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
      await txn.delete('corporate_contracts');
      await txn.delete('client_reputation');
      await txn.delete('researched_technologies');

      // Reset game state to defaults
      await txn.update(
        'game_state',
        {
          'money': 100.0, // Starting money
          'last_saved': DateTime.now().millisecondsSinceEpoch,
          'factory_tier': 1,
          'fleet_tier': 1,
          'research_points': 0,
          'overclock_active': 0,
          'maintenance_wear': 1.0,
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
          'factory_tier': state.factoryTier,
          'fleet_tier': state.fleetTier,
          'research_points': state.researchPoints,
          'overclock_active': state.overclockActive ? 1 : 0,
          'maintenance_wear': state.maintenanceWear,
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
        await _saveAllQuantityPreferencesOptimized(
          txn,
          state.buildQuantityPreferences,
          state.buyQuantityPreferences,
          state.sellQuantityPreferences,
        );
      }

      // Save automation data (auto-buy and auto-build machines) - v1.5.0
      if (_dirtyTables.contains('automation')) {
        await _saveAutomationDataOptimized(txn, state);
      }

      if (_dirtyTables.contains('contracts')) {
        await _saveContracts(txn, state);
      }

      if (_dirtyTables.contains('reputation')) {
        await _saveReputation(txn, state);
      }

      if (_dirtyTables.contains('technologies')) {
        await _saveTechnologies(txn, state);
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
          'factory_tier': state.factoryTier,
          'fleet_tier': state.fleetTier,
          'research_points': state.researchPoints,
          'overclock_active': state.overclockActive ? 1 : 0,
          'maintenance_wear': state.maintenanceWear,
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
      await _saveAllQuantityPreferencesOptimized(
        txn,
        state.buildQuantityPreferences,
        state.buyQuantityPreferences,
        state.sellQuantityPreferences,
      );
      await _saveAutomationDataOptimized(txn, state); // v1.5.0 - Save automation data
      await _saveContracts(txn, state);
      await _saveReputation(txn, state);
      await _saveTechnologies(txn, state);
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

  /// Optimized quantity preferences save (V1.4.11)
  Future<void> _saveAllQuantityPreferencesOptimized(
    Transaction txn,
    Map<String, int> buildQuantityPreferences,
    Map<String, int> buyQuantityPreferences,
    Map<String, int> sellQuantityPreferences,
  ) async {
    // Save build quantity preferences
    await txn.delete('build_quantity_preferences');
    for (final entry in buildQuantityPreferences.entries) {
      await txn.insert('build_quantity_preferences', {
        'product_id': entry.key,
        'quantity': entry.value,
      });
    }

    // Save buy quantity preferences
    await txn.delete('buy_quantity_preferences');
    for (final entry in buyQuantityPreferences.entries) {
      await txn.insert('buy_quantity_preferences', {
        'material_id': entry.key,
        'quantity': entry.value,
      });
    }

    // Save sell quantity preferences
    await txn.delete('sell_quantity_preferences');
    for (final entry in sellQuantityPreferences.entries) {
      await txn.insert('sell_quantity_preferences', {
        'product_id': entry.key,
        'quantity': entry.value,
      });
    }
  }

  /// Optimized automation data save (v1.5.0) - Auto-buy and Auto-build
  Future<void> _saveAutomationDataOptimized(
    Transaction txn,
    GameState state,
  ) async {
    // Update auto-buy data in core game state
    await txn.update(
      'game_state',
      {
        'auto_buy_machines_owned': state.autoBuyMachinesOwned,
        'auto_buy_enabled': state.autoBuyEnabled ? 1 : 0,
        'auto_buy_last_tick': state.lastAutoBuyTick?.millisecondsSinceEpoch,
        'auto_buy_resource_capacity': state.autoBuyResourceCapacity,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    // Save auto-build machine counts
    await txn.delete('auto_build_machines');
    for (final entry in state.autoBuildMachinesOwned.entries) {
      if (entry.value > 0) {
        await txn.insert('auto_build_machines', {
          'tier': entry.key,
          'machine_count': entry.value,
        });
      }
    }

    // Save auto-build enabled status
    await txn.delete('auto_build_enabled');
    for (final entry in state.autoBuildEnabled.entries) {
      await txn.insert('auto_build_enabled', {
        'tier': entry.key,
        'enabled': entry.value ? 1 : 0,
      });
    }

    // Save auto-build last tick times
    await txn.delete('auto_build_last_tick');
    for (final entry in state.lastAutoBuildTick.entries) {
      if (entry.value != null) {
        await txn.insert('auto_build_last_tick', {
          'tier': entry.key,
          'last_tick': entry.value!.millisecondsSinceEpoch,
        });
      }
    }

    // Save auto-build capacity settings
    await txn.delete('auto_build_capacity');
    for (final entry in state.autoBuildProductCapacity.entries) {
      await txn.insert('auto_build_capacity', {
        'tier': entry.key,
        'capacity': entry.value,
      });
    }
  }

  /// Manually verify and fix database schema (for debugging)
  /// Call this if you encounter "no such column" errors
  Future<void> verifyAndFixSchema() async {
    try {
      final db = await database;
      
      if (kDebugMode) {
        print('=== Starting manual schema verification ===');
      }
      
      // Check game_state table columns
      final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
      final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();
      
      if (kDebugMode) {
        print('Existing game_state columns: ${existingColumns.join(", ")}');
      }
      
      // Required columns for auto-buy
      final requiredColumns = {
        'auto_buy_machines_owned',
        'auto_buy_enabled',
        'auto_buy_last_tick',
        'auto_buy_resource_capacity',
      };
      
      bool needsFix = false;
      for (final column in requiredColumns) {
        if (!existingColumns.contains(column)) {
          needsFix = true;
          if (kDebugMode) {
            print('Missing column: $column');
          }
        }
      }
      
      if (needsFix) {
        if (kDebugMode) {
          print('Schema incomplete, running migration to version 6...');
        }
        await _migrateToVersion6(db);
        if (kDebugMode) {
          print('Schema fix completed');
        }
      } else {
        if (kDebugMode) {
          print('Schema is complete, no fixes needed');
        }
      }
      
      // Verify auto-build tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final existingTables = tables.map((t) => t['name'] as String).toSet();
      
      final requiredTables = [
        'auto_build_machines',
        'auto_build_enabled',
        'auto_build_last_tick',
        'auto_build_capacity',
      ];
      
      for (final table in requiredTables) {
        if (!existingTables.contains(table)) {
          if (kDebugMode) {
            print('Missing table: $table, will be created by migration');
          }
        }
      }
      
      if (kDebugMode) {
        print('=== Schema verification complete ===');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Schema verification error: $e');
      }
      rethrow;
    }
  }

  /// Force a complete database reset (WARNING: Deletes all data!)
  /// Use only for development or when database is corrupted beyond repair
  Future<void> resetDatabase() async {
    try {
      if (kDebugMode) {
        print('=== RESETTING DATABASE (ALL DATA WILL BE LOST) ===');
      }
      
      // Close current database
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Delete database file
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/$_databaseName';
      await deleteDatabase(path);
      
      if (kDebugMode) {
        print('Database deleted, will be recreated on next access');
      }
      
      // Reinitialize
      _database = await _initDatabase();
      
      if (kDebugMode) {
        print('Database reset complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Database reset error: $e');
      }
      rethrow;
    }
  }
}
