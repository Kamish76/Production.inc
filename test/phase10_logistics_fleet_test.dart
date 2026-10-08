import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/fleet_upgrade_card.dart';
import 'package:game1/widgets/item_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 10: Logistics Fleet Overhaul: Payload Capacities & Variety Caps', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_phase10_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    // =========================================================================
    // Group 1: Carrier Fleet Payload & Variety Matrix Specifications
    // =========================================================================
    group('1. Carrier Fleet Payload & Variety Matrix Specifications', () {
      test('Tier 1 (Courier Bikes) matches calibrated payload specifications', () {
        final tier = GameData.getFleetTier(1);
        expect(tier.name, 'Courier Bikes');
        expect(tier.maxSimultaneousShipments, 2);
        expect(tier.speedMultiplier, 1.0);
        expect(tier.maxPayloadUnits, 20);
        expect(tier.maxProductVarieties, 2);
        expect(tier.maxUnitsPerType, 10);
      });

      test('Tier 2 (Delivery Vans) matches calibrated payload specifications', () {
        final tier = GameData.getFleetTier(2);
        expect(tier.name, 'Delivery Vans');
        expect(tier.maxSimultaneousShipments, 4);
        expect(tier.speedMultiplier, 1.25);
        expect(tier.maxPayloadUnits, 60);
        expect(tier.maxProductVarieties, 4);
        expect(tier.maxUnitsPerType, 20);
      });

      test('Tier 3 (Freight Trucks) matches calibrated payload specifications', () {
        final tier = GameData.getFleetTier(3);
        expect(tier.name, 'Freight Trucks');
        expect(tier.maxSimultaneousShipments, 7);
        expect(tier.speedMultiplier, 1.6);
        expect(tier.maxPayloadUnits, 200);
        expect(tier.maxProductVarieties, 7);
        expect(tier.maxUnitsPerType, 50);
      });

      test('Tier 4 (Cargo Planes) matches calibrated payload specifications', () {
        final tier = GameData.getFleetTier(4);
        expect(tier.name, 'Cargo Planes');
        expect(tier.maxSimultaneousShipments, 12);
        expect(tier.speedMultiplier, 2.5);
        expect(tier.maxPayloadUnits, 600);
        expect(tier.maxProductVarieties, 12);
        expect(tier.maxUnitsPerType, 100);
      });
    });

    // =========================================================================
    // Group 2: Service Validation & Payload Enforcement in sellProduct
    // =========================================================================
    group('2. sellProduct Payload & Variety Enforcement', () {
      setUp(() {
        // Unlock chair and seed inventory
        final product = GameData.products.first;
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {product.id},
            products: {product.id: 1000},
            fleetTier: 1,
          ),
        );
      });

      test('Tier 1 allows selling up to 10 units and rejects > 10 units', () {
        final product = GameData.products.first;

        // Valid sells for Tier 1
        expect(gameService.sellProduct(product.id, 1), isTrue);
        expect(gameService.sellProduct(product.id, 10), isTrue);

        // Exceeds maxUnitsPerType (10) for Courier Bikes
        expect(gameService.sellProduct(product.id, 11), isFalse);
        // Exceeds maxPayloadUnits (20)
        expect(gameService.sellProduct(product.id, 25), isFalse);
      });

      test('Upgrading to Tier 2 (Delivery Vans) expands single-type limit to 20', () async {
        final product = GameData.products.first;

        // Upgrade fleet to Tier 2
        await gameService.setFleetTierForDev(2);
        expect(gameService.currentFleetTier.tierNumber, 2);

        // Now 20 units is allowed
        expect(gameService.sellProduct(product.id, 20), isTrue);

        // Exceeds Tier 2 limit (20)
        expect(gameService.sellProduct(product.id, 21), isFalse);
      });

      test('Upgrading to Tier 3 (Freight Trucks) expands single-type limit to 50', () async {
        final product = GameData.products.first;

        await gameService.setFleetTierForDev(3);
        expect(gameService.currentFleetTier.tierNumber, 3);

        // 50 units allowed
        expect(gameService.sellProduct(product.id, 50), isTrue);

        // 51 units rejected
        expect(gameService.sellProduct(product.id, 51), isFalse);
      });

      test('Upgrading to Tier 4 (Cargo Planes) expands single-type limit to 100', () async {
        final product = GameData.products.first;

        await gameService.setFleetTierForDev(4);
        expect(gameService.currentFleetTier.tierNumber, 4);

        // 100 units allowed
        expect(gameService.sellProduct(product.id, 100), isTrue);

        // 101 units rejected
        expect(gameService.sellProduct(product.id, 101), isFalse);
      });
    });

    // =========================================================================
    // Group 3: canCarrierHold Helper Method
    // =========================================================================
    group('3. canCarrierHold Helper Method', () {
      test('Accurately evaluates totalUnits, varietyCount, and maxUnitsInSingleType', () async {
        await gameService.setFleetTierForDev(1); // Bike: 20 max payload, 2 varieties, 10/type

        expect(gameService.canCarrierHold(totalUnits: 10), isTrue);
        expect(gameService.canCarrierHold(totalUnits: 20, varietyCount: 2, maxUnitsInSingleType: 10), isTrue);

        // Exceeds payload
        expect(gameService.canCarrierHold(totalUnits: 25), isFalse);
        // Exceeds variety count
        expect(gameService.canCarrierHold(totalUnits: 15, varietyCount: 3), isFalse);
        // Exceeds single-type max
        expect(gameService.canCarrierHold(totalUnits: 15, varietyCount: 2, maxUnitsInSingleType: 12), isFalse);
      });
    });

    // =========================================================================
    // Group 4: Sell Preference Auto-Clamping & Safety
    // =========================================================================
    group('4. Sell Preference Auto-Clamping & Safety', () {
      test('getSellQuantityPreference clamps stored values higher than carrier limit', () async {
        final product = GameData.products.first;

        // Set high preference in state
        gameService.testSetState(
          gameService.state.copyWith(
            fleetTier: 1, // max 10
            sellQuantityPreferences: {product.id: 50},
          ),
        );

        // At Tier 1, auto-clamps to 10
        expect(gameService.getSellQuantityPreference(product.id), 10);

        // At Tier 2, auto-clamps to 20
        await gameService.setFleetTierForDev(2);
        expect(gameService.getSellQuantityPreference(product.id), 20);

        // At Tier 3, allows full 50
        await gameService.setFleetTierForDev(3);
        expect(gameService.getSellQuantityPreference(product.id), 50);
      });

      test('setSellQuantityPreference respects carrier per-type limit', () async {
        final product = GameData.products.first;
        await gameService.setFleetTierForDev(1); // Tier 1: max 10

        // Setting valid options
        gameService.setSellQuantityPreference(product.id, 5);
        expect(gameService.getSellQuantityPreference(product.id), 5);

        gameService.setSellQuantityPreference(product.id, 10);
        expect(gameService.getSellQuantityPreference(product.id), 10);

        // Setting option higher than tier max is rejected
        gameService.setSellQuantityPreference(product.id, 20);
        // Preference remains 10
        expect(gameService.getSellQuantityPreference(product.id), 10);
      });
    });

    // =========================================================================
    // Group 5: B2B Corporate Contracts Exemption
    // =========================================================================
    group('5. B2B Corporate Contracts Exemption', () {
      test('B2B contracts with quantities exceeding carrier payload limits can still be shipped', () {
        final product = GameData.products.first;

        final contract = CorporateContract(
          id: 'test_bulk_mfg_contract',
          clientId: 'client_1',
          title: 'Bulk Intermediate Run',
          description: 'Industrial contract',
          contractType: ContractType.manufacturing,
          requiredProducts: {product.id: 80}, // Exceeds Tier 1 limit (10/type, 20 total)
          cashReward: 5000.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
          status: ContractStatus.available,
          createdAt: DateTime.now(),
        );

        gameService.testSetState(
          gameService.state.copyWith(
            fleetTier: 1, // Courier Bikes
            unlockedProducts: {product.id},
            products: {product.id: 100},
            corporateContracts: [contract],
          ),
        );

        // shipContract succeeds despite requiring 80 units
        final success = gameService.shipContract(contract.id);
        expect(success, isTrue);

        final updated = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
        expect(updated.status, ContractStatus.shipping);
        expect(gameService.state.activeShippingOrders.length, 1);
      });
    });

    // =========================================================================
    // Group 6: Presentation & UI Widgets
    // =========================================================================
    group('6. Presentation & UI Widgets', () {
      testWidgets('FleetUpgradeCard renders payload, variety, and per-type badges', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FleetUpgradeCard(gameService: gameService),
            ),
          ),
        );

        // Check for payload badges
        expect(find.text('Payload'), findsOneWidget);
        expect(find.text('20 Max'), findsOneWidget);

        expect(find.text('Varieties'), findsOneWidget);
        expect(find.text('2 Types'), findsOneWidget);

        expect(find.text('Single-Type'), findsOneWidget);
        expect(find.text('10 Max'), findsOneWidget);

        // Next tier preview
        expect(find.textContaining('60 cap'), findsOneWidget);
        expect(find.textContaining('20/type'), findsOneWidget);
      });

      testWidgets('ItemCard adapts third sell button to current fleet tier', (tester) async {
        final product = GameData.products.first;
        gameService.testSetState(
          gameService.state.copyWith(
            unlockedProducts: {product.id},
            products: {product.id: 200},
            fleetTier: 1, // Courier Bikes (max 10)
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ItemCard(
                item: product,
                mode: ItemCardMode.sell,
                gameService: gameService,
              ),
            ),
          ),
        );

        // At Tier 1: 1, 5, Max (Max = 10 units = +$40.00)
        expect(find.text('1'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('Max'), findsOneWidget);
        expect(find.text('+\$40.00'), findsOneWidget);

        // Upgrade fleet to Tier 2 (Delivery Vans, max 20)
        await gameService.setFleetTierForDev(2);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ItemCard(
                item: product,
                mode: ItemCardMode.sell,
                gameService: gameService,
              ),
            ),
          ),
        );

        // At Tier 2: 1, 5, Max (Max = 20 units = +$80.00)
        expect(find.text('1'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('Max'), findsOneWidget);
        expect(find.text('+\$80.00'), findsOneWidget);
      });
    });
  });
}
