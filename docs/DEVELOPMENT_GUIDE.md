# Development Guide

This guide provides comprehensive information for developers working on Production.Inc.

## Table of Contents

1. [Development Setup](#development-setup)
2. [Architecture Overview](#architecture-overview)
3. [Coding Standards](#coding-standards)
4. [Testing Guidelines](#testing-guidelines)
5. [Performance Best Practices](#performance-best-practices)
6. [Adding New Content](#adding-new-content)
7. [Debugging and Profiling](#debugging-and-profiling)
8. [Release Process](#release-process)

---

## Development Setup

### Prerequisites
- Flutter SDK 3.16.0 or later
- Dart SDK 3.2.0 or later
- Android Studio or VS Code with Flutter extension
- Android device or emulator for testing

### Environment Setup

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd Game1
   flutter pub get
   ```

2. **Verify Installation**
   ```bash
   flutter doctor -v
   flutter analyze
   flutter test
   ```

3. **Run Development Build**
   ```bash
   flutter run --debug
   ```

### IDE Configuration

#### VS Code Extensions
- Flutter
- Dart
- Error Lens
- Flutter Widget Snippets

#### Android Studio Plugins
- Flutter
- Dart

---

## Architecture Overview

### Design Patterns

#### Provider Pattern
- **State Management**: Uses Provider for game state management
- **Service Location**: ProductionGameService as main provider
- **Reactive UI**: Consumer widgets for automatic rebuilds

#### Repository Pattern
- **Data Layer**: GamePersistenceService handles all database operations
- **Service Layer**: Business logic in dedicated service classes
- **Model Layer**: Immutable data classes for game entities

#### Component Architecture
- **Shared Widgets**: Reusable UI components in `lib/widgets/`
- **Screen Widgets**: Page-level components in `lib/screens/`
- **Service Classes**: Business logic in `lib/services/`

### Data Flow

```
User Interaction → Screen Widget → Service Method → State Update → UI Rebuild
                                      ↓
                              Database Persistence
```

#### Example: Building a Product
1. User taps product card in BuildProductsScreen
2. Screen calls `gameService.startProduction()`
3. Service validates materials and creates ProductionTask
4. State updated and persisted to database
5. Consumer widgets automatically rebuild with new state

---

## Coding Standards

### Dart Style Guide

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with these additions:

#### File Organization
```dart
// 1. Dart/Flutter imports
import 'dart:async';
import 'package:flutter/material.dart';

// 2. Third-party package imports
import 'package:provider/provider.dart';

// 3. Local imports - services first
import '../services/production_game_service.dart';

// 4. Local imports - models
import '../models/game_state.dart';

// 5. Local imports - widgets/screens
import '../widgets/common_widgets.dart';
```

#### Class Structure
```dart
class ExampleWidget extends StatefulWidget {
  // 1. Static constants
  static const String routeName = '/example';
  
  // 2. Final fields
  final String title;
  final VoidCallback? onTap;
  
  // 3. Constructor
  const ExampleWidget({
    super.key,
    required this.title,
    this.onTap,
  });
  
  // 4. State creation
  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  // 1. State variables
  bool _isExpanded = false;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    // Initialization
  }
  
  // 3. Event handlers
  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
  
  // 4. Build methods (main build method last)
  Widget _buildHeader() {
    return Text(widget.title);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          // ... rest of UI
        ],
      ),
    );
  }
}
```

#### Naming Conventions

**Classes**: PascalCase
```dart
class ProductionGameService { }
class GameProgressIndicator { }
```

**Methods and Variables**: camelCase
```dart
void startProduction() { }
bool isProductUnlocked = false;
```

**Constants**: camelCase with descriptive names
```dart
static const int maxProducts = 1000000;
static const double cardElevation = 2.0;
```

**Private Members**: Prefix with underscore
```dart
bool _isExpanded = false;
void _handleTap() { }
```

### Documentation Standards

#### Class Documentation
```dart
/// Service for managing production operations and game state.
/// 
/// This service handles all production-related logic including:
/// - Production queue management
/// - Material validation
/// - Progress tracking
/// - State persistence
/// 
/// Example usage:
/// ```dart
/// final service = context.read<ProductionGameService>();
/// service.startProduction('box', 5);
/// ```
class ProductionGameService extends ChangeNotifier {
  // ...
}
```

#### Method Documentation
```dart
/// Starts production of the specified product with queue management.
/// 
/// Creates individual production tasks for proper sequential processing.
/// The first task will queue only if there's already an active production
/// of the same product type.
/// 
/// **Parameters:**
/// - [productId]: Unique identifier of the product to produce
/// - [quantity]: Number of units to produce (each becomes separate task)
/// 
/// **Throws:**
/// - [Exception] if product not found or insufficient materials
/// 
/// **Example:**
/// ```dart
/// service.startProduction('smartphone', 3);
/// ```
void startProduction(String productId, int quantity) {
  // Implementation
}
```

---

## Testing Guidelines

### Test Structure

#### Unit Tests (`test/`)
- **Services**: Test business logic in isolation
- **Models**: Test data validation and transformation
- **Utilities**: Test helper functions and calculations

#### Widget Tests (`test/`)
- **Screens**: Test user interactions and state changes
- **Components**: Test shared widget behavior
- **Integration**: Test widget-service interactions

#### Integration Tests (`integration_test/`)
- **End-to-End**: Test complete user workflows
- **Performance**: Test app performance under load
- **Database**: Test data persistence scenarios

### Test Examples

#### Unit Test Example
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/product_unlock_service.dart';
import 'package:game1/models/game_state.dart';

void main() {
  group('ProductUnlockService', () {
    test('should unlock box when sufficient cardboard available', () {
      // Arrange
      const gameState = GameState(
        materials: {'cardboard': 5},
      );
      
      // Act
      final isUnlocked = ProductUnlockService.isProductUnlocked('box', gameState);
      
      // Assert
      expect(isUnlocked, isTrue);
    });
    
    test('should not unlock box when insufficient cardboard', () {
      // Arrange
      const gameState = GameState(
        materials: {'cardboard': 1},
      );
      
      // Act
      final isUnlocked = ProductUnlockService.isProductUnlocked('box', gameState);
      
      // Assert
      expect(isUnlocked, isFalse);
    });
  });
}
```

#### Widget Test Example
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:game1/widgets/product_card.dart';
import 'package:game1/models/game_models.dart';

void main() {
  testWidgets('ProductCard displays product information correctly', (tester) async {
    // Arrange
    const product = Product(
      id: 'test_product',
      name: 'Test Product',
      description: 'A test product',
      sellPrice: 10.0,
      emoji: '📦',
      requiredMaterials: {'cardboard': 1},
      productionTimeSeconds: 5.0,
      baseShippingTimeSeconds: 10.0,
      shippingScalingFactor: 0.9,
      levelId: ProductLevel.basicParts,
    );
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product: product,
            currentQuantity: 5,
            isUnlocked: true,
          ),
        ),
      ),
    );
    
    // Assert
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('📦'), findsOneWidget);
    expect(find.text('\$10.00'), findsOneWidget);
  });
}
```

### Testing Best Practices

1. **AAA Pattern**: Arrange, Act, Assert
2. **Descriptive Names**: Test names should describe the scenario
3. **Single Responsibility**: One test per behavior
4. **Mock External Dependencies**: Use mocks for services and databases
5. **Test Edge Cases**: Include error conditions and boundary values

---

## Performance Best Practices

### Widget Performance

#### Use Const Constructors
```dart
// Good
const GameCard(
  child: Text('Static content'),
)

