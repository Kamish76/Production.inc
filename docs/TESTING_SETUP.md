# Testing Setup - Production.INC

This document outlines the testing infrastructure and setup for the Production.INC Flutter game.

## Test Structure

### Test Files
- `test/core_functionality_test.dart` - Core game logic tests
- `test/comprehensive_widget_test.dart` - Widget and UI tests
- `test/game_persistence_test.dart` - Database and persistence tests
- `test/new_player_experience_test.dart` - User onboarding tests
- `test/performance_optimization_test.dart` - Performance and lifecycle tests
- `test/v1_4_18_unlock_system_test.dart` - Product unlock system tests
- `test/test_utils.dart` - Shared testing utilities

### Test Categories
1. **Unit Tests** - Test individual functions and methods
2. **Widget Tests** - Test UI components and interactions
3. **Integration Tests** - Test complete user flows
4. **Performance Tests** - Test app lifecycle and optimization

## Database Testing Setup

### Issue Resolution
Previously, tests were failing due to database factory initialization issues. This has been resolved by:

1. **Proper Database Initialization**
   ```dart
   setUp(() {
     GamePersistenceService.initializeDatabaseFactory();
     gameService = ProductionGameService();
   });
   ```

2. **Test Utilities**
   - Created `test/test_utils.dart` for consistent test setup
   - Provides `initializeTestEnvironment()` helper function
   - Ensures proper database factory initialization

3. **Test Isolation**
   ```dart
   tearDown(() {
     gameService.dispose();
   });
   ```

## Fixed Issues

### 1. Comprehensive Widget Test (RESOLVED)
- **Issue**: Empty test file causing compilation errors
- **Solution**: Created proper widget tests for main screens
- **Status**: ✅ Fixed

### 2. Database Factory Initialization (RESOLVED)
- **Issue**: Tests failing with "databaseFactory not initialized"
- **Solution**: Added proper initialization in all test files
- **Status**: ✅ Fixed

### 3. Unlock System Test (RESOLVED)
- **Issue**: Intermediate parts unlock test failing
- **Solution**: Fixed test data to include required raw materials
- **Status**: ✅ Fixed

## Running Tests

### All Tests
```bash
flutter test
```

### Specific Test File
```bash
flutter test test/core_functionality_test.dart
```

### With Coverage
```bash
flutter test --coverage
```

### Test Categories
```bash
# Unit tests only
flutter test test/ --name "unit"

# Widget tests only
flutter test test/ --name "widget"
```

## Test Best Practices

### 1. Database Setup
Always initialize the database factory in test setUp:
```dart
setUp(() {
  GamePersistenceService.initializeDatabaseFactory();
  gameService = ProductionGameService();
});
```

### 2. Resource Cleanup
Always dispose of services in tearDown:
```dart
tearDown(() {
  gameService.dispose();
});
```

### 3. Test Data
Use realistic test data that matches game requirements:
```dart
final gameState = GameState(
  materials: {
    'cardboard': 10,
    'basic_metals': 10,
    'plastic': 10,
    'glass': 10,       // Include all required materials
    'advanced_metals': 10,
  },
  products: {
    'circuits': 1,     // Ensure all dependencies are met
    'wires': 1,
    'metal_enclosure': 1,
  },
);
```

### 4. Async Operations
Handle async operations properly:
```dart
testWidgets('async test', (WidgetTester tester) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle(); // Wait for animations
  
  // Perform test actions
  await tester.tap(find.byType(Button));
  await tester.pumpAndSettle();
  
  // Verify results
  expect(find.text('Expected'), findsOneWidget);
});
```

## Current Test Status

### Test Results Summary (After Fixes)
- ✅ Core functionality tests: Passing
- ✅ Comprehensive widget tests: Fixed and passing
- ✅ Database persistence tests: Passing
- ✅ New player experience tests: Passing
- ✅ Performance optimization tests: Fixed and passing
- ✅ Unlock system tests: Fixed and passing

### Coverage Goals
- **Target**: >80% code coverage
- **Current**: To be measured after full test suite completion
- **Focus Areas**: Core game logic, UI components, edge cases

## Continuous Integration

### GitHub Actions Integration
Tests should be run automatically on:
- Pull request creation
- Push to develop/main branches
- Scheduled nightly runs

### Test Commands in CI
```yaml
- name: Run tests
  run: flutter test --coverage

- name: Check coverage
  run: flutter test --coverage && lcov --summary coverage/lcov.info
```

## Troubleshooting

### Common Issues

1. **Database Factory Not Initialized**
   - **Cause**: Missing `GamePersistenceService.initializeDatabaseFactory()` call
   - **Solution**: Add to setUp() method

2. **Widget Test Failures**
   - **Cause**: Missing Provider context or async operations
   - **Solution**: Wrap in proper providers and use pumpAndSettle()

3. **Material Requirements**
   - **Cause**: Test data missing required raw materials for unlock conditions
   - **Solution**: Include all necessary materials in test GameState

4. **Memory Leaks in Tests**
   - **Cause**: Not disposing of services properly
   - **Solution**: Always call dispose() in tearDown()

---

**Last Updated**: October 8, 2025  
**Next Review**: November 8, 2025