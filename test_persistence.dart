import 'package:flutter/foundation.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/models/game_state.dart';

void main() async {
  debugPrint('Testing GamePersistenceService...');

  // Initialize database factory
  debugPrint('Initializing database factory...');
  GamePersistenceService.initializeDatabaseFactory();
  debugPrint('✅ Database factory initialized');

  try {
    // Create service instance
    debugPrint('Creating GamePersistenceService...');
    final service = GamePersistenceService();
    debugPrint('✅ Service created');

    // Test save operation
    debugPrint('Testing save operation...');
    final testState = const GameState(
      money: 500.0,
      materials: {'cardboard': 10, 'plastic': 5},
      products: {'box': 3},
    );

    await service.saveGameState(testState);
    debugPrint('✅ Game state saved successfully');

    // Test load operation
    debugPrint('Testing load operation...');
    final loadedState = await service.loadGameState();
    debugPrint('✅ Game state loaded successfully');
    debugPrint('   Money: ${loadedState.money}');
    debugPrint('   Materials: ${loadedState.materials}');
    debugPrint('   Products: ${loadedState.products}');

    // Test has save data
    debugPrint('Testing has save data...');
    final hasSave = await service.hasSaveData();
    debugPrint('✅ Has save data: $hasSave');

    // Clean up
    await service.dispose();
    debugPrint('✅ Service disposed');

    debugPrint(
      '\n🎉 All GamePersistenceService operations completed successfully!',
    );
  } catch (e) {
    debugPrint('❌ GamePersistenceService operation failed: $e');
    debugPrint('Stack trace: ${StackTrace.current}');
  }
}
