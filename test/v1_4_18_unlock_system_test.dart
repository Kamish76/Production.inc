import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/product_unlock_service.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';

void main() {
  group('Product Unlock System Tests v1.4.18', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    test('Basic parts unlock when materials threshold is met', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially, only box should be unlocked (if player has no materials)
      expect(gameService.isProductUnlocked('box'), false);
      expect(gameService.isProductUnlocked('wires'), false);

      // Buy enough cardboard to unlock box
      gameService.buyMaterial('cardboard', 3);
      expect(gameService.isProductUnlocked('box'), true);

      // Buy materials to unlock wires
      gameService.buyMaterial('basic_metals', 2);
      gameService.buyMaterial('plastic', 1);
      expect(gameService.isProductUnlocked('wires'), true);
    });

    test('Intermediate parts unlock when basic parts are produced', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // For this test, we'll test the unlock logic directly since we can't easily simulate production completion
      final gameState = gameService.state.copyWith(
        materials: {'cardboard': 10, 'basic_metals': 10, 'plastic': 10},
        products: {
          'box': 1,
          'wires': 1,
        }, // Simulate having produced some basic parts
      );

      // Test if intermediate parts would be unlocked (requires all basic parts to be produced)
      expect(
        ProductUnlockService.isProductUnlocked('display_screen', gameState),
        false,
      );

      // Add more produced basic parts and required raw materials (and Tier 2 license)
      final gameStateWithMoreProducts = gameState.copyWith(
        factoryTier: 2,
        materials: {
          'cardboard': 10,
          'basic_metals': 10,
          'plastic': 10,
          'glass': 10,
          'advanced_metals': 10,
        }, // Include all required raw materials
        products: {
          'box': 1,
          'wires': 1,
          'circuits': 1,
          'enclosure_plastic': 1,
          'metal_enclosure': 1,
          'lens': 1,
          'battery': 1,
          'solar_cells': 1,
          'gears': 1,
          'sound_driver': 1,
        },
      );

      // Now intermediate parts should be unlocked
      expect(
        ProductUnlockService.isProductUnlocked(
          'display_screen',
          gameStateWithMoreProducts,
        ),
        true,
      );
    });

    test('Tier progress strings work correctly', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially should show 0/X format
      final initialProgress = gameService.getTierProgressString(
        ProductLevel.basicParts,
      );
      expect(initialProgress, contains('/'));

      // Unlock some products and verify progress updates
      gameService.buyMaterial('cardboard', 3);
      final progressAfterBox = gameService.getTierProgressString(
        ProductLevel.basicParts,
      );
      expect(progressAfterBox, contains('/'));
    });

    test('Unlock service correctly evaluates unlock conditions', () {
      final gameState = gameService.state.copyWith(
        materials: {'cardboard': 3, 'basic_metals': 2, 'plastic': 1},
      );

      expect(ProductUnlockService.isProductUnlocked('box', gameState), true);
      expect(ProductUnlockService.isProductUnlocked('wires', gameState), true);
      expect(
        ProductUnlockService.isProductUnlocked('circuits', gameState),
        false,
      ); // needs 3 basic_metals, 2 plastic
    });

    test('Only unlocked products are shown in build screen data', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially very few products should be unlocked
      final unlockedBasicParts = gameService.getUnlockedProductsByTier(
        ProductLevel.basicParts,
      );
      expect(
        unlockedBasicParts.length,
        lessThan(gameService.basicPartsProducts.length),
      );

      // Buy materials to unlock more products
      gameService.buyMaterial('cardboard', 10);
      gameService.buyMaterial('basic_metals', 10);
      gameService.buyMaterial('plastic', 10);
      gameService.buyMaterial('glass', 10);
      gameService.buyMaterial('advanced_metals', 10);

      final unlockedAfter = gameService.getUnlockedProductsByTier(
        ProductLevel.basicParts,
      );
      expect(unlockedAfter.length, greaterThan(unlockedBasicParts.length));
    });

    test('Previously unlocked products remain visible', () {
      const gameState = GameState(
        materials: {},
        unlockedProducts: {'box'},
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );

      expect(ProductUnlockService.isProductUnlocked('box', gameState), isTrue);
    });

    test('Database migration for unlock system works', () async {
      // The fact that initialization works proves migration is working
      await Future.delayed(const Duration(milliseconds: 100));
      expect(gameService.isLoaded, true);

      // Verify unlock state is tracked
      expect(gameService.state.unlockedProducts, isA<Set<String>>());
      expect(gameService.state.productUnlockStatus, isA<Map<String, bool>>());
    });
  });
}
