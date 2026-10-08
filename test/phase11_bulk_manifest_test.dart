import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/item_card.dart';
import 'package:game1/widgets/shipping_manifest_tray.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 11: Commercial Dispatch Manifest (Bulk Sell Cart)', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_phase11_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    // =========================================================================
    // Group 1: Staged Manifest State Engine (CRUD & Inventory Bounds)
    // =========================================================================
    group('1. Staged Manifest State Engine', () {
      setUp(() {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id, p2.id},
            products: {p1.id: 50, p2.id: 50},
            fleetTier: 1, // Courier Bikes (maxPayload: 20, maxVarieties: 2, maxUnitsPerType: 10)
          ),
        );
      });

      test('addToManifest adds items and updates summary getters', () {
        final p1 = GameData.products[0];
        expect(gameService.manifestTotalUnits, 0);
        expect(gameService.manifestVarietyCount, 0);
        expect(gameService.stagedManifest.isEmpty, isTrue);

        final added = gameService.addToManifest(p1.id, 5);
        expect(added, isTrue);
        expect(gameService.manifestTotalUnits, 5);
        expect(gameService.manifestVarietyCount, 1);
        expect(gameService.getStagedQuantity(p1.id), 5);
        expect(gameService.manifestTotalRevenue, p1.sellPrice * 5);
      });

      test('addToManifest rejects invalid, zero, or negative quantities', () {
        final p1 = GameData.products[0];
        expect(gameService.addToManifest(p1.id, 0), isFalse);
        expect(gameService.addToManifest(p1.id, -2), isFalse);
        expect(gameService.manifestTotalUnits, 0);
      });

      test('addToManifest rejects items exceeding available inventory', () {
        final p1 = GameData.products[0];
        // Inventory is 50, but let's test a product with only 3 units
        gameService.testSetState(
          gameService.state.copyWith(
            products: {p1.id: 3},
          ),
        );

        // Trying to stage 4 units when only 3 exist
        expect(gameService.addToManifest(p1.id, 4), isFalse);
        expect(gameService.addToManifest(p1.id, 3), isTrue);
        // Staging 1 more should fail because already 3 staged
        expect(gameService.addToManifest(p1.id, 1), isFalse);
      });

      test('removeFromManifest and clearManifest work correctly', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        gameService.addToManifest(p1.id, 3);
        gameService.addToManifest(p2.id, 4);
        expect(gameService.manifestVarietyCount, 2);
        expect(gameService.manifestTotalUnits, 7);

        gameService.removeFromManifest(p1.id);
        expect(gameService.manifestVarietyCount, 1);
        expect(gameService.getStagedQuantity(p1.id), 0);
        expect(gameService.getStagedQuantity(p2.id), 4);

        gameService.clearManifest();
        expect(gameService.stagedManifest.isEmpty, isTrue);
        expect(gameService.manifestTotalUnits, 0);
      });

      test('updateManifestQuantity clamps and removes on 0', () {
        final p1 = GameData.products[0];
        gameService.addToManifest(p1.id, 4);

        // Update to 8
        expect(gameService.updateManifestQuantity(p1.id, 8), isTrue);
        expect(gameService.getStagedQuantity(p1.id), 8);

        // Update to 0 removes
        expect(gameService.updateManifestQuantity(p1.id, 0), isTrue);
        expect(gameService.getStagedQuantity(p1.id), 0);
        expect(gameService.stagedManifest.containsKey(p1.id), isFalse);
      });

      test('setManifestMaxForProduct fills to max valid capacity', () {
        final p1 = GameData.products[0];
        // Courier Bikes: maxUnitsPerType = 10, maxPayload = 20
        gameService.setManifestMaxForProduct(p1.id);
        expect(gameService.getStagedQuantity(p1.id), 10);
      });
    });

    // =========================================================================
    // Group 2: Carrier Payload & Variety Cap Enforcement
    // =========================================================================
    group('2. Carrier Payload & Variety Cap Hard Guards', () {
      setUp(() {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];
        final p3 = GameData.products[2];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id, p2.id, p3.id},
            products: {p1.id: 100, p2.id: 100, p3.id: 100},
            fleetTier: 1, // Courier Bikes: maxVarieties = 2, maxUnitsPerType = 10, maxPayload = 20
          ),
        );
      });

      test('Courier Bikes enforces maxUnitsPerType (10 units)', () {
        final p1 = GameData.products[0];
        expect(gameService.addToManifest(p1.id, 10), isTrue);
        // Exceeds 10 units per type
        expect(gameService.addToManifest(p1.id, 1), isFalse);
        expect(gameService.updateManifestQuantity(p1.id, 11), isFalse);
      });

      test('Courier Bikes enforces maxProductVarieties (2 varieties)', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];
        final p3 = GameData.products[2];

        expect(gameService.addToManifest(p1.id, 5), isTrue);
        expect(gameService.addToManifest(p2.id, 5), isTrue);
        expect(gameService.manifestVarietyCount, 2);

        // 3rd variety must be rejected
        expect(gameService.addToManifest(p3.id, 1), isFalse);
        expect(gameService.manifestVarietyCount, 2);
      });

      test('Courier Bikes enforces maxPayloadUnits (20 units total)', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        expect(gameService.addToManifest(p1.id, 10), isTrue);
        expect(gameService.addToManifest(p2.id, 10), isTrue);
        expect(gameService.manifestTotalUnits, 20);

        // Any additional unit exceeds 20 max payload
        expect(gameService.addToManifest(p1.id, 1), isFalse);
        expect(gameService.addToManifest(p2.id, 1), isFalse);
      });

      test('Upgrading fleet to Delivery Vans expands capacity limits', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];
        final p3 = GameData.products[2];

        // Upgrade to Tier 2 (Delivery Vans: 4 varieties, 20 units/type, 60 payload units)
        gameService.testSetState(
          gameService.state.copyWith(fleetTier: 2),
        );

        expect(gameService.addToManifest(p1.id, 20), isTrue);
        expect(gameService.addToManifest(p2.id, 20), isTrue);
        expect(gameService.addToManifest(p3.id, 20), isTrue);
        expect(gameService.manifestVarietyCount, 3);
        expect(gameService.manifestTotalUnits, 60);

        // Exceeds 60 units payload
        expect(gameService.addToManifest(p1.id, 1), isFalse);
      });
    });

    // =========================================================================
    // Group 3: Consolidated Mixed-Cargo Transit Time Calculation
    // =========================================================================
    group('3. Consolidated Mixed-Cargo Transit Time Formula', () {
      test('Matches square root scaling formula accurately', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id, p2.id},
            products: {p1.id: 100, p2.id: 100},
            fleetTier: 1, // Speed multiplier: 1.0
          ),
        );

        gameService.addToManifest(p1.id, 5);
        gameService.addToManifest(p2.id, 5);

        final totalUnits = 10;
        final maxBaseTime = math.max(p1.baseShippingTimeSeconds, p2.baseShippingTimeSeconds);
        final expectedBaseTransit = maxBaseTime * math.sqrt(1.0 + 0.04 * (totalUnits - 1));
        final expectedShippingTime = (expectedBaseTransit / 1.0).clamp(1.0, 86400.0);

        final calculatedTime = gameService.calculateManifestShippingTime();
        expect(calculatedTime, closeTo(expectedShippingTime, 0.001));
      });
    });

    // =========================================================================
    // Group 4: Auto-Clamping on Inventory Stock Drop
    // =========================================================================
    group('4. Auto-Clamping on Inventory Stock Drop', () {
      test('Clamps staged items down to available stock and notifies callback', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id, p2.id},
            products: {p1.id: 10, p2.id: 10},
            fleetTier: 1,
          ),
        );

        gameService.addToManifest(p1.id, 8);
        gameService.addToManifest(p2.id, 5);

        // Simulate external inventory drop (e.g. from Auto-Sell or B2B)
        // p1 drops from 10 to 3. p2 drops from 10 to 0.
        gameService.testSetState(
          gameService.state.copyWith(
            products: {p1.id: 3, p2.id: 0},
          ),
        );

        String? notificationMessage;
        final dispatched = gameService.dispatchManifest(
          onStockAdjusted: (msg) {
            notificationMessage = msg;
          },
        );

        expect(dispatched, isTrue);
        expect(notificationMessage, isNotNull);
        expect(notificationMessage, contains('adjusted'));

        // p1 had 3 units available; 3 were dispatched, remaining is 0
        expect(gameService.state.getProductCount(p1.id), 0);
        expect(gameService.stagedManifest.isEmpty, isTrue);

        // Exactly 1 consolidated shipping order created
        expect(gameService.state.activeShippingOrders.length, 1);
        final order = gameService.state.activeShippingOrders.first;
        expect(order.items.length, 1);
        expect(order.items.first.productId, p1.id);
        expect(order.items.first.quantity, 3);
      });

      test('Aborts dispatch cleanly if all items drop to 0 stock', () {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 10},
            fleetTier: 1,
          ),
        );

        gameService.addToManifest(p1.id, 5);

        // Simulate total depletion
        gameService.testSetState(
          gameService.state.copyWith(
            products: {p1.id: 0},
          ),
        );

        String? notificationMessage;
        final dispatched = gameService.dispatchManifest(
          onStockAdjusted: (msg) => notificationMessage = msg,
        );

        expect(dispatched, isFalse);
        expect(notificationMessage, isNotNull);
        expect(notificationMessage, contains('no longer available'));
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);
      });
    });

    // =========================================================================
    // Group 5: Consolidated Shipping Order Execution & Settlement
    // =========================================================================
    group('5. Consolidated Shipping Order Execution & Settlement', () {
      test('Consumes exactly 1 fleet slot and settles cumulative revenue', () {
        final p1 = GameData.products[0];
        final p2 = GameData.products[1];

        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id, p2.id},
            products: {p1.id: 20, p2.id: 20},
            money: 1000.0,
            fleetTier: 1, // 2 concurrent slots max
          ),
        );

        gameService.addToManifest(p1.id, 5);
        gameService.addToManifest(p2.id, 5);

        final expectedRevenue = (p1.sellPrice * 5) + (p2.sellPrice * 5);
        final initialMoney = gameService.state.money;

        final dispatched = gameService.dispatchManifest();
        expect(dispatched, isTrue);

        // Consumed 1 fleet slot
        expect(gameService.state.activeShippingOrders.length, 1);
        final order = gameService.state.activeShippingOrders.first;
        expect(order.items.length, 2);
        expect(order.totalRevenue, expectedRevenue);

        // Inventory was deducted
        expect(gameService.state.getProductCount(p1.id), 15);
        expect(gameService.state.getProductCount(p2.id), 15);

        // Simulate order completion: set start time into past
        final completedOrder = ShippingOrder(
          id: order.id,
          items: order.items,
          startTime: DateTime.now().subtract(Duration(seconds: order.totalShippingTime.toInt() + 10)),
          totalShippingTime: order.totalShippingTime,
          totalRevenue: order.totalRevenue,
        );

        gameService.testSetState(
          gameService.state.copyWith(
            activeShippingOrders: [completedOrder],
          ),
        );

        // Trigger game tick loop update
        gameService.updateProductions();

        // Shipping order completed & settled
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);
        expect(gameService.state.money, initialMoney + expectedRevenue);
        expect(gameService.state.shippingHistory.length, 1);
        expect(gameService.state.shippingHistory.first.items.length, 2);
      });
    });

    // =========================================================================
    // Group 6: Widget Tests (ShippingManifestTray & ShippingManifestDrawer)
    // =========================================================================
    group('6. Widget Interactions', () {
      testWidgets('ShippingManifestTray appears when staged and shows summary', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 20},
            fleetTier: 1,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: const Column(
                  children: [
                    Expanded(child: SizedBox()),
                    ShippingManifestTray(),
                  ],
                ),
              ),
            ),
          ),
        );

        // When manifest is empty, tray is not shown (SizedBox.shrink)
        expect(find.textContaining('Dispatch'), findsNothing);

        // Stage 4 units
        gameService.addToManifest(p1.id, 4);
        await tester.pump();

        // Tray now appears with stats
        expect(find.textContaining('4/20 Units'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('🚚 Dispatch'), findsOneWidget);
      });

      testWidgets('ItemCard shows + Manifest chip and updates on interaction', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 20},
            fleetTier: 1,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Consumer<ProductionGameService>(
                  builder: (context, service, _) => ItemCard(
                    item: p1,
                    gameService: service,
                    mode: ItemCardMode.sell,
                  ),
                ),
              ),
            ),
          ),
        );

        // "+ Manifest" chip is visible
        final manifestChip = find.text('+ Manifest');
        expect(manifestChip, findsOneWidget);

        // Tap chip to stage product
        await tester.tap(manifestChip);
        await tester.pump();

        // Now shows staged badge
        expect(find.textContaining('Staged'), findsOneWidget);
        expect(gameService.getStagedQuantity(p1.id), greaterThan(0));
      });
    });

    // =========================================================================
    // Group 7: Manifest-Only Sales & Accidental Sell Prevention
    // =========================================================================
    group('7. Manifest-Only Sales & Accidental Sell Prevention', () {
      testWidgets('Tapping the card body in ItemCardMode.sell does NOT sell products or decrease inventory', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 50},
            money: 1000.0,
            fleetTier: 1,
          ),
        );

        bool detailsCallbackCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Consumer<ProductionGameService>(
                  builder: (context, service, _) => ItemCard(
                    item: p1,
                    gameService: service,
                    mode: ItemCardMode.sell,
                    onProductDetails: () {
                      detailsCallbackCalled = true;
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // Tap the card body
        await tester.tap(find.byType(ItemCard));
        await tester.pumpAndSettle();

        // Details callback was invoked
        expect(detailsCallbackCalled, isTrue);

        // Inventory is intact (never sold)
        expect(gameService.state.getProductCount(p1.id), 50);
        expect(gameService.state.money, 1000.0);
        expect(gameService.stagedManifest.isEmpty, isTrue);
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);
      });

      testWidgets('Tapping card body without onProductDetails opens details sheet without selling', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 50},
            money: 1000.0,
            fleetTier: 1,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Consumer<ProductionGameService>(
                  builder: (context, service, _) => ItemCard(
                    item: p1,
                    gameService: service,
                    mode: ItemCardMode.sell,
                  ),
                ),
              ),
            ),
          ),
        );

        // Tap the card body
        await tester.tap(find.byType(ItemCard));
        await tester.pumpAndSettle();

        // Bottom sheet details opened
        expect(find.byType(BottomSheet), findsOneWidget);

        // Inventory and money are intact
        expect(gameService.state.getProductCount(p1.id), 50);
        expect(gameService.state.money, 1000.0);
        expect(gameService.stagedManifest.isEmpty, isTrue);
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);
      });

      testWidgets('Shortcut buttons (1, 5, Max) update preference only without staging units into manifest', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 50},
            money: 1000.0,
            fleetTier: 1, // Courier Bikes: maxUnitsPerType = 10, maxPayload = 20
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Consumer<ProductionGameService>(
                  builder: (context, service, _) => ItemCard(
                    item: p1,
                    gameService: service,
                    mode: ItemCardMode.sell,
                  ),
                ),
              ),
            ),
          ),
        );

        // 1. Tap "1" shortcut - updates preference only, does NOT stage
        await tester.tap(find.text('1'));
        await tester.pump();
        expect(gameService.getSellQuantityPreference(p1.id), 1);
        expect(gameService.getStagedQuantity(p1.id), 0);
        expect(gameService.state.getProductCount(p1.id), 50); // Unchanged!
        expect(gameService.state.money, 1000.0); // No instant cash!
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);

        // 2. Tap "5" shortcut - updates preference to 5 without staging
        await tester.tap(find.text('5'));
        await tester.pump();
        expect(gameService.getSellQuantityPreference(p1.id), 5);
        expect(gameService.getStagedQuantity(p1.id), 0);
        expect(gameService.state.getProductCount(p1.id), 50); // Unchanged!
        expect(gameService.state.money, 1000.0); // Unchanged!
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);

        // 3. Tap "Max" shortcut - updates preference to maxUnitsPerType (10) without staging
        await tester.tap(find.text('Max'));
        await tester.pump();
        expect(gameService.getSellQuantityPreference(p1.id), 10);
        expect(gameService.getStagedQuantity(p1.id), 0);
        expect(gameService.state.getProductCount(p1.id), 50); // Unchanged!
        expect(gameService.state.money, 1000.0); // Unchanged!
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);
      });

      testWidgets('+ Manifest button stages active preference quantity and stepper adjusts by preference amount', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 50},
            money: 1000.0,
            fleetTier: 1, // Courier Bikes: maxUnitsPerType = 10, maxPayload = 20
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Consumer<ProductionGameService>(
                  builder: (context, service, _) => ItemCard(
                    item: p1,
                    gameService: service,
                    mode: ItemCardMode.sell,
                  ),
                ),
              ),
            ),
          ),
        );

        // Select '5' preference
        await tester.tap(find.text('5'));
        await tester.pump();
        expect(gameService.getSellQuantityPreference(p1.id), 5);
        expect(gameService.getStagedQuantity(p1.id), 0);

        // Tap '+ Manifest' to stage preference amount (5)
        await tester.tap(find.text('+ Manifest'));
        await tester.pump();
        expect(gameService.getStagedQuantity(p1.id), 5);
        expect(find.text('🛒 5 Staged'), findsOneWidget);

        // Tap stepper '+' (Icon Icons.add) -> increments by preference (5), reaching 10 (max per type)
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
        expect(gameService.getStagedQuantity(p1.id), 10);
        expect(find.text('🛒 10 Staged'), findsOneWidget);

        // Tap stepper '-' (Icon Icons.remove) -> decrements by preference (5), down to 5
        await tester.tap(find.byIcon(Icons.remove));
        await tester.pump();
        expect(gameService.getStagedQuantity(p1.id), 5);
        expect(find.text('🛒 5 Staged'), findsOneWidget);

        // Tap stepper '-' again -> decrements by preference (5), down to 0 (removed from manifest)
        await tester.tap(find.byIcon(Icons.remove));
        await tester.pump();
        expect(gameService.getStagedQuantity(p1.id), 0);
        expect(find.text('+ Manifest'), findsOneWidget);
      });

      testWidgets('Dispatch button in ShippingManifestTray remains the only way to dispatch and sell staged goods', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 50},
            money: 1000.0,
            fleetTier: 1, // Courier Bikes
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Column(
                  children: [
                    Consumer<ProductionGameService>(
                      builder: (context, service, _) => ItemCard(
                        item: p1,
                        gameService: service,
                        mode: ItemCardMode.sell,
                      ),
                    ),
                    const Spacer(),
                    const ShippingManifestTray(),
                  ],
                ),
              ),
            ),
          ),
        );

        // Stage 5 units via selecting 5 and tapping + Manifest
        await tester.tap(find.text('5'));
        await tester.pump();
        await tester.tap(find.text('+ Manifest'));
        await tester.pump();

        // Goods are staged; inventory is still 50, money is still 1000.0
        expect(gameService.getStagedQuantity(p1.id), 5);
        expect(gameService.state.getProductCount(p1.id), 50);
        expect(gameService.state.money, 1000.0);
        expect(gameService.state.activeShippingOrders.isEmpty, isTrue);

        // ShippingManifestTray has appeared with Dispatch button
        final dispatchButton = find.text('🚚 Dispatch');
        expect(dispatchButton, findsOneWidget);

        // Tap Dispatch
        await tester.tap(dispatchButton);
        await tester.pump();

        // Now inventory is deducted (50 - 5 = 45), manifest is cleared, active shipping order created
        expect(gameService.state.getProductCount(p1.id), 45);
        expect(gameService.stagedManifest.isEmpty, isTrue);
        expect(gameService.state.activeShippingOrders.length, 1);
        final order = gameService.state.activeShippingOrders.first;
        expect(order.items.first.productId, p1.id);
        expect(order.items.first.quantity, 5);
        expect(order.totalRevenue, p1.sellPrice * 5);
      });

      testWidgets('Shortcut buttons visually highlight based on current sell quantity preference', (tester) async {
        final p1 = GameData.products[0];
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {p1.id},
            products: {p1.id: 50},
            money: 1000.0,
            fleetTier: 1, // Courier bikes (maxUnitsPerType = 10)
          ),
        );

        // Set preference to 5
        gameService.setSellQuantityPreference(p1.id, 5);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProductionGameService>.value(
                value: gameService,
                child: Consumer<ProductionGameService>(
                  builder: (context, service, _) => ItemCard(
                    item: p1,
                    gameService: service,
                    mode: ItemCardMode.sell,
                  ),
                ),
              ),
            ),
          ),
        );

        // When preference is 5, 5 button is selected (Color(0xFF5A2A82))
        final inkWidgets = tester.widgetList<Ink>(find.byType(Ink));
        expect(
          inkWidgets.any((ink) {
            final decoration = ink.decoration as BoxDecoration?;
            return decoration?.color == const Color(0xFF5A2A82);
          }),
          isTrue,
        );

        // Tap 1 button
        await tester.tap(find.text('1'));
        await tester.pump();

        // Preference updated to 1
        expect(gameService.getSellQuantityPreference(p1.id), 1);

        // Tap Max button
        await tester.tap(find.text('Max'));
        await tester.pump();

        // Preference updated to maxUnitsPerType (10)
        expect(gameService.getSellQuantityPreference(p1.id), 10);
      });
    });
  });
}
