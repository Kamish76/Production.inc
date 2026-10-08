import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 9B Adversarial Challenge & Stress Suite', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName =
          'test_db_adv_${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(10000)}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    // =========================================================================
    // Challenge 1: Zero State & Defensive Boundary Stress
    // =========================================================================
    group('1. Zero State & Defensive Boundary Stress', () {
      test('Tick does nothing when autoSellMachinesOwned is 0 and enabled is false', () {
        gameService.setAutoSellMachineCount(0);
        gameService.setAutoSellEnabled(false);
        gameService.addProductToInventory('box', 20);
        gameService.setMoney(500.0);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 20);
        expect(gameService.state.money, 500.0);
        expect(gameService.state.activeShippingOrders.length, 0);
      });

      test('Tick does nothing when autoSellMachinesOwned is 0 but enabled is true', () {
        gameService.setAutoSellMachineCount(0);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 20);
        gameService.setMoney(500.0);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 20);
        expect(gameService.state.money, 500.0);
        expect(gameService.state.activeShippingOrders.length, 0);
      });

      test('Tick does nothing when autoSellMachinesOwned is > 0 but enabled is false', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(3);
        gameService.setAutoSellEnabled(false);
        gameService.addProductToInventory('box', 20);
        gameService.setMoney(500.0);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 20);
        expect(gameService.state.money, 500.0);
      });

      test('Defensive resilience: Negative machines owned gracefully triggers no-op', () {
        gameService.setAutoSellMachineCount(-5);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 10);
        gameService.setMoney(100.0);

        expect(() => gameService.processAutoSellTickForTest(force: true), returnsNormally);

        expect(gameService.state.products['box'], 10);
        expect(gameService.state.money, 100.0);
      });

      test('Defensive resilience: Throughput level 0 or negative gracefully triggers no-op', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(0);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 10);
        gameService.setMoney(100.0);

        expect(() => gameService.processAutoSellTickForTest(force: true), returnsNormally);

        expect(gameService.state.products['box'], 10);
        expect(gameService.state.money, 100.0);

        gameService.setAutoSellThroughputLevel(-3);
        expect(() => gameService.processAutoSellTickForTest(force: true), returnsNormally);

        expect(gameService.state.products['box'], 10);
        expect(gameService.state.money, 100.0);
      });

      test('Completely empty inventory with active auto-sell triggers no-op without exceptions', () {
        gameService.setAutoSellMachineCount(10);
        gameService.setAutoSellThroughputLevel(5);
        gameService.setAutoSellEnabled(true);
        gameService.setMoney(250.0);

        expect(gameService.state.products.isEmpty, isTrue);

        expect(() => gameService.processAutoSellTickForTest(force: true), returnsNormally);

        expect(gameService.state.products.isEmpty, isTrue);
        expect(gameService.state.money, 250.0);
      });
    });

    // =========================================================================
    // Challenge 2: Raw Materials Immunity & Strict Product Target
    // =========================================================================
    group('2. Raw Materials Immunity & Strict Product Target', () {
      test('Inventory containing ONLY raw materials remains 100% untouched across massive capacity', () {
        gameService.setAutoSellMachineCount(20);
        gameService.setAutoSellThroughputLevel(10); // Capacity = 200 items per tick!
        gameService.setAutoSellEnabled(true);
        gameService.setMoney(0.0);

        // Populate every known material with large quantities
        final materialQuantities = {
          'cardboard': 5000,
          'basic_metals': 3000,
          'advanced_metals': 1500,
          'plastic': 4000,
          'glass': 2000,
        };

        for (final entry in materialQuantities.entries) {
          gameService.addMaterialToInventory(entry.key, entry.value);
        }

        expect(gameService.state.products.isEmpty, isTrue);

        // Execute multiple consecutive ticks
        for (int i = 0; i < 5; i++) {
          gameService.processAutoSellTickForTest(force: true);
        }

        // Assert 100% material immunity
        for (final entry in materialQuantities.entries) {
          expect(
            gameService.state.materials[entry.key],
            entry.value,
            reason: 'Material ${entry.key} was modified by auto-sell tick!',
          );
        }

        // Money must remain exactly 0.0 (no unauthorized material liquidation)
        expect(gameService.state.money, 0.0);
      });

      test('Mixed inventory: Finished goods sell while raw materials remain 100% intact', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(2); // Capacity = 4 items
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setMoney(10.0);

        gameService.addMaterialToInventory('cardboard', 100);
        gameService.addMaterialToInventory('plastic', 100);
        gameService.addProductToInventory('box', 10);

        gameService.processAutoSellTickForTest(force: true);

        // 4 boxes sold out of 10 -> 6 remaining
        expect(gameService.state.products['box'], 6);

        // Raw materials must stay 100% untouched
        expect(gameService.state.materials['cardboard'], 100);
        expect(gameService.state.materials['plastic'], 100);

        // Dispatched shipping order taking 1 fleet slot with $16.0 revenue
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.totalRevenue, 16.0);
      });

      test('Resilience: Unknown product ID gracefully falls back to default price without error', () {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('custom_gadget_99', true);
        gameService.setMoney(0.0);

        // Add unknown custom product directly into products map
        gameService.addProductToInventory('custom_gadget_99', 5);

        expect(() => gameService.processAutoSellTickForTest(force: true), returnsNormally);

        // Should have sold 2 units using fallback price ($4.0) into a shipping order
        expect(gameService.state.products['custom_gadget_99'], 3);
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.totalRevenue, 8.0); // 2 * 4.0
      });
    });

    // =========================================================================
    // Challenge 3: Multi-Tier Exhaustion & Priority Stress
    // =========================================================================
    group('3. Multi-Tier Exhaustion & Priority Stress', () {
      test('Strict ascending tier order: basicParts -> intermediate -> complex -> retail', () {
        // Find products for all 4 tiers from GameData
        final basicProd = GameData.products.firstWhere(
          (p) => p.levelId == ProductLevel.basicParts,
        );
        final interProd = GameData.products.firstWhere(
          (p) => p.levelId == ProductLevel.intermediate,
        );
        final complexProd = GameData.products.firstWhere(
          (p) => p.levelId == ProductLevel.complex,
        );
        final retailProd = GameData.products.firstWhere(
          (p) => p.levelId == ProductLevel.retail,
        );

        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(3); // Capacity = 3 units per tick
        gameService.setAutoSellEnabled(true);
        gameService.setMoney(0.0);
        gameService.setProductAutoSellWhitelist(basicProd.id, true);
        gameService.setProductAutoSellWhitelist(interProd.id, true);
        gameService.setProductAutoSellWhitelist(complexProd.id, true);
        gameService.setProductAutoSellWhitelist(retailProd.id, true);

        void completeLatestOrder() {
          final order = gameService.state.activeShippingOrders.first;
          final completedOrder = ShippingOrder(
            id: order.id,
            items: order.items,
            startTime: DateTime.now().subtract(const Duration(minutes: 5)),
            totalShippingTime: order.totalShippingTime,
            totalRevenue: order.totalRevenue,
          );
          gameService.testSetState(
            gameService.state.copyWith(activeShippingOrders: [completedOrder]),
          );
          gameService.updateProductions();
        }

        // Load 5 units of each tier
        gameService.addProductToInventory(basicProd.id, 5);
        gameService.addProductToInventory(interProd.id, 5);
        gameService.addProductToInventory(complexProd.id, 5);
        gameService.addProductToInventory(retailProd.id, 5);

        // Step 1: Capacity 3. Should sell 3 basicParts only!
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[basicProd.id], 2);
        expect(gameService.state.products[interProd.id], 5);
        expect(gameService.state.products[complexProd.id], 5);
        expect(gameService.state.products[retailProd.id], 5);
        double expectedMoney = 3 * basicProd.sellPrice;
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));

        // Step 2: Capacity 3. Should sell remaining 2 basicParts, then 1 intermediate!
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[basicProd.id], isNull); // 0 remaining
        expect(gameService.state.products[interProd.id], 4); // 5 - 1 = 4
        expect(gameService.state.products[complexProd.id], 5);
        expect(gameService.state.products[retailProd.id], 5);
        expectedMoney += (2 * basicProd.sellPrice) + (1 * interProd.sellPrice);
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));

        // Step 3: Capacity 3. Should sell 3 intermediate (leaving 1 intermediate).
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[basicProd.id], isNull);
        expect(gameService.state.products[interProd.id], 1); // 4 - 3 = 1
        expect(gameService.state.products[complexProd.id], 5);
        expect(gameService.state.products[retailProd.id], 5);
        expectedMoney += 3 * interProd.sellPrice;
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));

        // Step 4: Capacity 3. Should sell 1 intermediate (exhausting Tier 2), then 2 complex!
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[basicProd.id], isNull);
        expect(gameService.state.products[interProd.id], isNull); // 0 remaining
        expect(gameService.state.products[complexProd.id], 3); // 5 - 2 = 3
        expect(gameService.state.products[retailProd.id], 5);
        expectedMoney += (1 * interProd.sellPrice) + (2 * complexProd.sellPrice);
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));

        // Step 5: Capacity 3. Should sell remaining 3 complex (exhausting Tier 3)!
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[basicProd.id], isNull);
        expect(gameService.state.products[interProd.id], isNull);
        expect(gameService.state.products[complexProd.id], isNull); // 0 remaining
        expect(gameService.state.products[retailProd.id], 5);
        expectedMoney += 3 * complexProd.sellPrice;
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));

        // Step 6: Capacity 3. Should sell 3 retail!
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[retailProd.id], 2); // 5 - 3 = 2
        expect(gameService.state.products[retailProd.id], 2);
        expectedMoney += 3 * retailProd.sellPrice;
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));

        // Step 7: Capacity 3. Should sell remaining 2 retail (exhausting Tier 4). Excess capacity 1 does not crash.
        gameService.processAutoSellTickForTest(force: true);
        completeLatestOrder();
        expect(gameService.state.products[retailProd.id], isNull);
        expect(gameService.state.products.isEmpty, isTrue);
        expectedMoney += 2 * retailProd.sellPrice;
        expect(gameService.state.money, closeTo(expectedMoney, 0.001));
      });
    });

    // =========================================================================
    // Challenge 4: Exact Throughput Capacity Limits
    // =========================================================================
    group('4. Exact Throughput Capacity Limits', () {
      test('Single tick never sells more than machinesOwned * throughputLevel', () {
        const testMatrix = [
          {'machines': 1, 'throughput': 1, 'expectedCap': 1},
          {'machines': 2, 'throughput': 3, 'expectedCap': 6},
          {'machines': 5, 'throughput': 7, 'expectedCap': 35},
          {'machines': 8, 'throughput': 4, 'expectedCap': 32},
          {'machines': 10, 'throughput': 10, 'expectedCap': 100},
        ];

        for (final entry in testMatrix) {
          final machines = entry['machines']!;
          final throughput = entry['throughput']!;
          final expectedCap = entry['expectedCap']!;

          gameService.testSetState(gameService.state.copyWith(
            fleetTier: 4,
            activeShippingOrders: [],
          ));
          gameService.setAutoSellMachineCount(machines);
          gameService.setAutoSellThroughputLevel(throughput);
          gameService.setAutoSellEnabled(true);
          gameService.setProductAutoSellWhitelist('box', true);
          gameService.setMoney(0.0);

          // Add more products to inventory
          gameService.addProductToInventory('box', 500);
          final beforeTick = gameService.state.products['box']!;

          gameService.processAutoSellTickForTest(force: true);

          final remaining = gameService.state.products['box'] ?? 0;
          final sold = beforeTick - remaining;

          expect(
            sold,
            expectedCap,
            reason: 'Failed capacity limit for machines=$machines, throughput=$throughput',
          );
        }
      });

      test('Inventory smaller than capacity sells exactly available amount and never overshoots', () {
        gameService.testSetState(gameService.state.copyWith(fleetTier: 4));
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(10); // Capacity = 50 units
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setMoney(0.0);

        gameService.addProductToInventory('box', 17); // 17 available

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], isNull);
        expect(gameService.state.products.isEmpty, isTrue);
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.totalRevenue, 68.0);
      });
    });

    // =========================================================================
    // Challenge 5: Fleet Slots Verification & Shipping Order Isolation
    // =========================================================================
    group('5. Fleet Slots & Shipping Order Isolation', () {
      test('Active shipping orders are preserved and fleet slots are checked', () {
        gameService.setAutoSellMachineCount(3);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 15);

        // Create an existing manual shipping order in flight
        final activeOrder = ShippingOrder(
          id: 'manual_ship_001',
          items: const [ShippingItem(productId: 'box', quantity: 5)],
          startTime: DateTime.now(),
          totalShippingTime: 120.0,
          totalRevenue: 20.0,
        );

        // Put active shipping order into state (1 out of 2 slots used)
        gameService.testSetState(
          gameService.state.copyWith(activeShippingOrders: [activeOrder]),
        );
        expect(gameService.state.activeShippingOrders.length, 1);

        // Trigger auto-sell
        gameService.processAutoSellTickForTest(force: true);

        // Auto-sell dispatched into the remaining fleet slot (2 total active orders)
        expect(gameService.state.activeShippingOrders.length, 2);
        // First manual order preserved intact
        expect(gameService.state.activeShippingOrders.first.id, 'manual_ship_001');

        // Now test when fleet is 100% saturated (2/2 slots)
        gameService.resetAutoSellTickTimer();
        gameService.processAutoSellTickForTest(force: true);

        // Fleet is full: auto-sell waits and does not add a 3rd order
        expect(gameService.state.activeShippingOrders.length, 2);
      });

      test('Auto-sell awards money upon shipping order delivery', () {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(1);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setMoney(0.0);
        gameService.addProductToInventory('box', 1);

        // Before tick
        expect(gameService.state.money, 0.0);

        // Tick dispatches order
        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.activeShippingOrders.length, 1);

        // Complete order upon arrival
        final order = gameService.state.activeShippingOrders.first;
        final completedOrder = ShippingOrder(
          id: order.id,
          items: order.items,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          totalShippingTime: order.totalShippingTime,
          totalRevenue: order.totalRevenue,
        );
        gameService.testSetState(
          gameService.state.copyWith(activeShippingOrders: [completedOrder]),
        );
        gameService.updateProductions();

        // 1 box = $4.00 delivered
        expect(gameService.state.money, 4.0);
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // Challenge 6: Economy Math, Compounding & Salvage Precision
    // =========================================================================
    group('6. Economy Math, Compounding & Salvage Precision', () {
      test('Compounding price curves: \$1000 * 1.15^N match across 20 tiers', () {
        for (int n = 0; n <= 20; n++) {
          final expectedPrice = 1000.0 * math.pow(1.15, n);
          final actualPrice = gameService.getMachinePrice('autoSell', n);
          expect(
            actualPrice,
            closeTo(expectedPrice, 0.0001),
            reason: 'Pricing formula deviation at machineCount=$n',
          );
        }
      });

      test('Throughput upgrade cost curves: \$1000 * 1.15^(level - 1) across 20 levels', () {
        for (int level = 1; level <= 20; level++) {
          gameService.setAutoSellThroughputLevel(level);
          final expectedCost = 1000.0 * math.pow(1.15, level - 1);
          final actualCost = gameService.getAutoSellThroughputUpgradeCost();
          expect(
            actualCost,
            closeTo(expectedCost, 0.0001),
            reason: 'Throughput upgrade cost deviation at level=$level',
          );
        }
      });

      test('Salvage value math: floor(0.50 * 1000 * 1.15^(N - 1))', () {
        expect(gameService.getMachineSalvageValue('autoSell', 0), 0.0);

        for (int n = 1; n <= 20; n++) {
          final priorPrice = 1000.0 * math.pow(1.15, n - 1);
          final expectedSalvage = (0.50 * priorPrice).floorToDouble();
          final actualSalvage = gameService.getMachineSalvageValue('autoSell', n);
          expect(
            actualSalvage,
            expectedSalvage,
            reason: 'Salvage value mismatch at count=$n',
          );
        }
      });

      test('Buy then salvage cycle refunds exactly 50% (floored) of purchase price', () async {
        gameService.setAutoSellMachineCount(0);
        gameService.setMoney(10000.0);

        final initialMoney = gameService.state.money;
        final buyPrice = gameService.getMachinePrice('autoSell', 0); // 1000.0

        await gameService.buyAutoSellMachine();
        expect(gameService.state.autoSellMachinesOwned, 1);
        expect(gameService.state.money, initialMoney - buyPrice);

        final salvageRefund = gameService.getMachineSalvageValue('autoSell', 1); // 500.0
        expect(salvageRefund, 500.0);

        await gameService.salvageMachine('autoSell');
        expect(gameService.state.autoSellMachinesOwned, 0);
        expect(gameService.state.money, initialMoney - 500.0); // Exactly lost 50%
      });

      test('Total machine capital value scales by \$1000 per auto-sell machine', () {
        for (int count = 0; count <= 15; count++) {
          gameService.setAutoSellMachineCount(count);
          final state = gameService.state;
          // autoBuy is 0, autoBuild is empty -> total should be count * 1000.0
          expect(state.totalMachineCapitalValue, count * 1000.0);
        }
      });

      test('Purchase rejected when player funds are insufficient', () async {
        gameService.setAutoSellMachineCount(0);
        gameService.setMoney(999.99); // 1 cent short of 1000.0

        final success = await gameService.buyAutoSellMachine();
        expect(success, isFalse);
        expect(gameService.state.autoSellMachinesOwned, 0);
        expect(gameService.state.money, 999.99);
      });

      test('Upgrade rejected when player funds are insufficient', () async {
        gameService.setAutoSellThroughputLevel(1);
        gameService.setMoney(999.99); // 1 cent short of 1000.0

        final success = await gameService.upgradeAutoSellThroughput();
        expect(success, isFalse);
        expect(gameService.getAutoSellThroughputLevel(), 1);
        expect(gameService.state.money, 999.99);
      });
    });

    // =========================================================================
    // Challenge 7: Temporal Interval Enforcement & Rapid Polling
    // =========================================================================
    group('7. Temporal Interval Enforcement & Rapid Polling', () {
      test('Cooldown enforces 5-second interval when force is false', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(1);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellFulfillContracts(false);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 20);

        // Tick 1 (initial run): executes because _lastAutoSellTick was null
        gameService.processAutoSellTickForTest(force: false);
        expect(gameService.state.products['box'], 18); // 2 units sold
        // Clear order to keep fleet slot open for next test step
        gameService.testSetState(gameService.state.copyWith(activeShippingOrders: []));

        // Immediate subsequent tick without force: should be blocked by 5s cooldown!
        gameService.processAutoSellTickForTest(force: false);
        expect(gameService.state.products['box'], 18); // Untouched!

        // Calling updateProductions() immediately: should also be blocked by cooldown
        gameService.updateProductions();
        expect(gameService.state.products['box'], 18); // Still untouched!

        // Reset timer to simulate 5 seconds passing
        gameService.resetAutoSellTickTimer();
        gameService.processAutoSellTickForTest(force: false);
        expect(gameService.state.products['box'], 16); // 2 more units sold!
      });
    });

    // =========================================================================
    // Challenge 8: SQLite Migration Idempotency & Corrupted JSON Resilience
    // =========================================================================
    group('8. Persistence Migration & Schema Resilience', () {
      test('Migration to v12 is completely idempotent when re-run', () async {
        final persistence = GamePersistenceService();
        final db = await persistence.database;

        // Verify columns exist
        final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
        final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

        expect(existingColumns.contains('auto_sell_machines_owned'), isTrue);
        expect(existingColumns.contains('auto_sell_enabled'), isTrue);
        expect(existingColumns.contains('auto_sell_throughput_level'), isTrue);

        // Save state and read back
        const testState = GameState(
          money: 12345.0,
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
          autoSellMachinesOwned: 7,
          autoSellEnabled: true,
          autoSellThroughputLevel: 9,
        );

        await persistence.saveGameState(testState);
        final loaded = await persistence.loadGameState();

        expect(loaded.autoSellMachinesOwned, 7);
        expect(loaded.autoSellEnabled, isTrue);
        expect(loaded.autoSellThroughputLevel, 9);

        await persistence.dispose();
      });

      test('Corrupted or missing JSON fields safely fallback to defaults', () {
        // Missing keys
        final emptyJson = <String, dynamic>{};
        final state1 = GameState.fromJson(emptyJson);
        expect(state1.autoSellMachinesOwned, 0);
        expect(state1.autoSellEnabled, isFalse);
        expect(state1.autoSellThroughputLevel, 1);

        // Null keys
        final nullJson = <String, dynamic>{
          'autoSellMachinesOwned': null,
          'autoSellEnabled': null,
          'autoSellThroughputLevel': null,
        };
        final state2 = GameState.fromJson(nullJson);
        expect(state2.autoSellMachinesOwned, 0);
        expect(state2.autoSellEnabled, isFalse);
        expect(state2.autoSellThroughputLevel, 1);
      });
    });

    // =========================================================================
    // Challenge 9: Fuzzing & Invariant Stress Simulation
    // =========================================================================
    group('9. Property-Based Fuzzing & Invariant Simulation', () {
      test('100-step randomized simulation preserves core economic invariants', () async {
        final rng = math.Random(42); // Seeded for reproducibility
        gameService.setMoney(50000.0);
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(1);
        gameService.setAutoSellEnabled(true);

        final rawMaterials = ['cardboard', 'basic_metals', 'plastic'];
        for (final m in rawMaterials) {
          gameService.addMaterialToInventory(m, 1000);
        }

        final productIds = ['box', 'cables', 'chips', 'speaker'];

        for (int step = 0; step < 100; step++) {
          final action = rng.nextInt(7);

          switch (action) {
            case 0: // Add products
              final p = productIds[rng.nextInt(productIds.length)];
              gameService.addProductToInventory(p, rng.nextInt(10) + 1);
              break;
            case 1: // Add materials
              final m = rawMaterials[rng.nextInt(rawMaterials.length)];
              gameService.addMaterialToInventory(m, rng.nextInt(50) + 1);
              break;
            case 2: // Buy machine if possible
              await gameService.buyAutoSellMachine();
              break;
            case 3: // Upgrade throughput if possible
              await gameService.upgradeAutoSellThroughput();
              break;
            case 4: // Salvage machine if possible
              if (gameService.state.autoSellMachinesOwned > 0 && rng.nextBool()) {
                await gameService.salvageMachine('autoSell');
              }
              break;
            case 5: // Toggle enabled
              if (rng.nextInt(5) == 0) {
                gameService.toggleAutoSell();
              }
              break;
            case 6: // Process auto-sell tick
              final materialsBefore = Map<String, int>.from(gameService.state.materials);
              final moneyBefore = gameService.state.money;
              final maxCap = gameService.state.autoSellMachinesOwned *
                  gameService.state.autoSellThroughputLevel;
              final productsBefore = gameService.state.products.values
                  .fold<int>(0, (sum, count) => sum + count);

              gameService.processAutoSellTickForTest(force: true);

              final productsAfter = gameService.state.products.values
                  .fold<int>(0, (sum, count) => sum + count);
              final totalSold = productsBefore - productsAfter;

              if (gameService.state.autoSellEnabled &&
                  gameService.state.autoSellMachinesOwned > 0) {
                expect(
                  totalSold <= maxCap,
                  isTrue,
                  reason: 'Step $step: sold $totalSold units exceeding maxCap $maxCap',
                );
              } else {
                expect(
                  totalSold,
                  0,
                  reason: 'Step $step: sold $totalSold when disabled or 0 machines',
                );
              }

              // Invariant 1: Materials must NEVER decrease from auto-sell
              for (final m in rawMaterials) {
                expect(
                  gameService.state.materials[m]! >= materialsBefore[m]!,
                  isTrue,
                  reason: 'Step $step: material $m was decremented during auto-sell tick',
                );
              }

              // Invariant 2: Money must never decrease during auto-sell tick
              expect(
                gameService.state.money >= moneyBefore,
                isTrue,
                reason: 'Step $step: money decreased during auto-sell tick',
              );

              // Invariant 3: Active shipping orders count must be 0
              expect(gameService.state.activeShippingOrders.length, 0);
              break;
          }

          // Global Invariants across all steps:
          expect(gameService.state.money >= 0, isTrue);
          expect(gameService.state.autoSellMachinesOwned >= 0, isTrue);
          expect(gameService.state.autoSellThroughputLevel >= 1, isTrue);
        }
      });
    });
  });
}
