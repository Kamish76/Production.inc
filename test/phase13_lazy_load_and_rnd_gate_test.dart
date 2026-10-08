import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/models/game_models.dart' as game;
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/widgets/lazy_indexed_stack.dart';
import 'package:game1/widgets/lazy_tab_loader.dart';
import 'package:game1/screens/control_screen.dart';
import 'package:game1/screens/shipping_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LazyIndexedStack Tests', () {
    testWidgets('only calls builder for the active index initially', (tester) async {
      int builder0Calls = 0;
      int builder1Calls = 0;
      int builder2Calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LazyIndexedStack(
                  index: 0,
                  builders: [
                    (_) {
                      builder0Calls++;
                      return const Text('Screen 0');
                    },
                    (_) {
                      builder1Calls++;
                      return const Text('Screen 1');
                    },
                    (_) {
                      builder2Calls++;
                      return const Text('Screen 2');
                    },
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(builder0Calls, 1);
      expect(builder1Calls, 0);
      expect(builder2Calls, 0);
      expect(find.text('Screen 0'), findsOneWidget);
      expect(find.text('Screen 1'), findsNothing);
    });

    testWidgets('activates new index on change and keeps previous cached', (tester) async {
      int currentIndex = 0;
      late StateSetter setIndexState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setIndexState = setState;
                return LazyIndexedStack(
                  index: currentIndex,
                  builders: [
                    (_) => const Text('Screen 0'),
                    (_) => const Text('Screen 1'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Screen 0'), findsOneWidget);
      expect(find.text('Screen 1'), findsNothing);

      // Switch to index 1
      setIndexState(() {
        currentIndex = 1;
      });
      await tester.pumpAndSettle();

      expect(find.text('Screen 1'), findsOneWidget);
      // IndexedStack keeps children in the element tree
      expect(find.text('Screen 0', skipOffstage: false), findsOneWidget);
    });
  });

  group('LazyTabLoader Tests', () {
    testWidgets('defers building until tab index is reached', (tester) async {
      int buildTab0Calls = 0;
      int buildTab1Calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              body: TabBarView(
                children: [
                  LazyTabLoader(
                    index: 0,
                    builder: (_) {
                      buildTab0Calls++;
                      return const Text('Tab 0 Content');
                    },
                  ),
                  LazyTabLoader(
                    index: 1,
                    builder: (_) {
                      buildTab1Calls++;
                      return const Text('Tab 1 Content');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(buildTab0Calls, 1);
      expect(buildTab1Calls, 0);
      expect(find.text('Tab 0 Content'), findsOneWidget);
      expect(find.text('Tab 1 Content'), findsNothing);
    });
  });

  group('R&D Beta Gate & Redeem Tests', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_rnd_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    test('isRnDLabUnlocked is false by default', () {
      expect(gameService.isRnDLabUnlocked, isFalse);
      expect(gameService.isRnDLabBetaUnlocked, isFalse);
    });

    test('redeeming RNDBETA2026 unlocks R&D lab persistently', () {
      final result = gameService.redeemCode('RNDBETA2026');
      expect(result.status, RedeemCodeResult.rewardClaimed);
      expect(result.message, contains('R&D Lab Beta Access Unlocked'));
      expect(gameService.isRnDLabUnlocked, isTrue);
      expect(gameService.isRnDLabBetaUnlocked, isTrue);
      expect(gameService.state.redeemedCodes.contains('RNDBETA2026'), isTrue);

      // Subsequent attempt returns alreadyRedeemed
      final repeatResult = gameService.redeemCode('RNDBETA2026');
      expect(repeatResult.status, RedeemCodeResult.alreadyRedeemed);
    });

    test('redeeming 888888 dev code unlocks developer session but keeps R&D lab locked', () {
      final result = gameService.redeemCode('888888');
      expect(result.status, RedeemCodeResult.devUnlocked);
      expect(gameService.isDeveloperModeUnlocked, isTrue);
      expect(gameService.isRnDLabUnlocked, isFalse);
    });

    test('relockRnDLab re-locks R&D lab and removes beta code', () {
      gameService.redeemCode('RNDBETA2026');
      expect(gameService.isRnDLabUnlocked, isTrue);
      gameService.relockRnDLab();
      expect(gameService.isRnDLabUnlocked, isFalse);
    });
  });

  group('ControlScreen R&D Gate UI Tests', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_ctrl_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    testWidgets('shows RnDLabBetaGateView when locked', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: const MaterialApp(
            home: Scaffold(body: ControlScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap R&D Lab section
      await tester.tap(find.text('R&D Lab'));
      await tester.pumpAndSettle();

      // Should show the Closed Beta teaser gate
      expect(find.text('R&D Facility In Development'), findsOneWidget);
      expect(find.text('EXPERIMENTAL PROTOCOL // CLOSED BETA'), findsOneWidget);
      expect(find.text('Unlock'), findsOneWidget);
    });

    testWidgets('unlocks R&D Lab with in-place redeem input', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: const MaterialApp(
            home: Scaffold(body: ControlScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to R&D Lab
      await tester.tap(find.text('R&D Lab'));
      await tester.pumpAndSettle();

      // Enter RNDBETA2026
      await tester.enterText(find.byType(TextField), 'RNDBETA2026');
      await tester.ensureVisible(find.text('Unlock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      // Now R&D lab is unlocked and shows Tech Tree and BETA ACCESS badge
      expect(gameService.isRnDLabUnlocked, isTrue);
      expect(find.text('BETA ACCESS'), findsOneWidget);
      expect(find.text('Tech Tree'), findsOneWidget);
      expect(find.text('Deconstruction'), findsOneWidget);
    });
  });

  group('ShippingHistoryView Pagination Tests', () {
    late String testDbName;
    late ProductionGameService gameService;

    setUp(() {
      testDbName = 'test_db_hist_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() {
      gameService.dispose();
    });

    testWidgets('shows capped items and load more button when history > 30', (tester) async {
      // Populate 45 completed shipping orders
      final mockHistory = List.generate(
        45,
        (i) => game.ShippingHistory(
          id: 'order_$i',
          items: const [game.ShippingItem(productId: 'box', quantity: 5)],
          completedTime: DateTime.now().subtract(Duration(minutes: i)),
          totalRevenue: 50.0,
        ),
      );

      // Inject history into state
      gameService.testSetState(
        gameService.state.copyWith(shippingHistory: mockHistory),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: const MaterialApp(
            home: Scaffold(body: ShippingHistoryView()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down until the Load More button comes into view
      final loadMoreFinder = find.text('Load More (+15)');
      await tester.scrollUntilVisible(loadMoreFinder, 500);
      await tester.pumpAndSettle();

      // Load More button should now be visible
      expect(loadMoreFinder, findsOneWidget);

      // Tap Load More
      await tester.tap(loadMoreFinder);
      await tester.pumpAndSettle();

      // Now all 45 items are loaded and Load More button disappears
      expect(loadMoreFinder, findsNothing);
    });
  });
}
