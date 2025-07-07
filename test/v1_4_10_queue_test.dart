import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';

void main() {
  // Setup for SQLite testing
  setUpAll(() {
    GamePersistenceService.initializeDatabaseFactory();
  });

  group('V1.4.10 Queue System Tests', () {
    test('Production queue system works correctly', () async {
      final gameService = ProductionGameService();

      // Wait for the service to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        // Buy materials needed for production
        gameService.buyMaterial('cardboard', 20);
        gameService.buyMaterial('plastic', 20);
        gameService.buyMaterial('basic_metals', 10);

        // Verify we can start production normally
        gameService.startProduction('box', 1);
        expect(gameService.state.activeProductions.length, equals(1));
        expect(gameService.state.activeProductions.first.isQueued, isFalse);

        // Start another production of the same product - should be queued
        gameService.startProduction('box', 2);
        expect(
          gameService.state.activeProductions.length,
          equals(3),
        ); // 1 active + 2 queued

        // Check that the second and third ones are queued
        final queuedTasks =
            gameService.state.activeProductions
                .where((task) => task.isQueued)
                .toList();
        expect(queuedTasks.length, equals(2)); // 2 individual queued tasks
        expect(
          queuedTasks.every((task) => task.quantity == 1),
          isTrue,
        ); // Each task has quantity 1

        // Can start production of a different product without queuing
        gameService.startProduction('wires', 1);
        expect(gameService.state.activeProductions.length, equals(4));

        // Count active vs queued tasks
        final activeTasks =
            gameService.state.activeProductions
                .where((task) => !task.isQueued)
                .toList();
        final allQueuedTasks =
            gameService.state.activeProductions
                .where((task) => task.isQueued)
                .toList();

        expect(activeTasks.length, equals(2)); // box and wires active
        expect(
          allQueuedTasks.length,
          equals(2),
        ); // 2 individual box tasks queued
      } finally {
        gameService.dispose();
      }
    });

    test('Build quantity preferences are saved and loaded', () async {
      final gameService = ProductionGameService();

      // Wait for the service to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        // Set build quantity preferences (only 1 or 10 are allowed)
        gameService.setBuildQuantityPreference('box', 10);
        gameService.setBuildQuantityPreference('wires', 10);

        expect(gameService.getBuildQuantityPreference('box'), equals(10));
        expect(gameService.getBuildQuantityPreference('wires'), equals(10));
        expect(
          gameService.getBuildQuantityPreference('unknown'),
          equals(1),
        ); // default

        // Save and manually reload to test persistence
        await gameService.saveGame();
        gameService.dispose();

        final newGameService = ProductionGameService();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(newGameService.getBuildQuantityPreference('box'), equals(10));
        expect(newGameService.getBuildQuantityPreference('wires'), equals(10));

        newGameService.dispose();
      } catch (e) {
        gameService.dispose();
        rethrow;
      }
    });

    test('Queue counts are reported correctly', () async {
      final gameService = ProductionGameService();

      // Wait for the service to initialize
      await Future.delayed(const Duration(milliseconds: 100));

      try {
        // Buy materials needed for production
        gameService.buyMaterial('cardboard', 50);

        // Start multiple productions of the same product
        gameService.startProduction('box', 1); // First one active
        gameService.startProduction('box', 3); // Three more queued individually
        gameService.startProduction('box', 2); // Two more queued individually

        final activeCount = gameService.getActiveProductionCount('box');
        final queuedCount = gameService.getQueuedCount('box');

        expect(activeCount, equals(1));
        expect(queuedCount, equals(5)); // 3 + 2 = 5 items queued
      } finally {
        gameService.dispose();
      }
    });
  });
}
