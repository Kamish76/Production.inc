import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/models/game_models.dart';

/// Test to verify bug fix for newly unlocked items not showing in build section
/// 
/// Bug Description: When a new game is created and materials are bought,
/// newly unlocked items don't show in the build section, even though they're
/// identified as unlocked (basic parts counter increments correctly).
/// 
/// Root Cause: _checkAndUpdateUnlocks() was not calling notifyListeners(),
/// so the UI never received notification to re-render with newly unlocked products.
void main() {
  group('Bug Fix: Unlock Display Issue', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    test(
      'Newly unlocked items appear in build section after buying materials',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify starting state - no products unlocked
        expect(gameService.state.unlockedProducts.isEmpty, true);
        final initialBasicParts = gameService.getUnlockedProductsByTier(
          ProductLevel.basicParts,
        );
        expect(initialBasicParts.isEmpty, true);

        // Buy materials to unlock basic parts
        final success1 = gameService.buyMaterial('cardboard', 5);
        expect(success1, true);

        // After buying cardboard, box should be unlocked and visible
        expect(gameService.isProductUnlocked('box'), true);
        final unlockedAfterCardboard = gameService.getUnlockedProductsByTier(
          ProductLevel.basicParts,
        );
        expect(
          unlockedAfterCardboard.any((p) => p.id == 'box'),
          true,
          reason: 'Box should appear in unlocked products list',
        );

        // Buy more materials to unlock additional items
        final success2 = gameService.buyMaterial('basic_metals', 5);
        final success3 = gameService.buyMaterial('plastic', 5);
        expect(success2, true);
        expect(success3, true);

        // After buying metals and plastic, more items should be unlocked
        expect(gameService.isProductUnlocked('wires'), true);
        expect(gameService.isProductUnlocked('circuits'), true);

        final unlockedAfterMoreMaterials =
            gameService.getUnlockedProductsByTier(
          ProductLevel.basicParts,
        );

        // Verify all unlocked items are in the list returned to the UI
        expect(
          unlockedAfterMoreMaterials.any((p) => p.id == 'wires'),
          true,
          reason: 'Wires should appear in unlocked products list',
        );
        expect(
          unlockedAfterMoreMaterials.any((p) => p.id == 'circuits'),
          true,
          reason: 'Circuits should appear in unlocked products list',
        );

        // Verify the count matches (at least 3 items: box, wires, circuits)
        expect(
          unlockedAfterMoreMaterials.length,
          greaterThanOrEqualTo(3),
          reason: 'Should have at least box, wires, and circuits unlocked',
        );
      },
    );

    test(
      'Tier progress counter reflects newly unlocked products',
      () async {
        await Future.delayed(const Duration(milliseconds: 100));

        // Initial progress should be 0/X
        final initialProgress = gameService.getTierProgressString(
          ProductLevel.basicParts,
        );
        expect(initialProgress.startsWith('0/'), true);

        // Buy materials to unlock items
        gameService.buyMaterial('cardboard', 5);
        gameService.buyMaterial('basic_metals', 5);
        gameService.buyMaterial('plastic', 5);

        // Progress should now show non-zero unlocked count
        final updatedProgress = gameService.getTierProgressString(
          ProductLevel.basicParts,
        );

        // Extract the unlocked count from "X/Y" format
        final parts = updatedProgress.split('/');
        expect(parts.length, 2);

        final unlockedCount = int.parse(parts[0]);
        expect(
          unlockedCount,
          greaterThan(0),
          reason: 'Unlocked count should be greater than 0 after buying materials',
        );
      },
    );

    test(
      'State and unlock status cache stay synchronized',
      () async {
        await Future.delayed(const Duration(milliseconds: 100));

        // Buy materials
        gameService.buyMaterial('cardboard', 5);

        // Check both methods of checking unlock status
        final isUnlockedViaState = gameService.state.isProductUnlocked('box');
        final isUnlockedViaService = gameService.isProductUnlocked('box');

        expect(isUnlockedViaState, true);
        expect(isUnlockedViaService, true);

        // Verify the cached status matches
        expect(
          gameService.state.productUnlockStatus['box'],
          true,
          reason: 'productUnlockStatus cache should be updated',
        );

        // Verify the product appears in the unlocked set
        expect(
          gameService.state.unlockedProducts.contains('box'),
          true,
          reason: 'unlockedProducts set should contain box',
        );
      },
    );

    test(
      'Multiple material purchases correctly accumulate unlocks',
      () async {
        await Future.delayed(const Duration(milliseconds: 100));

        // Buy materials incrementally
        gameService.buyMaterial('cardboard', 3);
        final unlocksAfterFirst = gameService.getUnlockedProductsByTier(
          ProductLevel.basicParts,
        ).length;
        expect(unlocksAfterFirst, greaterThan(0));

        gameService.buyMaterial('basic_metals', 2);
        gameService.buyMaterial('plastic', 1);
        final unlocksAfterSecond = gameService.getUnlockedProductsByTier(
          ProductLevel.basicParts,
        ).length;
        expect(unlocksAfterSecond, greaterThan(unlocksAfterFirst));

        gameService.buyMaterial('glass', 2);
        gameService.buyMaterial('advanced_metals', 3);
        final unlocksAfterThird = gameService.getUnlockedProductsByTier(
          ProductLevel.basicParts,
        ).length;
        expect(unlocksAfterThird, greaterThanOrEqualTo(unlocksAfterSecond));

        // All previously unlocked items should still be unlocked
        expect(gameService.isProductUnlocked('box'), true);
        expect(gameService.isProductUnlocked('wires'), true);
      },
    );
  });
}
