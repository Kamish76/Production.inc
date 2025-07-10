import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import 'game_persistence_service.dart';
import 'product_unlock_service.dart';

// Production.INC Game Service - handles all game logic
class ProductionGameService extends ChangeNotifier {
  GameState _state = const GameState();
  Timer? _updateTimer;
  Timer? _saveTimer;
  final GamePersistenceService _persistenceService = GamePersistenceService();
  bool _isLoaded = false;
  bool _isAppPaused = false;
  bool _isTestMode = false;

  GameState get state => _state;
  bool get isLoaded => _isLoaded;
  bool get isAppPaused => _isAppPaused;
  bool get isTestMode => _isTestMode;

  ProductionGameService({bool testMode = false}) {
    _isTestMode = testMode;
    _initializeGame();
  }

  /// Initialize the game by loading saved state and starting timers
  Future<void> _initializeGame() async {
    try {
      if (_isTestMode) {
        // In test mode, use default state and don't start timers
        _state = const GameState();

        // Initialize unlock state for test mode (v1.4.18)
        _initializeUnlockState();

        _isLoaded = true;
        notifyListeners();
        return;
      }

      // Load saved game state
      _state = await _persistenceService.loadGameState();

      // Initialize unlock state after loading (v1.4.18)
      _initializeUnlockState();

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
      _state = const GameState();

      // Initialize unlock state for error fallback (v1.4.18)
      _initializeUnlockState();

      _isLoaded = true;
      notifyListeners();

      if (!_isTestMode) {
        // Still start timers (except in test mode)
        _startUpdateTimer();

        _saveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
          _saveGameState();
        });
      }
    }
  }

  /// Start the update timer with intelligent frequency management
  void _startUpdateTimer() {
    _updateTimer?.cancel();

    if (_isAppPaused || _isTestMode) {
      // Don't run timer when app is paused or in test mode for battery optimization
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
    if (!_isTestMode) {
      _saveGameState(); // Save one final time before disposing (except in test mode)
    }
    _persistenceService.dispose();
    super.dispose();
  }

  /// Save current game state to persistent storage (optimized for v1.4.8)
  Future<void> _saveGameStateOptimized() async {
    if (_isTestMode) return; // Skip save operations in test mode

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
    if (_isTestMode) return; // Skip save operations in test mode

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
    if (_isTestMode) return; // Skip save operations in test mode
    await _saveGameState();
  }

  /// Reset game to initial state
  Future<void> resetGame() async {
    if (_isTestMode) {
      // In test mode, just reset state without database operations
      _state = const GameState();
      notifyListeners();
      return;
    }

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

      // Check for newly unlocked products after material purchase (v1.4.18)
      _checkAndUpdateUnlocks();

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

      // V1.4.10 QUEUE SYSTEM: Check if there's already a production of this product type
      final existingProductionIndex = _state.activeProductions.indexWhere(
        (task) => task.productId == productId && !task.isQueued,
      );

      bool hasActiveProduction = existingProductionIndex != -1;
      final newProductions = List<ProductionTask>.from(
        _state.activeProductions,
      );

      // Create individual tasks for each unit to ensure proper queueing
      for (int i = 0; i < quantity; i++) {
        // For each task, check if we should queue it
        // First task: queue only if there's already an active production
        // Subsequent tasks: always queue them
        bool shouldQueue = hasActiveProduction || i > 0;

        DateTime startTime = DateTime.now();
        if (shouldQueue) {
          // Find the latest task for this product type to chain after it
          final lastTaskForProduct = newProductions
              .where((task) => task.productId == productId)
              .fold<ProductionTask?>(null, (latest, current) {
                if (latest == null) return current;
                final latestEnd = latest.startTime.add(
                  Duration(seconds: latest.durationSeconds.round()),
                );
                final currentEnd = current.startTime.add(
                  Duration(seconds: current.durationSeconds.round()),
                );
                return latestEnd.isAfter(currentEnd) ? latest : current;
              });

          if (lastTaskForProduct != null) {
            startTime = lastTaskForProduct.startTime.add(
              Duration(seconds: lastTaskForProduct.durationSeconds.round()),
            );
          }
        }

        // Create individual production task (quantity = 1 for proper queueing)
        final task = ProductionTask(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productId: productId,
          startTime: startTime,
          durationSeconds:
              product.productionTimeSeconds, // Single item duration
          quantity: 1, // Always 1 for proper queue behavior
          isQueued: shouldQueue,
        );

        newProductions.add(task);
      }

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

      // V1.4.10 QUEUE SYSTEM: Check production tasks with queue processing
      for (final task in _state.activeProductions) {
        try {
          if (task.isQueued) {
            // Check if this queued task should start now by looking at activeTasks being built
            final hasActiveProductionOfSameType = activeTasks.any(
              (otherTask) =>
                  otherTask.productId == task.productId && !otherTask.isQueued,
            );

            if (!hasActiveProductionOfSameType) {
              // Start this queued task
              final startedTask = task.copyWith(
                isQueued: false,
                startTime: DateTime.now(),
              );
              activeTasks.add(startedTask);
            } else {
              // Keep it queued
              activeTasks.add(task);
            }
          } else if (task.isCompleted) {
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

        // Check for newly unlocked products after production completion (v1.4.18)
        if (completedTasks.isNotEmpty) {
          _checkAndUpdateUnlocks();
        }

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

  // V1.4.18: Product unlock system methods

  /// Check for newly unlocked products and update state
  void _checkAndUpdateUnlocks() {
    try {
      final newlyUnlocked = ProductUnlockService.updateUnlockStatus(_state);

      if (newlyUnlocked.isNotEmpty) {
        // Update state with newly unlocked products
        final updatedUnlockedProducts = Set<String>.from(
          _state.unlockedProducts,
        )..addAll(newlyUnlocked);

        // Update the unlock status cache for performance
        final updatedUnlockStatus = Map<String, bool>.from(
          _state.productUnlockStatus,
        );
        for (final productId in newlyUnlocked) {
          updatedUnlockStatus[productId] = true;
        }

        _state = _state.copyWith(
          unlockedProducts: updatedUnlockedProducts,
          productUnlockStatus: updatedUnlockStatus,
        );

        // Show unlock notifications for newly unlocked products
        _showUnlockNotifications(newlyUnlocked);

        // Mark as dirty for saving
        _persistenceService.markDirty('unlocked_products');

        if (kDebugMode) {
          print('Unlocked new products: ${newlyUnlocked.join(', ')}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking unlocks: $e');
      }
    }
  }

  /// Show notifications for newly unlocked products
  void _showUnlockNotifications(Set<String> newlyUnlocked) {
    // For now, just log - could be extended to show UI notifications
    for (final productId in newlyUnlocked) {
      final product = GameData.getProduct(productId);
      if (product != null && kDebugMode) {
        print('🔓 NEW PRODUCT UNLOCKED: ${product.emoji} ${product.name}');
      }
    }
  }

  /// Initialize unlock state when game loads
  void _initializeUnlockState() {
    try {
      final allUnlockedProducts = ProductUnlockService.getAllUnlockedProducts(
        _state,
      );
      final unlockStatusMap = <String, bool>{};

      // Cache unlock status for all products for performance
      for (final product in GameData.products) {
        unlockStatusMap[product.id] = allUnlockedProducts.contains(product.id);
      }

      _state = _state.copyWith(
        unlockedProducts: allUnlockedProducts,
        productUnlockStatus: unlockStatusMap,
      );

      if (kDebugMode) {
        print(
          'Initialized unlock state: ${allUnlockedProducts.length} products unlocked',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing unlock state: $e');
      }
    }
  }

  /// Check if a product is unlocked
  bool isProductUnlocked(String productId) {
    // Use cached status for performance, fallback to service check
    return _state.productUnlockStatus[productId] ??
        ProductUnlockService.isProductUnlocked(productId, _state);
  }

  /// Get filtered products by tier (only unlocked)
  List<Product> getUnlockedProductsByTier(ProductLevel tier) {
    final tierProducts = productsByTier[tier] ?? [];
    return tierProducts
        .where((product) => isProductUnlocked(product.id))
        .toList();
  }

  /// Get tier unlock progress
  String getTierProgressString(ProductLevel tier) {
    return ProductUnlockService.getTierProgressString(tier, _state);
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

  // V1.4.10 Build Quantity Preference Management
  int getBuildQuantityPreference(String productId) {
    return _state.buildQuantityPreferences[productId] ?? 1;
  }

  void setBuildQuantityPreference(String productId, int quantity) {
    if (quantity != 1 && quantity != 10) return; // Only allow 1 or 10

    final newPreferences = Map<String, int>.from(
      _state.buildQuantityPreferences,
    );
    newPreferences[productId] = quantity;

    _state = _state.copyWith(buildQuantityPreferences: newPreferences);
    notifyListeners();
    _saveGameStateOptimized();
  }

  // Get the current build quantity for display
  String getBuildQuantityDisplay(String productId) {
    final quantity = getBuildQuantityPreference(productId);
    return quantity == 1 ? 'Build 1' : 'Build 10';
  }

  // Get queued count for a specific product
  int getQueuedCount(String productId) {
    return _state.activeProductions
        .where((task) => task.productId == productId && task.isQueued)
        .fold(0, (sum, task) => sum + task.quantity);
  }

  // Get active production count for a specific product
  int getActiveProductionCount(String productId) {
    return _state.activeProductions
        .where((task) => task.productId == productId && !task.isQueued)
        .fold(0, (sum, task) => sum + task.quantity);
  }

  // Check if there's any production (active or queued) for a product
  bool hasAnyProduction(String productId) {
    return _state.activeProductions.any((task) => task.productId == productId);
  }

  // V1.4.11 Buy Quantity Preference Management
  int getBuyQuantityPreference(String materialId) {
    return _state.buyQuantityPreferences[materialId] ?? 1;
  }

  void setBuyQuantityPreference(String materialId, int quantity) {
    if (quantity != 1 && quantity != 5 && quantity != 10) {
      return; // Only allow 1, 5, or 10
    }

    final newPreferences = Map<String, int>.from(_state.buyQuantityPreferences);
    newPreferences[materialId] = quantity;

    _state = _state.copyWith(buyQuantityPreferences: newPreferences);
    notifyListeners();
    _saveGameStateOptimized();
  }

  // V1.4.11 Sell Quantity Preference Management
  int getSellQuantityPreference(String productId) {
    return _state.sellQuantityPreferences[productId] ?? 1;
  }

  void setSellQuantityPreference(String productId, int quantity) {
    if (quantity != 1 && quantity != 5 && quantity != 10) {
      return; // Only allow 1, 5, or 10
    }

    final newPreferences = Map<String, int>.from(
      _state.sellQuantityPreferences,
    );
    newPreferences[productId] = quantity;

    _state = _state.copyWith(sellQuantityPreferences: newPreferences);
    notifyListeners();
    _saveGameStateOptimized();
  }
}
