import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/auto_sell_preview.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/auto_sell_status_card.dart';
import 'package:game1/widgets/auto_sell_setup_sheet.dart';
import 'package:game1/screens/sell_products_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 12: Sales Hub Selling Automation Setup System', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_phase12_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    // =========================================================================
    // Group 1: Safety-First Whitelist Management & Empty-by-Default
    // =========================================================================
    group('1. Whitelist Selection & Safety-First Default', () {
      test('Default whitelist is empty and nothing is sold by default', () {
        expect(gameService.state.autoSellWhitelistedProductIds, isEmpty);

        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(5);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 20);
        gameService.addProductToInventory('cables', 10);

        gameService.processAutoSellTickForTest(force: true);

        // Nothing sold because whitelist is empty
        expect(gameService.state.products['box'], 20);
        expect(gameService.state.products['cables'], 10);
        expect(gameService.state.activeShippingOrders, isEmpty);
      });

      test('Only explicitly whitelisted products are sold', () {
        gameService.setAutoSellMachineCount(5);
        gameService.setAutoSellThroughputLevel(5);
        gameService.setAutoSellEnabled(true);
        gameService.addProductToInventory('box', 20);
        gameService.addProductToInventory('cables', 10);

        // Whitelist ONLY 'box'
        gameService.setProductAutoSellWhitelist('box', true);
        expect(gameService.isProductWhitelistedForAutoSell('box'), isTrue);
        expect(gameService.isProductWhitelistedForAutoSell('cables'), isFalse);

        gameService.processAutoSellTickForTest(force: true);

        // 'box' was dispatched into shipping order
        expect(gameService.state.products['box'], lessThan(20));
        // 'cables' remains completely untouched
        expect(gameService.state.products['cables'], 10);
        expect(gameService.state.activeShippingOrders.length, 1);
        final shippedItems = gameService.state.activeShippingOrders.first.items;
        expect(shippedItems.any((i) => i.productId == 'cables'), isFalse);
      });

      test('Whitelist toggle and bulk whitelist operations function correctly', () {
        // Individual toggle
        gameService.toggleProductAutoSellWhitelist('box');
        expect(gameService.isProductWhitelistedForAutoSell('box'), isTrue);

        gameService.toggleProductAutoSellWhitelist('box');
        expect(gameService.isProductWhitelistedForAutoSell('box'), isFalse);

        // Bulk: Whitelist all products
        gameService.setAllProductsAutoSellWhitelist(true);
        expect(
          gameService.state.autoSellWhitelistedProductIds.length,
          GameData.products.length,
        );

        // Bulk: Clear all products
        gameService.setAllProductsAutoSellWhitelist(false);
        expect(gameService.state.autoSellWhitelistedProductIds, isEmpty);

        // Tier bulk: Whitelist only basicParts tier
        gameService.setTierAutoSellWhitelist(ProductLevel.basicParts, true);
        final basicParts = GameData.products
            .where((p) => p.levelId == ProductLevel.basicParts)
            .map((p) => p.id)
            .toSet();
        expect(
          gameService.state.autoSellWhitelistedProductIds,
          equals(basicParts),
        );

        // Tier bulk: Clear basicParts tier
        gameService.setTierAutoSellWhitelist(ProductLevel.basicParts, false);
        expect(gameService.state.autoSellWhitelistedProductIds, isEmpty);
      });

      test('Master switch toggle convenience method works', () {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellEnabled(false);

        gameService.toggleAutoSellMaster();
        expect(gameService.state.autoSellEnabled, isTrue);

        gameService.toggleAutoSellMaster();
        expect(gameService.state.autoSellEnabled, isFalse);
      });
    });

    // =========================================================================
    // Group 2: Fleet Slots & Logistics Fleet Integration
    // =========================================================================
    group('2. Logistics Fleet Real Dispatch & Fleet Slot Management', () {
      test('Auto-sell dispatches real ShippingOrder taking 1 fleet slot', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(2); // Capacity = 4
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 10);

        expect(gameService.state.activeShippingOrders, isEmpty);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.products['box'], 6);
        expect(gameService.state.activeShippingOrders.length, 1);
        final order = gameService.state.activeShippingOrders.first;
        expect(order.items.first.productId, 'box');
        expect(order.items.first.quantity, 4);
      });

      test('Auto-sell waits when fleet has zero available slots', () {
        gameService.setAutoSellMachineCount(3);
        gameService.setAutoSellThroughputLevel(3);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 15);

        // Fill all fleet slots (default carrier has 2 slots)
        final carrier = GameData.fleetTiers[0];
        final maxSlots = carrier.maxSimultaneousShipments;
        final dummyOrders = List.generate(
          maxSlots,
          (i) => ShippingOrder(
            id: 'in_flight_$i',
            items: const [ShippingItem(productId: 'box', quantity: 1)],
            startTime: DateTime.now(),
            totalShippingTime: 120.0,
            totalRevenue: 4.0,
          ),
        );
        gameService.testSetState(
          gameService.state.copyWith(activeShippingOrders: dummyOrders),
        );

        expect(
          gameService.state.canShipMore(gameService.state.activeShippingOrders.length),
          isFalse,
        );

        gameService.processAutoSellTickForTest(force: true);

        // Auto-sell was blocked by fleet saturation: inventory unchanged
        expect(gameService.state.products['box'], 15);
        expect(gameService.state.activeShippingOrders.length, maxSlots);
      });

      test('Carrier payload limits, variety limits, and units-per-type caps are strictly respected', () {
        final carrier = GameData.fleetTiers[0]; // Bicycle Courier: payload 20, maxPerType 10, maxVarieties 2
        gameService.setAutoSellMachineCount(10);
        gameService.setAutoSellThroughputLevel(10); // Auto-sell capacity = 100 units!
        gameService.setAutoSellEnabled(true);

        // Whitelist box and cables
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setProductAutoSellWhitelist('cables', true);

        // Add plenty of stock
        gameService.addProductToInventory('box', 50);
        gameService.addProductToInventory('cables', 50);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.activeShippingOrders.length, 1);
        final order = gameService.state.activeShippingOrders.first;

        // Total payload must not exceed carrier maxPayloadUnits (20)
        final totalUnits = order.items.fold(0, (sum, item) => sum + item.quantity);
        expect(totalUnits, lessThanOrEqualTo(carrier.maxPayloadUnits));

        // Total varieties must not exceed carrier maxProductVarieties (2)
        expect(order.items.length, lessThanOrEqualTo(carrier.maxProductVarieties));

        // Each item must not exceed carrier maxUnitsPerType (10)
        for (final item in order.items) {
          expect(item.quantity, lessThanOrEqualTo(carrier.maxUnitsPerType));
        }
      });

      test('Completed auto-sell shipments deliver revenue into player wallet', () {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setMoney(100.0);
        gameService.addProductToInventory('box', 2);

        gameService.processAutoSellTickForTest(force: true);

        expect(gameService.state.activeShippingOrders.length, 1);
        final order = gameService.state.activeShippingOrders.first;

        // Fast-forward delivery
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

        // Revenue added: 2 boxes * $4.0 = $8.0 -> $108.0
        expect(gameService.state.activeShippingOrders, isEmpty);
        expect(gameService.state.money, 108.0);
        expect(gameService.state.shippingHistory.length, 1);
      });
    });

    // =========================================================================
    // Group 3: B2B Contract Prioritization & Execution
    // =========================================================================
    group('3. B2B Corporate Contract Prioritization', () {
      test('Eligible accepted B2B contracts are fulfilled before storefront batches', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellFulfillContracts(true);
        gameService.setProductAutoSellWhitelist('box', true);

        // Create an available contract requiring 5 cables
        final contract = CorporateContract(
          id: 'b2b_test_01',
          clientId: 'client_apex',
          title: 'Urgent Cables Request',
          description: 'Need cables urgently',
          contractType: ContractType.retail,
          requiredProducts: {'cables': 5},
          cashReward: 150.0,
          repReward: 15,
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          status: ContractStatus.available,
          createdAt: DateTime.now(),
        );

        gameService.testSetState(
          gameService.state.copyWith(
            corporateContracts: [contract],
          ),
        );

        // Add 5 cables and 10 boxes
        gameService.addProductToInventory('cables', 5);
        gameService.addProductToInventory('box', 10);
        final initialMoney = gameService.state.money;

        // Tick auto-sell
        gameService.processAutoSellTickForTest(force: true);

        // Contract was fulfilled: cables consumed and placed into shipping order
        expect(gameService.state.products['cables'], isNull);
        final shippingContract = gameService.state.corporateContracts.firstWhere(
          (c) => c.id == 'b2b_test_01',
        );
        expect(shippingContract.status, ContractStatus.shipping);
        expect(gameService.state.activeShippingOrders.length, 1);
        expect(gameService.state.activeShippingOrders.first.contractId, 'b2b_test_01');

        // Complete the shipping order
        final order = gameService.state.activeShippingOrders.first;
        final completedOrder = ShippingOrder(
          id: order.id,
          contractId: order.contractId,
          items: order.items,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          totalShippingTime: order.totalShippingTime,
          totalRevenue: order.totalRevenue,
        );
        gameService.testSetState(
          gameService.state.copyWith(activeShippingOrders: [completedOrder]),
        );
        gameService.updateProductions();

        final completedContract = gameService.state.corporateContracts.firstWhere(
          (c) => c.id == 'b2b_test_01',
        );
        expect(completedContract.status, ContractStatus.completed);
        expect(gameService.state.money, initialMoney + 150.0);
        // Box remained untouched because contract took priority
        expect(gameService.state.products['box'], 10);
      });

      test('Skipping B2B contracts when autoSellFulfillContracts is disabled', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellFulfillContracts(false);
        gameService.setProductAutoSellWhitelist('box', true);

        final contract = CorporateContract(
          id: 'b2b_test_02',
          clientId: 'client_apex',
          title: 'Urgent Cables Request',
          description: 'Need cables urgently',
          contractType: ContractType.retail,
          requiredProducts: {'cables': 5},
          cashReward: 150.0,
          repReward: 15,
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          status: ContractStatus.available,
          createdAt: DateTime.now(),
        );

        gameService.testSetState(
          gameService.state.copyWith(
            corporateContracts: [contract],
          ),
        );

        gameService.addProductToInventory('cables', 5);
        gameService.addProductToInventory('box', 10);

        gameService.processAutoSellTickForTest(force: true);

        // Contract was NOT fulfilled because fulfillContracts is false
        final updatedContract = gameService.state.corporateContracts.firstWhere(
          (c) => c.id == 'b2b_test_02',
        );
        expect(updatedContract.status, ContractStatus.available);
        // Whitelisted storefront batch was dispatched instead
        expect(gameService.state.products['box'], lessThan(10));
      });

      test('Skipping storefront batch when autoSellBatchDispatch is disabled', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellBatchDispatch(false);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 10);

        gameService.processAutoSellTickForTest(force: true);

        // Storefront batch skipped: inventory untouched, no shipping order
        expect(gameService.state.products['box'], 10);
        expect(gameService.state.activeShippingOrders, isEmpty);
      });
    });

    // =========================================================================
    // Group 4: Live Queue Preview States (getAutoSellNextAction)
    // =========================================================================
    group('4. Live Queue Preview Diagnostics (getAutoSellNextAction)', () {
      test('Returns idleDisabled when machines == 0 or enabled == false', () {
        gameService.setAutoSellMachineCount(0);
        gameService.setAutoSellEnabled(true);
        var preview = gameService.getAutoSellNextAction();
        expect(preview.actionType, AutoSellActionType.idleDisabled);

        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(false);
        preview = gameService.getAutoSellNextAction();
        expect(preview.actionType, AutoSellActionType.idleDisabled);
      });

      test('Returns waitingStock when enabled but no whitelisted items have stock', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        // No box in inventory
        final preview = gameService.getAutoSellNextAction();
        expect(preview.actionType, AutoSellActionType.waitingStock);
      });

      test('Returns waitingFleet when stock is ready but fleet is full', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 10);

        // Fill all carrier slots
        final carrier = GameData.fleetTiers[0];
        final dummyOrders = List.generate(
          carrier.maxSimultaneousShipments,
          (i) => ShippingOrder(
            id: 'full_$i',
            items: const [ShippingItem(productId: 'box', quantity: 1)],
            startTime: DateTime.now(),
            totalShippingTime: 120.0,
            totalRevenue: 4.0,
          ),
        );
        gameService.testSetState(
          gameService.state.copyWith(activeShippingOrders: dummyOrders),
        );

        final preview = gameService.getAutoSellNextAction();
        expect(preview.actionType, AutoSellActionType.waitingFleet);
      });

      test('Returns b2bContract when eligible contract is ready', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellFulfillContracts(true);

        final contract = CorporateContract(
          id: 'b2b_preview_01',
          clientId: 'client_apex',
          title: 'Preview Order',
          description: 'Preview test',
          contractType: ContractType.retail,
          requiredProducts: {'box': 2},
          cashReward: 20.0,
          repReward: 5,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          status: ContractStatus.available,
          createdAt: DateTime.now(),
        );

        gameService.testSetState(
          gameService.state.copyWith(corporateContracts: [contract]),
        );
        gameService.addProductToInventory('box', 2);

        final preview = gameService.getAutoSellNextAction();
        expect(preview.actionType, AutoSellActionType.b2bContract);
        expect(preview.clientOrBatchName, 'Preview Order');
      });

      test('Returns batchDispatch when whitelisted stock and fleet slot are available', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 5);

        final preview = gameService.getAutoSellNextAction();
        expect(preview.actionType, AutoSellActionType.batchDispatch);
        final totalUnits = preview.stagedItems.values.fold(0, (a, b) => a + b);
        expect(totalUnits, greaterThan(0));
        expect(preview.estimatedRevenue, greaterThan(0));
      });
    });

    // =========================================================================
    // Group 5: Manual Staging Manifest Isolation
    // =========================================================================
    group('5. Manual Manifest Isolation', () {
      test('Manual staged manifest is completely untouched by auto-sell operations', () {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('cables', true);

        // Add inventory
        gameService.addProductToInventory('box', 20);
        gameService.addProductToInventory('cables', 20);

        // Player manually stages 5 boxes
        gameService.addToManifest('box', 5);
        expect(gameService.manifestTotalUnits, 5);
        expect(gameService.stagedManifest['box'], 5);

        // Auto-sell tick runs (selling whitelisted cables)
        gameService.processAutoSellTickForTest(force: true);

        // Manual staged manifest remains 100% untouched
        expect(gameService.manifestTotalUnits, 5);
        expect(gameService.stagedManifest['box'], 5);
        // Player can still dispatch manual manifest normally
        final manualDispatched = gameService.dispatchManifest();
        expect(manualDispatched, isTrue);
        expect(gameService.manifestTotalUnits, 0);
      });
    });

    // =========================================================================
    // Group 6: SQLite Schema & Migration v15 Idempotency
    // =========================================================================
    group('6. Persistence & Migration v15 Verification', () {
      test('AutoSell whitelist and mode flags are saved and loaded correctly', () async {
        gameService.setAutoSellMachineCount(3);
        gameService.setAutoSellThroughputLevel(2);
        gameService.setAutoSellEnabled(true);
        gameService.setAutoSellBatchDispatch(false);
        gameService.setAutoSellFulfillContracts(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.setProductAutoSellWhitelist('speaker', true);

        final persistence = GamePersistenceService();
        await persistence.saveGameState(gameService.state);

        // Load into state
        final loadedState = await persistence.loadGameState();

        expect(loadedState.autoSellBatchDispatch, isFalse);
        expect(loadedState.autoSellFulfillContracts, isTrue);
        expect(
          loadedState.autoSellWhitelistedProductIds,
          containsAll({'box', 'speaker'}),
        );
        expect(
          loadedState.autoSellWhitelistedProductIds.length,
          2,
        );
      });

      test('Database schema includes auto_sell_whitelist table and columns', () async {
        final persistence = GamePersistenceService();
        final db = await persistence.database;

        // Check columns in game_state
        final columns = await db.rawQuery('PRAGMA table_info(game_state)');
        final columnNames = columns.map((r) => r['name'] as String).toSet();
        expect(columnNames.contains('auto_sell_batch_dispatch'), isTrue);
        expect(columnNames.contains('auto_sell_fulfill_contracts'), isTrue);

        // Check auto_sell_whitelist table
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='auto_sell_whitelist'",
        );
        expect(tables.isNotEmpty, isTrue);
      });
    });

    // =========================================================================
    // Group 7: Widget Integration Tests (AutoSellStatusCard & AutoSellSetupSheet)
    // =========================================================================
    group('7. Presentation & Widget Mounting', () {
      testWidgets('AutoSellStatusCard renders cleanly and displays status', (tester) async {
        gameService.setAutoSellMachineCount(2);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);
        gameService.addProductToInventory('box', 5);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductionGameService>.value(
            value: gameService,
            child: const MaterialApp(
              home: Scaffold(
                body: AutoSellStatusCard(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Auto-Sell Dispatcher'), findsOneWidget);
        expect(find.text('2 Active'), findsOneWidget);
        expect(find.text('Setup'), findsOneWidget);
      });

      testWidgets('AutoSellSetupSheet mounts and renders controls cleanly', (tester) async {
        gameService.setAutoSellMachineCount(3);
        gameService.setAutoSellEnabled(true);
        gameService.setProductAutoSellWhitelist('box', true);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductionGameService>.value(
            value: gameService,
            child: const MaterialApp(
              home: Scaffold(
                body: AutoSellSetupSheet(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Selling Automation Setup'), findsOneWidget);
        expect(find.text('Auto-Dispatch Storefront Batches'), findsOneWidget);
        expect(find.text('Auto-Fulfill B2B Contracts'), findsOneWidget);
        expect(find.text('Select All'), findsOneWidget);
        expect(find.text('Clear All'), findsOneWidget);
      });

      testWidgets('SellProductsScreen includes automation action pill in header', (tester) async {
        gameService.setAutoSellMachineCount(1);
        gameService.setAutoSellEnabled(true);

        await tester.pumpWidget(
          ChangeNotifierProvider<ProductionGameService>.value(
            value: gameService,
            child: const MaterialApp(
              home: Scaffold(
                body: SellProductsScreen(),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Auto: ON'), findsOneWidget);
        expect(find.text('Auto-Sell Dispatcher'), findsOneWidget);
      });
    });
  });
}
