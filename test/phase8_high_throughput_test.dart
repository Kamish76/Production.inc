import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';

void main() {
  group('Phase 8: High-Throughput Automation (QA Tests)', () {
    late ProductionGameService gameService;

    setUp(() {
      final testDbName =
          'test_db_phase8_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
          testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    group('1. Auto-Buy Intake Multiplier Scaling', () {
      test('getAutoBuyIntakeMultiplier correctly scales across levels (1.0 for level 1, 1.25 for level 2, 1.5 for level 3)', () {
        // Base Level 1 gives 1.0x intake multiplier
        expect(gameService.getAutoBuyIntakeMultiplier(1), 1.0);

        // Level 2 gives 1.25x intake multiplier (+25%)
        expect(gameService.getAutoBuyIntakeMultiplier(2), 1.25);

        // Level 3 gives 1.50x intake multiplier (+50%)
        expect(gameService.getAutoBuyIntakeMultiplier(3), 1.50);

        // Level 4 gives 1.75x intake multiplier (+75%)
        expect(gameService.getAutoBuyIntakeMultiplier(4), 1.75);

        // Level 5 gives 2.00x intake multiplier (+100%)
        expect(gameService.getAutoBuyIntakeMultiplier(5), 2.00);
      });

      test('Current state autoBuyIntakeLevel reflects multiplier progression during gameplay', () async {
        // Initial default level is 1 -> 1.0x
        expect(gameService.state.autoBuyIntakeLevel, 1);
        expect(
          gameService.getAutoBuyIntakeMultiplier(gameService.state.autoBuyIntakeLevel),
          1.0,
        );

        // Upgrade to level 2 with sufficient funds
        gameService.addMoney(10000.0);
        await gameService.upgradeAutoBuyIntake();
        expect(gameService.state.autoBuyIntakeLevel, 2);
        expect(
          gameService.getAutoBuyIntakeMultiplier(gameService.state.autoBuyIntakeLevel),
          1.25,
        );

        // Upgrade to level 3
        await gameService.upgradeAutoBuyIntake();
        expect(gameService.state.autoBuyIntakeLevel, 3);
        expect(
          gameService.getAutoBuyIntakeMultiplier(gameService.state.autoBuyIntakeLevel),
          1.50,
        );
      });
    });

    group('2. Upgrade Cost Scaling (1000 * 1.15^(level-1))', () {
      test('Auto-buy intake upgrade costs scale correctly by 1000 * 1.15^(level-1)', () {
        // Level 1: 1000 * 1.15^0 = 1000.0
        gameService.setAutoBuyIntakeLevel(1);
        expect(gameService.getAutoBuyIntakeUpgradeCost(), closeTo(1000.0, 0.01));

        // Level 2: 1000 * 1.15^1 = 1150.0
        gameService.setAutoBuyIntakeLevel(2);
        expect(gameService.getAutoBuyIntakeUpgradeCost(), closeTo(1150.0, 0.01));

        // Level 3: 1000 * 1.15^2 = 1322.5
        gameService.setAutoBuyIntakeLevel(3);
        expect(gameService.getAutoBuyIntakeUpgradeCost(), closeTo(1322.5, 0.01));

        // Level 4: 1000 * 1.15^3 = 1520.875
        gameService.setAutoBuyIntakeLevel(4);
        final expectedLvl4 = 1000.0 * math.pow(1.15, 3);
        expect(gameService.getAutoBuyIntakeUpgradeCost(), closeTo(expectedLvl4, 0.01));

        // Level 5: 1000 * 1.15^4 ~ 1749.006
        gameService.setAutoBuyIntakeLevel(5);
        final expectedLvl5 = 1000.0 * math.pow(1.15, 4);
        expect(gameService.getAutoBuyIntakeUpgradeCost(), closeTo(expectedLvl5, 0.01));
      });

      test('Auto-build throughput upgrade costs scale correctly by 1000 * 1.15^(level-1)', () {
        const tiers = ['basicParts', 'intermediate', 'complex'];

        for (final tier in tiers) {
          // Level 1: 1000 * 1.15^0 = 1000.0
          gameService.setAutoBuildThroughputLevel(tier, 1);
          expect(
            gameService.getAutoBuildThroughputUpgradeCost(tier),
            closeTo(1000.0, 0.01),
            reason: 'Tier $tier failed at level 1',
          );

          // Level 2: 1000 * 1.15^1 = 1150.0
          gameService.setAutoBuildThroughputLevel(tier, 2);
          expect(
            gameService.getAutoBuildThroughputUpgradeCost(tier),
            closeTo(1150.0, 0.01),
            reason: 'Tier $tier failed at level 2',
          );

          // Level 3: 1000 * 1.15^2 = 1322.5
          gameService.setAutoBuildThroughputLevel(tier, 3);
          expect(
            gameService.getAutoBuildThroughputUpgradeCost(tier),
            closeTo(1322.5, 0.01),
            reason: 'Tier $tier failed at level 3',
          );

          // Level 5: 1000 * 1.15^4 ~ 1749.006
          gameService.setAutoBuildThroughputLevel(tier, 5);
          final expectedLvl5 = 1000.0 * math.pow(1.15, 4);
          expect(
            gameService.getAutoBuildThroughputUpgradeCost(tier),
            closeTo(expectedLvl5, 0.01),
            reason: 'Tier $tier failed at level 5',
          );
        }
      });
    });

    group('3. Upgrade Deduction and Level Increments', () {
      test('upgradeAutoBuyIntake deducts money and increments level sequentially', () async {
        // Initial state: Level 1, starting money + 10,000
        gameService.addMoney(10000.0);
        final initialMoney = gameService.state.money;
        expect(gameService.state.autoBuyIntakeLevel, 1);

        // Upgrade 1 -> 2 (Cost = $1000.0)
        final cost1 = gameService.getAutoBuyIntakeUpgradeCost();
        expect(cost1, closeTo(1000.0, 0.01));
        final success1 = await gameService.upgradeAutoBuyIntake();

        expect(success1, isTrue);
        expect(gameService.state.autoBuyIntakeLevel, 2);
        expect(gameService.state.money, closeTo(initialMoney - cost1, 0.01));

        // Upgrade 2 -> 3 (Cost = $1150.0)
        final moneyBefore2 = gameService.state.money;
        final cost2 = gameService.getAutoBuyIntakeUpgradeCost();
        expect(cost2, closeTo(1150.0, 0.01));
        final success2 = await gameService.upgradeAutoBuyIntake();

        expect(success2, isTrue);
        expect(gameService.state.autoBuyIntakeLevel, 3);
        expect(gameService.state.money, closeTo(moneyBefore2 - cost2, 0.01));

        // Upgrade 3 -> 4 (Cost = $1322.5)
        final moneyBefore3 = gameService.state.money;
        final cost3 = gameService.getAutoBuyIntakeUpgradeCost();
        expect(cost3, closeTo(1322.5, 0.01));
        final success3 = await gameService.upgradeAutoBuyIntake();

        expect(success3, isTrue);
        expect(gameService.state.autoBuyIntakeLevel, 4);
        expect(gameService.state.money, closeTo(moneyBefore3 - cost3, 0.01));
      });

      test('upgradeAutoBuildThroughput deducts money and increments level sequentially', () async {
        const tier = 'basicParts';

        // Initial state: Level 1, starting money + 10,000
        gameService.addMoney(10000.0);
        final initialMoney = gameService.state.money;
        expect(gameService.getAutoBuildThroughputLevel(tier), 1);

        // Upgrade 1 -> 2 (Cost = $1000.0)
        final cost1 = gameService.getAutoBuildThroughputUpgradeCost(tier);
        expect(cost1, closeTo(1000.0, 0.01));
        final success1 = await gameService.upgradeAutoBuildThroughput(tier);

        expect(success1, isTrue);
        expect(gameService.getAutoBuildThroughputLevel(tier), 2);
        expect(gameService.state.autoBuildThroughputLevel[tier], 2);
        expect(gameService.state.money, closeTo(initialMoney - cost1, 0.01));

        // Upgrade 2 -> 3 (Cost = $1150.0)
        final moneyBefore2 = gameService.state.money;
        final cost2 = gameService.getAutoBuildThroughputUpgradeCost(tier);
        expect(cost2, closeTo(1150.0, 0.01));
        final success2 = await gameService.upgradeAutoBuildThroughput(tier);

        expect(success2, isTrue);
        expect(gameService.getAutoBuildThroughputLevel(tier), 3);
        expect(gameService.state.autoBuildThroughputLevel[tier], 3);
        expect(gameService.state.money, closeTo(moneyBefore2 - cost2, 0.01));
      });

      test('upgradeAutoBuyIntake fails when funds are insufficient and preserves balance/level', () async {
        // Starting money is $100.0, but cost is $1000.0
        expect(gameService.state.money, lessThan(1000.0));
        expect(gameService.state.autoBuyIntakeLevel, 1);
        final moneyBefore = gameService.state.money;

        final success = await gameService.upgradeAutoBuyIntake();

        expect(success, isFalse);
        expect(gameService.state.autoBuyIntakeLevel, 1);
        expect(gameService.state.money, moneyBefore);
      });

      test('upgradeAutoBuildThroughput fails when funds are insufficient and preserves balance/level', () async {
        const tier = 'basicParts';

        // Starting money is $100.0, but cost is $1000.0
        expect(gameService.state.money, lessThan(1000.0));
        expect(gameService.getAutoBuildThroughputLevel(tier), 1);
        final moneyBefore = gameService.state.money;

        final success = await gameService.upgradeAutoBuildThroughput(tier);

        expect(success, isFalse);
        expect(gameService.getAutoBuildThroughputLevel(tier), 1);
        expect(gameService.state.money, moneyBefore);
      });
    });
  });
}
