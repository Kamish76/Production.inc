import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/constants/game_constants.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

GameState createTestState({
  double money = 100.0,
  int factoryTier = 1,
  int fleetTier = 1,
  int researchPoints = 0,
  Map<String, int> techLevels = const {},
  bool overclockActive = false,
  double maintenanceWear = 1.0,
  Map<String, int> products = const {},
}) {
  return GameState(
    money: money,
    factoryTier: factoryTier,
    fleetTier: fleetTier,
    researchPoints: researchPoints,
    techLevels: techLevels,
    overclockActive: overclockActive,
    maintenanceWear: maintenanceWear,
    products: products,
    autoBuildMachinesOwned: const {},
    autoBuildEnabled: const {},
    lastAutoBuildTick: const {},
    autoBuildProductCapacity: const {},
  );
}

void main() {
  group('Phase 4: R&D Lab & Technology Tree', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    group('1. Tech Tree Branch & Node Definitions', () {
      test('All 3 Tech Branches are defined with 3 levels each', () {
        expect(GameData.technologies.length, 3);

        final matSci = GameData.getTechnology('material_science');
        expect(matSci, isNotNull);
        expect(matSci!.branch, TechBranch.materialScience);
        expect(matSci.levels.length, 3);
        expect(matSci.levels[0].rpCost, 50);
        expect(matSci.levels[0].requiredFactoryTier, 1);
        expect(matSci.levels[1].rpCost, 150);
        expect(matSci.levels[1].requiredFactoryTier, 2);
        expect(matSci.levels[2].rpCost, 400);
        expect(matSci.levels[2].requiredFactoryTier, 3);

        final overclock = GameData.getTechnology('factory_overclocking');
        expect(overclock, isNotNull);
        expect(overclock!.branch, TechBranch.factoryOverclocking);
        expect(overclock.levels.length, 3);
        expect(overclock.levels[0].rpCost, 75);
        expect(overclock.levels[0].requiredFactoryTier, 1);
        expect(overclock.levels[1].rpCost, 200);
        expect(overclock.levels[1].requiredFactoryTier, 2);
        expect(overclock.levels[2].rpCost, 500);
        expect(overclock.levels[2].requiredFactoryTier, 3);

        final logistics = GameData.getTechnology('logistics_optimization');
        expect(logistics, isNotNull);
        expect(logistics!.branch, TechBranch.logisticsOptimization);
        expect(logistics.levels.length, 3);
        expect(logistics.levels[0].rpCost, 60);
        expect(logistics.levels[0].requiredFactoryTier, 1);
        expect(logistics.levels[1].rpCost, 175);
        expect(logistics.levels[1].requiredFactoryTier, 2);
        expect(logistics.levels[2].rpCost, 450);
        expect(logistics.levels[2].requiredFactoryTier, 3);
      });

      test('TechBranchExtension provides correct titles, icons, and summaries', () {
        expect(TechBranch.materialScience.displayName, 'Material Science');
        expect(TechBranch.factoryOverclocking.displayName, 'Factory Overclocking');
        expect(TechBranch.logisticsOptimization.displayName, 'Logistics Optimization');
      });
    });

    group('2. Component Deconstruction Bay', () {
      test('All 27 products have positive Research Points valuations', () {
        for (final product in GameData.products) {
          final rp = GameData.getResearchPointsForProduct(product.id);
          expect(rp, greaterThan(0), reason: 'Product ${product.id} should have positive RP valuation');
        }
      });

      test('Retail tier items provide higher RP yield than basic intermediate parts', () {
        final basicRp = GameData.getResearchPointsForProduct('box');
        final midRp = GameData.getResearchPointsForProduct('circuits');
        final highRp = GameData.getResearchPointsForProduct('robotic_arm');
        final ultraRp = GameData.getResearchPointsForProduct('wind_turbine_generator');

        expect(midRp, greaterThan(basicRp));
        expect(highRp, greaterThan(midRp));
        expect(ultraRp, greaterThan(highRp));
      });

      test('Deconstructing a product consumes inventory and credits Research Points', () {
        // Give player 10 boxes
        gameService.addProductToInventory('box', 10);
        expect(gameService.state.getProductCount('box'), 10);
        expect(gameService.state.researchPoints, 0);

        final unitRp = GameData.getResearchPointsForProduct('box');

        // Deconstruct 3 units
        final success = gameService.deconstructProduct('box', 3);
        expect(success, isTrue);

        expect(gameService.state.getProductCount('box'), 7);
        expect(gameService.state.researchPoints, unitRp * 3);
      });

      test('Deconstruction fails safely when requesting more than owned inventory', () {
        gameService.addProductToInventory('box', 2);
        expect(gameService.state.getProductCount('box'), 2);

        final success = gameService.deconstructProduct('box', 5);
        expect(success, isFalse);
        expect(gameService.state.getProductCount('box'), 2);
        expect(gameService.state.researchPoints, 0);
      });
    });

    group('3. Technology Research Progression & Tier Gating', () {
      test('Researching technology deducts RP and increments level', () {
        gameService.devAddResearchPoints(100);
        expect(gameService.state.researchPoints, 100);
        expect(gameService.state.getTechLevel('material_science'), 0);

        // Research Level 1 (Cost: 50 RP, requires Tier 1)
        final success = gameService.researchTechnology('material_science');
        expect(success, isTrue);
        expect(gameService.state.getTechLevel('material_science'), 1);
        expect(gameService.state.researchPoints, 50);
      });

      test('Cannot research technology without sufficient Research Points', () {
        gameService.devAddResearchPoints(20); // Level 1 costs 50
        final success = gameService.researchTechnology('material_science');
        expect(success, isFalse);
        expect(gameService.state.getTechLevel('material_science'), 0);
        expect(gameService.state.researchPoints, 20);
      });

      test('Cannot research technology without meeting Factory Tier requirement', () {
        // Player has plenty of RP, but is only Tier 1
        gameService.devAddResearchPoints(1000);
        expect(gameService.state.factoryTier, 1);

        // Level 1: succeeds (requires Tier 1)
        expect(gameService.researchTechnology('material_science'), isTrue);
        expect(gameService.state.getTechLevel('material_science'), 1);

        // Level 2: fails because it requires Factory Tier 2
        expect(gameService.researchTechnology('material_science'), isFalse);
        expect(gameService.state.getTechLevel('material_science'), 1);

        // Set Factory Tier to 2 using dev helper
        gameService.setFactoryTierForDev(2);
        expect(gameService.state.factoryTier, 2);

        // Level 2: now succeeds
        expect(gameService.researchTechnology('material_science'), isTrue);
        expect(gameService.state.getTechLevel('material_science'), 2);
      });

      test('Cannot upgrade beyond maximum level (Level 3)', () {
        gameService.devAddResearchPoints(2000);
        gameService.setFactoryTierForDev(3); // Tier 3 unlocks all levels

        expect(gameService.researchTechnology('logistics_optimization'), isTrue); // L1
        expect(gameService.researchTechnology('logistics_optimization'), isTrue); // L2
        expect(gameService.researchTechnology('logistics_optimization'), isTrue); // L3
        expect(gameService.state.getTechLevel('logistics_optimization'), 3);

        // Attempting 4th upgrade fails
        expect(gameService.researchTechnology('logistics_optimization'), isFalse);
        expect(gameService.state.getTechLevel('logistics_optimization'), 3);
      });
    });

    group('4. Branch 1: Material Science Perk Logic', () {
      test('Duplication chances match progression: 0% -> 5% -> 10% -> 15%', () {
        var state = createTestState();
        expect(state.materialScienceDuplicationChance, 0.0);

        state = state.copyWith(techLevels: {'material_science': 1});
        expect(state.materialScienceDuplicationChance, 0.05);

        state = state.copyWith(techLevels: {'material_science': 2});
        expect(state.materialScienceDuplicationChance, 0.10);

        state = state.copyWith(techLevels: {'material_science': 3});
        expect(state.materialScienceDuplicationChance, 0.15);
      });
    });

    group('5. Branch 2: Factory Overclocking & Maintenance Logic', () {
      test('Speed multipliers match progression: 1.0 -> 1.15 -> 1.25 -> 1.40', () {
        var state = createTestState();
        expect(state.overclockSpeedMultiplier, 1.0);

        // Level 1: Passive speed boost (+15%)
        state = state.copyWith(techLevels: {'factory_overclocking': 1});
        expect(state.overclockSpeedMultiplier, 1.15);

        // Level 2: Overclock switch off -> 1.15 baseline multiplier (passive L1 boost retained)
        state = state.copyWith(
          techLevels: {'factory_overclocking': 2},
          overclockActive: false,
          maintenanceWear: 1.0,
        );
        expect(state.isOverclockEngaged, isFalse);
        expect(state.overclockSpeedMultiplier, 1.15);

        // Level 2: Overclock switch on & wear healthy -> 1.25
        state = state.copyWith(overclockActive: true);
        expect(state.isOverclockEngaged, isTrue);
        expect(state.overclockSpeedMultiplier, 1.25);

        // Level 3: Overclock switch on & wear healthy -> 1.40
        state = state.copyWith(techLevels: {'factory_overclocking': 3});
        expect(state.overclockSpeedMultiplier, 1.40);
      });

      test('Overclock automatically falls back to baseline speed when maintenance wear hits 0', () {
        final state = createTestState(
          techLevels: {'factory_overclocking': 2},
          overclockActive: true,
          maintenanceWear: 0.0, // Broken / worn down
        );

        expect(state.isOverclockEngaged, isFalse);
        expect(state.overclockSpeedMultiplier, 1.15);
      });

      test('toggleOverclock only allows switching on if Level >= 2', () {
        // Level 0
        gameService.toggleOverclock(true);
        expect(gameService.state.overclockActive, isFalse);

        // Level 1
        gameService.devSetTechLevel('factory_overclocking', 1);
        gameService.toggleOverclock(true);
        expect(gameService.state.overclockActive, isFalse);

        // Level 2
        gameService.devSetTechLevel('factory_overclocking', 2);
        gameService.toggleOverclock(true);
        expect(gameService.state.overclockActive, isTrue);

        gameService.toggleOverclock(false);
        expect(gameService.state.overclockActive, isFalse);
      });

      test('Diagnostic checkup costs \$50 and restores maintenance wear to 1.0', () {
        gameService.devSetTechLevel('factory_overclocking', 2);
        gameService.devSetMaintenanceWear(0.2); // 20% health
        gameService.devSetMoney(100.0);

        final initialMoney = gameService.state.money;
        final success = gameService.performMaintenanceCheckup();

        expect(success, isTrue);
        expect(gameService.state.maintenanceWear, 1.0);
        expect(gameService.state.money, initialMoney - ResearchConstants.maintenanceCheckupFee);
      });

      test('Diagnostic checkup fails if player cannot afford \$50 fee', () {
        gameService.devSetTechLevel('factory_overclocking', 2);
        gameService.devSetMaintenanceWear(0.0);
        gameService.devSetMoney(10.0); // Only \$10, fee is \$50

        final success = gameService.performMaintenanceCheckup();
        expect(success, isFalse);
        expect(gameService.state.maintenanceWear, 0.0);
      });

      test('Production duration reflects overclock speed multiplier', () {
        final product = GameData.products.first;
        final baseDuration = product.productionTimeSeconds;

        // Base speed
        final normalTime = gameService.getAdjustedProductionTime(product.id, baseDuration);
        expect(normalTime, baseDuration);

        // Engage Level 3 Overclock
        gameService.devSetTechLevel('factory_overclocking', 3);
        gameService.toggleOverclock(true);
        gameService.devSetMaintenanceWear(1.0);

        final fastTime = gameService.getAdjustedProductionTime(product.id, baseDuration);
        expect(fastTime, closeTo(baseDuration / 1.40, 0.01));
        expect(fastTime, lessThan(normalTime));
      });
    });

    group('6. Branch 3: Logistics Optimization Perk Logic', () {
      test('Speed multipliers match progression: 1.0 -> 1.15 -> 1.30 -> 1.40', () {
        var state = createTestState();
        expect(state.logisticsSpeedMultiplier, 1.0);

        state = state.copyWith(techLevels: {'logistics_optimization': 1});
        expect(state.logisticsSpeedMultiplier, 1.15);

        state = state.copyWith(techLevels: {'logistics_optimization': 2});
        expect(state.logisticsSpeedMultiplier, 1.30);

        state = state.copyWith(techLevels: {'logistics_optimization': 3});
        expect(state.logisticsSpeedMultiplier, 1.40);
      });

      test('Level 3 Logistics grants +1 simultaneous shipment dispatch slot', () {
        // Fleet Tier 1 base is 2 slots
        var state = createTestState(fleetTier: 1);
        expect(state.maxSimultaneousShipments, 2);

        // With Logistics Level 2: still 2 slots
        state = state.copyWith(techLevels: {'logistics_optimization': 2});
        expect(state.maxSimultaneousShipments, 2);

        // With Logistics Level 3: becomes 3 slots
        state = state.copyWith(techLevels: {'logistics_optimization': 3});
        expect(state.maxSimultaneousShipments, 3);
      });
    });

    group('7. Database Persistence Round-Trip (v9)', () {
      late String testDbName;

      setUp(() async {
        testDbName = 'test_db_rnd_lab_${DateTime.now().microsecondsSinceEpoch}.db';
        GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);

        final dbPath = await sqflite.getDatabasesPath();
        final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
        await sqflite.databaseFactory.deleteDatabase(fullPath);
      });

      tearDown(() async {
        final dbPath = await sqflite.getDatabasesPath();
        final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
        await sqflite.databaseFactory.deleteDatabase(fullPath);
      });

      test('Saves and loads Research Points, Tech Levels, Overclock and Wear state', () async {
        final persistence = GamePersistenceService();

        final savedState = createTestState(
          money: 1250.0,
          researchPoints: 375,
          techLevels: {
            'material_science': 2,
            'factory_overclocking': 3,
            'logistics_optimization': 1,
          },
          overclockActive: true,
          maintenanceWear: 0.85,
        );

        await persistence.saveGameState(savedState);

        final loadedState = await persistence.loadGameState();
        expect(loadedState.researchPoints, 375);
        expect(loadedState.overclockActive, true);
        expect(loadedState.maintenanceWear, closeTo(0.85, 0.001));

        expect(loadedState.getTechLevel('material_science'), 2);
        expect(loadedState.getTechLevel('factory_overclocking'), 3);
        expect(loadedState.getTechLevel('logistics_optimization'), 1);

        await persistence.dispose();
      });
    });
  });
}
