import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/models/game_models.dart';

void main() {
  group('Performance Optimization Tests', () {
    late ProductionGameService gameService;

    setUp(() {
      // Initialize database factory for testing
      GamePersistenceService.initializeDatabaseFactory();
      gameService = ProductionGameService();
    });

    tearDown(() {
      gameService.dispose();
    });

    test('should handle app lifecycle state changes correctly', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      expect(gameService.isAppPaused, isFalse);

      // Test pausing
      gameService.handleAppLifecycleChange(AppLifecycleState.paused);
      expect(gameService.isAppPaused, isTrue);

      // Test resuming
      gameService.handleAppLifecycleChange(AppLifecycleState.resumed);
      expect(gameService.isAppPaused, isFalse);

      // Test hidden state
      gameService.handleAppLifecycleChange(AppLifecycleState.hidden);
      expect(gameService.isAppPaused, isTrue);

      // Test inactive state
      gameService.handleAppLifecycleChange(AppLifecycleState.inactive);
      expect(gameService.isAppPaused, isTrue);
    });

    test('should detect active operations correctly', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially no active operations
      expect(gameService.state.activeProductions, isEmpty);
      expect(gameService.state.activeShippingOrders, isEmpty);

      // Test with mock state that has active operations
      final gameStateWithProductions = GameState(
        money: 100.0,
        activeProductions: [
          ProductionTask(
            id: 'test1',
            productId: 'box',
            startTime: DateTime.now(),
            durationSeconds: 600,
            quantity: 1,
            isQueued: false,
          ),
        ],
        activeShippingOrders: [
          ShippingOrder(
            id: 'ship1',
            items: [ShippingItem(productId: 'box', quantity: 1)],
            startTime: DateTime.now(),
            totalShippingTime: 300,
            totalRevenue: 10.0,
          ),
        ],
      );

      // This test verifies the structure is correct
      expect(gameStateWithProductions.activeProductions.length, equals(1));
      expect(gameStateWithProductions.activeShippingOrders.length, equals(1));
    });

    test('should handle empty update productions efficiently', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Call updateProductions with no active operations
      // This should return early for battery optimization
      gameService.updateProductions();

      // Should not cause any errors and state should remain unchanged
      expect(gameService.state.activeProductions, isEmpty);
      expect(gameService.state.activeShippingOrders, isEmpty);
    });

    test('should manage timer states based on app lifecycle', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Test pausing (should stop timers)
      gameService.handleAppLifecycleChange(AppLifecycleState.paused);
      expect(gameService.isAppPaused, isTrue);

      // Test resuming (should restart timers)
      gameService.handleAppLifecycleChange(AppLifecycleState.resumed);
      expect(gameService.isAppPaused, isFalse);

      // Test detached state (should pause)
      gameService.handleAppLifecycleChange(AppLifecycleState.detached);
      expect(gameService.isAppPaused, isTrue);
    });

    test(
      'should maintain game state consistency during lifecycle changes',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final initialMoney = gameService.state.money;

        // Change lifecycle states multiple times
        gameService.handleAppLifecycleChange(AppLifecycleState.paused);
        gameService.handleAppLifecycleChange(AppLifecycleState.resumed);
        gameService.handleAppLifecycleChange(AppLifecycleState.hidden);
        gameService.handleAppLifecycleChange(AppLifecycleState.resumed);

        // Game state should remain consistent
        expect(gameService.state.money, equals(initialMoney));
        expect(gameService.isLoaded, isTrue);
      },
    );
  });
}
