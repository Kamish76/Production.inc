import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/models/game_state.dart';

void main() {
  group('V1.4.11 UI Consistency Tests', () {
    test('Buy quantity preferences work correctly', () {
      final gameService = ProductionGameService();

      // Test default preference
      expect(
        gameService.getBuyQuantityPreference('basic_metals'),
        equals(1),
      ); // Default
      expect(
        gameService.getBuyQuantityPreference('plastic'),
        equals(1),
      ); // Default

      // Test setting new preference
      gameService.setBuyQuantityPreference('basic_metals', 5);
      expect(gameService.getBuyQuantityPreference('basic_metals'), equals(5));

      gameService.setBuyQuantityPreference('plastic', 10);
      expect(gameService.getBuyQuantityPreference('plastic'), equals(10));

      // Test invalid quantity is ignored
      gameService.setBuyQuantityPreference('basic_metals', 7); // Invalid
      expect(
        gameService.getBuyQuantityPreference('basic_metals'),
        equals(5),
      ); // Unchanged

      gameService.setBuyQuantityPreference('basic_metals', 15); // Invalid
      expect(
        gameService.getBuyQuantityPreference('basic_metals'),
        equals(5),
      ); // Unchanged
    });

    test('Sell quantity preferences work correctly', () {
      final gameService = ProductionGameService();

      // Test default preference
      expect(
        gameService.getSellQuantityPreference('box'),
        equals(1),
      ); // Default
      expect(
        gameService.getSellQuantityPreference('bottle'),
        equals(1),
      ); // Default

      // Test setting new preference
      gameService.setSellQuantityPreference('box', 5);
      expect(gameService.getSellQuantityPreference('box'), equals(5));

      gameService.setSellQuantityPreference('bottle', 10);
      expect(gameService.getSellQuantityPreference('bottle'), equals(10));

      // Test invalid quantity is ignored
      gameService.setSellQuantityPreference('box', 3); // Invalid
      expect(
        gameService.getSellQuantityPreference('box'),
        equals(5),
      ); // Unchanged

      gameService.setSellQuantityPreference('box', 20); // Invalid
      expect(
        gameService.getSellQuantityPreference('box'),
        equals(5),
      ); // Unchanged
    });

    test('Preferences persist correctly in GameState', () {
      final state = const GameState(
        buyQuantityPreferences: {'material1': 5, 'material2': 10},
        sellQuantityPreferences: {'product1': 5, 'product2': 10},
      );

      // Test copyWith preserves preferences
      final newState = state.copyWith(money: 500.0);
      expect(
        newState.buyQuantityPreferences,
        equals(state.buyQuantityPreferences),
      );
      expect(
        newState.sellQuantityPreferences,
        equals(state.sellQuantityPreferences),
      );

      // Test updating preferences
      final updatedState = state.copyWith(
        buyQuantityPreferences: {'material1': 10, 'material3': 1},
      );
      expect(updatedState.buyQuantityPreferences['material1'], equals(10));
      expect(updatedState.buyQuantityPreferences['material3'], equals(1));
    });

    test('Valid quantity values are enforced', () {
      final gameService = ProductionGameService();

      // Valid quantities for buy/sell: 1, 5, 10
      gameService.setBuyQuantityPreference('test', 1);
      expect(gameService.getBuyQuantityPreference('test'), equals(1));

      gameService.setBuyQuantityPreference('test', 5);
      expect(gameService.getBuyQuantityPreference('test'), equals(5));

      gameService.setBuyQuantityPreference('test', 10);
      expect(gameService.getBuyQuantityPreference('test'), equals(10));

      // Invalid quantities should be ignored
      gameService.setBuyQuantityPreference('test', 2);
      expect(
        gameService.getBuyQuantityPreference('test'),
        equals(10),
      ); // Unchanged

      gameService.setBuyQuantityPreference('test', 15);
      expect(
        gameService.getBuyQuantityPreference('test'),
        equals(10),
      ); // Unchanged

      // Same for sell preferences
      gameService.setSellQuantityPreference('product', 5);
      expect(gameService.getSellQuantityPreference('product'), equals(5));

      gameService.setSellQuantityPreference('product', 3); // Invalid
      expect(
        gameService.getSellQuantityPreference('product'),
        equals(5),
      ); // Unchanged
    });

    test('GameState includes new preference fields', () {
      final state = const GameState(
        money: 1000.0,
        materials: {'basic_metals': 10},
        products: {'box': 5},
        buyQuantityPreferences: {'basic_metals': 10},
        sellQuantityPreferences: {'box': 5},
        buildQuantityPreferences: {'box': 10},
      );

      expect(state.buyQuantityPreferences['basic_metals'], equals(10));
      expect(state.sellQuantityPreferences['box'], equals(5));
      expect(state.buildQuantityPreferences['box'], equals(10));

      // Test that all fields are preserved in copyWith
      final newState = state.copyWith(money: 2000.0);
      expect(
        newState.buyQuantityPreferences,
        equals(state.buyQuantityPreferences),
      );
      expect(
        newState.sellQuantityPreferences,
        equals(state.sellQuantityPreferences),
      );
      expect(
        newState.buildQuantityPreferences,
        equals(state.buildQuantityPreferences),
      );
    });
  });
}
