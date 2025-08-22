import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';

void main() {
  group('New Player Experience Tests v1.4.18', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    test('New player has no unlocked products initially', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // New player should have no unlocked products
      expect(gameService.state.unlockedProducts.isEmpty, true);

      // All tier progress should show 0/X format
      expect(
        gameService.getTierProgressString(
          gameService.productsByTier.keys.first,
        ),
        contains('/'),
      );

      // No products should be visible in any tier
      for (final tier in gameService.productsByTier.keys) {
        final unlockedProducts = gameService.getUnlockedProductsByTier(tier);
        expect(unlockedProducts.isEmpty, true);
      }
    });

    test('First product unlocks when player buys cardboard', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Initially no unlocked products
      expect(gameService.state.unlockedProducts.isEmpty, true);

      // Buy cardboard to unlock Box
      final success = gameService.buyMaterial('cardboard', 3);
      expect(success, true);

      // Now Box should be unlocked
      expect(gameService.isProductUnlocked('box'), true);
      expect(gameService.state.unlockedProducts.contains('box'), true);

      // Basic Parts tier should show progress 1/X (not 0/X)
      final basicPartsTier = gameService.productsByTier.keys.firstWhere(
        (tier) => gameService.getTierName(tier) == 'Basic Parts',
      );
      final progressString = gameService.getTierProgressString(basicPartsTier);
      expect(progressString.startsWith('1/'), true);
    });

    test(
      'Player can see tier structure even with no unlocked products',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Even with no unlocked products, all tiers should be accessible for structure visibility
        expect(gameService.productsByTier.isNotEmpty, true);
        expect(
          gameService.productsByTier.length,
          greaterThan(3),
        ); // Basic, Intermediate, Complex, Retail

        // Each tier should have a name
        for (final tier in gameService.productsByTier.keys) {
          final tierName = gameService.getTierName(tier);
          expect(tierName.isNotEmpty, true);
        }
      },
    );

    test('Unlock progression follows correct order', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Start with materials that unlock multiple basic parts
      gameService.buyMaterial('cardboard', 10);
      gameService.buyMaterial('basic_metals', 10);
      gameService.buyMaterial('plastic', 10);

      // Should unlock several basic parts
      expect(gameService.isProductUnlocked('box'), true);
      expect(gameService.isProductUnlocked('wires'), true);
      expect(gameService.isProductUnlocked('circuits'), true);

      // But intermediate parts should still be locked (need production, not just materials)
      expect(gameService.isProductUnlocked('display_screen'), false);
      expect(gameService.isProductUnlocked('processor'), false);
    });
  });
}
