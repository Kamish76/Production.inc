import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/constants/game_constants.dart';
import 'package:game1/screens/build_products_screen.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/product_unlock_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/machine_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductionGameService gameService;

  setUp(() {
    final testDbName =
        'test_db_retail_${DateTime.now().microsecondsSinceEpoch}.db';
    GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName);
    gameService = ProductionGameService(testMode: true);
  });

  tearDown(() async {
    gameService.dispose();
  });

  group('Retail Auto-Build Machine: Economy, Pricing & Salvage', () {
    test('Machine price scales dynamically according to 1000 * 1.15^count', () {
      expect(gameService.getMachinePrice('retail', 0), 1000.0);
      expect(gameService.getMachinePrice('retail', 1), closeTo(1150.0, 0.01));
      expect(gameService.getMachinePrice('retail', 2), closeTo(1322.5, 0.01));
      expect(gameService.getMachinePrice('retail', 3), closeTo(1520.875, 0.01));

      for (int n = 0; n <= 8; n++) {
        final expected = 1000.0 * math.pow(1.15, n);
        expect(
          gameService.getMachinePrice('retail', n),
          closeTo(expected, 0.01),
        );
      }
    });

    test('buyAutoBuildMachine for retail tier deducts cost and increments owned count', () async {
      gameService.addMoney(50000.0);
      final initialMoney = gameService.state.money;
      expect(gameService.state.autoBuildMachinesOwned['retail'] ?? 0, 0);

      final price0 = gameService.getMachinePrice('retail', 0);
      final success = await gameService.buyAutoBuildMachine('retail');

      expect(success, isTrue);
      expect(gameService.state.autoBuildMachinesOwned['retail'], 1);
      expect(gameService.state.money, closeTo(initialMoney - price0, 0.01));

      final price1 = gameService.getMachinePrice('retail', 1);
      final success2 = await gameService.buyAutoBuildMachine('retail');

      expect(success2, isTrue);
      expect(gameService.state.autoBuildMachinesOwned['retail'], 2);
      expect(gameService.state.money, closeTo(initialMoney - price0 - price1, 0.01));
    });

    test('buyAutoBuildMachine for retail tier fails if player has insufficient funds', () async {
      // Set balance lower than 1000
      gameService.testSetState(gameService.state.copyWith(money: 50.0));
      expect(gameService.state.money, 50.0);

      final success = await gameService.buyAutoBuildMachine('retail');
      expect(success, isFalse);
      expect(gameService.state.autoBuildMachinesOwned['retail'] ?? 0, 0);
    });

    test('buyAutoBuildMachine enforces factory tier machine limit', () async {
      gameService.addMoney(1000000.0);
      final limit = gameService.getMachineTierLimit('retail'); // 10 at Tier 1
      expect(limit, 10);

      for (int i = 0; i < limit; i++) {
        final success = await gameService.buyAutoBuildMachine('retail');
        expect(success, isTrue);
      }

      expect(gameService.state.autoBuildMachinesOwned['retail'], limit);

      // Attempting to buy one more should fail
      final blocked = await gameService.buyAutoBuildMachine('retail');
      expect(blocked, isFalse);
      expect(gameService.state.autoBuildMachinesOwned['retail'], limit);
    });

    test('salvageMachine refunds 50% of the previous machine cost and decrements count', () async {
      gameService.addMoney(10000.0);
      await gameService.buyAutoBuildMachine('retail');
      await gameService.buyAutoBuildMachine('retail');
      expect(gameService.state.autoBuildMachinesOwned['retail'], 2);

      final balanceBefore = gameService.state.money;
      final expectedRefund = gameService.getMachineSalvageValue('retail', 2);
      expect(expectedRefund, (0.5 * gameService.getMachinePrice('retail', 1)).floorToDouble());

      final salvageSuccess = await gameService.salvageMachine('retail');
      expect(salvageSuccess, isTrue);
      expect(gameService.state.autoBuildMachinesOwned['retail'], 1);
      expect(gameService.state.money, closeTo(balanceBefore + expectedRefund, 0.01));
    });
  });

  group('Retail Auto-Build Machine: High-Throughput Upgrades', () {
    test('Default throughput level is 1 and scales sequentially up to level 5', () async {
      expect(gameService.getAutoBuildThroughputLevel('retail'), 1);

      gameService.addMoney(50000.0);
      final cost1 = gameService.getAutoBuildThroughputUpgradeCost('retail');
      expect(cost1, 1000.0);

      final upgraded1 = await gameService.upgradeAutoBuildThroughput('retail');
      expect(upgraded1, isTrue);
      expect(gameService.getAutoBuildThroughputLevel('retail'), 2);

      final cost2 = gameService.getAutoBuildThroughputUpgradeCost('retail');
      expect(cost2, closeTo(1150.0, 0.01));

      final upgraded2 = await gameService.upgradeAutoBuildThroughput('retail');
      expect(upgraded2, isTrue);
      expect(gameService.getAutoBuildThroughputLevel('retail'), 3);
    });

    test('Throughput upgrade fails when funds are insufficient or max level 5 reached', () async {
      gameService.setAutoBuildThroughputLevel('retail', 5);
      expect(gameService.getAutoBuildThroughputLevel('retail'), 5);

      final upgraded = await gameService.upgradeAutoBuildThroughput('retail');
      expect(upgraded, isFalse);
      expect(gameService.getAutoBuildThroughputLevel('retail'), 5);
    });
  });

  group('Retail Auto-Build Machine: Production Execution & Queue', () {
    test('AutoBuildConstants contains retail product order with all 12 retail goods', () {
      final retailOrder = AutoBuildConstants.productOrderByTier['retail'];
      expect(retailOrder, isNotNull);
      expect(retailOrder!.length, 12);
      expect(retailOrder.first, 'speaker');
      expect(retailOrder.contains('speaker'), isTrue);
      expect(retailOrder.contains('wall_clock'), isTrue);
      expect(retailOrder.contains('power_bank'), isTrue);
      expect(retailOrder.contains('solar_panel'), isTrue);
      expect(retailOrder.contains('toy_robot'), isTrue);
      expect(retailOrder.contains('orbital_satellite'), isTrue);
      expect(retailOrder.contains('camera'), isTrue);
      expect(retailOrder.contains('cleaning_drone'), isTrue);
      expect(retailOrder.contains('home_powerwall'), isTrue);
      expect(retailOrder.contains('smartphone'), isTrue);
      expect(retailOrder.contains('robotic_arm'), isTrue);
      expect(retailOrder.contains('wind_turbine_generator'), isTrue);
    });

    test('Auto-build tick automatically builds unlocked retail products when components exist', () async {
      final initialUnlocked = Set<String>.from(gameService.state.unlockedProducts)..add('speaker');
      final unlockMap = Map<String, bool>.from(gameService.state.productUnlockStatus);
      unlockMap['speaker'] = true;

      gameService.testSetState(gameService.state.copyWith(
        factoryTier: 4,
        unlockedProducts: initialUnlocked,
        productUnlockStatus: unlockMap,
        products: {
          'wires': 10,
          'circuits': 5,
          'sound_driver': 5,
          'enclosure_plastic': 5,
          'box': 10,
        },
        autoBuildMachinesOwned: {'retail': 1},
        autoBuildEnabled: {'retail': true},
        lastAutoBuildTick: {'retail': null},
      ));
      ProductUnlockService.clearCache();

      expect(gameService.isProductUnlocked('speaker'), isTrue);

      // Call updateProductions() which invokes _processAutoBuildTicks()
      gameService.updateProductions();

      // Speaker requires: wires: 2, circuits: 1, sound_driver: 1, enclosure_plastic: 1, box: 2
      expect(gameService.state.activeProductions.any((p) => p.productId == 'speaker'), isTrue);
      expect(gameService.state.products['wires'], 8); // 10 - 2
      expect(gameService.state.products['circuits'], 4); // 5 - 1
      expect(gameService.state.products['sound_driver'], 4); // 5 - 1
      expect(gameService.state.products['enclosure_plastic'], 4); // 5 - 1
      expect(gameService.state.products['box'], 8); // 10 - 2
    });

    test('Auto-build skips locked retail products and builds next unlocked product', () async {
      // Keep 'speaker' locked, unlock 'power_bank'
      final initialUnlocked = Set<String>.from(gameService.state.unlockedProducts)
        ..remove('speaker')
        ..add('power_bank');
      final unlockMap = Map<String, bool>.from(gameService.state.productUnlockStatus);
      unlockMap['speaker'] = false;
      unlockMap['power_bank'] = true;

      gameService.testSetState(gameService.state.copyWith(
        factoryTier: 4,
        unlockedProducts: initialUnlocked,
        productUnlockStatus: unlockMap,
        materials: {'basic_metals': 5},
        products: {
          'circuits': 5,
          'enclosure_plastic': 5,
          'wires': 5,
          'battery': 5,
          'box': 5,
        },
        autoBuildMachinesOwned: {'retail': 1},
        autoBuildEnabled: {'retail': true},
        lastAutoBuildTick: {'retail': null},
      ));
      ProductUnlockService.clearCache();

      expect(gameService.isProductUnlocked('speaker'), isFalse);
      expect(gameService.isProductUnlocked('power_bank'), isTrue);

      gameService.updateProductions();

      // Speaker was skipped because it is locked; Power Bank should be queued!
      expect(gameService.state.activeProductions.any((p) => p.productId == 'speaker'), isFalse);
      expect(gameService.state.activeProductions.any((p) => p.productId == 'power_bank'), isTrue);
    });

    test('getNextProductToBuild returns first unlocked retail item below capacity', () {
      gameService.incrementAutoBuildMachines('retail');
      gameService.toggleAutoBuild('retail');

      final initialUnlocked = Set<String>.from(gameService.state.unlockedProducts)
        ..add('speaker')
        ..add('wall_clock');
      final unlockMap = Map<String, bool>.from(gameService.state.productUnlockStatus);
      unlockMap['speaker'] = true;
      unlockMap['wall_clock'] = true;

      gameService.testSetState(gameService.state.copyWith(
        factoryTier: 4,
        unlockedProducts: initialUnlocked,
        productUnlockStatus: unlockMap,
        products: {},
      ));
      ProductUnlockService.clearCache();

      expect(gameService.getNextProductToBuild('retail'), 'Speaker');

      // Fill speaker to capacity (10)
      gameService.testSetState(gameService.state.copyWith(
        products: {'speaker': 10},
      ));
      ProductUnlockService.clearCache();

      expect(gameService.getNextProductToBuild('retail'), 'Analog Wall Clock');
    });

    test('increaseAutoBuildCapacity and decreaseAutoBuildCapacity manage retail capacity in steps of 10', () {
      expect(gameService.state.autoBuildProductCapacity['retail'] ?? 10, 10);

      gameService.increaseAutoBuildCapacity('retail');
      expect(gameService.state.autoBuildProductCapacity['retail'], 20);

      gameService.increaseAutoBuildCapacity('retail');
      expect(gameService.state.autoBuildProductCapacity['retail'], 30);

      gameService.decreaseAutoBuildCapacity('retail');
      expect(gameService.state.autoBuildProductCapacity['retail'], 20);

      // Cannot decrease below 10
      gameService.decreaseAutoBuildCapacity('retail');
      gameService.decreaseAutoBuildCapacity('retail');
      expect(gameService.state.autoBuildProductCapacity['retail'], 10);
    });
  });

  group('Retail Auto-Build Machine: UI & Widget Integration', () {
    testWidgets('MachineCard.autoBuild renders for retail tier', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => SingleChildScrollView(
                child: MachineCard.autoBuild(
                  context: context,
                  gameService: gameService,
                  tier: 'retail',
                  tierName: 'Retail',
                  accentColor: Colors.tealAccent,
                  icon: Icons.storefront,
                  subtitle: 'Automates finished end products (Speakers, Cameras, Powerwalls)',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Auto-Build: Retail'), findsOneWidget);
      expect(find.text('Automates finished end products (Speakers, Cameras, Powerwalls)'), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);
      expect(find.text('Buy Machine (\$1000)'), findsOneWidget);
    });

    testWidgets('BuildProductsScreen integrates retail tier key for auto-build controls', (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Deploy a retail machine so controls become visible
      gameService.addMoney(5000.0);
      await gameService.buyAutoBuildMachine('retail');
      expect(gameService.state.autoBuildMachinesOwned['retail'], 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ProductionGameService>.value(
              value: gameService,
              child: const BuildProductsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AUTO-BUILD: Retail widget is integrated
      expect(find.text('AUTO-BUILD: Retail'), findsOneWidget);
    });
  });
}
