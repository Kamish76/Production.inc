import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';

void main() {
  group('Phase 7: Machine Economy & Tier Limits', () {
    late ProductionGameService gameService;

    setUp(() {
      final testDbName =
          'test_db_phase7_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
          testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    group('1. Exponential Dynamic Machine Pricing (1000 * 1.15^N)', () {
      test('Base price for 0 machines is exactly 1000.0 for all categories', () {
        expect(gameService.getMachinePrice('autoBuy', 0), 1000.0);
        expect(gameService.getMachinePrice('basicParts', 0), 1000.0);
        expect(gameService.getMachinePrice('intermediate', 0), 1000.0);
        expect(gameService.getMachinePrice('complex', 0), 1000.0);
      });

      test('Machine price scales exponentially according to 1000 * 1.15^N', () {
        // N = 1 -> 1000 * 1.15 = 1150.0
        expect(gameService.getMachinePrice('autoBuy', 1), closeTo(1150.0, 0.01));

        // N = 2 -> 1000 * 1.15^2 = 1322.5
        expect(gameService.getMachinePrice('autoBuy', 2), closeTo(1322.5, 0.01));

        // N = 3 -> 1000 * 1.15^3 = 1520.875
        expect(gameService.getMachinePrice('autoBuy', 3), closeTo(1520.875, 0.01));

        // N = 5 -> 1000 * 1.15^5 ~ 2011.357
        final expectedN5 = 1000.0 * math.pow(1.15, 5);
        expect(gameService.getMachinePrice('autoBuy', 5), closeTo(expectedN5, 0.01));

        // N = 10 -> 1000 * 1.15^10 ~ 4045.558
        final expectedN10 = 1000.0 * math.pow(1.15, 10);
        expect(gameService.getMachinePrice('autoBuy', 10), closeTo(expectedN10, 0.01));
      });

      test('Price scaling matches formula across all machine tiers/categories', () {
        const categories = ['autoBuy', 'basicParts', 'intermediate', 'complex'];
        for (final cat in categories) {
          for (int n = 0; n <= 8; n++) {
            final expected = 1000.0 * math.pow(1.15, n);
            expect(
              gameService.getMachinePrice(cat, n),
              closeTo(expected, 0.01),
              reason: 'Category $cat price failed at count $n',
            );
          }
        }
      });

      test('Machine price increases monotonically with each additional machine', () {
        for (int n = 0; n < 15; n++) {
          final priceCurrent = gameService.getMachinePrice('autoBuy', n);
          final priceNext = gameService.getMachinePrice('autoBuy', n + 1);
          expect(priceNext, greaterThan(priceCurrent));
        }
      });
    });

    group('2. Machine Salvage System (50% Refund & Machine Reduction)', () {
      test('Salvage value is calculated as 50% of the last machine cost', () {
        // Count = 0 -> salvage value should be 0.0
        expect(gameService.getMachineSalvageValue('autoBuy', 0), 0.0);

        // Count = 1 -> last machine was machine 0 ($1000.0), 50% refund = 500.0
        expect(gameService.getMachineSalvageValue('autoBuy', 1), 500.0);

        // Count = 2 -> last machine was machine 1 ($1150.0), 50% refund = 575.0
        expect(gameService.getMachineSalvageValue('autoBuy', 2), 575.0);

        // Count = 3 -> last machine was machine 2 ($1322.5), 50% refund = 661.0 (floored)
        final expected3 = (0.50 * (1000.0 * math.pow(1.15, 2))).floorToDouble();
        expect(gameService.getMachineSalvageValue('autoBuy', 3), expected3);
      });

      test('salvageMachine correctly refunds 50% of last machine cost and decrements autoBuy count', () async {
        // Setup: 1 machine owned and initial money of $100
        gameService.setAutoBuyMachineCount(1);
        gameService.addMoney(100.0);
        expect(gameService.state.autoBuyMachinesOwned, 1);
        final initialMoney = gameService.state.money;

        final expectedRefund = gameService.getMachineSalvageValue('autoBuy', 1);
        expect(expectedRefund, 500.0);

        final result = await gameService.salvageMachine('autoBuy');

        expect(result, isTrue);
        expect(gameService.state.autoBuyMachinesOwned, 0);
        expect(gameService.state.money, initialMoney + expectedRefund);
      });

      test('salvageMachine refunds escalating value for higher machine counts', () async {
        // Setup: 3 machines owned
        gameService.setAutoBuyMachineCount(3);
        gameService.addMoney(200.0);
        final initialMoney = gameService.state.money;

        // Last machine cost was at index 2 (1322.5), refund is 50% floored = 661.0
        final expectedRefund = gameService.getMachineSalvageValue('autoBuy', 3);

        final result = await gameService.salvageMachine('autoBuy');

        expect(result, isTrue);
        expect(gameService.state.autoBuyMachinesOwned, 2);
        expect(gameService.state.money, initialMoney + expectedRefund);
      });

      test('salvageMachine returns false and does not alter balance when count is 0', () async {
        gameService.setAutoBuyMachineCount(0);
        gameService.addMoney(350.0);
        final moneyBefore = gameService.state.money;

        final result = await gameService.salvageMachine('autoBuy');

        expect(result, isFalse);
        expect(gameService.state.autoBuyMachinesOwned, 0);
        expect(gameService.state.money, moneyBefore);
      });

      test('salvageMachine works properly for auto-build tier categories', () async {
        gameService.incrementAutoBuildMachines('basicParts');
        gameService.incrementAutoBuildMachines('basicParts');
        expect(gameService.state.autoBuildMachinesOwned['basicParts'], 2);

        gameService.addMoney(50.0);
        final moneyBefore = gameService.state.money;
        final expectedRefund = gameService.getMachineSalvageValue('basicParts', 2);

        final result = await gameService.salvageMachine('basicParts');

        expect(result, isTrue);
        expect(gameService.state.autoBuildMachinesOwned['basicParts'], 1);
        expect(gameService.state.money, moneyBefore + expectedRefund);
      });
    });

    group('3. Factory Tier Machine Limits & Purchase Blocking', () {
      test('Tier 1 machine limit is 10 and increases with factory tier upgrades', () async {
        // Initial Tier is 1
        expect(gameService.state.factoryTier, 1);
        expect(gameService.getMachineTierLimit('autoBuy'), 10);

        // Tier 2 limit is 20
        await gameService.setFactoryTierForDev(2);
        expect(gameService.getMachineTierLimit('autoBuy'), 20);

        // Tier 3 limit is 30
        await gameService.setFactoryTierForDev(3);
        expect(gameService.getMachineTierLimit('autoBuy'), 30);

        // Tier 4 limit is 40
        await gameService.setFactoryTierForDev(4);
        expect(gameService.getMachineTierLimit('autoBuy'), 40);
      });

      test('buyAutoBuyMachine is blocked when autoBuyMachinesOwned is >= getMachineTierLimit (Tier 1 limit = 10)', () async {
        // Start at Tier 1 with plenty of money
        expect(gameService.state.factoryTier, 1);
        final tierLimit = gameService.getMachineTierLimit('autoBuy');
        expect(tierLimit, 10);

        // Set machine count to 10 (at limit)
        gameService.setAutoBuyMachineCount(10);
        gameService.addMoney(100000.0);
        final moneyBefore = gameService.state.money;

        // Attempting to buy 11th machine must be blocked
        final success = await gameService.buyAutoBuyMachine();

        expect(success, isFalse);
        expect(gameService.state.autoBuyMachinesOwned, 10);
        expect(gameService.state.money, moneyBefore);
      });

      test('Can purchase up to the Tier 1 limit of 10 with escalating prices', () async {
        expect(gameService.state.factoryTier, 1);
        gameService.setAutoBuyMachineCount(0);
        gameService.addMoney(500000.0); // Sufficient funds for all 10 machines

        // Purchase machines from 0 to 10
        for (int i = 0; i < 10; i++) {
          expect(gameService.state.autoBuyMachinesOwned, i);
          final expectedPrice = gameService.getMachinePrice('autoBuy', i);
          final moneyBefore = gameService.state.money;

          final success = await gameService.buyAutoBuyMachine();
          expect(success, isTrue, reason: 'Failed to buy machine at count $i');
          expect(gameService.state.autoBuyMachinesOwned, i + 1);
          expect(gameService.state.money, closeTo(moneyBefore - expectedPrice, 0.01));
        }

        // Now at limit 10, 11th purchase must fail
        expect(gameService.state.autoBuyMachinesOwned, 10);
        final successBlocked = await gameService.buyAutoBuyMachine();
        expect(successBlocked, isFalse);
        expect(gameService.state.autoBuyMachinesOwned, 10);
      });

      test('Upgrading factory tier unblocks purchases past Tier 1 limit', () async {
        // Set count to Tier 1 limit
        gameService.setAutoBuyMachineCount(10);
        gameService.addMoney(100000.0);

        // Blocked at Tier 1
        expect(await gameService.buyAutoBuyMachine(), isFalse);
        expect(gameService.state.autoBuyMachinesOwned, 10);

        // Upgrade to Tier 2 (limit becomes 20)
        await gameService.setFactoryTierForDev(2);
        expect(gameService.getMachineTierLimit('autoBuy'), 20);

        // Now purchase should succeed
        final successAfterUpgrade = await gameService.buyAutoBuyMachine();
        expect(successAfterUpgrade, isTrue);
        expect(gameService.state.autoBuyMachinesOwned, 11);
      });

      test('buyAutoBuyMachine still requires sufficient funds even below limit', () async {
        // Count is 0 and initial money ($100) is less than machine price ($1000)
        gameService.setAutoBuyMachineCount(0);
        expect(gameService.state.money, lessThan(gameService.getMachinePrice('autoBuy', 0)));

        final success = await gameService.buyAutoBuyMachine();
        expect(success, isFalse);
        expect(gameService.state.autoBuyMachinesOwned, 0);
      });

      test('buyAutoBuildMachine enforces tier limit and uses dynamic pricing', () async {
        expect(gameService.state.factoryTier, 1);
        final tierLimit = gameService.getMachineTierLimit('basicParts');
        expect(tierLimit, 10);

        gameService.addMoney(200000.0);

        // Buy up to limit of 10
        for (int i = 0; i < 10; i++) {
          expect(gameService.state.autoBuildMachinesOwned['basicParts'] ?? 0, i);
          final price = gameService.getMachinePrice('basicParts', i);
          final moneyBefore = gameService.state.money;

          final success = await gameService.buyAutoBuildMachine('basicParts');
          expect(success, isTrue);
          expect(gameService.state.autoBuildMachinesOwned['basicParts'], i + 1);
          expect(gameService.state.money, closeTo(moneyBefore - price, 0.01));
        }

        // At limit (10), 11th machine must be blocked
        final successBlocked = await gameService.buyAutoBuildMachine('basicParts');
        expect(successBlocked, isFalse);
        expect(gameService.state.autoBuildMachinesOwned['basicParts'], 10);
      });
    });
  });
}
