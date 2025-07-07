import 'package:flutter_test/flutter_test.dart';
import '../lib/services/production_game_service.dart';

void main() {
  group('Queue Sequential Processing Tests', () {
    test('Queue processes tasks one at a time, not in batches', () async {
      final gameService = ProductionGameService();

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        // Buy enough materials for multiple boxes
        gameService.buyMaterial('cardboard', 15); // 5 boxes × 3 cardboard each

        // Start production of 5 boxes (should create 5 individual tasks)
        final success = gameService.startProduction('box', 5);
        expect(success, isTrue);

        // Verify that we have exactly 5 tasks
        final allTasks =
            gameService.state.activeProductions
                .where((task) => task.productId == 'box')
                .toList();
        expect(allTasks.length, equals(5));

        // Verify that exactly 1 is active (not queued) and 4 are queued
        final activeTasks = allTasks.where((task) => !task.isQueued).toList();
        final queuedTasks = allTasks.where((task) => task.isQueued).toList();

        expect(
          activeTasks.length,
          equals(1),
          reason: 'Should have exactly 1 active task',
        );
        expect(
          queuedTasks.length,
          equals(4),
          reason: 'Should have exactly 4 queued tasks',
        );

        // Verify each task has quantity = 1
        for (final task in allTasks) {
          expect(
            task.quantity,
            equals(1),
            reason:
                'Each task should have quantity = 1 for proper queue behavior',
          );
        }

        // Now simulate time passing to complete the first task
        // We'll manually trigger the update mechanism
        await Future.delayed(const Duration(milliseconds: 50));

        // Manually trigger the update process
        gameService.updateProductions();

        // After update, check that one queued task has become active
        final remainingTasks =
            gameService.state.activeProductions
                .where((task) => task.productId == 'box')
                .toList();

        final stillActive =
            remainingTasks.where((task) => !task.isQueued).toList();
        final stillQueued =
            remainingTasks.where((task) => task.isQueued).toList();

        // Should still have only 1 active task (the next one in queue started)
        // and 3 remaining queued tasks
        expect(
          stillActive.length,
          equals(1),
          reason:
              'Should still have exactly 1 active task after first completes',
        );
        expect(
          stillQueued.length,
          equals(3),
          reason: 'Should have 3 tasks still queued',
        );
      } finally {
        gameService.dispose();
      }
    });

    test(
      'Multiple product types can run simultaneously but same types queue',
      () async {
        final gameService = ProductionGameService();

        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          // Buy materials for different products
          gameService.buyMaterial('cardboard', 6); // 2 boxes
          gameService.buyMaterial('plastic', 4); // 2 wires

          // Start production of boxes and wires
          gameService.startProduction('box', 2);
          gameService.startProduction('wires', 2);

          final allTasks = gameService.state.activeProductions;

          // Should have 4 total tasks
          expect(allTasks.length, equals(4));

          // Should have 1 active box, 1 queued box, 1 active wires, 1 queued wires
          final boxTasks =
              allTasks.where((task) => task.productId == 'box').toList();
          final wiresTasks =
              allTasks.where((task) => task.productId == 'wires').toList();

          expect(boxTasks.length, equals(2));
          expect(wiresTasks.length, equals(2));

          // Each product type should have 1 active and 1 queued
          final activeBoxTasks =
              boxTasks.where((task) => !task.isQueued).toList();
          final queuedBoxTasks =
              boxTasks.where((task) => task.isQueued).toList();
          final activeWiresTasks =
              wiresTasks.where((task) => !task.isQueued).toList();
          final queuedWiresTasks =
              wiresTasks.where((task) => task.isQueued).toList();

          expect(activeBoxTasks.length, equals(1));
          expect(queuedBoxTasks.length, equals(1));
          expect(activeWiresTasks.length, equals(1));
          expect(queuedWiresTasks.length, equals(1));
        } finally {
          gameService.dispose();
        }
      },
    );
  });
}
