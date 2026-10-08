import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/corporate_contract_card.dart';

void main() {
  group('Phase 9A: B2B Contract Overhaul (Retail vs Manufacturing & Lock & Ship)', () {
    late ProductionGameService gameService;

    setUp(() {
      final testDbName = 'test_phase9a_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    // =========================================================================
    // 1. Contract Models & Type System
    // =========================================================================
    group('1. Contract Models & Type System', () {
      test('CorporateContract supports retail and manufacturing ContractType', () {
        final retailContract = CorporateContract(
          id: 'c_retail_1',
          clientId: 'apex_telecom',
          title: 'Retail Order',
          description: 'Ship smartphones',
          contractType: ContractType.retail,
          requiredProducts: const {'smartphone': 10},
          cashReward: 5000.0,
          repReward: 75,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        expect(retailContract.contractType, ContractType.retail);
        expect(retailContract.requiredProducts['smartphone'], 10);
        expect(retailContract.totalRequiredUnits, 10);

        final mfgContract = CorporateContract(
          id: 'c_mfg_1',
          clientId: 'nova_robotics',
          title: 'Bulk Parts',
          description: 'Ship wires and gears',
          contractType: ContractType.manufacturing,
          requiredProducts: const {'wires': 50, 'gears': 30},
          cashReward: 3000.0,
          repReward: 60,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        expect(mfgContract.contractType, ContractType.manufacturing);
        expect(mfgContract.totalRequiredUnits, 80);
      });

      test('canFulfill correctly checks inventory against requiredProducts map', () {
        final contract = CorporateContract(
          id: 'c_multi',
          clientId: 'apex_telecom',
          title: 'Multi Order',
          description: 'Multi product test',
          contractType: ContractType.manufacturing,
          requiredProducts: const {'wires': 20, 'box': 10},
          cashReward: 1000.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        expect(contract.canFulfill(const {}), isFalse);
        expect(contract.canFulfill(const {'wires': 19, 'box': 10}), isFalse);
        expect(contract.canFulfill(const {'wires': 20, 'box': 9}), isFalse);
        expect(contract.canFulfill(const {'wires': 20, 'box': 10}), isTrue);
        expect(contract.canFulfill(const {'wires': 50, 'box': 20}), isTrue);
      });

      test('Contract slots scale by Factory Tier (T1: 3, T2: 3, T3: 4, T4: 5)', () {
        var state = gameService.state.copyWith(factoryTier: 1);
        expect(state.maxContractSlots, 3);

        state = gameService.state.copyWith(factoryTier: 2);
        expect(state.maxContractSlots, 3);

        state = gameService.state.copyWith(factoryTier: 3);
        expect(state.maxContractSlots, 4);

        state = gameService.state.copyWith(factoryTier: 4);
        expect(state.maxContractSlots, 5);
      });
    });

    // =========================================================================
    // 2. Lock & Ship Fulfillment Flow
    // =========================================================================
    group('2. Lock & Ship Fulfillment Flow', () {
      test('Lock & Ship fails if player lacks required inventory', () {
        final contract = CorporateContract(
          id: 'test_contract_insufficient',
          clientId: 'apex_telecom',
          title: 'Order',
          description: 'Test',
          contractType: ContractType.retail,
          requiredProducts: const {'box': 10},
          cashReward: 500.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        gameService.addContractForTest(contract);
        gameService.addProductToInventory('box', 5); // Only 5, needs 10

        final shipped = gameService.shipContract(contract.id);
        expect(shipped, isFalse);

        // Inventory and shipping orders untouched
        expect(gameService.state.products['box'], 5);
        expect(gameService.state.activeShippingOrders.length, 0);
      });

      test('Lock & Ship atomically deducts inventory, creates shipping order, and consumes 1 fleet slot', () {
        final contract = CorporateContract(
          id: 'test_contract_success',
          clientId: 'apex_telecom',
          title: 'Order',
          description: 'Test',
          contractType: ContractType.manufacturing,
          requiredProducts: const {'wires': 20, 'box': 10},
          cashReward: 1200.0,
          repReward: 60,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        gameService.addContractForTest(contract);
        gameService.addProductToInventory('wires', 30);
        gameService.addProductToInventory('box', 15);

        expect(gameService.state.activeShippingOrders.length, 0);

        final shipped = gameService.shipContract(contract.id);
        expect(shipped, isTrue);

        // Atomic inventory deduction
        expect(gameService.state.products['wires'], 10); // 30 - 20 = 10
        expect(gameService.state.products['box'], 5);   // 15 - 10 = 5

        // Contract status transitioned to shipping with order id
        final updatedContract = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
        expect(updatedContract.status, ContractStatus.shipping);
        expect(updatedContract.shippingOrderId, isNotNull);

        // 1 fleet slot consumed
        expect(gameService.state.activeShippingOrders.length, 1);
        final shippingOrder = gameService.state.activeShippingOrders.first;
        expect(shippingOrder.contractId, contract.id);
        expect(shippingOrder.totalRevenue, 1200.0);
      });

      test('Lock & Ship fails if fleet is at maximum capacity', () {
        final contract = CorporateContract(
          id: 'test_contract_fleet_full',
          clientId: 'apex_telecom',
          title: 'Order',
          description: 'Test',
          contractType: ContractType.retail,
          requiredProducts: const {'box': 5},
          cashReward: 500.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        gameService.addContractForTest(contract);
        gameService.addProductToInventory('box', 10);

        // Max out fleet capacity (Tier 1 fleet = 2 slots)
        gameService.addDummyShippingOrderForTest();
        gameService.addDummyShippingOrderForTest();
        expect(gameService.state.canShipMore(gameService.state.activeShippingOrders.length), isFalse);

        final shipped = gameService.shipContract(contract.id);
        expect(shipped, isFalse);

        // Inventory remains intact
        expect(gameService.state.products['box'], 10);
      });
    });

    // =========================================================================
    // 3. Manufacturing 0.75x Shipping Bonus
    // =========================================================================
    group('3. Logistics Timing & Bonuses', () {
      test('Manufacturing contracts receive 0.75x shipping time multiplier', () {
        final retailContract = CorporateContract(
          id: 'c_retail_time',
          clientId: 'apex_telecom',
          title: 'Retail',
          description: 'Test',
          contractType: ContractType.retail,
          requiredProducts: const {'box': 20},
          cashReward: 100.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        final mfgContract = CorporateContract(
          id: 'c_mfg_time',
          clientId: 'apex_telecom',
          title: 'Mfg',
          description: 'Test',
          contractType: ContractType.manufacturing,
          requiredProducts: const {'box': 20},
          cashReward: 100.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        final retailTime = gameService.calculateContractShippingTimeForTest(retailContract);
        final mfgTime = gameService.calculateContractShippingTimeForTest(mfgContract);

        // Manufacturing time must be exactly 0.75x of retail time for identical payloads
        expect(mfgTime, closeTo(retailTime * 0.75, 0.001));
      });
    });

    // =========================================================================
    // 4. Auto-Ship Toggles
    // =========================================================================
    group('4. Auto-Ship Toggles & Execution', () {
      test('Auto-ship retail automatically ships fulfillable retail contracts', () {
        final contract = CorporateContract(
          id: 'auto_ship_retail_1',
          clientId: 'apex_telecom',
          title: 'Retail Order',
          description: 'Test',
          contractType: ContractType.retail,
          requiredProducts: const {'box': 5},
          cashReward: 200.0,
          repReward: 40,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        gameService.addContractForTest(contract);
        gameService.addProductToInventory('box', 10);
        gameService.setAutoShipRetail(true);
        gameService.setAutoShipManufacturing(false);

        expect(gameService.state.activeShippingOrders.length, 0);

        gameService.processContractsTickForTest();

        // Should have automatically shipped
        expect(gameService.state.activeShippingOrders.length, 1);
        final shipped = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
        expect(shipped.status, ContractStatus.shipping);
        expect(gameService.state.products['box'], 5);
      });

      test('Auto-ship manufacturing ignores retail contracts when autoShipRetail is disabled', () {
        final retailContract = CorporateContract(
          id: 'auto_retail_ignored',
          clientId: 'apex_telecom',
          title: 'Retail Order',
          description: 'Test',
          contractType: ContractType.retail,
          requiredProducts: const {'box': 5},
          cashReward: 200.0,
          repReward: 40,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        gameService.addContractForTest(retailContract);
        gameService.addProductToInventory('box', 10);
        gameService.setAutoShipRetail(false);
        gameService.setAutoShipManufacturing(true);

        gameService.processContractsTickForTest();

        // Retail contract must remain available and not shipped
        expect(gameService.state.activeShippingOrders.length, 0);
        final contract = gameService.state.corporateContracts.firstWhere((c) => c.id == retailContract.id);
        expect(contract.status, ContractStatus.available);
      });
    });

    // =========================================================================
    // 5. UI Widgets & Badges
    // =========================================================================
    group('5. UI Presentation & Badges', () {
      testWidgets('CorporateContractCard displays visual badges (🏷️ RETAIL / 🏭 MANUFACTURING)', (tester) async {
        final retailContract = CorporateContract(
          id: 'card_retail',
          clientId: 'apex_telecom',
          title: 'Apex Retail Order',
          description: 'Ship smartphones',
          contractType: ContractType.retail,
          requiredProducts: const {'box': 5},
          cashReward: 500.0,
          repReward: 50,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        final mfgContract = CorporateContract(
          id: 'card_mfg',
          clientId: 'nova_robotics',
          title: 'Nova Bulk Order',
          description: 'Ship wires',
          contractType: ContractType.manufacturing,
          requiredProducts: const {'wires': 50},
          cashReward: 2000.0,
          repReward: 60,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CorporateContractCard(
                    contract: retailContract,
                    gameService: gameService,
                  ),
                  CorporateContractCard(
                    contract: mfgContract,
                    gameService: gameService,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('🏷️ RETAIL'), findsOneWidget);
        expect(find.text('🏭 MANUFACTURING'), findsOneWidget);
      });
    });

    // =========================================================================
    // 6. Tier-Scaled Contract Generation & Safety
    // =========================================================================
    group('6. Tier-Scaled Contract Generation & Safety', () {
      test('Tier 1 Manufacturing contracts are strictly single-product and bounded between 15 and 30 units', () {
        gameService.testSetState(
          gameService.state.copyWith(
            factoryTier: 1,
            unlockedProducts: {'wires', 'box', 'gears'},
          ),
        );

        final client = GameData.getCorporateClient('apex_telecom')!;

        for (int i = 0; i < 50; i++) {
          final contract = gameService.generateManufacturingContractForTest(client);
          expect(contract, isNotNull);
          expect(contract!.contractType, ContractType.manufacturing);
          // Strictly single product line at Tier 1
          expect(contract.requiredProducts.length, 1,
              reason: 'Tier 1 must never have multiple product lines');
          final qty = contract.requiredProducts.values.first;
          expect(qty, inInclusiveRange(15, 30),
              reason: 'Tier 1 items must be bounded between 15 and 30');
          expect(contract.totalRequiredUnits, lessThanOrEqualTo(30),
              reason: 'Tier 1 contracts must never exceed 30 total items');
        }
      });

      test('Tier 2 Manufacturing contracts allow 1-2 product lines and 30-60 units per line', () {
        gameService.testSetState(
          gameService.state.copyWith(
            factoryTier: 2,
            unlockedProducts: {'wires', 'display_screen', 'gears'},
          ),
        );

        final client = GameData.getCorporateClient('apex_telecom')!;

        for (int i = 0; i < 50; i++) {
          final contract = gameService.generateManufacturingContractForTest(client);
          expect(contract, isNotNull);
          expect(contract!.requiredProducts.length, inInclusiveRange(1, 2));
          for (final qty in contract.requiredProducts.values) {
            expect(qty, inInclusiveRange(30, 60));
          }
        }
      });

      test('Tier 3 Manufacturing contracts allow 2-3 product lines and 60-120 units per line', () {
        gameService.testSetState(
          gameService.state.copyWith(
            factoryTier: 3,
            unlockedProducts: {'wires', 'circuits', 'display_screen', 'processor'},
          ),
        );

        final client = GameData.getCorporateClient('apex_telecom')!;

        for (int i = 0; i < 50; i++) {
          final contract = gameService.generateManufacturingContractForTest(client);
          expect(contract, isNotNull);
          expect(contract!.requiredProducts.length, inInclusiveRange(2, 3));
          for (final qty in contract.requiredProducts.values) {
            expect(qty, inInclusiveRange(60, 120));
          }
        }
      });

      test('Tier 4 Manufacturing contracts allow 2-4 product lines and 100-200 units per line', () {
        gameService.testSetState(
          gameService.state.copyWith(
            factoryTier: 4,
            unlockedProducts: {'wires', 'circuits', 'display_screen', 'processor', 'silicon_wafer'},
          ),
        );

        final client = GameData.getCorporateClient('apex_telecom')!;

        for (int i = 0; i < 50; i++) {
          final contract = gameService.generateManufacturingContractForTest(client);
          expect(contract, isNotNull);
          expect(contract!.requiredProducts.length, inInclusiveRange(2, 4));
          for (final qty in contract.requiredProducts.values) {
            expect(qty, inInclusiveRange(100, 200));
          }
        }
      });
    });
  });
}
