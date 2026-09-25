import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/screens/shipping_screen.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/widgets/corporate_contract_card.dart';

void main() {
  group('Phase 6: B2B Bulk Requisitions: Auto-Sorting & Lazy-Loaded Archive', () {
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
            body: ShippingScreen(),
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

      // Generate initial contracts
      gameService.devRefreshContracts();
      expect(gameService.state.corporateContracts.length, greaterThanOrEqualTo(2));

      // Fulfill the first contract
      final completedTarget = gameService.state.corporateContracts[0];
      gameService.acceptContract(completedTarget.id);
      gameService.addProductToInventory(completedTarget.targetProductId, completedTarget.requiredQuantity);
      final fulfilledSuccess = gameService.fulfillContract(completedTarget.id);
      expect(fulfilledSuccess, isTrue);

      // Accept the second contract so it is active
      final activeTarget = gameService.state.corporateContracts[1];
      gameService.acceptContract(activeTarget.id);

      final totalContracts = gameService.state.corporateContracts.length;
      final completedCount = gameService.state.corporateContracts.where((c) => c.status == ContractStatus.completed).length;
      final activeCount = totalContracts - completedCount;

      expect(completedCount, 1);
      expect(activeCount, greaterThanOrEqualTo(1));

      // Render shipping screen
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check active count reflects only non-completed contracts
      expect(find.text('Active Bulk Requisitions ($activeCount)'), findsOneWidget);

      // Check ExpansionTile label displays completed count
      expect(find.text('Completed Requisitions ($completedCount)'), findsOneWidget);

      // The ExpansionTile must exist and be collapsed by default
      final expansionTileFinder = find.byType(ExpansionTile);
      expect(expansionTileFinder, findsOneWidget);
      final expansionTileWidget = tester.widget<ExpansionTile>(expansionTileFinder);
      expect(expansionTileWidget.initiallyExpanded, isFalse);

      // Verify lazy loading: because ExpansionTile is collapsed and maintainState is false,
      // only the active contract cards are rendered in the widget tree.
      expect(find.byType(CorporateContractCard), findsNWidgets(activeCount));

      // Tap on the ExpansionTile header to expand it
      await tester.tap(find.text('Completed Requisitions ($completedCount)'));
      await tester.pumpAndSettle();

      // After expansion, all cards should now be rendered (active + completed)
      expect(find.byType(CorporateContractCard), findsNWidgets(totalContracts));

      // Verify ListView inside ExpansionTile has shrinkWrap set to true
      final listViewInsideAccordion = find.descendant(
        of: expansionTileFinder,
        matching: find.byType(ListView),
      );
      expect(listViewInsideAccordion, findsOneWidget);
      final listViewWidget = tester.widget<ListView>(listViewInsideAccordion);
      expect(listViewWidget.shrinkWrap, isTrue);
    });

    testWidgets('Completed Requisitions expansion tile displays (0) when none are fulfilled', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      gameService.devRefreshContracts();
      final totalContracts = gameService.state.corporateContracts.length;
      expect(totalContracts, greaterThanOrEqualTo(1));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Bulk Requisitions ($totalContracts)'), findsOneWidget);
      expect(find.text('Completed Requisitions (0)'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.byType(CorporateContractCard), findsNWidgets(totalContracts));
    });

    testWidgets('Displays empty state message for active contracts when all are fulfilled', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      gameService.devRefreshContracts();
      final contracts = List<CorporateContract>.from(gameService.state.corporateContracts);

      // Fulfill all contracts
      for (final c in contracts) {
        gameService.acceptContract(c.id);
        gameService.addProductToInventory(c.targetProductId, c.requiredQuantity);
        gameService.fulfillContract(c.id);
      }

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Active Bulk Requisitions (0)'), findsOneWidget);
      expect(find.text('All active requisitions fulfilled! Check completed archive below.'), findsOneWidget);
      expect(find.text('Completed Requisitions (${contracts.length})'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
      // Because collapsed, 0 cards rendered initially
      expect(find.byType(CorporateContractCard), findsNothing);

      // Expand accordion
      await tester.tap(find.text('Completed Requisitions (${contracts.length})'));
      await tester.pumpAndSettle();

      // All fulfilled cards now rendered
      expect(find.byType(CorporateContractCard), findsNWidgets(contracts.length));
    });
  });
}
