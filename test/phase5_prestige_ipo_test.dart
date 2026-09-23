import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/constants/game_constants.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/product_unlock_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

GameState createTestState({
  double money = 100.0,
  int factoryTier = 1,
  int fleetTier = 1,
  int prestigeCount = 0,
  int goldenShares = 0,
  int lifetimeGoldenShares = 0,
  double lifetimeRevenue = 0.0,
  int lifetimeUnitsShipped = 0,
  Set<String> unlockedPrestigePerks = const {},
  Map<String, int> materials = const {},
  Map<String, int> products = const {},
  int autoBuyMachinesOwned = 0,
  Map<String, int> autoBuildMachinesOwned = const {},
  List<ShippingHistory> shippingHistory = const [],
}) {
  return GameState(
    money: money,
    factoryTier: factoryTier,
    fleetTier: fleetTier,
    prestigeCount: prestigeCount,
    goldenShares: goldenShares,
    lifetimeGoldenShares: lifetimeGoldenShares,
    lifetimeRevenue: lifetimeRevenue,
    lifetimeUnitsShipped: lifetimeUnitsShipped,
    unlockedPrestigePerks: unlockedPrestigePerks,
    materials: materials,
    products: products,
    autoBuyMachinesOwned: autoBuyMachinesOwned,
    autoBuildMachinesOwned: autoBuildMachinesOwned,
    shippingHistory: shippingHistory,
    autoBuildEnabled: const {},
    lastAutoBuildTick: const {},
    autoBuildProductCapacity: const {},
  );
}

