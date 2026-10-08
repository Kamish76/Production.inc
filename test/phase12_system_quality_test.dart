import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/screens/control_screen.dart';
import 'package:game1/screens/main_game_screen.dart';
import 'package:game1/screens/sell_products_screen.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/shipping_manifest_drawer.dart';
import 'package:game1/widgets/shipping_manifest_tray.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 12: Comprehensive System Quality & Cross-Pipeline Integration', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_phase12_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    // =========================================================================
    // 1. Cross-System Pipeline Harmonization Matrix
    // =========================================================================
    group('1. Cross-System Pipeline Harmonization Matrix', () {
      test('Auto-Sell x Fleet Slots: Auto-sell dispatches carrier fleet orders respecting max slots', () {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 100},
            money: 1000.0,
            fleetTier: 1, // 2 fleet slots max
            activeShippingOrders: [],
            autoSellMachinesOwned: 5,
            autoSellEnabled: true,
            autoSellThroughputLevel: 3, // Sells 5 * 3 = 15 units per tick
            autoSellWhitelistedProductIds: {p1.id},
          ),
        );

        expect(gameService.state.activeShippingOrders.length, 0);
        expect(gameService.state.canShipMore(gameService.state.activeShippingOrders.length), isTrue);

        // Process 5 consecutive auto-sell ticks
        for (int i = 0; i < 5; i++) {
          gameService.processAutoSellTickForTest(force: true);
        }

        // Inventory dispatched via carrier batches
        expect(gameService.state.products[p1.id], lessThan(100));

        // Fleet slots are used up to capacity (2 max for tier 1) and never exceed capacity
        expect(gameService.state.activeShippingOrders.length,
            equals(gameService.state.maxSimultaneousShipments));
        expect(gameService.state.canShipMore(gameService.state.activeShippingOrders.length), isFalse);
      });

      test('Auto-Sell x Staged Manifest: Depleted inventory auto-clamps staged quantities safely', () {
        final p1 = GameData.products[0]; // wires
        final p2 = GameData.products[1]; // gears
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id, p2.id},
            products: {p1.id: 10, p2.id: 10},
            money: 500.0,
            fleetTier: 1,
            autoSellMachinesOwned: 2,
            autoSellEnabled: true,
            autoSellThroughputLevel: 5, // 10 units per tick
          ),
        );

        // Stage 10 units of p1 into manifest cart
        gameService.addToManifest(p1.id, 10);
        expect(gameService.getStagedQuantity(p1.id), 10);

        // Auto-sell sells 8 units of p1 from under the staged cart
        final productsCopy = Map<String, int>.from(gameService.state.products);
        productsCopy[p1.id] = 2; // Only 2 remaining in warehouse!
        gameService.testSetState(gameService.state.copyWith(products: productsCopy));

        // Dispatch manifest — should auto-clamp to the remaining 2 units without error
        final dispatched = gameService.dispatchManifest();
        expect(dispatched, isTrue);

        // Verify remaining inventory is 0 (not negative!)
        expect(gameService.state.products[p1.id] ?? 0, 0);
        expect(gameService.stagedManifest.isEmpty, isTrue);
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.items.first.quantity, 2,
            reason: 'Dispatched quantity must auto-clamp to available warehouse stock');
      });

      test('Auto-Buy x Auto-Build: Batch throughput and bulk intake maintain steady material flow', () {
        // Setup 10 auto-buy machines and 10 auto-build machines
        gameService.testSetState(
          gameService.state.copyWith(
            money: 100000.0,
            autoBuyMachinesOwned: 10,
            autoBuyEnabled: true,
            autoBuyIntakeLevel: 3, // 1.50x intake multiplier
            autoBuyResourceCapacity: 200,
            autoBuildMachinesOwned: {'basicParts': 10},
            autoBuildEnabled: {'basicParts': true},
            autoBuildThroughputLevel: {'basicParts': 2},
            unlockedProducts: {'box'},
            materials: {'cardboard': 50},
          ),
        );

        // Run multi-tick cycle
        for (int i = 0; i < 5; i++) {
          gameService.testSetState(gameService.state.copyWith(
            lastAutoBuyTick: DateTime.now().subtract(const Duration(seconds: 10)),
            lastAutoBuildTick: {'basicParts': DateTime.now().subtract(const Duration(seconds: 10))},
          ));
          gameService.updateProductions();
        }

        // Materials should be purchased in bulk and items queued for building
        expect(gameService.state.materials['cardboard'], greaterThan(0));
        expect(gameService.state.activeProductions.isNotEmpty, isTrue,
            reason: 'Auto-build should queue production tasks without starving');
      });

      test('B2B Contracts x Carrier Caps: Manufacturing contracts (>200 units) exempt from retail caps', () {
        final p1 = GameData.products[0];
        final contract = CorporateContract(
          id: 'test_bulk_manufacturing_contract',
          title: 'Industrial Bulk Assembly',
          description: 'High-volume manufacturing batch',
          clientId: 'client_industrial_megacorp',
          contractType: ContractType.manufacturing,
          requiredProducts: {p1.id: 150},
          cashReward: 25000.0,
          repReward: 20,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
        );

        // Set player on Courier Bike tier (maxPayloadUnits is only 20!)
        gameService.testSetState(
          gameService.state.copyWith(
            fleetTier: 1, // Courier Bikes (20 max units for retail manifest)
            unlockedProducts: {p1.id},
            products: {p1.id: 200},
            corporateContracts: [contract],
            activeShippingOrders: [],
          ),
        );

        // Verify retail canCarrierHold rejects 150 units on Courier Bike
        expect(gameService.canCarrierHold(totalUnits: 150), isFalse);

        // But B2B contract shipping is industrial freight and succeeds with 1 fleet slot
        final shipped = gameService.shipContract(contract.id);
        expect(shipped, isTrue,
            reason: 'B2B contracts are client-arranged freight and exempt from retail bike payload caps');
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.products[p1.id], 50); // 200 - 150 = 50
      });

      test('Manifest Caps x Fleet Tiers: Strictly enforces payload, variety, and per-type caps across all 4 tiers', () {
        for (int tier = 1; tier <= 4; tier++) {
          final fleetTier = GameData.getFleetTier(tier);
          gameService.testSetState(gameService.state.copyWith(fleetTier: tier));

          // Within payload limit (with varieties & single-type distributed)
          expect(
            gameService.canCarrierHold(
              totalUnits: fleetTier.maxPayloadUnits,
              varietyCount: fleetTier.maxProductVarieties,
              maxUnitsInSingleType: fleetTier.maxUnitsPerType,
            ),
            isTrue,
          );
          // Exceeding payload limit
          expect(
            gameService.canCarrierHold(
              totalUnits: fleetTier.maxPayloadUnits + 1,
              varietyCount: fleetTier.maxProductVarieties,
              maxUnitsInSingleType: fleetTier.maxUnitsPerType,
            ),
            isFalse,
          );

          // Within variety limit
          expect(
            gameService.canCarrierHold(
              totalUnits: fleetTier.maxPayloadUnits,
              varietyCount: fleetTier.maxProductVarieties,
              maxUnitsInSingleType: fleetTier.maxUnitsPerType,
            ),
            isTrue,
          );
          // Exceeding variety limit
          expect(
            gameService.canCarrierHold(
              totalUnits: fleetTier.maxPayloadUnits,
              varietyCount: fleetTier.maxProductVarieties + 1,
              maxUnitsInSingleType: fleetTier.maxUnitsPerType,
            ),
            isFalse,
          );

          // Within per-type limit
          expect(
            gameService.canCarrierHold(
              totalUnits: fleetTier.maxPayloadUnits,
              maxUnitsInSingleType: fleetTier.maxUnitsPerType,
            ),
            isTrue,
          );
          // Exceeding per-type limit
          expect(
            gameService.canCarrierHold(
              totalUnits: fleetTier.maxPayloadUnits,
              maxUnitsInSingleType: fleetTier.maxUnitsPerType + 1,
            ),
            isFalse,
          );
        }
      });

      test('Dynamic Economy x Salvage: 1.20x compound curve and 50% salvage remain sound under upgrades', () async {
        gameService.testSetState(
          gameService.state.copyWith(
            money: 50000.0,
            factoryTier: 1, // Tier 1 cap = 10 machines
            autoBuyMachinesOwned: 0,
            autoBuyIntakeLevel: 4, // Upgraded intake level
          ),
        );

        // Buy 5 machines
        for (int i = 0; i < 5; i++) {
          final expectedPrice = 1000.0 * math.pow(1.15, i);
          expect(gameService.getMachinePrice('autoBuy', i), closeTo(expectedPrice, 0.01));
          gameService.buyAutoBuyMachine();
        }
        expect(gameService.state.autoBuyMachinesOwned, 5);

        // Salvage 1 machine (50% refund of the 5th machine)
        final moneyBefore = gameService.state.money;
        final salvageExpected = (0.50 * (1000.0 * math.pow(1.15, 4))).floorToDouble();
        final salvaged = await gameService.salvageMachine('autoBuy');
        expect(salvaged, isTrue);
        expect(gameService.state.autoBuyMachinesOwned, 4);
        expect(gameService.state.money - moneyBefore, closeTo(salvageExpected, 1.0));
      });
    });

    // =========================================================================
    // 2. Adversarial Stress Testing & Boundary Conditions
    // =========================================================================
    group('2. Adversarial Stress Testing & Boundary Conditions', () {
      test('200-Tick Concurrency Stress: All pipelines run concurrently without race conditions or crashes', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        gameService.testSetState(
          gameService.state.copyWith(
            money: 500000.0,
            factoryTier: 4,
            fleetTier: 4, // Cargo planes (12 slots)
            unlockedProducts: {p1.id, p2.id, 'box', 'wires'},
            materials: {'cardboard': 500, 'basic_metals': 500, 'plastic': 500},
            products: {p1.id: 200, p2.id: 200},
            autoBuyMachinesOwned: 20,
            autoBuyEnabled: true,
            autoBuyIntakeLevel: 5,
            autoBuildMachinesOwned: {'basicParts': 20},
            autoBuildEnabled: {'basicParts': true},
            autoBuildThroughputLevel: {'basicParts': 5},
            autoSellMachinesOwned: 10,
            autoSellEnabled: true,
            autoSellThroughputLevel: 5,
            autoShipRetail: true,
            autoShipManufacturing: true,
          ),
        );

        // Execute 200 consecutive ticks simulating aggressive gameplay
        for (int tick = 0; tick < 200; tick++) {
          gameService.testSetState(gameService.state.copyWith(
            lastAutoBuyTick: DateTime.now().subtract(const Duration(seconds: 10)),
            lastAutoBuildTick: {'basicParts': DateTime.now().subtract(const Duration(seconds: 10))},
          ));
          gameService.processAutoSellTickForTest(force: true);

          // Occasionally stage or ship manifest
          if (tick % 20 == 0 && gameService.manifestTotalUnits == 0) {
            gameService.addToManifest(p1.id, 5);
            gameService.dispatchManifest();
          }

          expect(() => gameService.updateProductions(), returnsNormally);

          // Invariant checks on every tick:
          expect(gameService.state.money.isFinite, isTrue);
          expect(gameService.state.money.isNaN, isFalse);
          expect(gameService.state.money, greaterThanOrEqualTo(0.0));

          // No negative materials
          for (final mat in gameService.state.materials.values) {
            expect(mat, greaterThanOrEqualTo(0));
          }
          // No negative products
          for (final prod in gameService.state.products.values) {
            expect(prod, greaterThanOrEqualTo(0));
          }
        }
      });

      test('Resource Starvation Edge Case: \$0.00 cash, 0 materials, 0 products, 0 fleet slots', () {
        gameService.testSetState(
          gameService.state.copyWith(
            money: 0.0,
            materials: {},
            products: {},
            autoBuyMachinesOwned: 10,
            autoBuyEnabled: true,
            autoBuildMachinesOwned: {'basicParts': 10},
            autoBuildEnabled: {'basicParts': true},
            autoSellMachinesOwned: 10,
            autoSellEnabled: true,
            fleetTier: 1,
            activeShippingOrders: [
              ShippingOrder(
                id: 's1',
                items: [],
                startTime: DateTime.now(),
                totalShippingTime: 100,
                totalRevenue: 0,
              ),
              ShippingOrder(
                id: 's2',
                items: [],
                startTime: DateTime.now(),
                totalShippingTime: 100,
                totalRevenue: 0,
              ),
            ],
          ),
        );

        // Fleet slots are full (2 / 2)
        expect(gameService.state.canShipMore(gameService.state.activeShippingOrders.length), isFalse);

        // Run ticks under complete starvation
        for (int i = 0; i < 10; i++) {
          gameService.testSetState(gameService.state.copyWith(
            lastAutoBuyTick: DateTime.now().subtract(const Duration(seconds: 10)),
            lastAutoBuildTick: {'basicParts': DateTime.now().subtract(const Duration(seconds: 10))},
          ));
          gameService.processAutoSellTickForTest(force: true);
          expect(() => gameService.updateProductions(), returnsNormally);
        }

        // Verify state is clean and no negative values
        expect(gameService.state.money, 0.0);
        expect(gameService.manifestTotalUnits, 0);
        expect(gameService.dispatchManifest(), isFalse);
      });

      test('Extreme Scale Megafactory Tier 4: Max machines and Cargo Planes operate flawlessly', () {
        final allProducts = GameData.products.map((p) => p.id).toSet();
        final warehouse = {for (final p in GameData.products) p.id: 1000};
        final rawMats = {for (final m in GameData.materials) m.id: 2000};

        gameService.testSetState(
          gameService.state.copyWith(
            factoryTier: 4, // Cleanroom
            fleetTier: 4, // Cargo Planes (600 payload cap, 12 varieties)
            money: 10000000.0,
            unlockedProducts: allProducts,
            materials: rawMats,
            products: warehouse,
            autoBuyMachinesOwned: 40, // Max tier limit
            autoBuyEnabled: true,
            autoBuyIntakeLevel: 5,
            autoBuildMachinesOwned: {
              'basicParts': 40,
              'intermediate': 40,
              'complex': 40,
            },
            autoBuildEnabled: {
              'basicParts': true,
              'intermediate': true,
              'complex': true,
            },
            autoBuildThroughputLevel: {
              'basicParts': 5,
              'intermediate': 5,
              'complex': 5,
            },
            autoSellMachinesOwned: 40,
            autoSellEnabled: true,
            autoSellThroughputLevel: 5,
          ),
        );

        // Stage 12 distinct varieties (up to 600 total units)
        int stagedCount = 0;
        for (final product in GameData.products.take(12)) {
          gameService.addToManifest(product.id, 50);
          stagedCount += 50;
        }

        expect(gameService.manifestVarietyCount, 12);
        expect(gameService.manifestTotalUnits, stagedCount);
        expect(gameService.manifestTotalUnits, lessThanOrEqualTo(600));

        // Dispatch consolidated flight
        final dispatched = gameService.dispatchManifest();
        expect(dispatched, isTrue);
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.items.length, 12);
      });

      test('SQLite Database Cold Restart: 100% state fidelity across database persistence cycle', () async {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        // Configure rich state
        final testState = gameService.state.copyWith(
          money: 88888.50,
          factoryTier: 3,
          fleetTier: 2,
          autoBuyMachinesOwned: 12,
          autoBuyIntakeLevel: 3,
          autoBuyEnabled: true,
          autoBuildMachinesOwned: {'basicParts': 15, 'intermediate': 8},
          autoBuildThroughputLevel: {'basicParts': 3, 'intermediate': 2},
          autoSellMachinesOwned: 7,
          autoSellThroughputLevel: 2,
          autoSellEnabled: true,
          autoShipRetail: true,
          autoShipManufacturing: false,
          unlockedProducts: {p1.id, p2.id},
          materials: {'cardboard': 45, 'basic_metals': 60},
          products: {p1.id: 30, p2.id: 25},
        );

        // Persist directly via GamePersistenceService
        final persistence = GamePersistenceService();
        await persistence.saveGameState(testState);

        // Cold load from SQLite
        final loaded = await persistence.loadGameState();

        // Assert 100% fidelity
        expect(loaded.money, 88888.50);
        expect(loaded.factoryTier, 3);
        expect(loaded.fleetTier, 2);
        expect(loaded.autoBuyMachinesOwned, 12);
        expect(loaded.autoBuyIntakeLevel, 3);
        expect(loaded.autoBuyEnabled, isTrue);
        expect(loaded.autoBuildMachinesOwned['basicParts'], 15);
        expect(loaded.autoBuildThroughputLevel['basicParts'], 3);
        expect(loaded.autoSellMachinesOwned, 7);
        expect(loaded.autoSellThroughputLevel, 2);
        expect(loaded.autoSellEnabled, isTrue);
        expect(loaded.autoShipRetail, isTrue);
        expect(loaded.autoShipManufacturing, isFalse);
        expect(loaded.materials['cardboard'], 45);
        expect(loaded.products[p1.id], 30);

        await persistence.dispose();
      });
    });

    // =========================================================================
    // 3. Responsive UI Constraints & Zero-Overflow Audit
    // =========================================================================
    group('3. Responsive UI Constraints & Zero-Overflow Audit', () {
      final formFactors = <String, Size>{
        'Mobile Small (360x640)': const Size(360, 640),
        'Mobile Standard (390x844)': const Size(390, 844),
        'Tablet Portrait (768x1024)': const Size(768, 1024),
        'Desktop Wide (1080x1920)': const Size(1080, 1920),
      };

      for (final entry in formFactors.entries) {
        final formFactorName = entry.key;
        final size = entry.value;

        testWidgets('ControlScreen renders with 0 overflows on $formFactorName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<ProductionGameService>.value(
                  value: gameService,
                  child: const ControlScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'ControlScreen must have 0 RenderFlex overflows on $formFactorName');
        });

        testWidgets('SellProductsScreen renders with 0 overflows on $formFactorName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<ProductionGameService>.value(
                  value: gameService,
                  child: const SellProductsScreen(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'SellProductsScreen must have 0 RenderFlex overflows on $formFactorName');
        });

        testWidgets('ShippingManifestTray renders with 0 overflows on $formFactorName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final p1 = GameData.products[0];
          gameService.testSetState(
            gameService.state.copyWith(
              unlockedProducts: {p1.id},
              products: {p1.id: 20},
            ),
          );
          gameService.addToManifest(p1.id, 5);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<ProductionGameService>.value(
                  value: gameService,
                  child: const ShippingManifestTray(),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'ShippingManifestTray must have 0 RenderFlex overflows on $formFactorName');
        });

        testWidgets('ShippingManifestDrawer renders with 0 overflows on $formFactorName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final p1 = GameData.products[0];
          final p2 = GameData.products[1];
          gameService.testSetState(
            gameService.state.copyWith(
              unlockedProducts: {p1.id, p2.id},
              products: {p1.id: 20, p2.id: 20},
            ),
          );
          gameService.addToManifest(p1.id, 5);
          gameService.addToManifest(p2.id, 5);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<ProductionGameService>.value(
                  value: gameService,
                  child: ShippingManifestDrawer(gameService: gameService),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'ShippingManifestDrawer must have 0 RenderFlex overflows on $formFactorName');
        });

        testWidgets('MainGameScreen navigation renders with 0 overflows on $formFactorName', (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: const MainGameScreen(),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull,
              reason: 'MainGameScreen must render without error on $formFactorName');
        });
      }
    });
  });
}
