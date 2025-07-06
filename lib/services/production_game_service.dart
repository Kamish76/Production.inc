import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import 'game_persistence_service.dart';

// Production.INC Game Service - handles all game logic
class ProductionGameService extends ChangeNotifier {
  GameState _state = const GameState();
  Timer? _updateTimer;
  Timer? _saveTimer;
  final GamePersistenceService _persistenceService = GamePersistenceService();
  bool _isLoaded = false;
  bool _isAppPaused = false;

  GameState get state => _state;
  bool get isLoaded => _isLoaded;
  bool get isAppPaused => _isAppPaused;

  ProductionGameService() {
    _initializeGame();
  }

  /// Initialize the game by loading saved state and starting timers
  Future<void> _initializeGame() async {
    try {
      // Load saved game state
      _state = await _persistenceService.loadGameState();
      _isLoaded = true;
      notifyListeners();

      // Start optimized update timer (1 second for better battery life)
      _startUpdateTimer();

      // Start periodic save timer (optimized for v1.4.8 - reduced frequency)
      _saveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        _saveGameStateOptimized();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading game state: $e');
      }
      // If loading fails, start with default state
      _isLoaded = true;
      notifyListeners();

      // Still start timers
      _startUpdateTimer();

      _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _saveGameState();
      });
    }
  }

  /// Start the update timer with intelligent frequency management
  void _startUpdateTimer() {
    _updateTimer?.cancel();

    if (_isAppPaused) {
      // Don't run timer when app is paused for battery optimization
      return;
    }

    // Determine timer interval based on activity
    final Duration interval =
        _hasActiveOperations()
            ? const Duration(
              seconds: 1,
            ) // 1 second when active (battery optimized)
            : const Duration(
              seconds: 5,
            ); // 5 seconds when idle (more battery friendly)

    _updateTimer = Timer.periodic(interval, (timer) {
      if (!_isAppPaused) {
        updateProductions();

        // Dynamically adjust timer frequency based on current activity
        if (_hasActiveOperations() !=
            (interval == const Duration(seconds: 1))) {
          _startUpdateTimer(); // Restart with new interval
        }
      }
    });
  }

  /// Check if there are any active operations that need frequent updates
  bool _hasActiveOperations() {
    return _state.activeProductions.isNotEmpty ||
        _state.activeShippingOrders.isNotEmpty;
  }

  /// Handle app lifecycle changes for mobile optimization
  void handleAppLifecycleChange(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isAppPaused = true;
        _pauseTimers();
        _saveGameState(); // Save when app goes to background
        break;
      case AppLifecycleState.resumed:
        _isAppPaused = false;
        _resumeTimers();
        break;
    }
    notifyListeners();
  }

  /// Pause all timers for battery optimization
  void _pauseTimers() {
    _updateTimer?.cancel();
    // Keep save timer running but at much lower frequency when paused (v1.4.8 optimization)
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isAppPaused) {
        _saveGameStateOptimized();
      }
    });
  }

  /// Resume timers when app becomes active
  void _resumeTimers() {
    _startUpdateTimer();

    // Resume normal save frequency (v1.4.8 optimization)
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _saveGameStateOptimized();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _saveTimer?.cancel();
    _saveGameState(); // Save one final time before disposing
    _persistenceService.dispose();
    super.dispose();
  }

  /// Save current game state to persistent storage (optimized for v1.4.8)
  Future<void> _saveGameStateOptimized() async {
    try {
      await _persistenceService.saveGameStateOptimized(_state);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game state (optimized): $e');
      }
      // Fallback to original save
      await _saveGameState();
    }
  }

  /// Save current game state to persistent storage
  Future<void> _saveGameState() async {
    try {
      await _persistenceService.saveGameState(_state);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving game state: $e');
      }
    }
  }

  /// Manually save game state (for user-triggered saves)
  Future<void> saveGame() async {
    await _saveGameState();
  }

  /// Reset game to initial state
  Future<void> resetGame() async {
    try {
      await _persistenceService.resetGameData();
      _state = const GameState();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting game: $e');
      }
    }
  }

  /// Check if there's existing save data
  Future<bool> hasSaveData() async {
    return await _persistenceService.hasSaveData();
  }

  // Buy materials with comprehensive error handling
  bool buyMaterial(String materialId, int quantity) {
    try {
      // Input validation
      if (materialId.isEmpty || quantity <= 0) {
        if (kDebugMode) {
          print(
            'Invalid buy material parameters: materialId=$materialId, quantity=$quantity',
          );
        }
        return false;
      }

      final material = GameData.getMaterial(materialId);
      if (material == null) {
        if (kDebugMode) {
          print('Material not found: $materialId');
        }
        return false;
      }

      final totalCost = material.buyPrice * quantity;
      if (!_state.canAfford(totalCost)) {
        if (kDebugMode) {
          print(
            'Insufficient funds: need \$${totalCost.toStringAsFixed(2)}, have \$${_state.money.toStringAsFixed(2)}',
          );
        }
        return false;
      }

      // Prevent integer overflow for large quantities
      const maxQuantity = 1000000;
      if (quantity > maxQuantity) {
        if (kDebugMode) {
          print('Quantity too large: $quantity > $maxQuantity');
        }
        return false;
      }

      final newMaterials = Map<String, int>.from(_state.materials);
      final currentAmount = newMaterials[materialId] ?? 0;

      // Check for potential overflow
      if (currentAmount > maxQuantity - quantity) {
        if (kDebugMode) {
          print(
            'Would exceed maximum material amount: $currentAmount + $quantity > $maxQuantity',
          );
        }
        return false;
      }

      newMaterials[materialId] = currentAmount + quantity;

      _state = _state.copyWith(
        money: _state.money - totalCost,
        materials: newMaterials,
      );

      // Mark materials as dirty for incremental save (v1.4.8)
      _persistenceService.markDirty('materials');

      notifyListeners();
      _saveGameStateOptimized(); // Use optimized save after major transaction
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error buying material $materialId (quantity: $quantity): $e');
      }
      return false;
    }
  }

  // Start production of a product with comprehensive error handling
  bool startProduction(String productId, int quantity) {
    try {
      // Input validation
      if (productId.isEmpty || quantity <= 0) {
        if (kDebugMode) {
          print(
            'Invalid production parameters: productId=$productId, quantity=$quantity',
          );
        }
        return false;
      }

      final product = GameData.getProduct(productId);
      if (product == null) {
        if (kDebugMode) {
          print('Product not found: $productId');
        }
        return false;
      }

      // Prevent excessive production quantities
      const maxQuantity = 10000;
      if (quantity > maxQuantity) {
        if (kDebugMode) {
          print('Production quantity too large: $quantity > $maxQuantity');
        }
        return false;
      }

      // Check if we have enough materials
      final requiredMaterials = <String, int>{};
      for (final entry in product.requiredMaterials.entries) {
        final needed = entry.value * quantity;
        if (needed < 0) {
          if (kDebugMode) {
            print(
              'Invalid material requirement calculation for ${entry.key}: $needed',
            );
          }
          return false;
        }
        requiredMaterials[entry.key] = needed;
      }

      if (!_state.hasMaterialsFor(requiredMaterials)) {
        if (kDebugMode) {
          print(
            'Insufficient materials for production of $productId x$quantity',
          );
          for (final entry in requiredMaterials.entries) {
            final have =
                _state.getMaterialCount(entry.key) +
                _state.getProductCount(entry.key);
            final need = entry.value;
            if (have < need) {
              print('  - ${entry.key}: have $have, need $need');
            }
          }
        }
        return false;
      }

      // Consume materials and products
      final newMaterials = Map<String, int>.from(_state.materials);
      final newProducts = Map<String, int>.from(_state.products);

      for (final entry in requiredMaterials.entries) {
        final itemId = entry.key;
        final needed = entry.value;

        // Try to consume from materials first
        final availableMaterials = newMaterials[itemId] ?? 0;
        if (availableMaterials >= needed) {
          newMaterials[itemId] = availableMaterials - needed;
          if (newMaterials[itemId]! <= 0) {
            newMaterials.remove(itemId);
          }
        } else {
          // Consume all materials first, then from products
          var remaining = needed;
          if (availableMaterials > 0) {
            newMaterials.remove(itemId);
            remaining -= availableMaterials;
          }

          // Consume remaining from products
          final availableProducts = newProducts[itemId] ?? 0;
          if (availableProducts < remaining) {
            if (kDebugMode) {
              print(
                'Insufficient products for consumption: $itemId, need $remaining, have $availableProducts',
              );
            }
            return false;
          }

          newProducts[itemId] = availableProducts - remaining;
          if (newProducts[itemId]! <= 0) {
            newProducts.remove(itemId);
          }
        }
      }

      // Validate production duration
      final totalDuration = product.productionTimeSeconds * quantity;
      if (totalDuration <= 0 || totalDuration > 86400) {
        // Max 24 hours
        if (kDebugMode) {
          print('Invalid production duration: ${totalDuration}s');
        }
        return false;
      }

      // Create production task
      final task = ProductionTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        startTime: DateTime.now(),
        durationSeconds: totalDuration,
        quantity: quantity,
      );

      final newProductions = List<ProductionTask>.from(
        _state.activeProductions,
      );
      newProductions.add(task);

      _state = _state.copyWith(
        materials: newMaterials,
        products: newProducts,
        activeProductions: newProductions,
      );

      // Mark relevant data as dirty for incremental save (v1.4.8)
      _persistenceService.markDirty('materials');
      _persistenceService.markDirty('products');
      _persistenceService.markDirty('productions');

      notifyListeners();
      _saveGameStateOptimized(); // Use optimized save after starting production
      _startUpdateTimer(); // Restart timer with optimal frequency for new activity
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting production $productId (quantity: $quantity): $e');
      }
      return false;
    }
  }

  // Sell products (now creates shipping orders) with comprehensive error handling
  bool sellProduct(String productId, int quantity) {
    try {
      // Input validation
      if (productId.isEmpty || quantity <= 0) {
        if (kDebugMode) {
          print(
            'Invalid sell parameters: productId=$productId, quantity=$quantity',
          );
        }
        return false;
      }

      final product = GameData.getProduct(productId);
      if (product == null) {
        if (kDebugMode) {
          print('Product not found: $productId');
        }
        return false;
      }

      final available = _state.getProductCount(productId);
      if (available < quantity) {
        if (kDebugMode) {
          print(
            'Insufficient products to sell: $productId, need $quantity, have $available',
          );
        }
        return false;
      }

      // Prevent excessive selling quantities
      const maxQuantity = 10000;
      if (quantity > maxQuantity) {
        if (kDebugMode) {
          print('Sell quantity too large: $quantity > $maxQuantity');
        }
        return false;
      }

      // Calculate shipping time using the new formula from Product model
      final totalShippingTime = product.calculateShippingTime(quantity);

      // Validate shipping time
      if (totalShippingTime <= 0 || totalShippingTime > 86400) {
        // Max 24 hours
        if (kDebugMode) {
          print('Invalid shipping time: ${totalShippingTime}s');
        }
        return false;
      }

      final totalRevenue = product.sellPrice * quantity;

      // Validate revenue calculation
      if (totalRevenue <= 0) {
        if (kDebugMode) {
          print('Invalid revenue calculation: $totalRevenue');
        }
        return false;
      }

      // Check for active shipping order limit (prevent spam)
      const maxActiveOrders = 100;
      if (_state.activeShippingOrders.length >= maxActiveOrders) {
        if (kDebugMode) {
          print(
            'Too many active shipping orders: ${_state.activeShippingOrders.length}',
          );
        }
        return false;
      }

      // Remove products from inventory
      final newProducts = Map<String, int>.from(_state.products);
      newProducts[productId] = available - quantity;
      if (newProducts[productId]! <= 0) {
        newProducts.remove(productId);
      }

      // Create shipping order
      final shippingOrder = ShippingOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        items: [ShippingItem(productId: productId, quantity: quantity)],
        startTime: DateTime.now(),
        totalShippingTime: totalShippingTime,
        totalRevenue: totalRevenue,
      );

      final newShippingOrders = List<ShippingOrder>.from(
        _state.activeShippingOrders,
      );
      newShippingOrders.add(shippingOrder);

      _state = _state.copyWith(
        products: newProducts,
        activeShippingOrders: newShippingOrders,
      );

      // Mark relevant data as dirty for incremental save (v1.4.8)
      _persistenceService.markDirty('products');
      _persistenceService.markDirty('shipping');

      notifyListeners();
      _saveGameStateOptimized(); // Use optimized save after starting shipment
      _startUpdateTimer(); // Restart timer with optimal frequency for new activity
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error selling product $productId (quantity: $quantity): $e');
      }
      return false;
    }
  }

  // Check and complete finished productions and shipping orders with error handling
  void updateProductions() {
    try {
      // Early return if no active operations (battery optimization)
      if (!_hasActiveOperations()) {
        return;
      }

      final completedTasks = <ProductionTask>[];
      final activeTasks = <ProductionTask>[];
      final completedShipping = <ShippingOrder>[];
      final activeShipping = <ShippingOrder>[];

      // Check production tasks
      for (final task in _state.activeProductions) {
        try {
          if (task.isCompleted) {
            completedTasks.add(task);
          } else {
            activeTasks.add(task);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error checking production task ${task.id}: $e');
          }
          // If there's an error with a task, consider it active to prevent data loss
          activeTasks.add(task);
        }
      }

      // Check shipping orders
      for (final order in _state.activeShippingOrders) {
        try {
          if (order.isCompleted) {
            completedShipping.add(order);
          } else {
            activeShipping.add(order);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error checking shipping order ${order.id}: $e');
          }
          // If there's an error with an order, consider it active to prevent data loss
          activeShipping.add(order);
        }
      }

      // Only update state if there are changes or active operations for progress updates
      if (completedTasks.isNotEmpty ||
          completedShipping.isNotEmpty ||
          _state.activeProductions.isNotEmpty ||
          _state.activeShippingOrders.isNotEmpty) {
        // Add completed products to inventory
        final newProducts = Map<String, int>.from(_state.products);
        for (final task in completedTasks) {
          try {
            final currentCount = newProducts[task.productId] ?? 0;
            const maxProducts = 1000000;

            // Prevent overflow
            if (currentCount > maxProducts - task.quantity) {
              if (kDebugMode) {
                print(
                  'Product overflow prevented: ${task.productId}, current: $currentCount, adding: ${task.quantity}',
                );
              }
              // Add what we can without overflow
              newProducts[task.productId] = maxProducts;
            } else {
              newProducts[task.productId] = currentCount + task.quantity;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error completing production task ${task.id}: $e');
            }
          }
        }

        // Add revenue from completed shipping orders and create history
        double newMoney = _state.money;
        final newHistory = List<ShippingHistory>.from(_state.shippingHistory);

        for (final order in completedShipping) {
          try {
            // Prevent money overflow
            const maxMoney = 999999999.0;
            if (newMoney > maxMoney - order.totalRevenue) {
              if (kDebugMode) {
                print(
                  'Money overflow prevented: current: $newMoney, adding: ${order.totalRevenue}',
                );
              }
              newMoney = maxMoney;
            } else {
              newMoney += order.totalRevenue;
            }

            // Add to history
            final historyEntry = ShippingHistory(
              id: order.id,
              items: order.items,
              completedTime: DateTime.now(),
              totalRevenue: order.totalRevenue,
            );
            newHistory.add(historyEntry);
          } catch (e) {
            if (kDebugMode) {
              print('Error completing shipping order ${order.id}: $e');
            }
          }
        }

        _state = _state.copyWith(
          money: newMoney,
          products: newProducts,
          activeProductions: activeTasks,
          activeShippingOrders: activeShipping,
          shippingHistory: newHistory,
        );

        notifyListeners();

        // Optimize timer frequency if all operations completed
        if (completedTasks.isNotEmpty || completedShipping.isNotEmpty) {
          _startUpdateTimer(); // Restart with optimal frequency
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating productions: $e');
      }
      // In case of error, still notify listeners to update UI
      notifyListeners();
    }
  }

  // Get material info
  Material? getMaterial(String id) => GameData.getMaterial(id);
  Product? getProduct(String id) => GameData.getProduct(id);

  // Get all available items
  List<Material> get allMaterials => GameData.materials;
  List<Product> get allProducts => GameData.products;

  // Get products categorized by tier/level
  List<Product> get basicPartsProducts => GameData.getBasicPartsProducts();
  List<Product> get intermediateProducts => GameData.getIntermediateProducts();
  List<Product> get complexProducts => GameData.getComplexProducts();
  List<Product> get retailProducts => GameData.getRetailProducts();

  // Get products organized by tiers for UI display
  Map<ProductLevel, List<Product>> get productsByTier => {
    ProductLevel.basicParts: basicPartsProducts,
    ProductLevel.intermediate: intermediateProducts,
    ProductLevel.complex: complexProducts,
    ProductLevel.retail: retailProducts,
  };

  // Error feedback methods for user notifications
  String? getLastErrorMessage(String operation) {
    // This could be expanded to track specific error messages per operation
    // For now, return generic messages based on operation type
    switch (operation) {
      case 'buy':
        return 'Unable to buy materials. Check if you have enough money.';
      case 'produce':
        return 'Unable to start production. Check if you have required materials.';
      case 'sell':
        return 'Unable to sell products. Check if you have enough inventory.';
      default:
        return 'An error occurred during the operation.';
    }
  }

  // Validate game state integrity
  bool validateGameState() {
    try {
      // Check for negative values
      if (_state.money < 0) {
        if (kDebugMode) {
          print('Invalid game state: negative money');
        }
        return false;
      }

      // Check for invalid material counts
      for (final entry in _state.materials.entries) {
        if (entry.value < 0) {
          if (kDebugMode) {
            print(
              'Invalid game state: negative material count for ${entry.key}',
            );
          }
          return false;
        }
      }

      // Check for invalid product counts
      for (final entry in _state.products.entries) {
        if (entry.value < 0) {
          if (kDebugMode) {
            print(
              'Invalid game state: negative product count for ${entry.key}',
            );
          }
          return false;
        }
      }

      // Check for invalid production tasks
      for (final task in _state.activeProductions) {
        if (task.quantity <= 0 || task.durationSeconds <= 0) {
          if (kDebugMode) {
            print('Invalid production task: ${task.id}');
          }
          return false;
        }
      }

      // Check for invalid shipping orders
      for (final order in _state.activeShippingOrders) {
        if (order.totalRevenue <= 0 || order.totalShippingTime <= 0) {
          if (kDebugMode) {
            print('Invalid shipping order: ${order.id}');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating game state: $e');
      }
      return false;
    }
  }

  // Get tier display name
  String getTierName(ProductLevel level) => GameData.getLevelName(level);
}
