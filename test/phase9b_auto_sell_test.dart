import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/machine_card.dart';
import 'package:game1/screens/control_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9B: Auto-Sell Dispatchers (Storefront Automation)', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName =
          'test_db_phase9b_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    // =========================================================================
    // Group 1: GameState Data Model & Serialization
    // =========================================================================
    group('1. GameState Model & Serialization', () {
      test('Default values for auto-sell are correctly initialized', () {
        const state = GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
        );

        expect(state.autoSellMachinesOwned, 0);
        expect(state.autoSellEnabled, isFalse);
        expect(state.autoSellThroughputLevel, 1);
      });

      test('copyWith preserves and updates auto-sell fields', () {
        const initialState = GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
          autoSellMachinesOwned: 2,
          autoSellEnabled: true,
          autoSellThroughputLevel: 3,
        );

        // Updating only autoSellMachinesOwned
        final state1 = initialState.copyWith(autoSellMachinesOwned: 5);
        expect(state1.autoSellMachinesOwned, 5);
        expect(state1.autoSellEnabled, isTrue);
        expect(state1.autoSellThroughputLevel, 3);

        // Updating only autoSellEnabled
        final state2 = initialState.copyWith(autoSellEnabled: false);
        expect(state2.autoSellMachinesOwned, 2);
        expect(state2.autoSellEnabled, isFalse);
        expect(state2.autoSellThroughputLevel, 3);

        // Updating only autoSellThroughputLevel
        final state3 = initialState.copyWith(autoSellThroughputLevel: 4);
        expect(state3.autoSellMachinesOwned, 2);
        expect(state3.autoSellEnabled, isTrue);
        expect(state3.autoSellThroughputLevel, 4);

        // copyWith without arguments preserves everything
        final state4 = initialState.copyWith();
        expect(state4.autoSellMachinesOwned, 2);
        expect(state4.autoSellEnabled, isTrue);
        expect(state4.autoSellThroughputLevel, 3);
      });

      test('toJson includes all three auto-sell fields', () {
        const state = GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
          autoSellMachinesOwned: 4,
          autoSellEnabled: true,
          autoSellThroughputLevel: 2,
        );

        final json = state.toJson();
        expect(json['autoSellMachinesOwned'], 4);
        expect(json['autoSellEnabled'], isTrue);
        expect(json['autoSellThroughputLevel'], 2);
      });

      test('fromJson deserializes camelCase keys accurately', () {
        final json = <String, dynamic>{
          'money': 500.0,
          'autoSellMachinesOwned': 3,
          'autoSellEnabled': true,
          'autoSellThroughputLevel': 5,
        };

        final state = GameState.fromJson(json);
        expect(state.autoSellMachinesOwned, 3);
        expect(state.autoSellEnabled, isTrue);
        expect(state.autoSellThroughputLevel, 5);
      });

      test('fromJson deserializes snake_case keys as fallback', () {
        final json = <String, dynamic>{
          'money': 750.0,
          'auto_sell_machines_owned': 6,
          'auto_sell_enabled': true,
          'auto_sell_throughput_level': 2,
        };

        final state = GameState.fromJson(json);
        expect(state.autoSellMachinesOwned, 6);
        expect(state.autoSellEnabled, isTrue);
        expect(state.autoSellThroughputLevel, 2);
      });

      test('totalMachineCapitalValue includes autoSellMachinesOwned * 1000', () {
        const state0 = GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
          autoSellMachinesOwned: 0,
        );
        expect(state0.totalMachineCapitalValue, 0.0);

        const state3 = GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
          autoSellMachinesOwned: 3,
        );
        expect(state3.totalMachineCapitalValue, 3000.0);

        // Combined with autoBuy and autoBuild machines
        final stateCombined = state3.copyWith(
          autoBuyMachinesOwned: 2,
          autoBuildMachinesOwned: {'basicParts': 1},
        );
        // 2 * 1000 + 1 * 1000 + 3 * 1000 = 6000.0
        expect(stateCombined.totalMachineCapitalValue, 6000.0);
      });
    });

    // =========================================================================
    // Group 2: SQLite Persistence & Database Migration v12
    // =========================================================================
    group('2. SQLite Persistence & Migration v12', () {
      test('GamePersistenceService saves and restores auto-sell state', () async {
        final persistence = GamePersistenceService();

        const stateToSave = GameState(
          money: 5000.0,
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
          autoSellMachinesOwned: 4,
          autoSellEnabled: true,
          autoSellThroughputLevel: 3,
        );

        await persistence.saveGameState(stateToSave);

        final loadedState = await persistence.loadGameState();
        expect(loadedState.autoSellMachinesOwned, 4);
        expect(loadedState.autoSellEnabled, isTrue);
        expect(loadedState.autoSellThroughputLevel, 3);

        await persistence.dispose();
      });

      test('SQLite database schema v12 includes auto_sell columns', () async {
        final persistence = GamePersistenceService();
        final db = await persistence.database;

        final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
        final columnNames =
            tableInfo.map((row) => row['name'] as String).toSet();

        expect(columnNames.contains('auto_sell_machines_owned'), isTrue);
        expect(columnNames.contains('auto_sell_enabled'), isTrue);
        expect(columnNames.contains('auto_sell_throughput_level'), isTrue);

        await persistence.dispose();
      });
    });

    // =========================================================================
    // Group 3: Dynamic Pricing, Scaling & Machine Economy
    // =========================================================================
    group('3. Machine Economy, Pricing & Salvage', () {
      test('Machine price uses \$1000 base compounded at 1.15x for autoSell', () {
        expect(gameService.getMachinePrice('autoSell', 0), 1000.0);

        for (int n = 0; n <= 6; n++) {
          final expected = 1000.0 * math.pow(1.15, n);
          expect(
            gameService.getMachinePrice('autoSell', n),
            closeTo(expected, 0.001),
            reason: 'Auto-sell price mismatch at count $n',
          );
        }
      });

      test('Throughput upgrade cost uses \$1000 base compounded at 1.15x', () {
        gameService.setAutoSellThroughputLevel(1);
        expect(gameService.getAutoSellThroughputUpgradeCost(), 1000.0);

        gameService.setAutoSellThroughputLevel(2);
        expect(
          gameService.getAutoSellThroughputUpgradeCost(),
          closeTo(1150.0, 0.01),
        );

        gameService.setAutoSellThroughputLevel(4);
        final expectedL4 = 1000.0 * math.pow(1.15, 3);
        expect(
          gameService.getAutoSellThroughputUpgradeCost(),
          closeTo(expectedL4, 0.01),
        );
      });

      test('buyAutoSellMachine deducts price and increments machine count', () async {
        gameService.addMoney(2000.0);
        gameService.setAutoSellMachineCount(0);

        final initialMoney = gameService.state.money;
        final price0 = gameService.getMachinePrice('autoSell', 0); // 1000.0

        final success = await gameService.buyAutoSellMachine();
        expect(success, isTrue);
        expect(gameService.state.autoSellMachinesOwned, 1);
        expect(gameService.state.money, closeTo(initialMoney - price0, 0.001));
      });

      test('buyAutoSellMachine rejects purchase if insufficient money', () async {
        gameService.setMoney(500.0); // Price is 1000.0
        gameService.setAutoSellMachineCount(0);

        final success = await gameService.buyAutoSellMachine();
        expect(success, isFalse);
        expect(gameService.state.autoSellMachinesOwned, 0);
        expect(gameService.state.money, 500.0);
      });

      test('buyAutoSellMachine rejects purchase if tier limit reached', () async {
        gameService.setMoney(100000.0);
        final limit = gameService.getMachineTierLimit('autoSell');
        gameService.setAutoSellMachineCount(limit);

        final success = await gameService.buyAutoSellMachine();
        expect(success, isFalse);
        expect(gameService.state.autoSellMachinesOwned, limit);
      });

      test('upgradeAutoSellThroughput deducts funds and increments level', () async {
        gameService.setMoney(3000.0);
        gameService.setAutoSellThroughputLevel(1);

        final cost = gameService.getAutoSellThroughputUpgradeCost(); // 1000.0
        final success = await gameService.upgradeAutoSellThroughput();

        expect(success, isTrue);
        expect(gameService.getAutoSellThroughputLevel(), 2);
        expect(gameService.state.money, closeTo(3000.0 - cost, 0.001));
      });

      test('upgradeAutoSellThroughput rejects upgrade if insufficient money', () async {
        gameService.setMoney(100.0);
        gameService.setAutoSellThroughputLevel(1);

        final success = await gameService.upgradeAutoSellThroughput();
        expect(success, isFalse);
        expect(gameService.getAutoSellThroughputLevel(), 1);
        expect(gameService.state.money, 100.0);
      });

      test('toggleAutoSell flips autoSellEnabled master state', () {
        expect(gameService.state.autoSellEnabled, isFalse);

        gameService.toggleAutoSell();
        expect(gameService.state.autoSellEnabled, isTrue);

        gameService.toggleAutoSell();
        expect(gameService.state.autoSellEnabled, isFalse);
      });

      test('salvageMachine with autoSell category decrements count and refunds 50%', () async {
        gameService.setAutoSellMachineCount(2);
        gameService.setMoney(100.0);

        // Price of 1st machine (N=0) was 1000. Price of 2nd (N=1) was 1150.
        // Salvaging machine #2 refunds 50% of the price of machine #1 (currentCount - 1 = 1) -> 50% of 1150 = 575.
        final expectedRefund =
            gameService.getMachineSalvageValue('autoSell', 2);
        expect(expectedRefund, 575.0);

        final success = await gameService.salvageMachine('autoSell');
        expect(success, isTrue);
        expect(gameService.state.autoSellMachinesOwned, 1);
        expect(gameService.state.money, closeTo(100.0 + expectedRefund, 0.01));
      });

      test('salvageMachine returns false when autoSell count is 0', () async {
        gameService.setAutoSellMachineCount(0);
        gameService.setMoney(50.0);

        final success = await gameService.salvageMachine('autoSell');
        expect(success, isFalse);
        expect(gameService.state.autoSellMachinesOwned, 0);
        expect(gameService.state.money, 50.0);
      });
    });

    // =========================================================================
    // Group 4: Auto-Sell Tick Execution & Logic
    // =========================================================================
    group('4. Auto-Sell Tick Logic & Execution', () {
      test('Tick does nothing if autoSellEnabled is false', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(false);
        gameService.addProductToInventory('box', 10);
        gameService.setMoney(100.0);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 10);
        expect(gameService.state.money, 100.0);
      });

      test('Tick does nothing if autoSellMachinesOwned is 0', () {
        gameService.setAutoSellMachineCount(0);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 10);
        gameService.setMoney(100.0);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 10);
        expect(gameService.state.money, 100.0);
      });

      test('Consumes ZERO fleet slots (no ShippingOrder created)', () {
        gameService.setAutoSellMachineCount(3);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 10);

        expect(gameService.state.activeShippingOrders.length, 0);

        gameService.processAutoSellTickForTest(force: true);

        // 3 machines * 2 throughput = 6 boxes sold directly
        expect(gameService.state.products['box'], 4);
        // Shipping orders must remain completely untouched (0 fleet slots)
        expect(gameService.state.activeShippingOrders.length, 0);
      });

      test('Only sells finished products and strictly skips raw materials', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(2); // Capacity = 10
        gameService.setAutoSellEnabled(true);

        // Add raw materials and some finished products
        gameService.addMaterialToInventory('cardboard', 50);
        gameService.addMaterialToInventory('basic_metals', 30);
        gameService.addMaterialToInventory('plastic', 25);
        gameService.addProductToInventory('box', 4);

        final initialCardboard = gameService.state.materials['cardboard'];
        final initialMetals = gameService.state.materials['basic_metals'];
        final initialPlastic = gameService.state.materials['plastic'];

        gameService.processAutoSellTickForTest(force: true);

        // 4 boxes sold
        expect(gameService.state.products['box'], isNull);

        // Raw materials must NOT be sold or decremented under any circumstances
        expect(gameService.state.materials['cardboard'], initialCardboard);
        expect(gameService.state.materials['basic_metals'], initialMetals);
        expect(gameService.state.materials['plastic'], initialPlastic);
      });

      test('Prioritizes lowest-tier products first (basicParts -> intermediate -> complex -> retail)', () {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(5); // Capacity = 5 units
        gameService.setAutoSellEnabled(true);
        gameService.setMoney(0.0);

        // Box: basicParts (Tier 1), sellPrice = 4.0
        // Display Screen: intermediate (Tier 2), sellPrice = 77.0
        // Speaker: retail (Tier 4), sellPrice = 146.0
        gameService.addProductToInventory('box', 3);
        gameService.addProductToInventory('display_screen', 4);
        gameService.addProductToInventory('speaker', 2);

        gameService.processAutoSellTickForTest(force: true);

        // Capacity of 5 units should consume:
        // 1. All 3 boxes (leaving 0 boxes)
        // 2. 2 display_screens (leaving 2 display_screens)
        // 3. 0 speakers (leaving 2 speakers untouched)
        expect(gameService.state.products['box'], isNull);
        expect(gameService.state.products['display_screen'], 2);
        expect(gameService.state.products['speaker'], 2);

        // Revenue: (3 * 4.0) + (2 * 77.0) = 12.0 + 154.0 = 166.0
        expect(gameService.state.money, 166.0);
      });

      test('Directly increases money by quantity * sellPrice without shipping delays', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(1); // Capacity = 2 units
        gameService.setAutoSellEnabled(true);
        gameService.setMoney(100.0);

        gameService.addProductToInventory('box', 5); // Box sell price is 4.0

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 3);
        // 2 * 4.0 = +8.0 cash
        expect(gameService.state.money, 108.0);
      });

      test('Handles inventory smaller than sales capacity without overselling', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(10); // Capacity = 50 units
        gameService.setAutoSellEnabled(true);
        gameService.setMoney(0.0);

        gameService.addProductToInventory('box', 7);

        gameService.processAutoSellTickForTest(force: true);

        // All 7 sold, 0 remaining
        expect(gameService.state.products['box'], isNull);
        // 7 * 4.0 = 28.0 cash
        expect(gameService.state.money, 28.0);
      });

      test('_processAutoSellTick executes during updateProductions() without exceptions', () {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 5);

        // Must run smoothly without throwing
        expect(() => gameService.updateProductions(), returnsNormally);
        expect(gameService.state.products['box'], 3);
      });
    });

    // =========================================================================
    // Group 5: Presentation & Widgets
    // =========================================================================
    group('5. Presentation & UI Widgets', () {
      testWidgets('MachineCard.autoSell renders storefront UI elements and omits capacity stepper', (tester) async {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(3);
        gameService.setAutoSellEnabled(true);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => MachineCard.autoSell(
                  context: context,
                  gameService: gameService,
                ),
              ),
            ),
          ),
        );

        // Verify Title and Subtitle
        expect(find.text('Auto-Sell Dispatchers'), findsOneWidget);
        expect(
          find.text('Automates finished goods walk-in sales (0 fleet slots)'),
          findsOneWidget,
        );

        // Verify Storefront icon
        expect(find.byIcon(Icons.storefront), findsOneWidget);

        // Verify Telemetry
        expect(
          find.text('Selling up to 6 items every 5s (walk-in)'),
          findsOneWidget,
        );

        // Verify Throughput Row
        expect(find.text('3 Units/Tick'), findsOneWidget);

        // Capacity Stepper Row must be omitted (showCapacity is false)
        expect(find.text('Capacity:'), findsNothing);
      });

      testWidgets('AutoSellMachineCard convenience wrapper mounts cleanly', (tester) async {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(1);
        gameService.setAutoSellEnabled(false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutoSellMachineCard(gameService: gameService),
            ),
          ),
        );

        expect(find.byType(AutoSellMachineCard), findsOneWidget);
        expect(find.text('Auto-Sell Dispatchers'), findsOneWidget);
        expect(find.text('Offline - Auto-sell is paused'), findsOneWidget);
      });

      testWidgets('Tapping buy button on AutoSellMachineCard invokes buyAutoSellMachine', (tester) async {
        gameService.setMoney(5000.0);
        gameService.setAutoSellMachineCount(0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutoSellMachineCard(gameService: gameService),
            ),
          ),
        );

        // Tap Buy button
        final buyButton = find.byIcon(Icons.add_shopping_cart);
        expect(buyButton, findsOneWidget);
        await tester.tap(buyButton);
        await tester.pump();

        expect(gameService.state.autoSellMachinesOwned, 1);
      });

      testWidgets('ControlScreen includes AutoSellMachineCard in Machines tab', (tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<ProductionGameService>.value(
            value: gameService,
            child: const MaterialApp(
              home: ControlScreen(),
            ),
          ),
        );
        await tester.pump();

        // ControlScreen displays AutoSellMachineCard under the Machines section
        expect(find.byType(AutoSellMachineCard), findsOneWidget);
        expect(find.text('Auto-Sell Dispatchers'), findsOneWidget);
      });
    });
  });
}
