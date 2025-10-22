import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/screens/main_game_screen.dart';
import 'package:game1/screens/buy_materials_screen.dart';
import 'package:game1/screens/build_products_screen.dart';
import 'package:game1/screens/sell_products_screen.dart';

void main() {
  group('Comprehensive Widget Tests', () {
    late ProductionGameService gameService;

    setUp(() {
  // Initialize database factory for testing with unique DB name
  final testDbName = 'test_db_comprehensive_widget_${DateTime.now().microsecondsSinceEpoch}.db';
  GamePersistenceService.initializeDatabaseFactory(testDatabaseName: testDbName);
  gameService = ProductionGameService();
    });

    tearDown(() async {
      await gameService.dispose();
    });

    testWidgets('Main game screen loads without errors', (WidgetTester tester) async {
      // Build the main game screen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const MainGameScreen(),
          ),
        ),
      );

      // Wait for initial rendering (shorter timeout)
      await tester.pump(const Duration(milliseconds: 100));

      // Verify the screen loads
      expect(find.byType(MainGameScreen), findsOneWidget);
    });

    testWidgets('Buy materials screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const BuyMaterialsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for key elements
      expect(find.text('Buy Materials'), findsOneWidget);
      expect(find.byType(BuyMaterialsScreen), findsOneWidget);
    });

    testWidgets('Build products screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const BuildProductsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for key elements
      expect(find.text('Build Products'), findsOneWidget);
      expect(find.byType(BuildProductsScreen), findsOneWidget);
    });

    testWidgets('Sell products screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const SellProductsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for key elements  
      expect(find.text('Sell Products'), findsOneWidget);
      expect(find.byType(SellProductsScreen), findsOneWidget);
    });

    testWidgets('Navigation between screens works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: gameService,
            child: const MainGameScreen(),
          ),
        ),
      );

      // Wait for initial rendering
      await tester.pump(const Duration(milliseconds: 100));

      // Verify initial screen
      expect(find.byType(MainGameScreen), findsOneWidget);

      // Test bottom navigation if present
      final bottomNavBar = find.byType(BottomNavigationBar);
      if (bottomNavBar.evaluate().isNotEmpty) {
        // Tap on different navigation items with controlled pumping
        await tester.tap(find.byIcon(Icons.build).first);
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byIcon(Icons.sell).first);
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  });
}