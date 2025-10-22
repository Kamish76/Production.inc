import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';

/// Test to verify bug fix for auto-buy machines not triggering unlocks
/// 
/// Bug Description: When auto-buy machines purchase materials, unlocks are not
/// triggered, even though the materials should unlock new products. This is
/// primarily a dev mode problem but could cause issues in actual gameplay.
/// 
/// Root Cause: _processAutoBuyTick() was not calling _checkAndUpdateUnlocks()
/// after purchasing materials, unlike manual buyMaterial() which does call it.
/// 
/// Fix: Added _checkAndUpdateUnlocks() call in _processAutoBuyTick() after
/// materials are purchased, ensuring auto-buy triggers unlocks just like manual purchases.
void main() {
  group('Bug Fix: Auto-Buy Machines Not Triggering Unlocks', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    test(
      'Auto-buy machines trigger unlocks when purchasing materials',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Give player money and set up auto-buy machines
        gameService.addMoney(1000);
        gameService.setAutoBuyMachineCount(2);
        gameService.increaseAutoBuyCapacity(); // Set capacity to 20
        gameService.toggleAutoBuy(); // Enable auto-buy

        // Verify starting state - no products unlocked
        expect(gameService.state.unlockedProducts.isEmpty, true);
        expect(gameService.isProductUnlocked('box'), false);
        expect(gameService.isProductUnlocked('wires'), false);

        // Manually trigger auto-buy tick (simulating the periodic update)
        // This should purchase materials and trigger unlock checks
        gameService.updateProductions();

        // After auto-buy tick, materials should be purchased
        final cardboardAmount = gameService.state.materials['cardboard'] ?? 0;
        final metalsAmount = gameService.state.materials['basic_metals'] ?? 0;
        final plasticAmount = gameService.state.materials['plastic'] ?? 0;

        // Verify materials were purchased (at least some)
        expect(
          cardboardAmount + metalsAmount + plasticAmount,
          greaterThan(0),
          reason: 'Auto-buy should have purchased some materials',
        );

        // BUG FIX VERIFICATION: Check if products are unlocked after auto-buy
        // Box should be unlocked if cardboard >= 3
        if (cardboardAmount >= 3) {
          expect(
            gameService.isProductUnlocked('box'),
            true,
            reason: 'Box should be unlocked after auto-buy purchases cardboard',
          );
        }

        // Wires should be unlocked if basic_metals >= 2 AND plastic >= 1
        if (metalsAmount >= 2 && plasticAmount >= 1) {
          expect(
            gameService.isProductUnlocked('wires'),
            true,
            reason: 'Wires should be unlocked after auto-buy purchases materials',
          );
        }
      },
    );

    test(
      'Multiple auto-buy ticks accumulate unlocks correctly',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Give player money and set up auto-buy machines
        gameService.addMoney(10000);
        gameService.setAutoBuyMachineCount(3); // More machines for faster buying
        gameService.increaseAutoBuyCapacity(); // Capacity: 20
        gameService.increaseAutoBuyCapacity(); // Capacity: 30
        gameService.toggleAutoBuy(); // Enable auto-buy

        // Track unlocked products over multiple ticks
        final unlockedOverTime = <String>[];
        int previousUnlockCount = 0;

        // Simulate multiple auto-buy ticks
        for (int i = 0; i < 5; i++) {
          // Trigger auto-buy tick
          gameService.updateProductions();

          // Check for newly unlocked products
          final currentUnlockCount = gameService.state.unlockedProducts.length;
          if (currentUnlockCount > previousUnlockCount) {
            // New products unlocked!
            final newUnlocks = gameService.state.unlockedProducts
                .where((id) => !unlockedOverTime.contains(id))
                .toList();
            unlockedOverTime.addAll(newUnlocks);
            previousUnlockCount = currentUnlockCount;
          }

          // Small delay to simulate time passing
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Verify that unlocks accumulated over multiple ticks
        // At minimum, we should have unlocked SOME products with all that money
        expect(
          unlockedOverTime.length,
          greaterThan(0),
          reason: 'Multiple auto-buy ticks should accumulate unlocks',
        );
      },
    );

    test(
      'Auto-buy unlocks match manual buy unlocks for same materials',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Create two parallel game services for comparison
        final gameServiceManual = ProductionGameService(testMode: true);
        final gameServiceAuto = ProductionGameService(testMode: true);

        await Future.delayed(const Duration(milliseconds: 100));

        // Manual purchase scenario
        gameServiceManual.addMoney(500);
        gameServiceManual.buyMaterial('cardboard', 10);
        gameServiceManual.buyMaterial('basic_metals', 10);
        gameServiceManual.buyMaterial('plastic', 10);

        // Auto-buy scenario (set up to buy similar amounts)
        gameServiceAuto.addMoney(500);
        gameServiceAuto.setAutoBuyMachineCount(5);
        gameServiceAuto.increaseAutoBuyCapacity(); // Capacity: 20
        gameServiceAuto.toggleAutoBuy();

        // Trigger auto-buy until it reaches similar material levels
        for (int i = 0; i < 10; i++) {
          gameServiceAuto.updateProductions();
          await Future.delayed(const Duration(milliseconds: 10));

          // Stop when materials are roughly similar
          final autoCardboard = gameServiceAuto.state.materials['cardboard'] ?? 0;
          if (autoCardboard >= 10) break;
        }

        // Compare unlocked products
        final manualUnlocks = gameServiceManual.state.unlockedProducts;
        final autoUnlocks = gameServiceAuto.state.unlockedProducts;

        // BUG FIX VERIFICATION: Both should have similar unlocks
        // (exact match depends on auto-buy purchasing order, but should be close)
        expect(
          autoUnlocks.length,
          greaterThanOrEqualTo(manualUnlocks.length - 1),
          reason: 'Auto-buy should unlock similar number of products as manual buy',
        );

        // Check specific products that should be unlocked in both
        if (gameServiceManual.isProductUnlocked('box')) {
          final autoCardboard = gameServiceAuto.state.materials['cardboard'] ?? 0;
          if (autoCardboard >= 3) {
            expect(
              gameServiceAuto.isProductUnlocked('box'),
              true,
              reason: 'Box should be unlocked in both manual and auto scenarios',
            );
          }
        }
      },
    );

    test(
      'Auto-build machines also trigger unlocks when building products',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        // Set up game state: buy materials manually first
        gameService.addMoney(1000);
        gameService.buyMaterial('cardboard', 50);
        gameService.buyMaterial('basic_metals', 50);
        gameService.buyMaterial('plastic', 50);

        // Verify starting state
        final initialUnlocks = Set<String>.from(gameService.state.unlockedProducts);
        expect(initialUnlocks.contains('box'), true);
        expect(initialUnlocks.contains('wires'), true);

        // Set up auto-build machines for basic parts
        gameService.incrementAutoBuildMachines('basicParts');
        gameService.incrementAutoBuildMachines('basicParts');
        gameService.toggleAutoBuild('basicParts'); // Enable auto-build

        // Trigger auto-build tick
        gameService.updateProductions();

        // After auto-build, some basic parts should be built
        final boxCount = gameService.state.products['box'] ?? 0;
        final wiresCount = gameService.state.products['wires'] ?? 0;

        // Verify products were built
        expect(
          boxCount + wiresCount,
          greaterThan(0),
          reason: 'Auto-build should have built some products',
        );

        // BUG FIX VERIFICATION: Check if intermediate parts unlock after basic parts are built
        // Battery requires wires to be produced
        if (wiresCount > 0) {
          // Battery should now be unlockable (if other materials available)
          final advancedMetals = gameService.state.materials['advanced_metals'] ?? 0;
          if (advancedMetals >= 2 && (gameService.state.materials['plastic'] ?? 0) >= 2) {
            expect(
              gameService.isProductUnlocked('battery'),
              true,
              reason: 'Battery should unlock after wires are produced by auto-build',
            );
          }
        }
      },
    );
  });
}
