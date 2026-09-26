import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/screens/sell_products_screen.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';

void main() {
  group('Phase 6 & 9A: B2B Bulk Requisitions: Auto-Sorting & Lazy-Loaded Archive in Sell Screen', () {
    late ProductionGameService gameService;

    setUp(() {
      final testDbName = 'test_db_phase6_shipping_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      gameService.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: const Scaffold(
            body: SellProductsScreen(),
          ),
        ),
      );
    }

    testWidgets('Contracts are auto-sorted: active first, fulfilled moved to collapsed ExpansionTile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract1 = CorporateContract(
        id: 'c_active_1',
        clientId: 'apex_telecom',
        title: 'Active Contract',
        description: 'Test',
        contractType: ContractType.retail,
        requiredProducts: const {'box': 5},
        cashReward: 500.0,
        repReward: 50,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        status: ContractStatus.available,
        createdAt: DateTime.now(),
      );

      final contract2 = CorporateContract(
        id: 'c_completed_1',
        clientId: 'nova_robotics',
        title: 'Completed Contract',
        description: 'Test',
        contractType: ContractType.manufacturing,
        requiredProducts: const {'wires': 20},
        cashReward: 1000.0,
        repReward: 60,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        status: ContractStatus.completed,
        createdAt: DateTime.now(),
      );

      gameService.addContractForTest(contract1);
      gameService.addContractForTest(contract2);

      // Render sell screen
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to B2B Contracts tab
      await tester.tap(find.text('B2B Contracts'));
      await tester.pumpAndSettle();

      // Check active count reflects only non-completed contracts
      expect(find.text('Active Contracts (1 / ${gameService.state.maxContractSlots})'), findsOneWidget);

      // Check ExpansionTile label displays completed count
      expect(find.text('Completed Requisitions (1)'), findsOneWidget);

      // The ExpansionTile must exist and be collapsed by default
      final expansionTileFinder = find.byType(ExpansionTile);
      expect(expansionTileFinder, findsOneWidget);
      final expansionTileWidget = tester.widget<ExpansionTile>(expansionTileFinder);
      expect(expansionTileWidget.initiallyExpanded, isFalse);

      // Verify lazy loading: because ExpansionTile is collapsed and maintainState is false,
      // only the active contract is rendered in the widget tree.
      expect(find.text('Active Contract'), findsOneWidget);
      expect(find.text('Completed Contract'), findsNothing);

      // Tap on the ExpansionTile header to expand it
      await tester.tap(find.text('Completed Requisitions (1)'));
      await tester.pumpAndSettle();

      // After expansion, both contracts should now be rendered
      expect(find.text('Active Contract'), findsOneWidget);
      expect(find.text('Completed Contract'), findsOneWidget);
    });

    testWidgets('Completed Requisitions expansion tile omitted when none are fulfilled', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = CorporateContract(
        id: 'c_active_only',
        clientId: 'apex_telecom',
        title: 'Active Contract Only',
        description: 'Test',
        contractType: ContractType.retail,
        requiredProducts: const {'box': 5},
        cashReward: 500.0,
        repReward: 50,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        status: ContractStatus.available,
        createdAt: DateTime.now(),
      );
      gameService.addContractForTest(contract);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('B2B Contracts'));
      await tester.pumpAndSettle();

      expect(find.text('Active Contracts (1 / ${gameService.state.maxContractSlots})'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Active Contract Only'), findsOneWidget);
    });
  });
}
