/// Test utilities for Production.INC game tests
/// 
/// This file provides common test setup and teardown functionality
/// to ensure consistent test environments across all test files.

import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/services/production_game_service.dart';

/// Initialize the test environment
/// 
/// This should be called in the setUp() method of test groups
/// to ensure proper database initialization and clean state.
void initializeTestEnvironment() {
  // Initialize database factory for testing
  GamePersistenceService.initializeDatabaseFactory();
}

/// Create a fresh game service for testing
/// 
/// Returns a new ProductionGameService instance with proper
/// database initialization for testing.
ProductionGameService createTestGameService() {
  initializeTestEnvironment();
  return ProductionGameService();
}

/// Clean up test environment
/// 
/// This should be called in tearDown() methods to ensure
/// proper cleanup of resources.
void cleanupTestEnvironment(ProductionGameService gameService) {
  gameService.dispose();
}