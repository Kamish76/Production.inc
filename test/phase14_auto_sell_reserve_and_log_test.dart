import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/models/game_models.dart' hide Material;
import 'package:game1/models/auto_sell_preview.dart';
import 'package:game1/models/auto_sell_log_entry.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/machine_setup_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 14: Auto-Sell Global Minimum Stock Reserve & Recent Activity Log', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_phase14_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    // =========================================================================
    // Group 1: Global Minimum Stock Reserve Logic & Stepper / Presets
    // =========================================================================
    group('1. Minimum Reserve State Management', () {
      test('Default reserve is 0 and can be set or incremented with clamping', () {
        expect(gameService.state.autoSellMinReserve, 0);

        gameService.setAutoSellMinReserve(25);
        expect(gameService.state.autoSellMinReserve, 25);

        gameService.incrementAutoSellMinReserve(5);
        expect(gameService.state.autoSellMinReserve, 30);

        gameService.incrementAutoSellMinReserve(-10);
        expect(gameService.state.autoSellMinReserve, 20);

        // Clamps to zero when decremented below 0
        gameService.incrementAutoSellMinReserve(-50);
        expect(gameService.state.autoSellMinReserve, 0);

        gameService.setAutoSellMinReserve(-15);
        expect(gameService.state.autoSellMinReserve, 0);
      });
    });

    // =========================================================================
    // Group 2: Storefront Dispatch Respects Reserve & Protects Stockpile
    // =========================================================================
    group('2. Storefront Batch Dispatch Surplus Enforcement', () {
      test('Storefront batch does NOT sell when stock is at or below reserve', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(5);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);

        // Add 10 boxes, set reserve to 10
        gameService.addProductToInventory('box', 10);
        gameService.setAutoSellMinReserve(10);

        // Diagnostic preview reports waiting stock because surplus is 0
        final nextAction = gameService.getAutoSellNextAction();
        expect(nextAction.actionType, AutoSellActionType.waitingStock);
        expect(nextAction.subtitle, contains('reserve (10)'));

        // Trigger tick
        gameService.processAutoSellTickForTest(force: true);

        // Inventory is completely protected
        expect(gameService.state.products['box'], 10);
        expect(gameService.state.activeShippingOrders, isEmpty);
        expect(gameService.state.autoSellRecentLog, isEmpty);
      });

      test('Storefront batch strictly sells only the surplus exceeding reserve', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(5);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);

        // Add 25 boxes, set reserve to 15 (surplus is 10)
        gameService.addProductToInventory('box', 25);
        gameService.setAutoSellMinReserve(15);

        final nextAction = gameService.getAutoSellNextAction();
        expect(nextAction.actionType, AutoSellActionType.batchDispatch);
        expect(nextAction.stagedItems['box'], 10);

        // Process tick
        gameService.processAutoSellTickForTest(force: true);

        // 10 units dispatched, leaving exactly 15 units intact
        expect(gameService.state.products['box'], 15);
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.items.first.productId, 'box');
        expect(gameService.state.activeShippingOrders.first.items.first.quantity, 10);

        // Log entry recorded
        expect(gameService.state.autoSellRecentLog.length, 1);
        final log = gameService.state.autoSellRecentLog.first;
        expect(log.actionType, AutoSellActionType.batchDispatch);
        expect(log.items['box'], 10);
        expect(log.totalRevenue, greaterThan(0));
      });
    });

    // =========================================================================
    // Group 3: B2B Corporate Contracts Bypass Reserve & Record to Log
    // =========================================================================
    group('3. B2B Corporate Contract Reserve Bypass', () {
      test('Corporate contract fulfills even if stock is below or equal to reserve', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellFulfillContracts(true);

        // Set reserve to 50
        gameService.setAutoSellMinReserve(50);

        // Inject contract requiring 10 boxes
        final contract = CorporateContract(
          id: 'test_b2b_contract_1',
          clientId: 'client_apex',
          title: 'Priority Packaging Order',
          description: 'Emergency supply of shipping containers',
          contractType: ContractType.retail,
          requiredProducts: {'box': 10},
          cashReward: 5000.0,
          repReward: 10,
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
          status: ContractStatus.available,
          createdAt: DateTime.now(),
        );

        gameService.testSetState(
          gameService.state.copyWith(
            corporateContracts: [contract],
          ),
        );

        // Add only 10 boxes (which is below reserve 50)
        gameService.addProductToInventory('box', 10);

        // Diagnostic shows B2B contract is ready
        final nextAction = gameService.getAutoSellNextAction();
        expect(nextAction.actionType, AutoSellActionType.b2bContract);
        expect(nextAction.subtitle, contains('Priority Packaging Order'));

        // Tick auto sell
        gameService.processAutoSellTickForTest(force: true);

        // Stock consumed to fulfill contract
        expect(gameService.state.getProductCount('box'), 0);

        // Contract status updated to shipping
        final updatedContract = gameService.state.corporateContracts.firstWhere(
          (c) => c.id == 'test_b2b_contract_1',
        );
        expect(updatedContract.status, ContractStatus.shipping);

        // Log entry recorded with B2B contract details
        expect(gameService.state.autoSellRecentLog.length, 1);
        final log = gameService.state.autoSellRecentLog.first;
        expect(log.actionType, AutoSellActionType.b2bContract);
        expect(log.items['box'], 10);
        expect(log.totalRevenue, 5000.0);
      });
    });

    // =========================================================================
    // Group 4: Recent Log FIFO / Cap at 10 Entries & Model Serialization
    // =========================================================================
    group('4. Activity Log Capping and Clearing', () {
      test('Auto-sell log caps at 10 items newest first', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(1);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setAutoSellMinReserve(0);

        // Complete 12 simulated log entries
        for (int i = 1; i <= 12; i++) {
          final entry = AutoSellLogEntry(
            id: 'log_$i',
            timestamp: DateTime.now().add(Duration(seconds: i)),
            actionType: AutoSellActionType.batchDispatch,
            title: 'Storefront Auto-Batch #$i',
            items: {'box': i},
            totalRevenue: i * 100.0,
            clientOrBatchName: 'Batch #$i',
          );
          // Prepend as service does
          gameService.testSetState(
            gameService.state.copyWith(
              autoSellRecentLog: [entry, ...gameService.state.autoSellRecentLog].take(10).toList(),
            ),
          );
        }

        expect(gameService.state.autoSellRecentLog.length, 10);
        // Newest is log_12
        expect(gameService.state.autoSellRecentLog.first.id, 'log_12');
        expect(gameService.state.autoSellRecentLog.last.id, 'log_3');

        // Clear log
        gameService.clearAutoSellLog();
        expect(gameService.state.autoSellRecentLog, isEmpty);
      });

      test('AutoSellLogEntry JSON roundtrip serialization', () {
        final now = DateTime.now();
        final entry = AutoSellLogEntry(
          id: 'test_entry_123',
          timestamp: now,
          actionType: AutoSellActionType.b2bContract,
          title: 'Contract Fulfillment',
          items: {'box': 5, 'cables': 10},
          totalRevenue: 1250.75,
          clientOrBatchName: 'Nexus Tech',
        );

        final json = entry.toJson();
        final parsed = AutoSellLogEntry.fromJson(json);

        expect(parsed.id, 'test_entry_123');
        expect(parsed.actionType, AutoSellActionType.b2bContract);
        expect(parsed.title, 'Contract Fulfillment');
        expect(parsed.items['box'], 5);
        expect(parsed.items['cables'], 10);
        expect(parsed.totalRevenue, 1250.75);
        expect(parsed.clientOrBatchName, 'Nexus Tech');
        expect(parsed.totalUnits, 15);
      });
    });

    // =========================================================================
    // Group 5: SQLite Database Migration v16 & State Persistence
    // =========================================================================
    group('5. Persistence & Migration v16 Verification', () {
      test('autoSellMinReserve and autoSellRecentLog persist across database reloads', () async {
        gameService.setAutoSellMinReserve(35);

        final logEntry = AutoSellLogEntry(
          id: 'persisted_log_1',
          timestamp: DateTime.now(),
          actionType: AutoSellActionType.batchDispatch,
          title: 'Storefront Auto-Batch',
          items: {'box': 8},
          totalRevenue: 240.0,
          clientOrBatchName: 'Batch Alpha',
        );

        gameService.testSetState(
          gameService.state.copyWith(
            autoSellRecentLog: [logEntry],
          ),
        );

        final persistence = GamePersistenceService();
        await persistence.saveGameState(gameService.state);

        // Load into fresh state
        final loadedState = await persistence.loadGameState();

        expect(loadedState.autoSellMinReserve, 35);
        expect(loadedState.autoSellRecentLog.length, 1);
        expect(loadedState.autoSellRecentLog.first.id, 'persisted_log_1');
        expect(loadedState.autoSellRecentLog.first.items['box'], 8);
        expect(loadedState.autoSellRecentLog.first.totalRevenue, 240.0);
      });

      test('Database schema includes auto_sell_min_reserve column and auto_sell_log table', () async {
        final persistence = GamePersistenceService();
        final db = await persistence.database;

        // Check columns in game_state
        final columns = await db.rawQuery('PRAGMA table_info(game_state)');
        final columnNames = columns.map((r) => r['name'] as String).toSet();
        expect(columnNames.contains('auto_sell_min_reserve'), isTrue);

        // Check auto_sell_log table
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='auto_sell_log'",
        );
        expect(tables.isNotEmpty, isTrue);
      });
    });

    // =========================================================================
    // Group 6: Widget Integration (MachineSetupView)
    // =========================================================================
    group('6. MachineSetupView Presentation & UI Controls', () {
      testWidgets('Renders Global Stock Reserve and Recent Dispatches sections cleanly', (tester) async {
        gameService.setAutoSellMachineCount(3);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellMinReserve(10);

        final logEntry = AutoSellLogEntry(
          id: 'ui_log_1',
          timestamp: DateTime.now(),
          actionType: AutoSellActionType.batchDispatch,
          title: 'Storefront Auto-Batch',
          items: {'box': 5},
          totalRevenue: 150.0,
          clientOrBatchName: 'Storefront Auto-Batch',
        );
        gameService.testSetState(
          gameService.state.copyWith(
            autoSellRecentLog: [logEntry],
          ),
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductionGameService>.value(
            value: gameService,
            child: const MaterialApp(
              home: Scaffold(
                body: MachineSetupView(isBottomSheet: false),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Minimum Reserve Section
        expect(find.text('Global Stock Reserve'), findsOneWidget);
        expect(find.text('Buffer: 10 units'), findsOneWidget);
        expect(find.text('10'), findsWidgets); // stepper display & preset chip

        // 2. Recent Dispatches Card
        expect(find.text('RECENT AUTOMATION DISPATCHES'), findsOneWidget);
        expect(find.text('1 Logged'), findsOneWidget);
        expect(find.text('STOREFRONT'), findsWidgets);
        expect(find.text('+ \$150.00'), findsOneWidget);
      });

      testWidgets('Interacting with Reserve stepper and preset chips updates gameService state', (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        gameService.setAutoSellMinReserve(0);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductionGameService>.value(
            value: gameService,
            child: const MaterialApp(
              home: Scaffold(
                body: MachineSetupView(isBottomSheet: false),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Disabled (0)'), findsOneWidget);

        // Tap '+' button
        final addButton = find.byTooltip('Increase Reserve');
        expect(addButton, findsOneWidget);
        await tester.tap(addButton);
        await tester.pumpAndSettle();

        expect(gameService.state.autoSellMinReserve, 1);
        expect(find.text('Buffer: 1 units'), findsOneWidget);

        // Tap preset chip '25'
        final chip25 = find.text('25');
        expect(chip25, findsOneWidget);
        await tester.tap(chip25);
        await tester.pumpAndSettle();

        expect(gameService.state.autoSellMinReserve, 25);
        expect(find.text('Buffer: 25 units'), findsOneWidget);

        // Tap preset chip '0 (Off)'
        final chip0 = find.text('0 (Off)');
        expect(chip0, findsOneWidget);
        await tester.tap(chip0);
        await tester.pumpAndSettle();

        expect(gameService.state.autoSellMinReserve, 0);
        expect(find.text('Disabled (0)'), findsOneWidget);
      });
    });
  });
}
