import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/widgets/machine_card.dart';

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
        const categories = ['autoBuy', 'basicParts', 'intermediate', 'complex', 'retail'];
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

    group('4. MachineCard UI Layer (Phase 7)', () {
      testWidgets('Buy button is wrapped in Tooltip and disabled when machineCount >= machineLimit', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.shopping_cart,
                title: 'Auto-Buy Machines',
                accentColor: Colors.greenAccent,
                isEnabled: true,
                machineCount: 10,
                machineCost: 4045.56,
                canBuy: true, // Even if canBuy is true, limit reached must disable button
                machineLimit: 10,
                salvageValue: 1758.0,
                canSalvage: true,
                capacity: 50,
                capacityUnit: 'per resource',
                telemetryText: 'Buying materials',
              ),
            ),
          ),
        );

        // Tooltip must wrap the buy button with the exact message
        final buttonFinder = find.widgetWithText(ElevatedButton, 'Buy Machine (\$4045)');
        expect(buttonFinder, findsOneWidget);
        final buttonWidget = tester.widget<ElevatedButton>(buttonFinder);
        expect(buttonWidget.onPressed, isNull);

        final tooltipFinder = find.ancestor(
          of: buttonFinder,
          matching: find.byType(Tooltip),
        );
        expect(tooltipFinder, findsOneWidget);
        final tooltipWidget = tester.widget<Tooltip>(tooltipFinder);
        expect(
          tooltipWidget.message,
          'Tier Limit Reached (10/10). Upgrade Factory to expand.',
        );
      });

      testWidgets('Buy button has no tooltip and is enabled when machineCount < machineLimit', (WidgetTester tester) async {
        bool bought = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.shopping_cart,
                title: 'Auto-Buy Machines',
                accentColor: Colors.greenAccent,
                isEnabled: true,
                machineCount: 3,
                machineCost: 1520.0,
                canBuy: true,
                machineLimit: 10,
                salvageValue: 661.0,
                canSalvage: true,
                capacity: 50,
                capacityUnit: 'per resource',
                telemetryText: 'Buying materials',
                onBuy: () => bought = true,
              ),
            ),
          ),
        );

        final buttonFinder = find.widgetWithText(ElevatedButton, 'Buy Machine (\$1520)');
        expect(buttonFinder, findsOneWidget);

        // Buy button must NOT be wrapped in a Tooltip
        final buttonTooltip = find.ancestor(
          of: buttonFinder,
          matching: find.byType(Tooltip),
        );
        expect(buttonTooltip, findsNothing);

        // Tier limit tooltip must not exist
        expect(find.byTooltip('Tier Limit Reached (10/10). Upgrade Factory to expand.'), findsNothing);

        // Buy button is enabled and clickable
        await tester.tap(buttonFinder);
        expect(bought, isTrue);
      });

      testWidgets('Salvage button is disabled when canSalvage is false', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.shopping_cart,
                title: 'Auto-Buy Machines',
                accentColor: Colors.greenAccent,
                isEnabled: true,
                machineCount: 0,
                machineCost: 1000.0,
                canBuy: true,
                machineLimit: 10,
                salvageValue: 0.0,
                canSalvage: false,
                capacity: 10,
                capacityUnit: 'per resource',
                telemetryText: 'No machines deployed',
              ),
            ),
          ),
        );

        final salvageButtonFinder = find.widgetWithIcon(IconButton, Icons.recycling);
        expect(salvageButtonFinder, findsOneWidget);
        final salvageButton = tester.widget<IconButton>(salvageButtonFinder);
        expect(salvageButton.onPressed, isNull);
      });

      testWidgets('Salvage button shows confirmation dialog and Cancel dismisses it', (WidgetTester tester) async {
        bool salvaged = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.shopping_cart,
                title: 'Auto-Buy Machines',
                accentColor: Colors.greenAccent,
                isEnabled: true,
                machineCount: 2,
                machineCost: 1322.0,
                canBuy: true,
                machineLimit: 10,
                salvageValue: 575.0,
                canSalvage: true,
                onSalvage: () => salvaged = true,
                capacity: 20,
                capacityUnit: 'per resource',
                telemetryText: 'Active',
              ),
            ),
          ),
        );

        final salvageButtonFinder = find.widgetWithIcon(IconButton, Icons.recycling);
        expect(salvageButtonFinder, findsOneWidget);

        // Tap salvage button to open dialog
        await tester.tap(salvageButtonFinder);
        await tester.pumpAndSettle();

        // Verify AlertDialog elements
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Salvage Machine'), findsOneWidget);
        expect(find.text('Salvage 1 Machine for +\$575.00?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Salvage'), findsOneWidget);

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be dismissed and onSalvage NOT called
        expect(find.byType(AlertDialog), findsNothing);
        expect(salvaged, isFalse);
      });

      testWidgets('Salvage button confirmation dialog calls onSalvage on confirm', (WidgetTester tester) async {
        bool salvaged = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.shopping_cart,
                title: 'Auto-Buy Machines',
                accentColor: Colors.greenAccent,
                isEnabled: true,
                machineCount: 1,
                machineCost: 1150.0,
                canBuy: true,
                machineLimit: 10,
                salvageValue: 500.0,
                canSalvage: true,
                onSalvage: () => salvaged = true,
                capacity: 10,
                capacityUnit: 'per resource',
                telemetryText: 'Active',
              ),
            ),
          ),
        );

        await tester.tap(find.widgetWithIcon(IconButton, Icons.recycling));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Salvage 1 Machine for +\$500.00?'), findsOneWidget);

        // Tap Salvage action
        await tester.tap(find.text('Salvage'));
        await tester.pumpAndSettle();

        // Dialog dismissed and onSalvage called
        expect(find.byType(AlertDialog), findsNothing);
        expect(salvaged, isTrue);
      });

      testWidgets('MachineCard.autoBuy connects properly with gameService', (WidgetTester tester) async {
        // Setup gameService: 1 machine owned, Tier 1 (limit 10), initial money $10000
        gameService.setAutoBuyMachineCount(1);
        gameService.addMoney(10000.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => MachineCard.autoBuy(
                  context: context,
                  gameService: gameService,
                ),
              ),
            ),
          ),
        );

        // Machine price for count 1 is 1150.0
        expect(find.text('Buy Machine (\$1150)'), findsOneWidget);

        // Salvage value for count 1 is 500.0
        final salvageButtonFinder = find.widgetWithIcon(IconButton, Icons.recycling);
        expect(salvageButtonFinder, findsOneWidget);

        // Tap salvage
        await tester.tap(salvageButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('Salvage 1 Machine for +\$500.00?'), findsOneWidget);
        await tester.tap(find.text('Salvage'));
        await tester.pumpAndSettle();

        // Service should reflect salvage
        expect(gameService.state.autoBuyMachinesOwned, 0);
      });

      testWidgets('MachineCard.autoBuild connects properly with gameService', (WidgetTester tester) async {
        // Setup: 2 basicParts machines owned, limit 10
        gameService.incrementAutoBuildMachines('basicParts');
        gameService.incrementAutoBuildMachines('basicParts');
        gameService.addMoney(10000.0);
        expect(gameService.state.autoBuildMachinesOwned['basicParts'], 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => MachineCard.autoBuild(
                  context: context,
                  gameService: gameService,
                  tier: 'basicParts',
                  tierName: 'Basic Parts',
                ),
              ),
            ),
          ),
        );

        // Price for machine 2 is 1000 * 1.15^2 = 1322.5 -> $1322
        expect(find.text('Buy Machine (\$1322)'), findsOneWidget);

        // Salvage value for machine 2 is 575.0
        final salvageBtn = find.widgetWithIcon(IconButton, Icons.recycling);
        await tester.tap(salvageBtn);
        await tester.pumpAndSettle();

        expect(find.text('Salvage 1 Machine for +\$575.00?'), findsOneWidget);
        await tester.tap(find.text('Salvage'));
        await tester.pumpAndSettle();

        expect(gameService.state.autoBuildMachinesOwned['basicParts'], 1);
      });
    });
  });
}
