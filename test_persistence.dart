import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/models/game_state.dart';

void main() async {
  print('Testing GamePersistenceService...');

  // Initialize database factory
  print('Initializing database factory...');
  GamePersistenceService.initializeDatabaseFactory();
  print('✅ Database factory initialized');

  try {
    // Create service instance
    print('Creating GamePersistenceService...');
    final service = GamePersistenceService();
    print('✅ Service created');

    // Test save operation
    print('Testing save operation...');
    final testState = GameState(
      money: 500.0,
      materials: {'cardboard': 10, 'plastic': 5},
      products: {'box': 3},
    );

    await service.saveGameState(testState);
    print('✅ Game state saved successfully');

    // Test load operation
    print('Testing load operation...');
    final loadedState = await service.loadGameState();
    print('✅ Game state loaded successfully');
    print('   Money: ${loadedState.money}');
    print('   Materials: ${loadedState.materials}');
    print('   Products: ${loadedState.products}');

    // Test has save data
    print('Testing has save data...');
    final hasSave = await service.hasSaveData();
    print('✅ Has save data: $hasSave');

    // Clean up
    await service.dispose();
    print('✅ Service disposed');

    print('\n🎉 All GamePersistenceService operations completed successfully!');
  } catch (e) {
    print('❌ GamePersistenceService operation failed: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
