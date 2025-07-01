import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/main.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/screens/main_game_screen.dart';
import 'package:game1/screens/buy_materials_screen.dart';
import 'package:game1/screens/build_products_screen.dart';
import 'package:game1/screens/sell_products_screen.dart';
import 'package:game1/screens/settings_screen.dart';

void main() {
  group('Widget Tests', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService();
    });

    testWidgets('Main app should load without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      // Should show the main game screen
      expect(find.byType(MainGameScreen), findsOneWidget);

      // Should have navigation buttons
      expect(find.text('Buy Materials'), findsOneWidget);
      expect(find.text('Build Products'), findsOneWidget);
      expect(find.text('Sell Products'), findsOneWidget);
    });

    testWidgets('Navigation between screens works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: MainGameScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Test navigation to Buy Materials screen
      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();
      expect(find.byType(BuyMaterialsScreen), findsOneWidget);

      // Go back and test Build Products screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build Products'));
      await tester.pumpAndSettle();
      expect(find.byType(BuildProductsScreen), findsOneWidget);

      // Go back and test Sell Products screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sell Products'));
      await tester.pumpAndSettle();
      expect(find.byType(SellProductsScreen), findsOneWidget);
    });

    testWidgets('Buy Materials screen functionality', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: BuyMaterialsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should show materials list
      expect(find.text('Buy Materials'), findsAtLeastNWidgets(1));

      // Should have material cards
      expect(find.text('📦'), findsAtLeastNWidgets(1)); // Cardboard emoji

      // Should have buy buttons
      expect(find.text('Buy 1'), findsAtLeastNWidgets(1));
      expect(find.text('Buy 10'), findsAtLeastNWidgets(1));
    });

    testWidgets('Buy material interaction works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: BuyMaterialsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Get initial money
      final initialMoney = gameService.state.money;

      // Find and tap a buy button
      final buyButton = find.text('Buy 1').first;
      await tester.tap(buyButton);
      await tester.pumpAndSettle();

      // Money should have decreased (assuming the buy was successful)
      // Note: This test assumes we have enough money to buy at least one material
      if (initialMoney >= 1.0) {
        // Assuming cheapest material costs at least $1
        expect(gameService.state.money, lessThan(initialMoney));
      }
    });

    testWidgets('Build Products screen functionality', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: BuildProductsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should show products organized by tiers
      expect(find.text('Basic Parts'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Complex'), findsOneWidget);
      expect(find.text('Retail'), findsOneWidget);

      // Should have expand/collapse functionality
      expect(find.byIcon(Icons.keyboard_arrow_down), findsAtLeastNWidgets(1));
    });

    testWidgets('Sell Products screen functionality', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: SellProductsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should show sell products interface
      expect(find.text('Sell Products'), findsAtLeastNWidgets(1));

      // Should show active shipping section (even if empty)
      expect(find.text('Active Shipping'), findsOneWidget);

      // Should show shipping history section
      expect(find.text('Shipping History'), findsOneWidget);
    });

    testWidgets('Settings screen functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should show settings sections
      expect(find.text('Game Data'), findsOneWidget);
      expect(find.text('Game Statistics'), findsOneWidget);
      expect(find.text('Help & Tutorial'), findsOneWidget);

      // Should have save and reset buttons
      expect(find.text('Save Game'), findsOneWidget);
      expect(find.text('Reset Game'), findsOneWidget);
    });

    testWidgets('Help dialogs work', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: SettingsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Test How to Play dialog
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();

      expect(find.text('How to Play'), findsAtLeastNWidgets(1));
      expect(find.text('🎯 Goal'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      // Test Game Tips dialog
      await tester.tap(find.text('Game Tips'));
      await tester.pumpAndSettle();

      expect(find.text('Game Tips'), findsAtLeastNWidgets(1));
      expect(find.text('💡 Efficiency Tips'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Thanks!'));
      await tester.pumpAndSettle();
    });

    testWidgets('Money display updates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: MainGameScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should display money
      final moneyText = '\$${gameService.state.money.toStringAsFixed(2)}';
      expect(find.text(moneyText), findsOneWidget);
    });

    testWidgets('Game state persists across widget rebuilds', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: MainGameScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final initialMoney = gameService.state.money;

      // Trigger a rebuild
      await tester.pump();

      // Money should remain the same
      expect(gameService.state.money, equals(initialMoney));
    });

    testWidgets('Error handling in UI works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: BuyMaterialsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Try to buy with insufficient funds
      // First, set money to 0 if possible (this would require modifying the service)
      // For now, just test that the UI doesn't crash when operations fail

      // Find and tap multiple buy buttons rapidly
      final buyButtons = find.text('Buy 10');
      if (buyButtons.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(buyButtons.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();

        // UI should still be functional
        expect(find.byType(BuyMaterialsScreen), findsOneWidget);
      }
    });

    testWidgets('Responsive layout works on different screen sizes', (
      WidgetTester tester,
    ) async {
      // Test with narrow screen
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        ChangeNotifierProvider<ProductionGameService>.value(
          value: gameService,
          child: MaterialApp(home: BuildProductsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Should still display properly on narrow screen
      expect(find.byType(BuildProductsScreen), findsOneWidget);

      // Test with wide screen
      tester.binding.window.physicalSizeTestValue = const Size(800, 600);

      await tester.pump();

      // Should still display properly on wide screen
      expect(find.byType(BuildProductsScreen), findsOneWidget);

      // Reset to default
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });
  });
}
