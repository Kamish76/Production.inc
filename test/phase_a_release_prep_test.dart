import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:game1/constants/game_constants.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/screens/control_screen.dart';
import 'package:game1/screens/main_menu_screen.dart';
import 'package:game1/screens/settings_screen.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/factory_tier_card.dart';

void main() {
  group('Phase A: GameConstants Sanitization', () {
    test('DebugConstants.persistenceLogging is disabled for production', () {
      expect(DebugConstants.persistenceLogging, isFalse);
    });
  });

  group('Phase A: Redeem Codes Business Logic', () {
    late ProductionGameService gameService;
    late String testDbName;

    setUp(() {
      testDbName = 'test_db_redeem_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('888888 unlocks developer mode in session only (ephemeral)', () {
      expect(gameService.isDeveloperModeUnlocked, isFalse);

      final result = gameService.redeemCode('888888');
      expect(result.status, equals(RedeemCodeResult.devUnlocked));
      expect(result.message, contains('Developer Tools Unlocked'));
      expect(gameService.isDeveloperModeUnlocked, isTrue);

      // Re-entering 888888 returns devUnlocked and stays unlocked
      final repeatResult = gameService.redeemCode('888888');
      expect(repeatResult.status, equals(RedeemCodeResult.devUnlocked));
      expect(gameService.isDeveloperModeUnlocked, isTrue);

      // Relocking
      gameService.setDeveloperModeUnlocked(false);
      expect(gameService.isDeveloperModeUnlocked, isFalse);

      // Ephemeral nature: fresh service starts locked
      final freshService = ProductionGameService(testMode: true);
      expect(freshService.isDeveloperModeUnlocked, isFalse);
      freshService.dispose();
    });

    test('888888 supports whitespace trimming', () {
      expect(gameService.isDeveloperModeUnlocked, isFalse);
      final result = gameService.redeemCode('  888888  ');
      expect(result.status, equals(RedeemCodeResult.devUnlocked));
      expect(gameService.isDeveloperModeUnlocked, isTrue);
    });

    test('PRODUCTION2026 grants \$5,000 cash and records redemption', () {
      final initialMoney = gameService.state.money;
      expect(gameService.state.isCodeRedeemed('PRODUCTION2026'), isFalse);

      final result = gameService.redeemCode('PRODUCTION2026');
      expect(result.status, equals(RedeemCodeResult.rewardClaimed));
      expect(result.cashGranted, equals(5000.0));
      expect(result.message, contains('\$5,000'));
      expect(gameService.state.money, equals(initialMoney + 5000.0));
      expect(gameService.state.isCodeRedeemed('PRODUCTION2026'), isTrue);

      // Duplicate redemption is rejected
      final duplicateResult = gameService.redeemCode('PRODUCTION2026');
      expect(duplicateResult.status, equals(RedeemCodeResult.alreadyRedeemed));
      expect(duplicateResult.message, contains('already been redeemed'));
      expect(gameService.state.money, equals(initialMoney + 5000.0));
    });

    test('PRODUCTION2026 supports case-insensitivity and whitespace', () {
      final initialMoney = gameService.state.money;
      final result = gameService.redeemCode('  production2026  ');
      expect(result.status, equals(RedeemCodeResult.rewardClaimed));
      expect(gameService.state.money, equals(initialMoney + 5000.0));
      expect(gameService.state.isCodeRedeemed('PRODUCTION2026'), isTrue);
    });

    test('Invalid codes are rejected', () {
      final invalid1 = gameService.redeemCode('INVALID_CODE');
      expect(invalid1.status, equals(RedeemCodeResult.invalid));

      final invalid2 = gameService.redeemCode('');
      expect(invalid2.status, equals(RedeemCodeResult.invalid));

      final invalid3 = gameService.redeemCode('   ');
      expect(invalid3.status, equals(RedeemCodeResult.invalid));
    });

    test('resetGame relocks developer mode session flag', () async {
      gameService.redeemCode('888888');
      expect(gameService.isDeveloperModeUnlocked, isTrue);

      await gameService.resetGame();
      expect(gameService.isDeveloperModeUnlocked, isFalse);
    });
  });

  group('Phase A: Redeemed Codes Database Persistence', () {
    late GamePersistenceService persistenceService;
    late String testDbName;

    setUp(() async {
      testDbName = 'test_db_persist_redeem_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      persistenceService = GamePersistenceService();

      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    tearDown(() async {
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('Redeemed codes persist across save and load', () async {
      const state = GameState(
        money: 1000.0,
        redeemedCodes: {'PRODUCTION2026', 'TESTCODE'},
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );

      await persistenceService.saveGameState(state);
      final loadedState = await persistenceService.loadGameState();

      expect(loadedState.redeemedCodes, contains('PRODUCTION2026'));
      expect(loadedState.redeemedCodes, contains('TESTCODE'));
      expect(loadedState.isCodeRedeemed('PRODUCTION2026'), isTrue);
      expect(loadedState.isCodeRedeemed('OTHER_CODE'), isFalse);
    });

    test('Resetting database clears redeemed codes', () async {
      const state = GameState(
        money: 1000.0,
        redeemedCodes: {'PRODUCTION2026'},
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );

      await persistenceService.saveGameState(state);
      await persistenceService.resetDatabase();

      final loadedState = await persistenceService.loadGameState();
      expect(loadedState.redeemedCodes, isEmpty);
      expect(loadedState.isCodeRedeemed('PRODUCTION2026'), isFalse);
    });

    test('Incremental save persists both money change and redeemed codes after PRODUCTION2026', () async {
      const initialState = GameState(
        money: 1000.0,
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
      await persistenceService.saveGameState(initialState);

      // Simulate what redeemCode does when PRODUCTION2026 is redeemed
      persistenceService.markDirty('game_state');
      persistenceService.markDirty('redeemed_codes');

      final updatedState = initialState.copyWith(
        money: 6000.0,
        redeemedCodes: {'PRODUCTION2026'},
      );

      // Execute optimized incremental save with dirty tables
      await persistenceService.saveGameStateOptimized(updatedState);

      // Verify loaded state from database contains the updated money and redeemed code
      final loaded = await persistenceService.loadGameState();
      expect(loaded.money, equals(6000.0));
      expect(loaded.isCodeRedeemed('PRODUCTION2026'), isTrue);
    });

    test('Migration from schema version 13 to 14 seamlessly creates redeemed_codes and preserves user data', () async {
      final migrationDbName = 'test_db_mig_v13_v14_${DateTime.now().microsecondsSinceEpoch}.db';
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, migrationDbName].join(Platform.pathSeparator);

      // 1. Create a raw SQLite database at version 13 with player data
      final v13Db = await sqflite.openDatabase(
        fullPath,
        version: 13,
        onCreate: (db, version) async {
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
              auto_buy_intake_level INTEGER NOT NULL DEFAULT 1,
              auto_ship_retail INTEGER NOT NULL DEFAULT 0,
              auto_ship_manufacturing INTEGER NOT NULL DEFAULT 0,
              auto_sell_machines_owned INTEGER NOT NULL DEFAULT 0,
              auto_sell_enabled INTEGER NOT NULL DEFAULT 0,
              auto_sell_throughput_level INTEGER NOT NULL DEFAULT 1,
              factory_tier INTEGER NOT NULL DEFAULT 1,
              fleet_tier INTEGER NOT NULL DEFAULT 1,
              research_points INTEGER NOT NULL DEFAULT 0,
              overclock_active INTEGER NOT NULL DEFAULT 0,
              maintenance_wear REAL NOT NULL DEFAULT 1.0,
              prestige_count INTEGER NOT NULL DEFAULT 0,
              golden_shares INTEGER NOT NULL DEFAULT 0,
              lifetime_golden_shares INTEGER NOT NULL DEFAULT 0,
              lifetime_revenue REAL NOT NULL DEFAULT 0.0,
              lifetime_units_shipped INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE materials (
              material_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE products (
              product_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL
            )
          ''');
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
          await db.execute('''
            CREATE TABLE active_shipping_orders (
              id TEXT PRIMARY KEY,
              start_time INTEGER NOT NULL,
              total_shipping_time REAL NOT NULL,
              total_revenue REAL NOT NULL,
              contract_id TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE shipping_order_items (
              order_id TEXT NOT NULL,
              product_id TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              FOREIGN KEY (order_id) REFERENCES active_shipping_orders (id)
            )
          ''');
          await db.execute('''
            CREATE TABLE shipping_history (
              id TEXT PRIMARY KEY,
              completed_time INTEGER NOT NULL,
              total_revenue REAL NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE shipping_history_items (
              history_id TEXT NOT NULL,
              product_id TEXT NOT NULL,
              quantity INTEGER NOT NULL,
              FOREIGN KEY (history_id) REFERENCES shipping_history (id)
            )
          ''');
          await db.execute('''
            CREATE TABLE build_quantity_preferences (
              product_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE buy_quantity_preferences (
              material_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE sell_quantity_preferences (
              product_id TEXT PRIMARY KEY,
              quantity INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE unlocked_products (
              product_id TEXT PRIMARY KEY,
              unlocked_time INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE auto_build_machines (
              tier TEXT PRIMARY KEY,
              machine_count INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE auto_build_enabled (
              tier TEXT PRIMARY KEY,
              enabled INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE auto_build_last_tick (
              tier TEXT PRIMARY KEY,
              last_tick INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE auto_build_capacity (
              tier TEXT PRIMARY KEY,
              capacity INTEGER NOT NULL DEFAULT 10
            )
          ''');
          await db.execute('''
            CREATE TABLE auto_build_throughput (
              tier TEXT PRIMARY KEY,
              level INTEGER NOT NULL DEFAULT 1
            )
          ''');
          await db.execute('''
            CREATE TABLE corporate_contracts (
              id TEXT PRIMARY KEY,
              client_id TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              contract_type TEXT NOT NULL DEFAULT 'retail',
              target_product_id TEXT,
              required_quantity INTEGER,
              delivered_quantity INTEGER DEFAULT 0,
              required_products TEXT,
              cash_reward REAL NOT NULL,
              rep_reward INTEGER NOT NULL,
              expires_at INTEGER NOT NULL,
              status TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              shipping_order_id TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE client_reputation (
              client_id TEXT PRIMARY KEY,
              reputation INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE researched_technologies (
              tech_id TEXT PRIMARY KEY,
              level INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE prestige_perks (
              perk_id TEXT PRIMARY KEY,
              unlocked_at INTEGER NOT NULL
            )
          ''');

          // Seed v13 data
          await db.insert('game_state', {
            'id': 1,
            'money': 8888.0,
            'last_saved': DateTime.now().millisecondsSinceEpoch,
            'factory_tier': 3,
            'fleet_tier': 2,
            'auto_buy_intake_level': 2,
          });
          await db.insert('materials', {'material_id': 'metal', 'quantity': 42});
        },
      );
      await v13Db.close();

      // 2. Open via GamePersistenceService, triggering onUpgrade to v14
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: migrationDbName);
      final migrationPersistenceService = GamePersistenceService();
      final loadedState = await migrationPersistenceService.loadGameState();

      // 3. Verify user data preserved 100%
      expect(loadedState.money, equals(8888.0));
      expect(loadedState.factoryTier, equals(3));
      expect(loadedState.fleetTier, equals(2));
      expect(loadedState.materials['metal'], equals(42));
      expect(loadedState.redeemedCodes, isEmpty);

      // 4. Verify redeemed_codes table works properly
      final updatedState = loadedState.copyWith(
        redeemedCodes: {'PRODUCTION2026'},
      );
      await migrationPersistenceService.saveGameState(updatedState);
      final reloaded = await migrationPersistenceService.loadGameState();
      expect(reloaded.isCodeRedeemed('PRODUCTION2026'), isTrue);

      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });
  });

  group('Phase A: SettingsScreen Lazy Loading and Dev Controls Transfer', () {
    late ProductionGameService gameService;
    late String testDbName;

    setUp(() {
      testDbName = 'test_db_settings_screen_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    testWidgets('SettingsScreen uses ListView.builder and hides dev controls when locked',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check for ListView with virtualized configuration
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final listView = tester.widget<ListView>(listViewFinder);
      final builderDelegate = listView.childrenDelegate as SliverChildBuilderDelegate;
      expect(builderDelegate.addAutomaticKeepAlives, isFalse);
      expect(builderDelegate.addRepaintBoundaries, isTrue);

      // Dev tools section is not rendered when locked
      expect(find.byKey(const ValueKey('developer_tools_section')), findsNothing);
      expect(find.text('Developer Controls'), findsNothing);

      // Redeem code section is visible
      expect(find.byKey(const ValueKey('redeem_code_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('redeem_code_button')), findsOneWidget);

      // Offscreen sections (Battery Optimization card at index 5) are not built initially
      expect(find.text('Auto-save: Every 30 seconds and when app goes to background'), findsNothing);

      // Jumping to maxScrollExtent builds the offscreen card and recycles top cards
      final scrollableState = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollableState.position.jumpTo(scrollableState.position.maxScrollExtent);
      await tester.pump();

      expect(find.text('Auto-save: Every 30 seconds and when app goes to background'), findsOneWidget);
      expect(find.text('Game Data'), findsNothing);
    });

    testWidgets('Entering 888888 in SettingsScreen unlocks developer tools and relock locks it',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially locked
      expect(find.byKey(const ValueKey('developer_tools_section')), findsNothing);

      // Enter 888888 and tap Redeem
      await tester.enterText(find.byKey(const ValueKey('redeem_code_field')), '888888');
      await tester.tap(find.byKey(const ValueKey('redeem_code_button')));
      await tester.pumpAndSettle();

      // SnackBar shows unlock message
      expect(find.text('🛠️ Developer Tools Unlocked! (Session Only)'), findsOneWidget);
      expect(gameService.isDeveloperModeUnlocked, isTrue);

      // Dev tools section is now mounted
      expect(find.byKey(const ValueKey('developer_tools_section')), findsOneWidget);
      expect(find.text('Developer Controls'), findsOneWidget);
      expect(find.byKey(const ValueKey('relock_dev_tools_button')), findsOneWidget);

      // Tap Relock button
      await tester.tap(find.byKey(const ValueKey('relock_dev_tools_button')));
      await tester.pumpAndSettle();

      expect(gameService.isDeveloperModeUnlocked, isFalse);
      expect(find.byKey(const ValueKey('developer_tools_section')), findsNothing);
    });

    testWidgets('Redeeming PRODUCTION2026 in SettingsScreen adds \$5,000 and displays feedback',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final initialMoney = gameService.state.money;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Redeem PRODUCTION2026
      await tester.enterText(find.byKey(const ValueKey('redeem_code_field')), 'PRODUCTION2026');
      await tester.tap(find.byKey(const ValueKey('redeem_code_button')));
      await tester.pumpAndSettle();

      expect(gameService.state.money, equals(initialMoney + 5000.0));
      expect(find.text('🎉 Redeemed PRODUCTION2026! +\$5,000 Cash added!'), findsOneWidget);

      // Wait for first SnackBar to finish
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Duplicate redemption attempt
      await tester.enterText(find.byKey(const ValueKey('redeem_code_field')), 'PRODUCTION2026');
      await tester.tap(find.byKey(const ValueKey('redeem_code_button')));
      await tester.pumpAndSettle();

      expect(find.text('⚠️ Code has already been redeemed!'), findsOneWidget);
      expect(gameService.state.money, equals(initialMoney + 5000.0));
    });

    testWidgets('SettingsScreen provides user feedback on empty or whitespace code submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap redeem button with empty field
      await tester.tap(find.byKey(const ValueKey('redeem_code_button')));
      await tester.pumpAndSettle();

      expect(find.text('❌ Please enter a redeem code.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap redeem button with whitespace only
      await tester.enterText(find.byKey(const ValueKey('redeem_code_field')), '   ');
      await tester.tap(find.byKey(const ValueKey('redeem_code_button')));
      await tester.pumpAndSettle();

      expect(find.text('❌ Please enter a redeem code.'), findsOneWidget);
    });

    testWidgets('SettingsScreen trims and uppercase handles code input',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('redeem_code_field')), '  production2026  ');
      await tester.tap(find.byKey(const ValueKey('redeem_code_button')));
      await tester.pumpAndSettle();

      expect(find.text('🎉 Redeemed PRODUCTION2026! +\$5,000 Cash added!'), findsOneWidget);
      expect(gameService.state.isCodeRedeemed('PRODUCTION2026'), isTrue);
    });

    testWidgets('SettingsScreen displays all 15 developer controls when unlocked',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      gameService.setDeveloperModeUnlocked(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 15 dev controls
      expect(find.textContaining('Cycle Factory Tier'), findsOneWidget);
      expect(find.textContaining('Cycle Fleet Tier'), findsOneWidget);
      expect(find.textContaining('Boost Corporate Reputation'), findsOneWidget);
      expect(find.textContaining('Refresh Corporate Contracts'), findsOneWidget);
      expect(find.textContaining('Add Research Points'), findsOneWidget);
      expect(find.textContaining('Reset Maintenance Wear'), findsOneWidget);
      expect(find.textContaining('Simulate Critical Wear'), findsOneWidget);
      expect(find.textContaining('Add Golden Shares'), findsOneWidget);
      expect(find.textContaining('Add \$1,000,000 Cash'), findsOneWidget);
      expect(find.text('Add Money'), findsOneWidget);
      expect(find.text('Add Big Money'), findsOneWidget);
      expect(find.text('Complete Productions'), findsOneWidget);
      expect(find.text('Complete Shipments'), findsOneWidget);
      expect(find.text('Unlock All Products'), findsOneWidget);
      expect(find.text('Force Unlock Check'), findsOneWidget);
    });
  });

  group('Phase A: ControlScreen Clean Tiers Tab', () {
    late ProductionGameService gameService;
    late String testDbName;

    setUp(() {
      testDbName = 'test_db_control_screen_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    testWidgets('ControlScreen Tiers tab does not display developer controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const Scaffold(body: ControlScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Tiers tab (index 1)
      final tiersTabFinder = find.text('Tiers');
      expect(tiersTabFinder, findsOneWidget);
      await tester.tap(tiersTabFinder);
      await tester.pumpAndSettle();

      // Dev controls should NOT be anywhere in ControlScreen, but FactoryTierCard is rendered
      expect(find.byType(FactoryTierCard), findsOneWidget);
      expect(find.text('Developer Controls'), findsNothing);
      expect(find.text('Quick Testing Tools'), findsNothing);
      expect(find.text('Unlock Next Tier'), findsNothing);
      expect(find.text('Complete Current Tier Goal'), findsNothing);
    });
  });

  group('Phase A: Discord Community Intent', () {
    testWidgets('MainMenuScreen displays Join Discord Community button with correct color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final discordButtonFinder = find.widgetWithText(ElevatedButton, 'Join Discord Community');
      expect(discordButtonFinder, findsOneWidget);

      final elevatedButton = tester.widget<ElevatedButton>(discordButtonFinder);
      expect(elevatedButton.style?.backgroundColor?.resolve({}), equals(const Color(0xFF5865F2)));
    });

    testWidgets('Tapping Join Discord Community invokes launch logic',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // On non-Android test platform, tapping shows SnackBar with Discord invite url
      final discordButtonFinder = find.widgetWithText(ElevatedButton, 'Join Discord Community');
      await tester.tap(discordButtonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Join Discord Community: https://discord.gg/7yH3jgMnhf'), findsOneWidget);
    });

    testWidgets('launchDiscordIntent handles exception gracefully with fallback messaging',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => MainMenuScreen.launchDiscordIntent(
                  context: context,
                  customLauncher: (_) async => throw Exception('ActivityNotFound: No browser'),
                ),
                child: const Text('Launch Discord Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Launch Discord Test'));
      await tester.pumpAndSettle();

      expect(find.text('Could not open Discord. Community link: https://discord.gg/7yH3jgMnhf'), findsOneWidget);
    });
  });

  group('Phase A: Adversarial Edge Cases & Robustness', () {
    test('GameState toJson and fromJson round-trips redeemedCodes properly', () {
      const state = GameState(
        money: 5000.0,
        redeemedCodes: {'PRODUCTION2026', 'TEST1234'},
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );

      final json = state.toJson();
      expect(json['redeemedCodes'], contains('PRODUCTION2026'));
      expect(json['redeemedCodes'], contains('TEST1234'));

      final restored = GameState.fromJson(json);
      expect(restored.redeemedCodes, contains('PRODUCTION2026'));
      expect(restored.redeemedCodes, contains('TEST1234'));
      expect(restored.isCodeRedeemed('PRODUCTION2026'), isTrue);
    });

    test('Redeemed codes are preserved across IPO / Prestige resets', () async {
      final testDbName = 'test_db_ipo_redeem_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final gameService = ProductionGameService(testMode: true);

      // Redeem PRODUCTION2026
      gameService.redeemCode('PRODUCTION2026');
      expect(gameService.state.isCodeRedeemed('PRODUCTION2026'), isTrue);

      // Set state to qualify for IPO ($1,000,000 net worth threshold)
      gameService.addMoney(1000000.0);
      expect(gameService.state.canInitiateIPO, isTrue);

      // Execute IPO
      final ipoSuccess = await gameService.initiateIPO();
      expect(ipoSuccess, isTrue);

      // Verify redeemed codes are still intact after IPO reset
      expect(gameService.state.isCodeRedeemed('PRODUCTION2026'), isTrue);
      expect(gameService.state.redeemedCodes, contains('PRODUCTION2026'));

      // Attempting to re-claim PRODUCTION2026 after IPO is rejected
      final duplicateResult = gameService.redeemCode('PRODUCTION2026');
      expect(duplicateResult.status, equals(RedeemCodeResult.alreadyRedeemed));

      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('PRODUCTION2026 redemption clamps money at LimitsConstants.maxMoney without overflow', () {
      final testDbName = 'test_db_overflow_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final gameService = ProductionGameService(testMode: true);

      // Set money to maxMoney - 1000
      gameService.setMoney(LimitsConstants.maxMoney - 1000.0);
      expect(gameService.state.money, equals(LimitsConstants.maxMoney - 1000.0));

      final result = gameService.redeemCode('PRODUCTION2026');
      expect(result.status, equals(RedeemCodeResult.rewardClaimed));
      expect(gameService.state.money, equals(LimitsConstants.maxMoney));

      gameService.dispose();
    });

    test('verifyAndFixDatabaseSchema creates missing redeemed_codes table', () async {
      final testDbName = 'test_db_repair_schema_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final persistenceService = GamePersistenceService();

      final db = await persistenceService.database;

      // Drop redeemed_codes table to simulate missing schema
      await db.execute('DROP TABLE IF EXISTS redeemed_codes');

      // Verify table is missing
      final tablesBefore = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='redeemed_codes'");
      expect(tablesBefore, isEmpty);

      // Run verifyAndFixSchema
      await persistenceService.verifyAndFixSchema();

      // Verify table was recreated
      final tablesAfter = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='redeemed_codes'");
      expect(tablesAfter, isNotEmpty);

      await persistenceService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('completeAllShipmentsInstantly preserves contractId and completes corporate contract', () async {
      final testDbName = 'test_db_complete_shipments_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final gameService = ProductionGameService(testMode: true);

      // Create an active contract
      final contract = CorporateContract(
        id: 'contract_test_complete_shipment',
        clientId: 'apex_robotics',
        title: 'High Tech Batch',
        description: 'Supply advanced robotics widgets',
        contractType: ContractType.retail,
        requiredProducts: const {'box': 2},
        cashReward: 2500.0,
        repReward: 25,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        status: ContractStatus.shipping,
        createdAt: DateTime.now(),
      );
      gameService.addContractForTest(contract);

      // Add active shipping order linked to this contract
      final order = ShippingOrder(
        id: 'shipping_order_test_1',
        items: const [ShippingItem(productId: 'box', quantity: 2)],
        startTime: DateTime.now(),
        totalShippingTime: 60.0,
        totalRevenue: 2500.0,
        contractId: contract.id,
      );
      final orders = List<ShippingOrder>.from(gameService.state.activeShippingOrders)..add(order);
      gameService.testSetState(gameService.state.copyWith(activeShippingOrders: orders));

      expect(gameService.state.activeShippingOrders.length, equals(1));
      expect(gameService.state.activeShippingOrders.first.contractId, equals(contract.id));

      // Trigger completeAllShipmentsInstantly
      gameService.completeAllShipmentsInstantly();

      // Verify shipping completed
      expect(gameService.state.activeShippingOrders, isEmpty);

      // Verify contract was fulfilled and client reputation was credited
      final completedContract = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
      expect(completedContract.status, equals(ContractStatus.completed));
      expect(gameService.state.clientReputation['apex_robotics'], greaterThanOrEqualTo(25));

      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('Maintenance wear semantics: Reset wear sets health to 1.0 (0% wear), critical wear sets health to 0.0', () {
      final gameService = ProductionGameService(testMode: true);

      // Initially 1.0 (100% health / 0% wear)
      expect(gameService.state.maintenanceWear, equals(1.0));

      // Set to critical wear (0.0)
      gameService.devSetMaintenanceWear(0.0);
      expect(gameService.state.maintenanceWear, equals(0.0));

      // Cannot engage overclock at critical wear
      final overclockEngaged = gameService.toggleOverclock(true);
      expect(overclockEngaged, isFalse);

      // Reset to 0% wear (1.0 health)
      gameService.devSetMaintenanceWear(1.0);
      expect(gameService.state.maintenanceWear, equals(1.0));

      gameService.dispose();
    });

    test('addMoney and unlockAllProductsForTesting clamp at LimitsConstants.maxMoney', () {
      final gameService = ProductionGameService(testMode: true);

      // 1. addMoney near limit
      gameService.setMoney(LimitsConstants.maxMoney - 500.0);
      gameService.addMoney(1000.0);
      expect(gameService.state.money, equals(LimitsConstants.maxMoney));

      // 2. unlockAllProductsForTesting near limit
      gameService.setMoney(LimitsConstants.maxMoney - 500.0);
      gameService.unlockAllProductsForTesting();
      expect(gameService.state.money, equals(LimitsConstants.maxMoney));

      gameService.dispose();
    });

    test('resetDatabase relocks ephemeral developer mode session flag', () async {
      final testDbName = 'test_db_reset_db_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final gameService = ProductionGameService(testMode: true);

      gameService.redeemCode('888888');
      expect(gameService.isDeveloperModeUnlocked, isTrue);

      await gameService.resetDatabase();
      expect(gameService.isDeveloperModeUnlocked, isFalse);

      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('_loadRedeemedCodes and GameState.fromJson normalize lowercase codes to uppercase', () async {
      // 1. fromJson normalization
      final json = {
        'money': 100.0,
        'redeemedCodes': ['production2026', '  launch2026  '],
      };
      final stateFromJson = GameState.fromJson(json);
      expect(stateFromJson.redeemedCodes, contains('PRODUCTION2026'));
      expect(stateFromJson.redeemedCodes, contains('LAUNCH2026'));
      expect(stateFromJson.isCodeRedeemed('production2026'), isTrue);

      // 2. Database load normalization
      final testDbName = 'test_db_normalize_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final persistenceService = GamePersistenceService();
      final db = await persistenceService.database;
      await db.insert('redeemed_codes', {'code': 'production2026', 'redeemed_at': 12345});
      await db.insert('redeemed_codes', {'code': '  giftcode  ', 'redeemed_at': 12345});

      final loadedState = await persistenceService.loadGameState();
      expect(loadedState.redeemedCodes, contains('PRODUCTION2026'));
      expect(loadedState.redeemedCodes, contains('GIFTCODE'));

      await persistenceService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    testWidgets('Tapping all 15 developer controls in SettingsScreen executes correctly without throwing exceptions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testDbName = 'test_db_dev_taps_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      final gameService = ProductionGameService(testMode: true);
      addTearDown(() async {
        await gameService.dispose();
        final dbPath = await sqflite.getDatabasesPath();
        final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
        await sqflite.databaseFactory.deleteDatabase(fullPath);
      });
      gameService.setDeveloperModeUnlocked(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Cycle Factory Tier
      expect(gameService.state.factoryTier, equals(1));
      await tester.tap(find.textContaining('Cycle Factory Tier'));
      await tester.pumpAndSettle();
      expect(gameService.state.factoryTier, equals(2));

      // 2. Cycle Fleet Tier
      expect(gameService.state.fleetTier, equals(1));
      await tester.tap(find.textContaining('Cycle Fleet Tier'));
      await tester.pumpAndSettle();
      expect(gameService.state.fleetTier, equals(2));

      // 3. Boost Corporate Reputation
      await tester.tap(find.textContaining('Boost Corporate Reputation'));
      await tester.pumpAndSettle();
      expect(gameService.state.clientReputation.values.first, greaterThanOrEqualTo(100));

      // 4. Refresh Corporate Contracts
      await tester.tap(find.textContaining('Refresh Corporate Contracts'));
      await tester.pumpAndSettle();
      expect(gameService.state.corporateContracts, isNotEmpty);

      // 5. Add Research Points
      final initialRP = gameService.state.researchPoints;
      await tester.tap(find.textContaining('Add Research Points'));
      await tester.pumpAndSettle();
      expect(gameService.state.researchPoints, equals(initialRP + 250));

      // 6. Simulate Critical Wear (health 0.0)
      await tester.tap(find.textContaining('Simulate Critical Wear'));
      await tester.pumpAndSettle();
      expect(gameService.state.maintenanceWear, equals(0.0));

      // 7. Reset Maintenance Wear (health 1.0)
      await tester.tap(find.textContaining('Reset Maintenance Wear'));
      await tester.pumpAndSettle();
      expect(gameService.state.maintenanceWear, equals(1.0));

      // 8. Add Golden Shares
      final initialShares = gameService.state.goldenShares;
      await tester.tap(find.textContaining('Add Golden Shares'));
      await tester.pumpAndSettle();
      expect(gameService.state.goldenShares, equals(initialShares + 10));

      // 9. Add $1,000,000 Cash
      final moneyBeforeBig = gameService.state.money;
      await tester.tap(find.textContaining('Add \$1,000,000 Cash'));
      await tester.pumpAndSettle();
      expect(gameService.state.money, equals(moneyBeforeBig + 1000000.0));

      // 10. Add Money ($1,000)
      final moneyBefore1k = gameService.state.money;
      await tester.tap(find.text('Add Money'));
      await tester.pumpAndSettle();
      expect(gameService.state.money, equals(moneyBefore1k + 1000.0));

      // 11. Add Big Money ($10,000)
      final moneyBefore10k = gameService.state.money;
      await tester.tap(find.text('Add Big Money'));
      await tester.pumpAndSettle();
      expect(gameService.state.money, equals(moneyBefore10k + 10000.0));

      // 12. Complete Productions
      ScaffoldMessenger.of(tester.element(find.byType(SettingsScreen))).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Productions'));
      await tester.pumpAndSettle();
      expect(find.text('No active productions to complete'), findsOneWidget);

      // 13. Complete Shipments
      ScaffoldMessenger.of(tester.element(find.byType(SettingsScreen))).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Shipments'));
      await tester.pumpAndSettle();
      expect(find.text('No active shipments to complete'), findsOneWidget);

      // 14. Unlock All Products
      ScaffoldMessenger.of(tester.element(find.byType(SettingsScreen))).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock All Products'));
      await tester.pumpAndSettle();
      expect(find.text('🔓 All products unlocked (Dev)'), findsOneWidget);

      // 15. Force Unlock Check
      ScaffoldMessenger.of(tester.element(find.byType(SettingsScreen))).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Force Unlock Check'));
      await tester.pumpAndSettle();
      expect(find.text('🔄 Unlock check completed'), findsOneWidget);
    });
  });
}
