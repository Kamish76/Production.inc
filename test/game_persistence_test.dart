import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/models/game_models.dart';

void main() {
  // Setup for SQLite testing
  setUpAll(() {
    GamePersistenceService.initializeDatabaseFactory();
  });

  group('GamePersistenceService Tests', () {
    test('should save and load game state correctly', () async {
      final persistenceService = GamePersistenceService();

      try {
        // Create a test game state
        final testState = GameState(
          money: 500.0,
          materials: {'cardboard': 10, 'plastic': 5},
          products: {'box': 3, 'bottle': 2},
          buildQuantityPreferences: {'box': 5, 'bottle': 10},
          activeProductions: [
            ProductionTask(
              id: 'test_prod_1',
              productId: 'box',
              startTime: DateTime.now().subtract(const Duration(minutes: 5)),
              durationSeconds: 600,
              quantity: 2,
              isQueued: false,
            ),
          ],
          activeShippingOrders: [
            ShippingOrder(
              id: 'test_ship_1',
              items: const [ShippingItem(productId: 'box', quantity: 1)],
              startTime: DateTime.now().subtract(const Duration(minutes: 2)),
              totalShippingTime: 300,
              totalRevenue: 10.0,
            ),
          ],
          shippingHistory: [
            ShippingHistory(
              id: 'test_hist_1',
              items: const [ShippingItem(productId: 'bottle', quantity: 1)],
              completedTime: DateTime.now().subtract(const Duration(hours: 1)),
              totalRevenue: 5.0,
            ),
          ],
        );

        // Save the state
        await persistenceService.saveGameState(testState);

        // Load the state
        final loadedState = await persistenceService.loadGameState();

        // Verify the data matches
        expect(loadedState.money, equals(testState.money));
        expect(loadedState.materials, equals(testState.materials));
        expect(loadedState.products, equals(testState.products));
        expect(
          loadedState.buildQuantityPreferences,
          equals(testState.buildQuantityPreferences),
        );
        expect(
          loadedState.activeProductions.length,
          equals(testState.activeProductions.length),
        );
        expect(
          loadedState.activeShippingOrders.length,
          equals(testState.activeShippingOrders.length),
        );
        expect(
          loadedState.shippingHistory.length,
          equals(testState.shippingHistory.length),
        );

        // Verify production task details
        final loadedProduction = loadedState.activeProductions.first;
        final originalProduction = testState.activeProductions.first;
        expect(loadedProduction.id, equals(originalProduction.id));
        expect(
          loadedProduction.productId,
          equals(originalProduction.productId),
        );
        expect(loadedProduction.quantity, equals(originalProduction.quantity));
        expect(
          loadedProduction.durationSeconds,
          equals(originalProduction.durationSeconds),
        );
        expect(loadedProduction.isQueued, equals(originalProduction.isQueued));

        // Verify shipping order details
        final loadedShipping = loadedState.activeShippingOrders.first;
        final originalShipping = testState.activeShippingOrders.first;
        expect(loadedShipping.id, equals(originalShipping.id));
        expect(
          loadedShipping.totalRevenue,
          equals(originalShipping.totalRevenue),
        );
        expect(
          loadedShipping.items.length,
          equals(originalShipping.items.length),
        );
      } finally {
        await persistenceService.dispose();
      }
    });

    test('should reset game data correctly', () async {
      final persistenceService = GamePersistenceService();

      try {
        // Create and save a game state with data
        final testState = GameState(
          money: 500.0,
          materials: {'cardboard': 10},
          products: {'box': 5},
          activeProductions: [
            ProductionTask(
              id: 'test_prod',
              productId: 'box',
              startTime: DateTime.now(),
              durationSeconds: 600,
              quantity: 1,
              isQueued: false,
            ),
          ],
        );

        await persistenceService.saveGameState(testState);

        // Reset the game
        await persistenceService.resetGameData();

        // Load the state
        final loadedState = await persistenceService.loadGameState();

        // Verify reset to default values
        expect(loadedState.money, equals(100.0)); // Default starting money
        expect(loadedState.materials, isEmpty);
        expect(loadedState.products, isEmpty);
        expect(loadedState.buildQuantityPreferences, isEmpty);
        expect(loadedState.activeProductions, isEmpty);
        expect(loadedState.activeShippingOrders, isEmpty);
        expect(loadedState.shippingHistory, isEmpty);
      } finally {
        await persistenceService.dispose();
      }
    });

    test('should handle empty database correctly', () async {
      final persistenceService = GamePersistenceService();

      try {
        // Load from empty database
        final loadedState = await persistenceService.loadGameState();

        // Should return default state
        expect(loadedState.money, equals(100.0));
        expect(loadedState.materials, isEmpty);
        expect(loadedState.products, isEmpty);
        expect(loadedState.buildQuantityPreferences, isEmpty);
        expect(loadedState.activeProductions, isEmpty);
        expect(loadedState.activeShippingOrders, isEmpty);
        expect(loadedState.shippingHistory, isEmpty);
      } finally {
        await persistenceService.dispose();
      }
    });

    test('should check save data existence after saving', () async {
      final persistenceService = GamePersistenceService();

      try {
        // Save some data
        await persistenceService.saveGameState(const GameState(money: 200.0));

        // Now should have save data
        expect(await persistenceService.hasSaveData(), isTrue);
      } finally {
        await persistenceService.dispose();
      }
    });
  });
}