void main() {
  group('Phase 5: Prestige / Initial Public Offering (IPO) System', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    group('1. Prestige Constants & Catalog Definitions', () {
      test('Thresholds and conversion rates match design specifications', () {
        expect(PrestigeConstants.ipoNetWorthThreshold, 1000000.0);
        expect(PrestigeConstants.goldenShareNetWorthUnit, 100000.0);
        expect(PrestigeConstants.goldenShareUnitsShippedUnit, 100);
        expect(PrestigeConstants.speedBoostPerGoldenShare, 0.10);
        expect(PrestigeConstants.angelSeedCapitalAmount, 2500.0);
        expect(PrestigeConstants.quantumWarpSpeedBonus, 1.25);
      });

      test('All 4 Venture Perks are cataloged with distinct perks and costs', () {
        expect(GameData.prestigePerks.length, 4);

        final instant = GameData.getPrestigePerk(PrestigeConstants.perkInstantMachines);
        expect(instant, isNotNull);
        expect(instant!.goldenShareCost, 5);

        final blueprints = GameData.getPrestigePerk(PrestigeConstants.perkPrototypeBlueprints);
        expect(blueprints, isNotNull);
        expect(blueprints!.goldenShareCost, 10);

        final angel = GameData.getPrestigePerk(PrestigeConstants.perkAngelSeedCapital);
        expect(angel, isNotNull);
        expect(angel!.goldenShareCost, 8);

        final warp = GameData.getPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch);
        expect(warp, isNotNull);
        expect(warp!.goldenShareCost, 12);
      });

      test('Prototype products exist with valid values and prototype flags', () {
        final qProcessor = GameData.getProduct('quantum_processor');
        expect(qProcessor, isNotNull);
        expect(qProcessor!.isPrototype, true);
        expect(qProcessor.sellPrice, 1800.0);

        final qCore = GameData.getProduct('quantum_core');
        expect(qCore, isNotNull);
        expect(qCore!.isPrototype, true);
        expect(qCore.sellPrice, 4200.0);

        final satellite = GameData.getProduct('orbital_satellite');
        expect(satellite, isNotNull);
        expect(satellite!.isPrototype, true);
        expect(satellite.sellPrice, 18500.0);
      });
    });

    group('2. Corporate Net Worth Valuation', () {
      test('Calculates valuation from cash, materials, products, and machine investments', () {
        // Material costs: cardboard = $1 (100 -> $100), plastic = $2 (50 -> $100) -> $200
        // Products: box = $4 (50 -> $200)
        // Machines: 2 auto-buy ($1,000 ea) + 1 auto-build ($1,000 ea) = $3,000
        // Cash: $5,000
        // Total Net Worth = $5,000 + $200 + $200 + $3,000 = $8,400
        final state = createTestState(
          money: 5000.0,
          materials: {'cardboard': 100, 'plastic': 50},
          products: {'box': 50},
          autoBuyMachinesOwned: 2,
          autoBuildMachinesOwned: {'basicParts': 1},
        );

        expect(state.totalMaterialsMarketValue, 200.0);
        expect(state.totalProductsMarketValue, 200.0);
        expect(state.totalMachineCapitalValue, 3000.0);
        expect(state.netWorth, 8400.0);
      });
    });

    group('3. IPO Eligibility & Golden Shares Yield', () {
      test('Cannot initiate IPO below \$1,000,000 net worth', () {
        final state = createTestState(money: 999999.0);
        expect(state.canInitiateIPO, false);
        expect(state.pendingGoldenShares, 0);
      });

      test('Qualifies for IPO at \$1,000,000 and calculates Golden Shares accurately', () {
        // Net worth: $1,250,000 -> floor(1,250,000 / 100,000) = 12 shares
        // Shipped units: 350 -> floor(350 / 100) = 3 shares
        // Total pending: 12 + 3 = 15 Golden Shares
        final history = [
          ShippingHistory(
            id: 'order_1',
            items: const [
              ShippingItem(productId: 'speaker', quantity: 200),
              ShippingItem(productId: 'camera', quantity: 150),
            ],
            completedTime: DateTime.now(),
            totalRevenue: 19750.0,
          ),
        ];

        final state = createTestState(
          money: 1250000.0,
          shippingHistory: history,
        );

        expect(state.canInitiateIPO, true);
        expect(state.currentRunUnitsShipped, 350);
        expect(state.currentRunRevenue, 19750.0);
        expect(state.pendingGoldenShares, 15);
      });
    });

    group('4. Build Speed Multiplier Mechanics', () {
      test('Golden Shares grant +10% speed per share', () {
        final state0 = createTestState(goldenShares: 0);
        expect(state0.prestigeSpeedMultiplier, 1.0);

        final state5 = createTestState(goldenShares: 5);
        expect(state5.prestigeSpeedMultiplier, 1.5);

        final state10 = createTestState(goldenShares: 10);
        expect(state10.prestigeSpeedMultiplier, 2.0);
      });

      test('Production duration scales down with prestigeSpeedMultiplier in service', () {
        // Base wires production time: 5.0s
        final baseDuration = gameService.getAdjustedProductionTime('wires', 5.0);
        expect(baseDuration, 5.0);

        // Grant 10 Golden Shares (+100% speed -> 2.0x speed multiplier)
        gameService.devAddGoldenShares(10);
        expect(gameService.state.goldenShares, 10);
        expect(gameService.state.prestigeSpeedMultiplier, 2.0);

        final boostedDuration = gameService.getAdjustedProductionTime('wires', 5.0);
        expect(boostedDuration, 2.5); // 5.0 / 2.0 = 2.5s
      });
    });

    group('5. Venture Perks Integration', () {
      test('Unlocking perks deducts Golden Shares and marks perk as owned', () async {
        gameService.devAddGoldenShares(10);
        expect(gameService.state.goldenShares, 10);

        // Cannot unlock non-existent perk
        final fakeSuccess = await gameService.unlockPrestigePerk('fake_perk');
        expect(fakeSuccess, false);

        // Cannot unlock when shares insufficient
        final warpPerk = GameData.getPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch)!;
        expect(warpPerk.goldenShareCost, 12);
        final cannotAfford = await gameService.unlockPrestigePerk(warpPerk.id);
        expect(cannotAfford, false);

        // Successfully unlock Instant Machines (cost: 5)
        final success = await gameService.unlockPrestigePerk(PrestigeConstants.perkInstantMachines);
        expect(success, true);
        expect(gameService.state.goldenShares, 5);
        expect(gameService.state.hasPrestigePerk(PrestigeConstants.perkInstantMachines), true);

        // Cannot unlock already owned perk
        final reUnlock = await gameService.unlockPrestigePerk(PrestigeConstants.perkInstantMachines);
        expect(reUnlock, false);
      });

      test('Quantum Warp Dispatch perk reduces shipping time and increases simultaneous slots', () async {
        // Fleet Tier 1 starts with 2 simultaneous shipments
        expect(gameService.state.maxSimultaneousShipments, 2);

        gameService.devAddGoldenShares(15);
        await gameService.unlockPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch);

        expect(gameService.state.hasPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch), true);
        expect(gameService.state.maxSimultaneousShipments, 3); // Fleet Tier 1 (2) + Warp Bonus (1) = 3
        expect(gameService.state.logisticsSpeedMultiplier, closeTo(1.25, 0.001));
      });

      test('Prototype Blueprints perk unlocks quantum prototypes based on Factory Tier', () async {
        // Without perk, prototypes are locked even with funds
        gameService.devSetMoney(100000.0);
        ProductUnlockService.clearCache();
        expect(gameService.state.isProductUnlocked('quantum_processor'), false);
        expect(gameService.state.isProductUnlocked('orbital_satellite'), false);

        // Unlock Prototype Blueprints perk
        gameService.devAddGoldenShares(10);
        await gameService.unlockPrestigePerk(PrestigeConstants.perkPrototypeBlueprints);
        expect(gameService.state.hasPrestigePerk(PrestigeConstants.perkPrototypeBlueprints), true);

        // At Factory Tier 1, intermediate and complex prototypes are gated by factory tier
        expect(gameService.state.factoryTier, 1);
        ProductUnlockService.clearCache();
        expect(gameService.state.isProductUnlocked('quantum_processor'), false);

        // Set Factory Tier 2 (Light Assembly): unlocks Intermediate parts including Quantum Processor
        await gameService.setFactoryTierForDev(2);
        expect(gameService.state.factoryTier, 2);
        ProductUnlockService.clearCache();
        expect(gameService.state.isProductUnlocked('quantum_processor'), true);

        // Set Factory Tier 3 (Precision Fab): unlocks Complex parts including Quantum Core
        await gameService.setFactoryTierForDev(3);
        expect(gameService.state.factoryTier, 3);
        ProductUnlockService.clearCache();
        expect(gameService.state.isProductUnlocked('quantum_core'), true);
        expect(gameService.state.isProductUnlocked('orbital_satellite'), false);

        // Set Factory Tier 4 (Megafactory): unlocks Orbital Satellite flagship
        await gameService.setFactoryTierForDev(4);
        expect(gameService.state.factoryTier, 4);
        ProductUnlockService.clearCache();
        expect(gameService.state.isProductUnlocked('orbital_satellite'), true);
      });
    });

    group('6. Full IPO Execution & Reset/Persist Boundaries', () {
      test('IPO resets run inventory/tier but preserves Golden Shares and lifetime stats', () async {
        // Set up rich corporate state
        await gameService.setFactoryTierForDev(2);
        await gameService.setFleetTierForDev(2);

        // Set money to exactly $1.5M
        gameService.devSetMoney(1500000.0);

        // Add 100 units shipped
        final testOrder = ShippingHistory(
          id: 'hist_1',
          items: const [ShippingItem(productId: 'wires', quantity: 100)],
          completedTime: DateTime.now(),
          totalRevenue: 400.0,
        );
        gameService.devSetShippingHistory([testOrder]);

        expect(gameService.state.canInitiateIPO, true);
        // $1.5M = 15 shares, 100 units = 1 share -> 16 shares
        expect(gameService.state.pendingGoldenShares, 16);

        // Initiate IPO
        final success = await gameService.initiateIPO();
        expect(success, true);

        final postIpoState = gameService.state;

        // Reset boundaries
        expect(postIpoState.money, 100.0); // Standard starting cash (no Angel perk yet)
        expect(postIpoState.materials.isEmpty, true);
        expect(postIpoState.products.isEmpty, true);
        expect(postIpoState.activeProductions.isEmpty, true);
        expect(postIpoState.activeShippingOrders.isEmpty, true);
        expect(postIpoState.factoryTier, 1);
        expect(postIpoState.fleetTier, 1);
        expect(postIpoState.researchPoints, 0);

        // Persist boundaries
        expect(postIpoState.prestigeCount, 1);
        expect(postIpoState.goldenShares, 16);
        expect(postIpoState.lifetimeGoldenShares, 16);
        expect(postIpoState.lifetimeUnitsShipped, 100);
        expect(postIpoState.lifetimeRevenue, 400.0);
        expect(postIpoState.prestigeSpeedMultiplier, closeTo(2.6, 0.001)); // 1.0 + 16 * 0.1 = 2.6
      });

      test('Angel Investor Seed Capital grants \$2,500 startup cash on subsequent IPOs', () async {
        // Unlock Angel perk
        gameService.devAddGoldenShares(10);
        await gameService.unlockPrestigePerk(PrestigeConstants.perkAngelSeedCapital);
        expect(gameService.state.hasPrestigePerk(PrestigeConstants.perkAngelSeedCapital), true);

        // Give enough cash to qualify for IPO
        gameService.devSetMoney(1000000.0);
        expect(gameService.state.canInitiateIPO, true);

        await gameService.initiateIPO();

        // Starting cash should be $2,500.00 instead of $100.00
        expect(gameService.state.money, 2500.0);
        expect(gameService.state.hasPrestigePerk(PrestigeConstants.perkAngelSeedCapital), true);
      });
    });

    group('7. Database Persistence Round-Trip (v10)', () {
      late String testDbName;

      setUp(() async {
        testDbName = 'test_db_prestige_${DateTime.now().microsecondsSinceEpoch}.db';
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

      test('Saves and loads all Phase 5 prestige stats and perks from SQLite v10', () async {
        final persistence = GamePersistenceService();

        final savedState = createTestState(
          money: 2500.0,
          prestigeCount: 3,
          goldenShares: 24,
          lifetimeGoldenShares: 45,
          lifetimeRevenue: 2850000.0,
          lifetimeUnitsShipped: 4200,
          unlockedPrestigePerks: {
            PrestigeConstants.perkInstantMachines,
            PrestigeConstants.perkAngelSeedCapital,
            PrestigeConstants.perkPrototypeBlueprints,
          },
        );

        await persistence.saveGameState(savedState);

        final loadedState = await persistence.loadGameState();

        expect(loadedState.prestigeCount, 3);
        expect(loadedState.goldenShares, 24);
        expect(loadedState.lifetimeGoldenShares, 45);
        expect(loadedState.lifetimeRevenue, 2850000.0);
        expect(loadedState.lifetimeUnitsShipped, 4200);
        expect(loadedState.unlockedPrestigePerks.length, 3);
        expect(loadedState.hasPrestigePerk(PrestigeConstants.perkInstantMachines), true);
        expect(loadedState.hasPrestigePerk(PrestigeConstants.perkAngelSeedCapital), true);
        expect(loadedState.hasPrestigePerk(PrestigeConstants.perkPrototypeBlueprints), true);
        expect(loadedState.hasPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch), false);

        await persistence.dispose();
      });

      test('resetRunDataForPrestige clears inventory while keeping prestige metrics', () async {
        final persistence = GamePersistenceService();

        final initial = createTestState(
          money: 2500.0,
          materials: {'plastic': 500},
          products: {'wires': 200},
          prestigeCount: 2,
          goldenShares: 18,
          lifetimeGoldenShares: 30,
          lifetimeRevenue: 1500000.0,
          lifetimeUnitsShipped: 1200,
          unlockedPrestigePerks: {PrestigeConstants.perkAngelSeedCapital},
        );

        await persistence.saveGameState(initial);
        await persistence.resetRunDataForPrestige(initial);

        final loaded = await persistence.loadGameState();
        expect(loaded.money, 2500.0);
        expect(loaded.materials.isEmpty, true);
        expect(loaded.products.isEmpty, true);
        expect(loaded.prestigeCount, 2);
        expect(loaded.goldenShares, 18);
        expect(loaded.lifetimeGoldenShares, 30);
        expect(loaded.hasPrestigePerk(PrestigeConstants.perkAngelSeedCapital), true);

        await persistence.dispose();
      });
    });
  });
}
