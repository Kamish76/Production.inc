import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/main.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/screens/main_game_screen.dart';
import 'package:game1/screens/buy_materials_screen.dart';
import 'package:game1/screens/build_products_screen.dart';
import 'package:game1/screens/sell_products_screen.dart';

void main() {
  group('Integration Tests - Full Game Flow', () {
    testWidgets('Complete game flow: Buy -> Build -> Sell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      // Start from main screen
      expect(find.byType(MainGameScreen), findsOneWidget);

      // Get initial game state
      final context = tester.element(find.byType(MainGameScreen));
      final gameService = Provider.of<ProductionGameService>(
        context,
        listen: false,
      );
      final initialMoney = gameService.state.money;

      // Step 1: Buy materials
      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();

      // Should be on Buy Materials screen
      expect(find.byType(BuyMaterialsScreen), findsOneWidget);

      // Buy some cardboard (basic material)
      final buyCardboardButton = find.descendant(
        of: find.ancestor(
          of: find.text('📦'), // Cardboard emoji
          matching: find.byType(Card),
        ),
        matching: find.text('Buy 1'),
      );

      if (buyCardboardButton.evaluate().isNotEmpty) {
        await tester.tap(buyCardboardButton);
        await tester.pumpAndSettle();

        // Verify money decreased
        expect(gameService.state.money, lessThan(initialMoney));

        // Verify we have cardboard
        expect(gameService.state.getMaterialCount('cardboard'), greaterThan(0));
      }

      // Step 2: Build products
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build Products'));
      await tester.pumpAndSettle();

      // Should be on Build Products screen
      expect(find.byType(BuildProductsScreen), findsOneWidget);

      // Expand Basic Parts tier if collapsed
      final basicPartsTile = find.ancestor(
        of: find.text('Basic Parts'),
        matching: find.byType(ExpansionTile),
      );

      if (basicPartsTile.evaluate().isNotEmpty) {
        await tester.tap(basicPartsTile);
        await tester.pumpAndSettle();
      }

      // Try to build a box (requires cardboard)
      final buildBoxButton = find.descendant(
        of: find.ancestor(
          of: find.text('📦'), // Box emoji
          matching: find.byType(Card),
        ),
        matching: find.text('Build 1'),
      );

      if (buildBoxButton.evaluate().isNotEmpty &&
          gameService.state.getMaterialCount('cardboard') > 0) {
        await tester.tap(buildBoxButton);
        await tester.pumpAndSettle();

        // Verify production started
        expect(gameService.state.activeProductions.length, greaterThan(0));

        // Verify materials were consumed
        expect(gameService.state.getMaterialCount('cardboard'), equals(0));
      }

      // Step 3: Wait for production to complete and sell
      // Note: In a real scenario, we'd wait for actual production time
      // For testing, we'll simulate time passing or complete production manually

      // Simulate production completion by calling updateProductions
      // (This is a simplified approach for testing)
      while (gameService.state.activeProductions.isNotEmpty) {
        gameService.updateProductions();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Go back and navigate to Sell Products
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sell Products'));
      await tester.pumpAndSettle();

      // Should be on Sell Products screen
      expect(find.byType(SellProductsScreen), findsOneWidget);

      // Try to sell the box we produced
      final sellButton = find.text('Sell 1');

      if (sellButton.evaluate().isNotEmpty &&
          gameService.state.getProductCount('box') > 0) {
        final moneyBeforeSale = gameService.state.money;

        await tester.tap(sellButton.first);
        await tester.pumpAndSettle();

        // Verify shipping order was created
        expect(gameService.state.activeShippingOrders.length, greaterThan(0));

        // Verify product was removed from inventory
        expect(gameService.state.getProductCount('box'), equals(0));

        // Simulate shipping completion
        while (gameService.state.activeShippingOrders.isNotEmpty) {
          gameService
              .updateProductions(); // This handles both production and shipping
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify money increased
        expect(gameService.state.money, greaterThan(moneyBeforeSale));

        // Verify shipping history was created
        expect(gameService.state.shippingHistory.length, greaterThan(0));
      }
    });

    testWidgets('Bulk production and selling workflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MainGameScreen));
      final gameService = Provider.of<ProductionGameService>(
        context,
        listen: false,
      );

      // Buy materials in bulk
      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();

      // Buy 10 cardboard
      final buyBulkButton = find.descendant(
        of: find.ancestor(of: find.text('📦'), matching: find.byType(Card)),
        matching: find.text('Buy 10'),
      );

      if (buyBulkButton.evaluate().isNotEmpty) {
        await tester.tap(buyBulkButton);
        await tester.pumpAndSettle();

        expect(gameService.state.getMaterialCount('cardboard'), equals(10));
      }

      // Build products in bulk
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build Products'));
      await tester.pumpAndSettle();

      // Expand Basic Parts
      final basicPartsTile = find.ancestor(
        of: find.text('Basic Parts'),
        matching: find.byType(ExpansionTile),
      );

      if (basicPartsTile.evaluate().isNotEmpty) {
        await tester.tap(basicPartsTile);
        await tester.pumpAndSettle();
      }

      // Build 10 boxes
      final buildBulkButton = find.descendant(
        of: find.ancestor(of: find.text('📦'), matching: find.byType(Card)),
        matching: find.text('Build 10'),
      );

      if (buildBulkButton.evaluate().isNotEmpty &&
          gameService.state.getMaterialCount('cardboard') >= 10) {
        await tester.tap(buildBulkButton);
        await tester.pumpAndSettle();

        expect(gameService.state.activeProductions.length, greaterThan(0));
        expect(gameService.state.getMaterialCount('cardboard'), equals(0));
      }

      // Wait for production completion
      while (gameService.state.activeProductions.isNotEmpty) {
        gameService.updateProductions();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Sell products in bulk
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sell Products'));
      await tester.pumpAndSettle();

      final sellBulkButton = find.text('Sell 10');

      if (sellBulkButton.evaluate().isNotEmpty &&
          gameService.state.getProductCount('box') >= 10) {
        await tester.tap(sellBulkButton.first);
        await tester.pumpAndSettle();

        expect(gameService.state.activeShippingOrders.length, greaterThan(0));
        expect(gameService.state.getProductCount('box'), equals(0));
      }
    });

    testWidgets('Multi-tier production chain', (WidgetTester tester) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      // This test verifies the flow structure and navigation between screens
      // for multi-tier production chains

      // Navigate through all screens to ensure they work together
      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();
      expect(find.byType(BuyMaterialsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build Products'));
      await tester.pumpAndSettle();
      expect(find.byType(BuildProductsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sell Products'));
      await tester.pumpAndSettle();
      expect(find.byType(SellProductsScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(MainGameScreen), findsOneWidget);
    });

    testWidgets('Game persistence during navigation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(MainGameScreen));
      final gameService = Provider.of<ProductionGameService>(
        context,
        listen: false,
      );
      final initialMoney = gameService.state.money;

      // Make a purchase
      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();

      final buyButton = find.text('Buy 1').first;
      await tester.tap(buyButton);
      await tester.pumpAndSettle();

      final moneyAfterPurchase = gameService.state.money;
      expect(moneyAfterPurchase, lessThan(initialMoney));

      // Navigate away and back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Build Products'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();

      // Money should still be the same
      expect(gameService.state.money, equals(moneyAfterPurchase));
    });

    testWidgets('Settings screen integration', (WidgetTester tester) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Test save functionality
      await tester.tap(find.text('Save Game'));
      await tester.pumpAndSettle();

      // Should show confirmation
      expect(find.text('Game saved successfully!'), findsOneWidget);

      // Test help dialogs
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();

      expect(find.text('🎯 Goal'), findsOneWidget);

      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();

      // Test game tips
      await tester.tap(find.text('Game Tips'));
      await tester.pumpAndSettle();

      expect(find.text('💡 Efficiency Tips'), findsOneWidget);

      await tester.tap(find.text('Thanks!'));
      await tester.pumpAndSettle();
    });

    testWidgets('Error recovery and UI consistency', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProductionIncApp());
      await tester.pumpAndSettle();

      // Perform operations that might fail
      await tester.tap(find.text('Buy Materials'));
      await tester.pumpAndSettle();

      // Rapidly tap buy buttons to test error handling
      final buyButtons = find.text('Buy 10');
      for (int i = 0; i < 10; i++) {
        if (buyButtons.evaluate().isNotEmpty) {
          await tester.tap(buyButtons.first);
          await tester.pump(const Duration(milliseconds: 50));
        }
      }
      await tester.pumpAndSettle();

      // UI should still be responsive and show consistent state
      expect(find.byType(BuyMaterialsScreen), findsOneWidget);

      // Get game service to check state
      final context = tester.element(find.byType(BuyMaterialsScreen));
      final gameService = Provider.of<ProductionGameService>(
        context,
        listen: false,
      );
      expect(
        gameService.state.money,
        greaterThanOrEqualTo(0),
      ); // Money should never go negative
    });
  });
}
