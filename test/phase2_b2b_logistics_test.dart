import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() {
  group('Phase 2: B2B Corporate Contracts & Dynamic Logistics', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    group('Fleet Tiers & Dispatch Slots', () {
      test('All 4 Logistics Fleet Tiers are defined correctly', () {
        expect(GameData.fleetTiers.length, 4);

        final tier1 = GameData.getFleetTier(1);
        expect(tier1.name, 'Courier Bikes');
        expect(tier1.maxSimultaneousShipments, 2);
        expect(tier1.speedMultiplier, 1.0);
        expect(tier1.upgradeCost, 0.0);

        final tier2 = GameData.getFleetTier(2);
        expect(tier2.name, 'Delivery Vans');
        expect(tier2.maxSimultaneousShipments, 4);
        expect(tier2.speedMultiplier, 1.25);
        expect(tier2.upgradeCost, 1500.0);

        final tier3 = GameData.getFleetTier(3);
        expect(tier3.name, 'Freight Trucks');
        expect(tier3.maxSimultaneousShipments, 7);
        expect(tier3.speedMultiplier, 1.6);
        expect(tier3.upgradeCost, 12500.0);

        final tier4 = GameData.getFleetTier(4);
        expect(tier4.name, 'Cargo Planes');
        expect(tier4.maxSimultaneousShipments, 12);
        expect(tier4.speedMultiplier, 2.5);
        expect(tier4.upgradeCost, 75000.0);

        expect(GameData.getNextFleetTier(1)?.tierNumber, 2);
        expect(GameData.getNextFleetTier(4), isNull);
      });

      test('GameState enforces fleet simultaneous shipment limits', () {
        var state = const GameState(
          fleetTier: 1, // max 2 shipments
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
        );

        expect(state.maxSimultaneousShipments, 2);
        expect(state.canShipMore(0), isTrue);
        expect(state.canShipMore(1), isTrue);
        expect(state.canShipMore(2), isFalse);

        // Upgrade state to Tier 2 (max 4 shipments)
        state = state.copyWith(fleetTier: 2);
        expect(state.maxSimultaneousShipments, 4);
        expect(state.canShipMore(2), isTrue);
        expect(state.canShipMore(3), isTrue);
        expect(state.canShipMore(4), isFalse);
      });

      test('Fleet upgrade deducts cash and increments tier in GameService', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        final initialMoney = gameService.state.money;
        gameService.addMoney(2000.0);
        await gameService.setFleetTierForDev(1);

        expect(gameService.state.fleetTier, 1);
        expect(gameService.currentFleetTier.tierNumber, 1);

        // Upgrade from Tier 1 to Tier 2 (cost: 1500)
        final success = await gameService.upgradeFleet();
        expect(success, isTrue);
        expect(gameService.state.fleetTier, 2);
        expect(gameService.state.money, initialMoney + 2000.0 - 1500.0);

        // Trying to upgrade to Tier 3 with insufficient money (cost: 12500)
        final fail = await gameService.upgradeFleet();
        expect(fail, isFalse);
        expect(gameService.state.fleetTier, 2);
      });

      test('sellProduct scales shipping time by fleet speed multiplier', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        gameService.addProductToInventory('box', 10);
        await gameService.setFleetTierForDev(4); // 2.5 multiplier

        final success = gameService.sellProduct('box', 5);
        expect(success, isTrue);

        final activeOrders = gameService.state.activeShippingOrders;
        expect(activeOrders.length, 1);
        // Base box shipping duration for 5 units: 4.0 + (5 * 0.5) = 6.5.
        // Scaled by 2.5 speed multiplier: 6.5 / 2.5 = 2.6.
        expect(activeOrders.first.totalShippingTime, 2.6);
      });
    });

    group('Corporate Clients & Standing Reputation', () {
      test('Corporate clients are defined with key perks and discount materials', () {
        expect(GameData.corporateClients.length, 3);

        final apex = GameData.getCorporateClient('apex_telecom');
        expect(apex?.name, 'Apex Telecom');
        expect(apex?.discountMaterialIds, contains('plastic'));
        expect(apex?.discountMaterialIds, contains('advanced_metals'));

        final solaria = GameData.getCorporateClient('solaria_energy');
        expect(solaria?.name, 'Solaria Energy');
        expect(solaria?.discountMaterialIds, contains('glass'));
        expect(solaria?.discountMaterialIds, contains('basic_metals'));

        final nova = GameData.getCorporateClient('nova_robotics');
        expect(nova?.name, 'Nova Robotics');
        expect(nova?.discountMaterialIds, contains('cardboard'));
        expect(nova?.discountMaterialIds, contains('basic_metals'));
      });

      test('Reputation levels and perk discount scaling', () {
        var state = const GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
        );

        // Neutral standing (< 100)
        expect(state.getReputationLevel('apex_telecom'), 0);
        expect(state.getReputationTitle('apex_telecom'), 'Neutral');
        expect(state.getMaterialDiscount('plastic'), 0.0);
        expect(state.getContractBonusMultiplier('apex_telecom'), 0.0);

        // Partner Tier (100 - 299) -> Level 1 (5% discount)
        state = state.copyWith(clientReputation: {'apex_telecom': 150});
        expect(state.getReputationLevel('apex_telecom'), 1);
        expect(state.getReputationTitle('apex_telecom'), 'Partner');
        expect(state.getMaterialDiscount('plastic'), 0.05);
        expect(state.getContractBonusMultiplier('apex_telecom'), 0.0);

        // Preferred Vendor Tier (300 - 699) -> Level 2 (10% discount, +5% bonus)
        state = state.copyWith(clientReputation: {'apex_telecom': 400});
        expect(state.getReputationLevel('apex_telecom'), 2);
        expect(state.getReputationTitle('apex_telecom'), 'Preferred Vendor');
        expect(state.getMaterialDiscount('plastic'), 0.10);
        expect(state.getContractBonusMultiplier('apex_telecom'), 0.05);

        // Strategic Alliance Tier (700 - 1499) -> Level 3 (15% discount, +10% bonus)
        state = state.copyWith(clientReputation: {'apex_telecom': 750});
        expect(state.getReputationLevel('apex_telecom'), 3);
        expect(state.getReputationTitle('apex_telecom'), 'Strategic Alliance');
        expect(state.getMaterialDiscount('plastic'), closeTo(0.15, 0.0001));
        expect(state.getContractBonusMultiplier('apex_telecom'), 0.10);

        // Executive Partner Tier (1500+) -> Level 4 (20% discount, +15% bonus)
        state = state.copyWith(clientReputation: {'apex_telecom': 1600});
        expect(state.getReputationLevel('apex_telecom'), 4);
        expect(state.getReputationTitle('apex_telecom'), 'Executive Partner');
        expect(state.getMaterialDiscount('plastic'), closeTo(0.20, 0.0001));
        expect(state.getContractBonusMultiplier('apex_telecom'), 0.15);
      });

      test('buyMaterial applies client reputation discount', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        gameService.devAddReputation('apex_telecom', 750); // 15% discount on plastic
        gameService.addMoney(100.0);

        // Buy 10 plastic: normal cost = 20.0, with 15% discount = 17.0
        final initialMoney = gameService.state.money;
        final success = gameService.buyMaterial('plastic', 10);
        expect(success, isTrue);
        expect(gameService.state.materials['plastic'], 10);
        expect(gameService.state.money, initialMoney - 17.0);
      });
    });

    group('Corporate Contracts System', () {
      test('Contract acceptance and state transition', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        gameService.devRefreshContracts();

        expect(gameService.state.corporateContracts.isNotEmpty, isTrue);
        final contract = gameService.state.corporateContracts.first;
        expect(contract.status, ContractStatus.available);

        // Accept contract
        final success = gameService.acceptContract(contract.id);
        expect(success, isTrue);

        final accepted = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
        expect(accepted.status, ContractStatus.active);
      });

      test('Contract partial delivery and full completion awards cash, rep, and shipping history', () async {
        await Future.delayed(const Duration(milliseconds: 50));
        gameService.devRefreshContracts();

        final contract = gameService.state.corporateContracts.first;
        gameService.acceptContract(contract.id);

        // Stock up inventory with target product
        final needed = contract.requiredQuantity;
        gameService.addProductToInventory(contract.targetProductId, needed);
        expect(gameService.state.getProductCount(contract.targetProductId), needed);

        // Partial delivery: 1 item (if requiredQuantity > 1)
        if (needed > 1) {
          final partialSuccess = gameService.deliverToContract(contract.id, 1);
          expect(partialSuccess, isTrue);
          final inProgress = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
          expect(inProgress.deliveredQuantity, 1);
          expect(inProgress.status, ContractStatus.active);
        }

        final initialMoney = gameService.state.money;
        final initialRep = gameService.state.clientReputation[contract.clientId] ?? 0;

        // Fulfill the rest
        final completeSuccess = gameService.fulfillContract(contract.id);
        expect(completeSuccess, isTrue);

        final completed = gameService.state.corporateContracts.firstWhere((c) => c.id == contract.id);
        expect(completed.status, ContractStatus.completed);
        expect(completed.deliveredQuantity, contract.requiredQuantity);

        // Verify rewards awarded
        expect(gameService.state.money, greaterThan(initialMoney));
        expect(gameService.state.clientReputation[contract.clientId], initialRep + contract.repReward);

        // Verify shipping history entry logged
        final history = gameService.state.shippingHistory;
        expect(history.any((h) => h.id == 'contract_${contract.id}'), isTrue);
      });
    });

    group('Database Migration and Persistence Round-Trip', () {
      late String testDbName;

      setUp(() async {
        testDbName = 'test_db_phase2_${DateTime.now().microsecondsSinceEpoch}.db';
        GamePersistenceService.initializeDatabaseFactory(
          testDatabaseName: testDbName,
        );
        final dbPath = await sqflite.getDatabasesPath();
        final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
        await sqflite.databaseFactory.deleteDatabase(fullPath);
      });

      tearDown(() async {
        final dbPath = await sqflite.getDatabasesPath();
        final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
        await sqflite.databaseFactory.deleteDatabase(fullPath);
      });

      test('GamePersistenceService saves and loads fleet tier, reputation, and contracts', () async {
        final persistenceService = GamePersistenceService();

        final contract = CorporateContract(
          id: 'contract_db_test_1',
          clientId: 'nova_robotics',
          title: 'Robotics Sensors',
          description: 'Provide sensory chips',
          targetProductId: 'circuits',
          requiredQuantity: 20,
          deliveredQuantity: 5,
          cashReward: 1500.0,
          repReward: 100,
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
          status: ContractStatus.active,
          createdAt: DateTime.now(),
        );

        final originalState = GameState(
          money: 10000.0,
          fleetTier: 3,
          clientReputation: const {
            'apex_telecom': 120,
            'nova_robotics': 450,
          },
          corporateContracts: [contract],
          autoBuildMachinesOwned: const {},
          autoBuildEnabled: const {},
          lastAutoBuildTick: const {},
          autoBuildProductCapacity: const {},
        );

        await persistenceService.saveGameState(originalState);

        final loadedState = await persistenceService.loadGameState();
        expect(loadedState, isNotNull);
        expect(loadedState.fleetTier, 3);
        expect(loadedState.clientReputation['apex_telecom'], 120);
        expect(loadedState.clientReputation['nova_robotics'], 450);
        expect(loadedState.corporateContracts.length, 1);

        final loadedContract = loadedState.corporateContracts.first;
        expect(loadedContract.id, 'contract_db_test_1');
        expect(loadedContract.clientId, 'nova_robotics');
        expect(loadedContract.targetProductId, 'circuits');
        expect(loadedContract.requiredQuantity, 20);
        expect(loadedContract.deliveredQuantity, 5);
        expect(loadedContract.status, ContractStatus.active);
      });
    });
  });
}
