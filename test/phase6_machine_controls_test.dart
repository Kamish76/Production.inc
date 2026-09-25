import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/widgets/machine_card.dart';
import 'package:game1/screens/control_screen.dart';

void main() {
  group('Phase 6: Machine Controls Uncapping & Unified UI Architecture', () {
    late ProductionGameService gameService;

    setUp(() {
      final testDbName = 'test_db_phase6_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    group('1. Auto-Buy Capacity Uncapping', () {
      test('Auto-buy capacity is uncapped and scales infinitely past Tier 1 limit (25)', () {
        expect(gameService.state.factoryTier, 1);
        expect(gameService.state.autoBuyResourceCapacity, 10);

        // Increase once -> 20
        gameService.increaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 20);

        // Increase past old Tier 1 limit of 25 -> 30
        gameService.increaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 30);

        // Continues scaling infinitely
        gameService.increaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 40);

        gameService.increaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 50);

        gameService.increaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 60);
      });

      test('Auto-buy capacity cannot decrease below minimum of 10', () {
        expect(gameService.state.autoBuyResourceCapacity, 10);

        // Attempting to decrease at 10 should keep it at 10
        gameService.decreaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 10);

        // Increase to 30, then decrease twice back to 10
        gameService.increaseAutoBuyCapacity();
        gameService.increaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 30);

        gameService.decreaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 20);

        gameService.decreaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 10);

        // Try decreasing again
        gameService.decreaseAutoBuyCapacity();
        expect(gameService.state.autoBuyResourceCapacity, 10);
      });
    });

    group('2. Generic MachineCard Widget', () {
      testWidgets('Renders all required sections and data', (WidgetTester tester) async {
        bool toggled = false;
        bool bought = false;
        bool increased = false;
        bool decreased = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.precision_manufacturing,
                title: 'Test Fabricator',
                subtitle: 'Automates testing widgets',
                accentColor: Colors.cyanAccent,
                isEnabled: true,
                machineCount: 3,
                machineCost: 1000.0,
                canBuy: true,
                onBuy: () => bought = true,
                onToggle: (_) => toggled = true,
                capacity: 50,
                capacityUnit: 'units / cycle',
                onIncreaseCapacity: () => increased = true,
                onDecreaseCapacity: () => decreased = true,
                telemetryText: 'Producing 15 units every 5s',
              ),
            ),
          ),
        );

        // Header elements
        expect(find.text('Test Fabricator'), findsOneWidget);
        expect(find.text('Automates testing widgets'), findsOneWidget);
        expect(find.byIcon(Icons.precision_manufacturing), findsOneWidget);
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);

        // Fleet Count elements
        expect(find.text('Fleet Count:'), findsOneWidget);
        expect(find.text('3 Units'), findsOneWidget);
        expect(find.text('Buy Machine (\$1000)'), findsOneWidget);

        // Capacity Stepper elements
        expect(find.text('Capacity:'), findsOneWidget);
        expect(find.text('50'), findsOneWidget);
        expect(find.text('units / cycle'), findsOneWidget);
        expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);

        // Telemetry Strip
        expect(find.text('Producing 15 units every 5s'), findsOneWidget);

        // Test interactions
        await tester.tap(find.text('Buy Machine (\$1000)'));
        expect(bought, isTrue);

        await tester.tap(find.byType(Switch));
        expect(toggled, isTrue);

        await tester.tap(find.byIcon(Icons.add_circle_outline));
        expect(increased, isTrue);

        await tester.tap(find.byIcon(Icons.remove_circle_outline));
        expect(decreased, isTrue);
      });

      testWidgets('Displays PAUSED badge when machineCount > 0 but disabled', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.precision_manufacturing,
                title: 'Paused Machine',
                accentColor: Colors.amberAccent,
                isEnabled: false,
                machineCount: 2,
                machineCost: 1000.0,
                canBuy: false,
                capacity: 20,
                capacityUnit: 'units',
                telemetryText: 'Offline - Machine paused',
              ),
            ),
          ),
        );

        expect(find.text('PAUSED'), findsOneWidget);
        expect(find.text('Offline - Machine paused'), findsOneWidget);
      });

      testWidgets('Displays OFFLINE badge when machineCount is 0', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MachineCard(
                icon: Icons.precision_manufacturing,
                title: 'Unowned Machine',
                accentColor: Colors.blueAccent,
                isEnabled: false,
                machineCount: 0,
                machineCost: 1000.0,
                canBuy: true,
                capacity: 10,
                capacityUnit: 'units',
                telemetryText: 'No machines deployed',
              ),
            ),
          ),
        );

        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.text('0 Units'), findsOneWidget);
        expect(find.text('No machines deployed'), findsOneWidget);
      });
    });

    group('3. MachineCard Factory Constructors & ControlScreen Integration', () {
      testWidgets('MachineCard.autoBuy and MachineCard.autoBuild render within ControlScreen', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<ProductionGameService>.value(
              value: gameService,
              child: const ControlScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Control Center header
        expect(find.text('Control Center'), findsOneWidget);

        // Machines section is selected by default (index 0)
        expect(find.text('Machine Controls'), findsOneWidget);

        // Auto-Buy card
        expect(find.text('Auto-Buy Machines'), findsOneWidget);
        expect(find.text('per resource'), findsOneWidget);

        // Auto-Build cards
        expect(find.text('AUTO-BUILD ASSEMBLY TIERS'), findsOneWidget);
        expect(find.text('Auto-Build: Basic Parts'), findsOneWidget);
        expect(find.text('Auto-Build: Intermediate'), findsOneWidget);
        expect(find.text('Auto-Build: Complex'), findsOneWidget);
        expect(find.text('per product'), findsNWidgets(3));
      });
    });
  });
}