// Avoid
GameCard(
  child: Text('Static content'),
)
```

#### Implement Proper Keys
```dart
// Good - for dynamic lists
ListView.builder(
  itemBuilder: (context, index) {
    return ProductCard(
      key: ValueKey(products[index].id),
      product: products[index],
    );
  },
)
```

#### Use Builder Widgets for Scope Isolation
```dart
// Good - isolates rebuilds
Consumer<ProductionGameService>(
  builder: (context, service, child) {
    return Text('Money: \$${service.state.money}');
  },
)
```

### Database Performance

#### Use Transactions for Multiple Operations
```dart
// Good
await db.transaction((txn) async {
  await _saveMaterials(txn, state);
  await _saveProducts(txn, state);
  await _saveProductions(txn, state);
});
```

#### Avoid Unnecessary Saves
```dart
// Good - check if data actually changed
void updateMoney(double newAmount) {
  if (_state.money != newAmount) {
    _state = _state.copyWith(money: newAmount);
    _saveGameState(); // Only save when changed
    notifyListeners();
  }
}
```

### Caching Strategies

Follow the ProductUnlockService caching pattern:

```dart
class MyService {
  static final Map<String, bool> _cache = {};
  static String? _lastStateHash;
  
  static bool expensiveCalculation(String input, GameState state) {
    final currentHash = _generateHash(state);
    
    if (_lastStateHash != currentHash) {
      _cache.clear();
      _lastStateHash = currentHash;
    }
    
    if (_cache.containsKey(input)) {
      return _cache[input]!;
    }
    
    final result = _performCalculation(input, state);
    _cache[input] = result;
    return result;
  }
}
```

---

## Adding New Content

### Adding Materials

1. **Define in Game Data**
   ```dart
   // lib/models/game_data.dart
   static const List<Material> materials = [
     // ... existing materials
     Material(
       id: 'new_material',
       name: 'New Material',
       description: 'Description of the new material',
       buyPrice: 15.0,
       emoji: '🆕',
     ),
   ];
   ```

2. **Update Constants (if needed)**
   ```dart
   // lib/constants/game_constants.dart
   class UnlockThresholds {
     // Add unlock thresholds if this material affects unlocks
     static const int newMaterialThreshold = 2;
   }
   ```

### Adding Products

1. **Define Product**
   ```dart
   // lib/models/game_data.dart
   static const List<Product> products = [
     // ... existing products
     Product(
       id: 'new_product',
       name: 'New Product',
       description: 'Description of the new product',
       sellPrice: 25.0,
       emoji: '🆕',
       requiredMaterials: {
         'cardboard': 2,
         'plastic': 1,
       },
       productionTimeSeconds: 15.0,
       baseShippingTimeSeconds: 20.0,
       shippingScalingFactor: 0.9,
       levelId: ProductLevel.basicParts,
     ),
   ];
   ```

2. **Update Unlock Logic (if needed)**
   ```dart
   // lib/services/product_unlock_service.dart
   static bool _checkBasicPartsUnlockConditions(String productId, GameState gameState) {
     switch (productId) {
       // ... existing cases
       case 'new_product':
         return gameState.getMaterialCount('cardboard') >= 2 &&
                gameState.getMaterialCount('plastic') >= 1;
       // ...
     }
   }
   ```

3. **Add Constants**
   ```dart
   // lib/constants/game_constants.dart
   class UnlockThresholds {
     static const int newProductCardboardThreshold = 2;
     static const int newProductPlasticThreshold = 1;
   }
   ```

4. **Update Tests**
   ```dart
   // test/product_unlock_test.dart
   test('should unlock new_product when requirements met', () {
     const gameState = GameState(
       materials: {'cardboard': 3, 'plastic': 2},
     );
     
     final isUnlocked = ProductUnlockService.isProductUnlocked('new_product', gameState);
     expect(isUnlocked, isTrue);
   });
   ```

### Adding UI Components

1. **Create in Widgets Directory**
   ```dart
   // lib/widgets/new_component.dart
   class NewComponent extends StatelessWidget {
     const NewComponent({super.key});
     
     @override
     Widget build(BuildContext context) {
       return GameCard(  // Use existing shared components
         child: // ... implementation
       );
     }
   }
   ```

2. **Export from Index File**
   ```dart
   // lib/widgets/widgets.dart
   export 'common_widgets.dart';
   export 'product_card.dart';
   export 'new_component.dart';  // Add new export
   ```

3. **Use Consistent Theming**
   ```dart
   // Use constants for consistency
   Container(
     padding: const EdgeInsets.all(UIConstants.standardPadding),
     decoration: BoxDecoration(
       color: AppColors.cardBackground,
       borderRadius: BorderRadius.circular(12),
     ),
   )
   ```

---

## Debugging and Profiling

### Debug Tools

#### Flutter Inspector
- **Widget Tree**: Analyze widget hierarchy
- **Performance**: Monitor rebuild frequency
- **Layout**: Debug layout issues

#### Dart DevTools
- **Performance**: CPU and memory profiling
- **Network**: Monitor database operations
- **Logging**: View debug output

### Common Debug Scenarios

#### Production Queue Issues
```dart
// Add debug logging in updateProductions()
void updateProductions() {
  if (kDebugMode) {
    print('Active productions: ${_state.activeProductions.length}');
    for (final task in _state.activeProductions) {
      print('Task ${task.id}: ${task.productId}, queued: ${task.isQueued}');
    }
  }
  // ... rest of method
}
```

#### Unlock Condition Debug
```dart
// Add to ProductUnlockService
static bool isProductUnlocked(String productId, GameState gameState) {
  final result = // ... calculation
  
  if (kDebugMode) {
    print('Unlock check for $productId: $result');
    if (!result) {
      print('Materials: ${gameState.materials}');
      print('Produced: ${gameState.unlockedProducts}');
    }
  }
  
  return result;
}
```

### Performance Profiling

#### Database Performance
```dart
// Time database operations
Future<void> saveGameState(GameState state) async {
  final stopwatch = Stopwatch()..start();
  
  // ... save operations
  
  stopwatch.stop();
  if (kDebugMode) {
    print('Save took ${stopwatch.elapsedMilliseconds}ms');
  }
}
```

#### Widget Rebuild Tracking
```dart
class PerformanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('${runtimeType} rebuilding at ${DateTime.now()}');
    }
    
    return // ... widget implementation
  }
}
```

---

## Release Process

### Version Management

#### Version Format
Use semantic versioning: `MAJOR.MINOR.PATCH+BUILD`
- **MAJOR**: Breaking changes or major features
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, optimizations
- **BUILD**: Build number for app stores

#### Version Update Checklist

1. **Update Version Numbers**
   ```yaml
   # pubspec.yaml
   version: 1.4.19+19
   ```

2. **Update Documentation**
   - README.md with new features
   - CHANGELOG.md with detailed changes
   - API documentation if needed

3. **Run Full Test Suite**
   ```bash
   flutter test
   flutter analyze
   flutter test integration_test/
   ```

4. **Build and Test**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

### Release Checklist

#### Pre-Release
- [ ] All tests passing
- [ ] No analyzer warnings
- [ ] Documentation updated
- [ ] Performance testing completed
- [ ] Device compatibility tested

#### Release Build
- [ ] Version numbers updated
- [ ] Release notes prepared
- [ ] Screenshots updated (if UI changes)
- [ ] Store listing updated

#### Post-Release
- [ ] Git tag created
- [ ] Release branch merged
- [ ] Next version planning
- [ ] Monitoring deployment

### Deployment Scripts

#### Build Script Example
```bash
#!/bin/bash
# build_release.sh

