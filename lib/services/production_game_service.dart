
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';
import 'game_persistence_service.dart';
import 'product_unlock_service.dart';
import 'machine_buyer.dart' as machine_buyer;
import 'machine_builder.dart' as machine_builder;

// Logging utility for Production.INC
class GameLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) => _logger.e(message, error: error, stackTrace: stackTrace);
}

/// Container for operation processing results
/// Used internally by ProductionGameService for updateProductions refactoring
class _OperationResults {
  final List<ProductionTask> completedTasks;
  final List<ProductionTask> activeTasks;
  final List<ShippingOrder> completedShipping;
  final List<ShippingOrder> activeShipping;

  _OperationResults({
    required this.completedTasks,
    required this.activeTasks,
    required this.completedShipping,
    required this.activeShipping,
  });
}

/// Container for money and history results
/// Used internally by ProductionGameService for shipping completion processing
class _MoneyAndHistory {
  final double money;
  final List<ShippingHistory> history;

  _MoneyAndHistory({required this.money, required this.history});
}

// Production.INC Game Service - handles all game logic
class ProductionGameService extends ChangeNotifier {
  GameState _state = const GameState(
    autoBuildMachinesOwned: {},
    autoBuildEnabled: {},
    lastAutoBuildTick: {},
    autoBuildProductCapacity: {},
  );
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
        _state = const GameState(
          autoBuildMachinesOwned: {},
          autoBuildEnabled: {},
          lastAutoBuildTick: {},
          autoBuildProductCapacity: {},
        );

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
        GameLogger.error('Error loading game state', e);
      }
      // If loading fails, start with default state
      _state = const GameState(
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );

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
  /// Uses constants from GameConstants for consistent timing across the app
  void _startUpdateTimer() {
    _updateTimer?.cancel();

    if (_isAppPaused || _isTestMode) {
      // Don't run timer when app is paused or in test mode for battery optimization
      return;
    }

    // Determine timer interval based on activity using centralized constants
    final Duration interval =
        _hasActiveOperations()
            ? const Duration(
              milliseconds: TimerConstants.normalUpdateMs,
            ) // Active operations
            : const Duration(milliseconds: TimerConstants.idleUpdateMs); // Idle state

    _updateTimer = Timer.periodic(interval, (timer) {
      if (!_isAppPaused) {
        updateProductions();

        // Dynamically adjust timer frequency based on current activity
        if (_hasActiveOperations() !=
            (interval.inMilliseconds == TimerConstants.normalUpdateMs)) {
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
  Future<void> dispose() async {
    _updateTimer?.cancel();
    _saveTimer?.cancel();
    if (!_isTestMode) {
      await _saveGameState(); // Save one final time before disposing (except in test mode)
    }
    await _persistenceService.dispose();
    super.dispose();
  }

  /// Save current game state to persistent storage (optimized for v1.4.8)
  Future<void> _saveGameStateOptimized() async {
    if (_isTestMode) return; // Skip save operations in test mode

    try {
      await _persistenceService.saveGameStateOptimized(_state);
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error saving game state (optimized)', e);
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
        GameLogger.error('Error saving game state', e);
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
      _state = const GameState(
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
      notifyListeners();
      return;
    }

    try {
      await _persistenceService.resetGameData();
      _state = const GameState(
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error resetting game', e);
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
          GameLogger.warning('Invalid buy material parameters: materialId=$materialId, quantity=$quantity');
        }
        return false;
      }

      final material = GameData.getMaterial(materialId);
      if (material == null) {
        if (kDebugMode) {
          GameLogger.warning('Material not found: $materialId');
        }
        return false;
      }

      final totalCost = material.buyPrice * quantity;
      if (!_state.canAfford(totalCost)) {
        if (kDebugMode) {
          GameLogger.warning('Insufficient funds: need \$${totalCost.toStringAsFixed(2)}, have \$${_state.money.toStringAsFixed(2)}');
        }
        return false;
      }

      // Prevent integer overflow for large quantities
      const maxQuantity = 1000000;
      if (quantity > maxQuantity) {
        if (kDebugMode) {
          GameLogger.warning('Quantity too large: $quantity > $maxQuantity');
        }
        return false;
      }

      final newMaterials = Map<String, int>.from(_state.materials);
      final currentAmount = newMaterials[materialId] ?? 0;

      // Check for potential overflow
      if (currentAmount > maxQuantity - quantity) {
        if (kDebugMode) {
          GameLogger.warning('Would exceed maximum material amount: $currentAmount + $quantity > $maxQuantity');
        }
        return false;
      }

      newMaterials[materialId] = currentAmount + quantity;

      _state = _state.copyWith(
        money: _state.money - totalCost,
        materials: newMaterials,
      );

      // Check for newly unlocked products after material purchase (v1.4.18)
      // Note: This will call notifyListeners() if any products are newly unlocked
      _checkAndUpdateUnlocks();

      // Mark materials as dirty for incremental save (v1.4.8)
      _persistenceService.markDirty('materials');

      // Notify listeners for material/money changes (unlock check notifies separately if needed)
      notifyListeners();
      _saveGameStateOptimized(); // Use optimized save after major transaction
      return true;
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error buying material $materialId (quantity: $quantity)', e);
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
          GameLogger.warning('Invalid production parameters: productId=$productId, quantity=$quantity');
        }
        return false;
      }

      final product = GameData.getProduct(productId);
      if (product == null) {
        if (kDebugMode) {
          GameLogger.warning('Product not found: $productId');
        }
        return false;
      }

      // Prevent excessive production quantities
      const maxQuantity = 10000;
      if (quantity > maxQuantity) {
        if (kDebugMode) {
          GameLogger.warning('Production quantity too large: $quantity > $maxQuantity');
        }
        return false;
      }

      // Check if we have enough materials
      final requiredMaterials = <String, int>{};
      for (final entry in product.requiredMaterials.entries) {
        final needed = entry.value * quantity;
        if (needed < 0) {
          if (kDebugMode) {
            GameLogger.error('Invalid material requirement calculation for ${entry.key}: $needed');
          }
          return false;
        }
        requiredMaterials[entry.key] = needed;
      }

      if (!_state.hasMaterialsFor(requiredMaterials)) {
        if (kDebugMode) {
          GameLogger.warning('Insufficient materials for production of $productId x$quantity');
          for (final entry in requiredMaterials.entries) {
            final have = _state.getMaterialCount(entry.key) + _state.getProductCount(entry.key);
            final need = entry.value;
            if (have < need) {
              GameLogger.info('  - ${entry.key}: have $have, need $need');
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
              GameLogger.warning('Insufficient products for consumption: $itemId, need $remaining, have $availableProducts');
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
          GameLogger.warning('Invalid production duration: ${totalDuration}s');
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
        // Apply auto-build machine speed bonus (1.2x per machine)
        final adjustedTime = getAdjustedProductionTime(
          productId,
          product.productionTimeSeconds,
        );
        
        final task = ProductionTask(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          productId: productId,
          startTime: startTime,
          durationSeconds: adjustedTime, // Adjusted for machine speed bonus
          quantity: 1, // Always 1 for proper queue behavior
          isQueued: shouldQueue,
        );

        newProductions.add(task);
      }

      // Log speed bonus if machines are present (v1.5.0)
      if (kDebugMode) {
        final product = GameData.products.firstWhere((p) => p.id == productId);
        final baseTime = product.productionTimeSeconds;
        final adjustedTime = getAdjustedProductionTime(productId, baseTime);
        if ((baseTime - adjustedTime).abs() > 0.01) {
          final speedMultiplier = baseTime / adjustedTime;
          GameLogger.info('⚡ Build speed bonus: $productId - ${baseTime}s → ${adjustedTime.toStringAsFixed(1)}s (${speedMultiplier.toStringAsFixed(2)}x faster)');
        }
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
          GameLogger.error('Error starting production $productId (quantity: $quantity)', e);
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
          GameLogger.warning('Invalid sell parameters: productId=$productId, quantity=$quantity');
        }
        return false;
      }

      final product = GameData.getProduct(productId);
      if (product == null) {
        if (kDebugMode) {
          GameLogger.warning('Product not found: $productId');
        }
        return false;
      }

      final available = _state.getProductCount(productId);
      if (available < quantity) {
        if (kDebugMode) {
          GameLogger.warning('Insufficient products to sell: $productId, need $quantity, have $available');
        }
        return false;
      }

      // Prevent excessive selling quantities
      const maxQuantity = 10000;
      if (quantity > maxQuantity) {
        if (kDebugMode) {
          GameLogger.warning('Sell quantity too large: $quantity > $maxQuantity');
        }
        return false;
      }

      // Calculate shipping time using the new formula from Product model
      final totalShippingTime = product.calculateShippingTime(quantity);

      // Validate shipping time
      if (totalShippingTime <= 0 || totalShippingTime > 86400) {
        // Max 24 hours
        if (kDebugMode) {
          GameLogger.warning('Invalid shipping time: ${totalShippingTime}s');
        }
        return false;
      }

      final totalRevenue = product.sellPrice * quantity;

      // Validate revenue calculation
      if (totalRevenue <= 0) {
        if (kDebugMode) {
          GameLogger.warning('Invalid revenue calculation: $totalRevenue');
        }
        return false;
      }

      // Check for active shipping order limit (prevent spam)
      const maxActiveOrders = 100;
      if (_state.activeShippingOrders.length >= maxActiveOrders) {
        if (kDebugMode) {
          GameLogger.warning('Too many active shipping orders: ${_state.activeShippingOrders.length}');
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
        GameLogger.error('Error selling product $productId (quantity: $quantity)', e);
      }
      return false;
    }
  }

  /// Main update method - coordinates all production and shipping updates
  /// This is the central orchestrator for all game progress updates
  void updateProductions() {
    try {
      // Check and process auto-buy tick (v1.5.0)
      _processAutoBuyTick();
      
      // Check and process auto-build ticks for all tiers (v1.5.0 Phase 2)
      _processAutoBuildTicks();
      
      // Early return if no active operations (battery optimization)
      if (!_hasActiveOperations()) {
        return;
      }

      // Process all active operations
      final operationResults = _processActiveOperations();

      // Apply completed operations to game state if any changes occurred
      if (_shouldUpdateGameState(operationResults)) {
        _applyCompletedOperations(operationResults);
        _handlePostUpdateTasks(operationResults);
      }
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error updating productions', e);
      }
      // In case of error, still notify listeners to update UI
      notifyListeners();
    }
  }

  /// Process all active production tasks and shipping orders
  /// Returns the results of processing for state updates
  _OperationResults _processActiveOperations() {
    final completedTasks = <ProductionTask>[];
    final activeTasks = <ProductionTask>[];
    final completedShipping = <ShippingOrder>[];
    final activeShipping = <ShippingOrder>[];

    // Process production tasks with queue system (V1.4.10)
    _processProductionTasks(activeTasks, completedTasks);

    // Process shipping orders
    _processShippingOrders(activeShipping, completedShipping);

    return _OperationResults(
      completedTasks: completedTasks,
      activeTasks: activeTasks,
      completedShipping: completedShipping,
      activeShipping: activeShipping,
    );
  }

  /// Process production tasks including queue management (V1.4.10 QUEUE SYSTEM)
  void _processProductionTasks(
    List<ProductionTask> activeTasks,
    List<ProductionTask> completedTasks,
  ) {
    for (final task in _state.activeProductions) {
      try {
        if (task.isQueued) {
          _handleQueuedTask(task, activeTasks);
        } else if (task.isCompleted) {
          completedTasks.add(task);
        } else {
          activeTasks.add(task);
        }
      } catch (e) {
        if (kDebugMode) {
          GameLogger.error('Error checking production task ${task.id}', e);
        }
        // If there's an error with a task, consider it active to prevent data loss
        activeTasks.add(task);
      }
    }
  }

  /// Handle queued task logic - start if no active production of same type
  void _handleQueuedTask(
    ProductionTask task,
    List<ProductionTask> activeTasks,
  ) {
    // Check if this queued task should start now
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
  }

  /// Process shipping orders - separate completed from active
  void _processShippingOrders(
    List<ShippingOrder> activeShipping,
    List<ShippingOrder> completedShipping,
  ) {
    for (final order in _state.activeShippingOrders) {
      try {
        if (order.isCompleted) {
          completedShipping.add(order);
        } else {
          activeShipping.add(order);
        }
      } catch (e) {
        if (kDebugMode) {
          GameLogger.error('Error checking shipping order ${order.id}', e);
        }
        // If there's an error with an order, consider it active to prevent data loss
        activeShipping.add(order);
      }
    }
  }

  /// Check if game state should be updated based on operation results
  bool _shouldUpdateGameState(_OperationResults results) {
    return results.completedTasks.isNotEmpty ||
        results.completedShipping.isNotEmpty ||
        _state.activeProductions.isNotEmpty ||
        _state.activeShippingOrders.isNotEmpty;
  }

  /// Process auto-buy tick if enabled and interval has elapsed (v1.5.0)
  void _processAutoBuyTick() {
    // Skip if not enabled or no machines owned
    if (!_state.autoBuyEnabled || _state.autoBuyMachinesOwned <= 0) {
      return;
    }

    final now = DateTime.now();
    final lastTick = _state.lastAutoBuyTick;

    // Check if it's time for a tick
    if (lastTick != null) {
      final elapsed = now.difference(lastTick).inSeconds;
      if (elapsed < AutoBuyConstants.tickIntervalSeconds) {
        return; // Not time yet
      }
    }

    // Build material prices map from game data
    final materialPrices = <String, double>{};
    for (final material in GameData.materials) {
      materialPrices[material.id] = material.buyPrice;
    }

    // Perform auto-buy tick using pooled-capacity model with money constraints
    final materialsCopy = Map<String, int>.from(_state.materials);
    final result = machine_buyer.performAutoBuyTick(
      inventory: materialsCopy,
      currentMoney: _state.money,
      materialPrices: materialPrices,
      machinesEnabled: _state.autoBuyMachinesOwned,
      buysPerMachinePerTick: AutoBuyConstants.buysPerMachinePerTick,
      resourceOrder: AutoBuyConstants.resourceOrder,
      resourceCap: _state.autoBuyResourceCapacity, // Use player's configurable capacity
    );

    // Update state if any purchases were made
    if (result.itemsPurchased > 0) {
      final newMoney = _state.money - result.moneySpent;
      _state = _state.copyWith(
        materials: materialsCopy,
        money: newMoney,
        lastAutoBuyTick: now,
      );
      
      // Check for newly unlocked products after material purchase (v1.5.0 bug fix)
      // This ensures that auto-buy machines trigger unlocks just like manual purchases
      _checkAndUpdateUnlocks();
      
      notifyListeners();

      if (kDebugMode) {
        GameLogger.info(
          'Auto-buy tick: purchased ${result.itemsPurchased} items for \$${result.moneySpent.toStringAsFixed(2)} with ${_state.autoBuyMachinesOwned} machines',
        );
      }
    } else {
      // Update tick time even if no purchases (all resources at cap or out of money)
      _state = _state.copyWith(lastAutoBuyTick: now);
      
      if (kDebugMode) {
        final cheapestMaterial = materialPrices.values.isEmpty ? 0.0 : materialPrices.values.reduce((a, b) => a < b ? a : b);
        if (_state.money < cheapestMaterial) {
          GameLogger.warning('Auto-buy tick: insufficient money to buy any materials');
        }
      }
    }
  }

  /// Process auto-build ticks for all tiers (v1.5.0 Phase 2)
  void _processAutoBuildTicks() {
    // Process each tier independently
    for (final tierEntry in AutoBuildConstants.productOrderByTier.entries) {
      final tier = tierEntry.key;
      final productOrder = tierEntry.value;
      
      if (productOrder.isEmpty) continue; // Skip tiers with no products defined
      
      final machineCount = _state.autoBuildMachinesOwned[tier] ?? 0;
      final enabled = _state.autoBuildEnabled[tier] ?? false;
      
      // Skip if disabled or no machines
      if (!enabled || machineCount <= 0) continue;
      
      // Check if it's time for a tick
      final now = DateTime.now();
      final lastTick = _state.lastAutoBuildTick[tier];
      
      if (lastTick != null) {
        final elapsed = now.difference(lastTick).inSeconds;
        if (elapsed < AutoBuildConstants.tickIntervalSeconds) {
          continue; // Not time yet for this tier
        }
      }
      
      // Build product recipes map
      final productRecipes = <String, Map<String, int>>{};
      for (final productId in productOrder) {
        final product = GameData.products.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: productId,
            name: productId,
            description: '',
            sellPrice: 0,
            emoji: '❓',
            requiredMaterials: {},
            productionTimeSeconds: 0,
            baseShippingTimeSeconds: 0,
            levelId: ProductLevel.basicParts,
          ),
        );
        productRecipes[productId] = product.requiredMaterials;
      }
      
      // Get unlocked products for this tier
      final unlockedProducts = <String>{};
      for (final productId in productOrder) {
        if (isProductUnlocked(productId)) {
          unlockedProducts.add(productId);
        }
      }
      
      if (kDebugMode) {
        GameLogger.info('Auto-build ($tier): ${unlockedProducts.length}/${productOrder.length} products unlocked: ${unlockedProducts.join(", ")}');
        // Show available materials
        final materialsList = <String>[];
        final relevantMaterials = {'basic_metals', 'plastic', 'advanced_metals', 'glass', 'cardboard'};
        for (final matId in relevantMaterials) {
          final amount = _state.materials[matId] ?? 0;
          if (amount > 0) {
            materialsList.add('$matId:$amount');
          }
        }
        if (materialsList.isNotEmpty) {
          GameLogger.info('Auto-build ($tier): Materials available: ${materialsList.join(", ")}');
        }
      }
      
      // Perform auto-build tick using pooled-capacity model
      // Merge materials and products into a single inventory for material checking
      // (products can be used as materials for other products)
      final materialsCopy = Map<String, int>.from(_state.materials);
      // Add products to materials inventory so they can be consumed as materials
      for (final entry in _state.products.entries) {
        materialsCopy[entry.key] = (materialsCopy[entry.key] ?? 0) + entry.value;
      }
      
      if (kDebugMode) {
        // Log if wires are available in merged inventory
        final wiresAvailable = materialsCopy['wires'] ?? 0;
        if (wiresAvailable > 0) {
          GameLogger.info('Auto-build ($tier): wires available in merged inventory: $wiresAvailable');
        }
      }
      
      final productsCopy = Map<String, int>.from(_state.products);
      final capacity = _state.autoBuildProductCapacity[tier] ?? AutoBuildConstants.defaultProductCapacity;
      
      // Calculate queued product counts (items currently in production or queued)
      final queuedProductCounts = <String, int>{};
      for (final task in _state.activeProductions) {
        queuedProductCounts[task.productId] = (queuedProductCounts[task.productId] ?? 0) + task.quantity;
      }
      
      final result = machine_builder.performAutoBuildTick(
        productInventory: productsCopy,
        materialInventory: materialsCopy,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: queuedProductCounts,
        machinesEnabled: machineCount,
        buildsPerMachinePerTick: AutoBuildConstants.buildsPerMachinePerTick,
        productOrder: productOrder,
        productCap: capacity,
      );
      
      // Update state and enqueue production tasks if any items were built
      if (result.itemsBuilt > 0) {
        // Update tick time
        final newLastTicks = Map<String, DateTime?>.from(_state.lastAutoBuildTick);
        newLastTicks[tier] = now;
        
        // Enqueue production tasks for built items (following v1.4.10 queue system)
        final newProductions = List<ProductionTask>.from(_state.activeProductions);
        
        for (final entry in productsCopy.entries) {
          final productId = entry.key;
          final newAmount = entry.value;
          final oldAmount = _state.products[productId] ?? 0;
          final builtCount = newAmount - oldAmount;
          
          if (builtCount > 0) {
            // Find product info for production time
            final product = GameData.products.firstWhere(
              (p) => p.id == productId,
              orElse: () => Product(
                id: productId,
                name: productId,
                description: '',
                sellPrice: 0,
                emoji: '❓',
                requiredMaterials: {},
                productionTimeSeconds: 1,
                baseShippingTimeSeconds: 0,
                levelId: ProductLevel.basicParts,
              ),
            );
            
            // Check if there's already an active production of this product
            final hasActiveProduction = newProductions.any(
              (task) => task.productId == productId && !task.isQueued,
            );
            
            // Enqueue production tasks (one per unit, following v1.4.10 pattern)
            for (int i = 0; i < builtCount; i++) {
              final shouldQueue = hasActiveProduction || i > 0;
              
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
              
              // Apply auto-build machine speed bonus (1.2x per machine)
              final adjustedTime = getAdjustedProductionTime(
                productId,
                product.productionTimeSeconds,
              );
              
              final task = ProductionTask(
                id: '${DateTime.now().millisecondsSinceEpoch}_autobuild_$i',
                productId: productId,
                startTime: startTime,
                durationSeconds: adjustedTime, // Adjusted for machine speed bonus
                quantity: 1, // Always 1 for proper queue behavior
                isQueued: shouldQueue,
              );
              
              newProductions.add(task);
              
              // Log speed bonus for auto-build (v1.5.0)
              if (kDebugMode && (product.productionTimeSeconds - adjustedTime).abs() > 0.01) {
                final speedMultiplier = product.productionTimeSeconds / adjustedTime;
                GameLogger.info('⚡ Auto-build speed bonus: $productId - ${product.productionTimeSeconds}s → ${adjustedTime.toStringAsFixed(1)}s (${speedMultiplier.toStringAsFixed(2)}x faster)');
              }
            }
          }
        }
        
        // Update state with consumed materials and enqueued productions
        // Split materialsCopy back into pure materials and products
        final updatedMaterials = Map<String, int>.from(_state.materials);
        final updatedProducts = Map<String, int>.from(_state.products);
        
        // BUG FIX: Properly track consumed materials vs products
        // materialsCopy is a merged inventory (materials + products merged together)
        // We need to split it back correctly:
        // 1. For pure materials (items that exist ONLY in materials, not products)
        // 2. For products used as materials (items in products that were consumed)
        
        // Update raw materials from materialsCopy
        // Only update items that are PURE materials (not products)
        for (final matId in _state.materials.keys) {
          // Check if this is a pure material (not a product)
          final isPureProduct = _state.products.containsKey(matId);
          
          if (!isPureProduct) {
            // This is a pure material, update it from materialsCopy
            final newAmount = materialsCopy[matId] ?? 0;
            if (newAmount > 0) {
              updatedMaterials[matId] = newAmount;
            } else {
              updatedMaterials.remove(matId);
            }
          } else {
            // This item exists as BOTH material and product
            // We need to carefully split the consumption
            // The material portion was the original material count
            final originalMaterial = _state.materials[matId] ?? 0;
            final originalProduct = _state.products[matId] ?? 0;
            final originalTotal = originalMaterial + originalProduct;
            final remainingTotal = materialsCopy[matId] ?? 0;
            final totalConsumed = originalTotal - remainingTotal;
            
            // Consume from materials first, then products
            final materialConsumed = math.min(totalConsumed, originalMaterial);
            final productConsumed = totalConsumed - materialConsumed;
            
            final newMaterialAmount = math.max(0, originalMaterial - materialConsumed);
            final newProductAmount = math.max(0, originalProduct - productConsumed);
            
            if (newMaterialAmount > 0) {
              updatedMaterials[matId] = newMaterialAmount;
            } else {
              updatedMaterials.remove(matId);
            }
            
            if (newProductAmount > 0) {
              updatedProducts[matId] = newProductAmount;
            } else {
              updatedProducts.remove(matId);
            }
          }
        }
        
        // Update products that were consumed as materials (but NOT in materials)
        for (final productId in _state.products.keys) {
          // Skip if we already handled it above (exists in both materials and products)
          if (_state.materials.containsKey(productId)) {
            continue;
          }
          
          if (materialsCopy.containsKey(productId)) {
            // Calculate how much was consumed
            final originalAmount = _state.products[productId] ?? 0;
            final remainingAmount = materialsCopy[productId] ?? 0;
            final consumed = originalAmount - remainingAmount;
            
            if (consumed > 0) {
              // Deduct consumed amount from product inventory
              final newAmount = math.max(0, originalAmount - consumed);
              if (newAmount > 0) {
                updatedProducts[productId] = newAmount;
              } else {
                updatedProducts.remove(productId);
              }
            }
          }
        }
        
        _state = _state.copyWith(
          materials: updatedMaterials,
          products: updatedProducts,
          activeProductions: newProductions,
          lastAutoBuildTick: newLastTicks,
        );
        
        // Check for newly unlocked products after auto-build (v1.5.0 bug fix)
        // This ensures that auto-build machines trigger unlocks when products are built
        _checkAndUpdateUnlocks();
        
        notifyListeners();
        
        if (kDebugMode) {
          GameLogger.info(
            'Auto-build tick ($tier): built ${result.itemsBuilt} items with $machineCount machines',
          );
        }
      } else {
        // Update tick time even if nothing built (all at cap or insufficient materials)
        final newLastTicks = Map<String, DateTime?>.from(_state.lastAutoBuildTick);
        newLastTicks[tier] = now;
        
        _state = _state.copyWith(lastAutoBuildTick: newLastTicks);
        
        if (kDebugMode) {
          // Show detailed status for each unlocked product
          final statusList = <String>[];
          for (final productId in unlockedProducts) {
            final inv = productsCopy[productId] ?? 0;
            final queued = queuedProductCounts[productId] ?? 0;
            final total = inv + queued;
            
            if (total >= capacity) {
              statusList.add('$productId:$inv+$queued=$total(AT_CAP)');
            } else {
              // Show what materials are needed vs available
              final recipe = productRecipes[productId];
              final matsList = <String>[];
              if (recipe != null) {
                for (final entry in recipe.entries) {
                  final matId = entry.key;
                  final needed = entry.value;
                  final available = materialsCopy[matId] ?? 0;
                  matsList.add('$matId:$available/$needed');
                }
              }
              statusList.add('$productId:$inv+$queued=$total(NEED_MATS[${matsList.join(",")}])');
            }
          }
          GameLogger.info('Auto-build tick ($tier): no items built - ${statusList.join(" | ")}');
        }
      }
    }
  }

  /// Apply completed operations to game state
  void _applyCompletedOperations(_OperationResults results) {
    // Process completed productions and add to inventory
    final newProducts = _addCompletedProductionsToInventory(
      results.completedTasks,
    );

    // Process completed shipping and add revenue/history
    final moneyAndHistory = _processCompletedShipping(
      results.completedShipping,
    );

    // Update game state with all changes
    _state = _state.copyWith(
      money: moneyAndHistory.money,
      products: newProducts,
      activeProductions: results.activeTasks,
      activeShippingOrders: results.activeShipping,
      shippingHistory: moneyAndHistory.history,
    );
  }

  /// Add completed production tasks to product inventory
  Map<String, int> _addCompletedProductionsToInventory(
    List<ProductionTask> completedTasks,
  ) {
    final newProducts = Map<String, int>.from(_state.products);

    for (final task in completedTasks) {
      try {
        final currentCount = newProducts[task.productId] ?? 0;
        const maxProducts = LimitsConstants.maxProducts;

        // Prevent overflow
        if (currentCount > maxProducts - task.quantity) {
          if (kDebugMode) {
            GameLogger.warning('Product overflow prevented: ${task.productId}, current: $currentCount, adding: ${task.quantity}');
          }
          // Add what we can without overflow
          newProducts[task.productId] = maxProducts;
        } else {
          newProducts[task.productId] = currentCount + task.quantity;
        }
      } catch (e) {
        if (kDebugMode) {
          GameLogger.error('Error completing production task ${task.id}', e);
        }
      }
    }

    return newProducts;
  }

  /// Process completed shipping orders - add revenue and create history
  _MoneyAndHistory _processCompletedShipping(
    List<ShippingOrder> completedShipping,
  ) {
    double newMoney = _state.money;
    final newHistory = List<ShippingHistory>.from(_state.shippingHistory);

    for (final order in completedShipping) {
      try {
        // Add revenue with overflow protection
        newMoney = _addRevenueWithOverflowProtection(
          newMoney,
          order.totalRevenue,
        );

        // Add to shipping history
        final historyEntry = ShippingHistory(
          id: order.id,
          items: order.items,
          completedTime: DateTime.now(),
          totalRevenue: order.totalRevenue,
        );
        newHistory.add(historyEntry);
      } catch (e) {
        if (kDebugMode) {
          GameLogger.error('Error completing shipping order ${order.id}', e);
        }
      }
    }

    return _MoneyAndHistory(money: newMoney, history: newHistory);
  }

  /// Add revenue to player money with overflow protection
  double _addRevenueWithOverflowProtection(
    double currentMoney,
    double revenue,
  ) {
    const maxMoney = LimitsConstants.maxMoney;

    if (currentMoney > maxMoney - revenue) {
      if (kDebugMode) {
        GameLogger.warning('Money overflow prevented: current: $currentMoney, adding: $revenue');
      }
      return maxMoney;
    } else {
      return currentMoney + revenue;
    }
  }

  /// Handle post-update tasks like unlock checking and timer optimization
  void _handlePostUpdateTasks(_OperationResults results) {
    // Check for newly unlocked products after production completion (v1.4.18)
    if (results.completedTasks.isNotEmpty) {
      _checkAndUpdateUnlocks();
    }

    notifyListeners();

    // Optimize timer frequency if operations completed
    if (results.completedTasks.isNotEmpty ||
        results.completedShipping.isNotEmpty) {
      _startUpdateTimer(); // Restart with optimal frequency
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

        // Notify listeners so UI updates to show newly unlocked products
        notifyListeners();

        if (kDebugMode) {
          GameLogger.info('🔓 Unlocked new products: ${newlyUnlocked.join(', ')} (Total unlocked: ${updatedUnlockedProducts.length})');
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
        // Could show UI notifications here in the future
        // Product unlocked: ${product.emoji} ${product.name}
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
        GameLogger.info('Initialized unlock state: ${allUnlockedProducts.length} products unlocked');
      }
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error initializing unlock state', e);
      }
    }
  }

  /// Check if a product is unlocked
  bool isProductUnlocked(String productId) {
    // Use cached status for performance, fallback to service check
    return _state.productUnlockStatus[productId] ??
        ProductUnlockService.isProductUnlocked(productId, _state);
  }

  /// Calculate adjusted production time with auto-build machine speed bonus
  /// Each machine provides a 1.2x speed multiplier (stacks multiplicatively)
  /// Formula: adjustedTime = baseTime / (1.2 ^ machineCount)
  double getAdjustedProductionTime(String productId, double baseTime) {
    // Find which tier this product belongs to
    final product = GameData.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => Product(
        id: productId,
        name: productId,
        description: '',
        sellPrice: 0,
        emoji: '❓',
        requiredMaterials: {},
        productionTimeSeconds: baseTime,
        baseShippingTimeSeconds: 0,
        levelId: ProductLevel.basicParts,
      ),
    );

    // Determine the tier key based on product level
    String? tierKey;
    switch (product.levelId) {
      case ProductLevel.basicParts:
        tierKey = 'basicParts';
        break;
      case ProductLevel.intermediate:
        tierKey = 'intermediate';
        break;
      case ProductLevel.complex:
        tierKey = 'complex';
        break;
      default:
        // Materials and retail products don't get speed bonus
        return baseTime;
    }

    // Get machine count for this tier
    final machineCount = _state.autoBuildMachinesOwned[tierKey] ?? 0;
    
    if (machineCount <= 0) {
      return baseTime;
    }

    // Calculate speed multiplier: 1.2 ^ machineCount
    final speedMultiplier = math.pow(
      AutoBuildConstants.buildSpeedMultiplierPerMachine,
      machineCount,
    ).toDouble();

    // Apply speed bonus: time / multiplier
    final adjustedTime = baseTime / speedMultiplier;

    return adjustedTime;
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
          GameLogger.warning('Invalid game state: negative money');
        }
        return false;
      }

      // Check for invalid material counts
      for (final entry in _state.materials.entries) {
        if (entry.value < 0) {
          if (kDebugMode) {
            GameLogger.warning('Invalid game state: negative material count for ${entry.key}');
          }
          return false;
        }
      }

      // Check for invalid product counts
      for (final entry in _state.products.entries) {
        if (entry.value < 0) {
          if (kDebugMode) {
            GameLogger.warning('Invalid game state: negative product count for ${entry.key}');
          }
          return false;
        }
      }

      // Check for invalid production tasks
      for (final task in _state.activeProductions) {
        if (task.quantity <= 0 || task.durationSeconds <= 0) {
          if (kDebugMode) {
            GameLogger.warning('Invalid production task: ${task.id}');
          }
          return false;
        }
      }

      // Check for invalid shipping orders
      for (final order in _state.activeShippingOrders) {
        if (order.totalRevenue <= 0 || order.totalShippingTime <= 0) {
          if (kDebugMode) {
            GameLogger.warning('Invalid shipping order: ${order.id}');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error validating game state', e);
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

  // V1.5.0 Auto-Buy Machine Management (Development Mode)
  /// Toggle auto-buy machines on/off
  void toggleAutoBuy() {
    _state = _state.copyWith(autoBuyEnabled: !_state.autoBuyEnabled);
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-buy toggled: ${_state.autoBuyEnabled ? "ON" : "OFF"}',
      );
    }
  }

  /// Set the number of auto-buy machines owned (DEV MODE ONLY)
  /// This is a temporary control for development/testing
  void setAutoBuyMachineCount(int count) {
    if (count < 0) return; // Clamp to non-negative

    _state = _state.copyWith(autoBuyMachinesOwned: count);
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('Auto-buy machine count set to: $count');
    }
  }

  /// Increment auto-buy machine count (DEV MODE ONLY)
  void incrementAutoBuyMachines() {
    setAutoBuyMachineCount(_state.autoBuyMachinesOwned + 1);
  }

  /// Decrement auto-buy machine count (DEV MODE ONLY)
  void decrementAutoBuyMachines() {
    if (_state.autoBuyMachinesOwned > 0) {
      setAutoBuyMachineCount(_state.autoBuyMachinesOwned - 1);
    }
  }

  /// Increase auto-buy resource capacity by 10
  void increaseAutoBuyCapacity() {
    final newCapacity = _state.autoBuyResourceCapacity + AutoBuyConstants.capacityIncrement;
    _state = _state.copyWith(autoBuyResourceCapacity: newCapacity);
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('Auto-buy capacity increased to: $newCapacity');
    }
  }

  /// Decrease auto-buy resource capacity by 10 (minimum 10)
  void decreaseAutoBuyCapacity() {
    if (_state.autoBuyResourceCapacity > AutoBuyConstants.defaultResourceCapacity) {
      final newCapacity = _state.autoBuyResourceCapacity - AutoBuyConstants.capacityIncrement;
      _state = _state.copyWith(autoBuyResourceCapacity: newCapacity);
      notifyListeners();
      _saveGameStateOptimized();

      if (kDebugMode) {
        GameLogger.info('Auto-buy capacity decreased to: $newCapacity');
      }
    }
  }

  // Auto-Buy Machine Status Getters (v1.5.0)
  
  /// Get seconds remaining until next auto-buy tick (returns null if not active)
  int? getSecondsUntilNextAutoBuyTick() {
    if (!_state.autoBuyEnabled || _state.autoBuyMachinesOwned <= 0) {
      return null;
    }
    
    final lastTick = _state.lastAutoBuyTick;
    if (lastTick == null) {
      return 0; // Never ticked yet, will tick immediately
    }
    
    final now = DateTime.now();
    final elapsed = now.difference(lastTick).inSeconds;
    final remaining = AutoBuyConstants.tickIntervalSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Get the name of the next material that will be bought (based on current inventory)
  String? getNextMaterialToBuy() {
    if (!_state.autoBuyEnabled || _state.autoBuyMachinesOwned <= 0) {
      return null;
    }
    
    // Check each resource in order to find the first one below cap
    for (final resourceId in AutoBuyConstants.resourceOrder) {
      final currentAmount = _state.materials[resourceId] ?? 0;
      if (currentAmount < _state.autoBuyResourceCapacity) {
        // Find the material name from game data
        final material = GameData.materials.firstWhere(
          (m) => m.id == resourceId,
          orElse: () => Material(
            id: resourceId,
            name: resourceId,
            description: '',
            buyPrice: 0,
            emoji: '❓',
          ),
        );
        return material.name;
      }
    }
    
    return 'All at cap'; // All resources at cap
  }

  // V1.5.0 Phase 2: Auto-Build Machine Management (Development Mode)
  
  /// Toggle auto-build machines on/off for a specific tier
  void toggleAutoBuild(String tier) {
    final newEnabled = Map<String, bool>.from(_state.autoBuildEnabled);
    newEnabled[tier] = !(newEnabled[tier] ?? false);
    
    _state = _state.copyWith(autoBuildEnabled: newEnabled);
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-build toggled for $tier: ${newEnabled[tier]! ? "ON" : "OFF"}',
      );
    }
  }

  /// Increment auto-build machine count for a tier (DEV MODE ONLY)
  void incrementAutoBuildMachines(String tier) {
    final newMachines = Map<String, int>.from(_state.autoBuildMachinesOwned);
    newMachines[tier] = (newMachines[tier] ?? 0) + 1;
    
    _state = _state.copyWith(autoBuildMachinesOwned: newMachines);
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('Auto-build machine count for $tier set to: ${newMachines[tier]}');
    }
  }

  /// Decrement auto-build machine count for a tier (DEV MODE ONLY)
  void decrementAutoBuildMachines(String tier) {
    final currentCount = _state.autoBuildMachinesOwned[tier] ?? 0;
    if (currentCount > 0) {
      final newMachines = Map<String, int>.from(_state.autoBuildMachinesOwned);
      newMachines[tier] = currentCount - 1;
      
      _state = _state.copyWith(autoBuildMachinesOwned: newMachines);
      notifyListeners();
      _saveGameStateOptimized();

      if (kDebugMode) {
        GameLogger.info('Auto-build machine count for $tier set to: ${newMachines[tier]}');
      }
    }
  }

  /// Increase auto-build product capacity by 10 for a tier
  void increaseAutoBuildCapacity(String tier) {
    final newCapacities = Map<String, int>.from(_state.autoBuildProductCapacity);
    final currentCapacity = newCapacities[tier] ?? AutoBuildConstants.defaultProductCapacity;
    newCapacities[tier] = currentCapacity + AutoBuildConstants.capacityIncrement;
    
    _state = _state.copyWith(autoBuildProductCapacity: newCapacities);
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('Auto-build capacity for $tier increased to: ${newCapacities[tier]}');
    }
  }

  /// Decrease auto-build product capacity by 10 for a tier (minimum 10)
  void decreaseAutoBuildCapacity(String tier) {
    final currentCapacity = _state.autoBuildProductCapacity[tier] ?? AutoBuildConstants.defaultProductCapacity;
    if (currentCapacity > AutoBuildConstants.defaultProductCapacity) {
      final newCapacities = Map<String, int>.from(_state.autoBuildProductCapacity);
      newCapacities[tier] = currentCapacity - AutoBuildConstants.capacityIncrement;
      
      _state = _state.copyWith(autoBuildProductCapacity: newCapacities);
      notifyListeners();
      _saveGameStateOptimized();

      if (kDebugMode) {
        GameLogger.info('Auto-build capacity for $tier decreased to: ${newCapacities[tier]}');
      }
    }
  }

  /// Get seconds remaining until next auto-build tick for a tier (returns null if not active)
  int? getSecondsUntilNextAutoBuildTick(String tier) {
    final machineCount = _state.autoBuildMachinesOwned[tier] ?? 0;
    final enabled = _state.autoBuildEnabled[tier] ?? false;
    
    if (!enabled || machineCount <= 0) {
      return null;
    }
    
    final lastTick = _state.lastAutoBuildTick[tier];
    if (lastTick == null) {
      return 0; // Never ticked yet, will tick immediately
    }
    
    final now = DateTime.now();
    final elapsed = now.difference(lastTick).inSeconds;
    final remaining = AutoBuildConstants.tickIntervalSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Get the name of the next product that will be built for a tier (based on current inventory)
  String? getNextProductToBuild(String tier) {
    final machineCount = _state.autoBuildMachinesOwned[tier] ?? 0;
    final enabled = _state.autoBuildEnabled[tier] ?? false;
    
    if (!enabled || machineCount <= 0) {
      return null;
    }
    
    // Get product order for this tier
    final productOrder = AutoBuildConstants.productOrderByTier[tier] ?? [];
    final capacity = _state.autoBuildProductCapacity[tier] ?? AutoBuildConstants.defaultProductCapacity;
    
    // Check each product in order to find the first one below cap and unlocked
    for (final productId in productOrder) {
      if (!isProductUnlocked(productId)) continue;
      
      final currentAmount = _state.products[productId] ?? 0;
      if (currentAmount < capacity) {
        // Find the product name from game data
        final product = GameData.products.firstWhere(
          (p) => p.id == productId,
          orElse: () => Product(
            id: productId,
            name: productId,
            description: '',
            sellPrice: 0,
            emoji: '❓',
            requiredMaterials: {},
            productionTimeSeconds: 0,
            baseShippingTimeSeconds: 0,
            levelId: ProductLevel.basicParts,
          ),
        );
        return product.name;
      }
    }
    
    
    return 'All at cap'; // All products at cap
  }

  /// Dev method: Add product directly to inventory (for testing/unlocking)
  void addProductToInventory(String productId, int quantity) {
    if (quantity <= 0) return;
    
    final newProducts = Map<String, int>.from(_state.products);
    final currentCount = newProducts[productId] ?? 0;
    newProducts[productId] = currentCount + quantity;
    
    _state = _state.copyWith(products: newProducts);
    
    // Check for newly unlocked products after adding to inventory
    _checkAndUpdateUnlocks();
    
    notifyListeners();
    _saveGameStateOptimized();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Added $quantity $productId to inventory (total: ${newProducts[productId]})');
    }
  }

  /// Dev method: Add money directly to balance (for testing)
  void addMoney(double amount) {
    if (amount <= 0) return;
    
    _state = _state.copyWith(money: _state.money + amount);
    
    // Check for newly unlocked products after adding money
    _checkAndUpdateUnlocks();
    
    notifyListeners();
    _saveGameStateOptimized();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Added \$${amount.toStringAsFixed(2)} to balance (total: \$${_state.money.toStringAsFixed(2)})');
    }
  }

  /// Dev method: Complete all active productions instantly (for testing)
  void completeAllProductionsInstantly() {
    if (_state.activeProductions.isEmpty) return;
    
    final completedCount = _state.activeProductions.length;
    
    // Set all productions to have started in the past so they complete immediately
    final now = DateTime.now();
    final updatedProductions = _state.activeProductions.map((task) {
      return task.copyWith(
        startTime: now.subtract(Duration(seconds: task.durationSeconds.ceil() + 1)),
      );
    }).toList();
    
    _state = _state.copyWith(activeProductions: updatedProductions);
    
    // Trigger update to process completed productions
    updateProductions();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Completed $completedCount productions instantly');
    }
  }

  /// Dev method: Complete all active shipments instantly (for testing)
  void completeAllShipmentsInstantly() {
    if (_state.activeShippingOrders.isEmpty) return;
    
    final completedCount = _state.activeShippingOrders.length;
    
    // Set all shipments to have started in the past so they complete immediately
    final now = DateTime.now();
    final updatedShipments = _state.activeShippingOrders.map((order) {
      return ShippingOrder(
        id: order.id,
        items: order.items,
        startTime: now.subtract(Duration(seconds: order.totalShippingTime.ceil() + 1)),
        totalShippingTime: order.totalShippingTime,
        totalRevenue: order.totalRevenue,
      );
    }).toList();
    
    _state = _state.copyWith(activeShippingOrders: updatedShipments);
    
    // Trigger update to process completed shipments
    updateProductions();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Completed $completedCount shipments instantly');
    }
  }

  /// Dev method: Unlock all products by setting a high money amount (for testing)
  void unlockAllProductsForTesting() {
    // Add a very large amount of money to trigger all unlocks
    _state = _state.copyWith(money: _state.money + 1000000);
    
    // Force unlock check
    _checkAndUpdateUnlocks();
    
    notifyListeners();
    _saveGameStateOptimized();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Unlocked all products (added \$1,000,000)');
    }
  }

  /// Dev method: Force a manual unlock check (for debugging)
  void forceUnlockCheck() {
    // Re-initialize unlock state from scratch
    _initializeUnlockState();
    
    // Then check for any newly unlocked products
    _checkAndUpdateUnlocks();
    
    notifyListeners();
    _saveGameStateOptimized();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Forced unlock check - ${_state.unlockedProducts.length} products unlocked');
    }
  }

  /// Dev method: Repair database structure (for fixing migration issues)
  Future<void> repairDatabase() async {
    try {
      if (kDebugMode) {
        GameLogger.info('Dev: Starting database repair...');
      }
      
      // Close current database connection
      await _persistenceService.dispose();
      
      // Reinitialize database (this will run migrations)
      await _persistenceService.database;
      
      // Reload the game state
      _state = await _persistenceService.loadGameState();
      
      // Reinitialize unlock state
      _initializeUnlockState();
      _checkAndUpdateUnlocks();
      
      notifyListeners();
      
      if (kDebugMode) {
        GameLogger.info('Dev: Database repair completed');
      }
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Dev: Database repair failed: $e');
      }
      rethrow;
    }
  }
}




