import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';

void main() {
  group('B2B Contract Buffer, Shipping Isolation, and Orphan Recovery', () {
    late ProductionGameService gameService;

    setUp(() {
      final testDbName = 'test_b2b_buffer_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    test('Initial state generates 3 available contracts for Tier 1 factory', () {
      final availableContracts = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.available)
          .toList();
      expect(availableContracts.length, 3);
      expect(gameService.pendingContractRefillCount, 0);
    });

    test('Shipping a contract transitions it to shipping, leaving 2 available and 1 refill scheduled', () {
      final available = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.available)
          .toList();
      expect(available.length, 3);

      final contractToShip = available.first;
      // Add required products to inventory to allow shipping
      for (final entry in contractToShip.requiredProducts.entries) {
        gameService.addProductToInventory(entry.key, entry.value);
      }

      final shipped = gameService.shipContract(contractToShip.id);
      expect(shipped, isTrue);

      // Immediately after shipping:
      // 2 available, 1 shipping
      final remainingAvailable = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.available)
          .toList();
      final shippingContracts = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.shipping)
          .toList();

      expect(remainingAvailable.length, 2);
      expect(shippingContracts.length, 1);
      expect(shippingContracts.first.id, contractToShip.id);
      expect(gameService.pendingContractRefillCount, 1);
      expect(gameService.nextContractRefillSeconds, inInclusiveRange(1, 3));
    });

    test('Refill buffer waits 3 seconds before generating the 3rd available contract', () {
      final available = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.available)
          .toList();
      final contractToShip = available.first;
      for (final entry in contractToShip.requiredProducts.entries) {
        gameService.addProductToInventory(entry.key, entry.value);
      }

      final shipped = gameService.shipContract(contractToShip.id);
      expect(shipped, isTrue);
      expect(gameService.state.corporateContracts.where((c) => c.status == ContractStatus.available).length, 2);
      expect(gameService.pendingContractRefillCount, 1);

      // Fast forward 1 second: should still NOT be refilled
      gameService.fastForwardScheduledContractRefills(const Duration(seconds: 1));
      gameService.processContractsTickForTest();
      expect(gameService.state.corporateContracts.where((c) => c.status == ContractStatus.available).length, 2);
      expect(gameService.pendingContractRefillCount, 1);

      // Fast forward 2 more seconds (total 3 seconds): now it should trigger refill
      gameService.fastForwardScheduledContractRefills(const Duration(seconds: 2));
      gameService.processContractsTickForTest();

      final refilledAvailable = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.available)
          .toList();
      final refilledShipping = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.shipping)
          .toList();

      expect(refilledAvailable.length, 3, reason: 'Must restore 3 available contract slots');
      expect(refilledShipping.length, 1, reason: 'Shipped contract remains in shipping status');
      expect(gameService.pendingContractRefillCount, 0);
    });

    test('Shipping contracts do NOT block slot generation or reduce available capacity', () {
      // Create 2 artificial shipping contracts
      final ship1 = CorporateContract(
        id: 'c_ship_1',
        clientId: 'apex_telecom',
        title: 'Ship 1',
        description: 'Test',
        contractType: ContractType.retail,
        requiredProducts: const {'box': 5},
        cashReward: 500,
        repReward: 10,
        status: ContractStatus.shipping,
        shippingOrderId: 'order_1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
      );
      final ship2 = CorporateContract(
        id: 'c_ship_2',
        clientId: 'apex_telecom',
        title: 'Ship 2',
        description: 'Test',
        contractType: ContractType.retail,
        requiredProducts: const {'box': 5},
        cashReward: 500,
        repReward: 10,
        status: ContractStatus.shipping,
        shippingOrderId: 'order_2',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
      );

      gameService.addContractForTest(ship1);
      gameService.addContractForTest(ship2);

      // Process tick with instant refill
      gameService.processContractsTickForTest(instantRefill: true);

      final available = gameService.state.corporateContracts
          .where((c) => c.status == ContractStatus.available)
          .toList();

      // Factory Tier 1 has maxContractSlots = 3.
      // Even with 2 shipping contracts, available must remain 3!
      expect(available.length, 3);
    });

    test('Orphaned shipping contracts recover automatically to completed status', () {
      // Contract is in shipping status, but no active shipping order exists with its ID
      final orphanContract = CorporateContract(
        id: 'c_orphan_1',
        clientId: 'apex_telecom',
        title: 'Orphan Order',
        description: 'Lost courier test',
        contractType: ContractType.retail,
        requiredProducts: const {'box': 5},
        cashReward: 500,
        repReward: 10,
        status: ContractStatus.shipping,
        shippingOrderId: 'lost_order_999',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      gameService.addContractForTest(orphanContract);
      expect(gameService.state.activeShippingOrders.any((o) => o.id == 'lost_order_999'), isFalse);

      // Run contracts tick
      gameService.processContractsTickForTest();

      final updated = gameService.state.corporateContracts.firstWhere((c) => c.id == 'c_orphan_1');
      expect(updated.status, ContractStatus.completed);
      expect(updated.completedAt, isNotNull);
      expect(updated.isCompleted, isTrue);
    });

    test('CorporateContract completedAt is serialized and deserialized properly', () {
      final now = DateTime.now();
      final contract = CorporateContract(
        id: 'c_serial_test',
        clientId: 'apex_telecom',
        title: 'Serialization Test',
        description: 'Testing completedAt',
        contractType: ContractType.manufacturing,
        requiredProducts: const {'wires': 20},
        cashReward: 1000,
        repReward: 50,
        status: ContractStatus.completed,
        shippingOrderId: 'order_123',
        completedAt: now,
        expiresAt: now.add(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(minutes: 10)),
      );

      final map = contract.toMap();
      expect(map['completed_at'], now.toIso8601String());

      final restored = CorporateContract.fromMap(map);
      expect(restored.completedAt, isNotNull);
      expect(restored.isCompleted, isTrue);
      expect(restored.completedAt!.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('Auto-sell log stores up to 50 entries and retains older entries', () {
      for (int i = 0; i < 40; i++) {
        gameService.recordAutoSellDispatchForTest(
          channel: 'b2b',
          productCount: i + 1,
          revenue: (i + 1) * 100.0,
          details: 'Dispatched order #$i',
        );
      }

      expect(gameService.state.recentAutoSoldLogs.length, 40);
      expect(gameService.state.recentAutoSoldLogs.first.details, 'Dispatched order #39');
      expect(gameService.state.recentAutoSoldLogs.last.details, 'Dispatched order #0');
    });
  });
}