echo "Building Production.Inc Release..."

# Clean
flutter clean
flutter pub get

# Analyze
echo "Running flutter analyze..."
flutter analyze
if [ $? -ne 0 ]; then
  echo "Analysis failed!"
  exit 1
fi

# Test
echo "Running tests..."
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed!"
  exit 1
fi

# Build
echo "Building release APK..."
flutter build apk --release

echo "Building App Bundle..."
flutter build appbundle --release

echo "Release build complete!"
```

---

## Troubleshooting

### Common Issues

#### Database Errors
- **Symptom**: App crashes on startup
- **Solution**: Check database version migration
- **Debug**: Enable database logging in GamePersistenceService

#### Performance Issues
- **Symptom**: UI lag during production updates
- **Solution**: Profile with Dart DevTools, check unnecessary rebuilds
- **Debug**: Add performance logging to updateProductions()

#### Unlock System Issues
- **Symptom**: Products not unlocking as expected
- **Solution**: Check ProductUnlockService logic and material thresholds
- **Debug**: Enable unlock debug logging

### Debug Configuration

#### Enable Debug Logging
```dart
// lib/constants/game_constants.dart
class DebugConstants {
  static const bool verboseProductionLogging = true;
  static const bool unlockSystemLogging = true;
  static const bool performanceLogging = true;
  static const bool persistenceLogging = true;
}
```

#### Test Environment Setup
```dart
// test/test_helpers.dart
class TestGameService extends ProductionGameService {
  TestGameService() : super(testMode: true);
  
  // Override methods for testing
}
```

---

*This development guide reflects the Production.Inc codebase as of v1.4.19. Keep it updated as the project evolves.*
