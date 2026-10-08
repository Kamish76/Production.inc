
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../models/auto_sell_preview.dart';
import '../models/auto_sell_log_entry.dart';
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

/// Result category for code redemption
enum RedeemCodeResult {
  devUnlocked,
  rewardClaimed,
  alreadyRedeemed,
  invalid,
}

/// Detailed outcome of a code redemption attempt
class RedeemResult {
  final RedeemCodeResult status;
  final String message;
  final double? cashGranted;

  const RedeemResult({
    required this.status,
    required this.message,
    this.cashGranted,
  });
}

// Production.INC Game Service - handles all game logic
class ProductionGameService extends ChangeNotifier {
  // ignore: prefer_const_constructors
  GameState _state = GameState(
    autoBuildMachinesOwned: <String, int>{},
    autoBuildEnabled: <String, bool>{},
    lastAutoBuildTick: <String, DateTime?>{},
    autoBuildProductCapacity: <String, int>{},
  );
  Timer? _updateTimer;
  Timer? _saveTimer;
  final GamePersistenceService _persistenceService = GamePersistenceService();
  bool _isLoaded = false;
  bool _isAppPaused = false;
  bool _isTestMode = false;

  // Phase A: Ephemeral developer mode session flag (memory only)
  bool _isDeveloperModeUnlocked = false;

  GameState get state => _state;
  bool get isLoaded => _isLoaded;
  bool get isAppPaused => _isAppPaused;
  bool get isTestMode => _isTestMode;
  bool get isDeveloperModeUnlocked => _isDeveloperModeUnlocked;

  /// Whether the R&D Lab is unlocked (strictly via Discord beta code RNDBETA2026)
  bool get isRnDLabUnlocked =>
      _state.redeemedCodes.contains('RNDBETA2026');

  /// Whether the player specifically redeemed the Discord beta code
  bool get isRnDLabBetaUnlocked =>
      _state.redeemedCodes.contains('RNDBETA2026');

  /// Re-lock R&D Lab for testing or reset
  void relockRnDLab() {
    final updatedCodes = Set<String>.from(_state.redeemedCodes)..remove('RNDBETA2026');
    _state = _state.copyWith(redeemedCodes: updatedCodes);
    _persistenceService.markDirty('game_state');
    _persistenceService.markDirty('redeemed_codes');
    notifyListeners();
    if (!_isTestMode) {
      saveGame();
    }
  }

  /// Toggle R&D Lab unlock state for dev testing
  void toggleRnDLabLock() {
    if (isRnDLabUnlocked) {
      relockRnDLab();
    } else {
      redeemCode('RNDBETA2026');
    }
  }

  void setDeveloperModeUnlocked(bool value) {
    if (_isDeveloperModeUnlocked != value) {
      _isDeveloperModeUnlocked = value;
      notifyListeners();
    }
  }

  /// Redeem promotional or developer codes
  RedeemResult redeemCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return const RedeemResult(
        status: RedeemCodeResult.invalid,
        message: '❌ Invalid redeem code.',
      );
    }

    // 1. Ephemeral Session Debug Unlock: 888888
    if (cleanCode == '888888') {
      _isDeveloperModeUnlocked = true;
      notifyListeners();
      return const RedeemResult(
        status: RedeemCodeResult.devUnlocked,
        message: '🛠️ Developer Tools Unlocked! (Session Only)',
      );
    }

    // 2. Already redeemed check
    if (_state.redeemedCodes.contains(cleanCode)) {
      return const RedeemResult(
        status: RedeemCodeResult.alreadyRedeemed,
        message: '⚠️ Code has already been redeemed!',
      );
    }

    // 3. Persistent Launch Gift Code: PRODUCTION2026
    if (cleanCode == 'PRODUCTION2026') {
      const reward = 5000.0;
      final updatedCodes = Set<String>.from(_state.redeemedCodes)..add(cleanCode);
      _state = _state.copyWith(
        money: math.min(_state.money + reward, LimitsConstants.maxMoney),
        redeemedCodes: updatedCodes,
      );
      _persistenceService.markDirty('game_state');
      _persistenceService.markDirty('redeemed_codes');
      notifyListeners();
      if (!_isTestMode) {
        saveGame();
      }
      return const RedeemResult(
        status: RedeemCodeResult.rewardClaimed,
        message: '🎉 Redeemed PRODUCTION2026! +\$5,000 Cash added!',
        cashGranted: reward,
      );
    }

    // 4. Closed Beta Code: RNDBETA2026 (Unlocks R&D Lab)
    if (cleanCode == 'RNDBETA2026') {
      final updatedCodes = Set<String>.from(_state.redeemedCodes)..add(cleanCode);
      _state = _state.copyWith(
        redeemedCodes: updatedCodes,
      );
      _persistenceService.markDirty('game_state');
      _persistenceService.markDirty('redeemed_codes');
      notifyListeners();
      if (!_isTestMode) {
        saveGame();
      }
      return const RedeemResult(
        status: RedeemCodeResult.rewardClaimed,
        message: '🧪 R&D Lab Beta Access Unlocked! Welcome to the lab.',
      );
    }

    // 5. Unknown code
    return const RedeemResult(
      status: RedeemCodeResult.invalid,
      message: '❌ Invalid redeem code.',
    );
  }

  // Phase 11: Staged Shipping Manifest (Bulk Sell Cart)
  final Map<String, int> _stagedManifest = <String, int>{};

  Map<String, int> get stagedManifest => Map.unmodifiable(_stagedManifest);
  int get manifestTotalUnits => _stagedManifest.values.fold(0, (sum, q) => sum + q);
  int get manifestVarietyCount => _stagedManifest.length;
  int getStagedQuantity(String productId) => _stagedManifest[productId] ?? 0;

  double get manifestTotalRevenue {
    double total = 0.0;
    for (final entry in _stagedManifest.entries) {
      try {
        final product = GameData.products.firstWhere((p) => p.id == entry.key);
        total += product.sellPrice * entry.value;
      } catch (_) {}
    }
    return total;
  }

  ProductionGameService({bool testMode = false}) {
    _isTestMode = testMode;
    _initializeGame();
  }

  /// Initialize the game by loading saved state and starting timers
  Future<void> _initializeGame() async {
    try {
      if (_isTestMode) {
        // In test mode, use default state and don't start timers
        // ignore: prefer_const_constructors
        _state = GameState(
          autoBuildMachinesOwned: <String, int>{},
          autoBuildEnabled: <String, bool>{},
          lastAutoBuildTick: <String, DateTime?>{},
          autoBuildProductCapacity: <String, int>{},
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

      // Ensure corporate contracts exist (Phase 2)
      _checkAndGenerateInitialContracts();

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

      // Ensure corporate contracts exist (Phase 2)
      _checkAndGenerateInitialContracts();

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
      _isDeveloperModeUnlocked = false;
      notifyListeners();
      return;
    }

    try {
      await _persistenceService.resetGameData();
      _isDeveloperModeUnlocked = false;
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

      final discount = _state.getMaterialDiscount(materialId);
      final effectivePrice = material.buyPrice * (1.0 - discount);
      final totalCost = effectivePrice * quantity;
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

      // Manual Build Lockout (Phase 10)
      if ((_state.autoBuildEnabled[product.levelId.name] ?? false) &&
          (_state.autoBuildMachinesOwned[product.levelId.name] ?? 0) > 0) {
        if (kDebugMode) {
          GameLogger.warning('Manual build locked: Auto-Build is active for tier ${product.levelId.name}');
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
        
        // Use microseconds to ensure unique IDs even when multiple items are produced in same millisecond
        final task = ProductionTask(
          id: '${DateTime.now().microsecondsSinceEpoch}_manual_$i',
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

      double updatedWear = _state.maintenanceWear;
      if (_state.isOverclockEngaged) {
        updatedWear = math.max(0.0, updatedWear - ResearchConstants.wearPerManualBuild);
      }

      _state = _state.copyWith(
        materials: newMaterials,
        products: newProducts,
        activeProductions: newProductions,
        maintenanceWear: updatedWear,
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

      // Check for carrier payload capacity and single-type limit (Phase 10)
      final fleet = GameData.getFleetTier(_state.fleetTier);
      if (quantity > fleet.maxUnitsPerType) {
        if (kDebugMode) {
          GameLogger.warning(
            'Sell quantity exceeds carrier per-type limit: $quantity > ${fleet.maxUnitsPerType} (${fleet.name})',
          );
        }
        return false;
      }

      if (quantity > fleet.maxPayloadUnits) {
        if (kDebugMode) {
          GameLogger.warning(
            'Sell quantity exceeds carrier payload capacity: $quantity > ${fleet.maxPayloadUnits} (${fleet.name})',
          );
        }
        return false;
      }

      // Check for active shipping order limit based on fleet tier (Phase 2)
      if (!_state.canShipMore(_state.activeShippingOrders.length)) {
        if (kDebugMode) {
          GameLogger.warning(
            'Logistics fleet at capacity: ${_state.activeShippingOrders.length} / ${_state.maxSimultaneousShipments}',
          );
        }
        return false;
      }

      // Calculate shipping time using the formula scaled by fleet speed multiplier
      final rawShippingTime = product.calculateShippingTime(quantity);

      double effectiveSpeedMultiplier =
          fleet.speedMultiplier * _state.logisticsSpeedMultiplier;
      final hasActiveContract =
          _state.corporateContracts.any((c) => c.status == ContractStatus.active || c.status == ContractStatus.shipping);
      if (hasActiveContract && _state.hasCorporateContractFastTrack) {
        effectiveSpeedMultiplier *= ResearchConstants.logisticsContractSpeedBonus;
      }

      final totalShippingTime =
          (rawShippingTime / effectiveSpeedMultiplier).clamp(1.0, 86400.0);

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

      // Remove products from inventory
      final newProducts = Map<String, int>.from(_state.products);
      newProducts[productId] = available - quantity;
      if (newProducts[productId]! <= 0) {
        newProducts.remove(productId);
      }

      // Create shipping order (use microseconds for unique ID)
      final shippingOrder = ShippingOrder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
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

  // =========================================================================
  // Phase 11: Staged Shipping Manifest Methods (Bulk Sell Cart)
  // =========================================================================

  /// Calculate shipping time for the staged manifest (Phase 11)
  /// Formula:
  /// Base Transit Time = max_{p in Manifest}(baseTime(p)) * (1 + 0.04 * (Total Units - 1))^0.5
  /// Actual Shipping Time = Base Transit Time / (Fleet Speed Multiplier * Tech Multipliers)
  double calculateManifestShippingTime() {
    if (_stagedManifest.isEmpty) return 0.0;

    double maxBaseTime = 0.0;
    int totalUnits = 0;

    for (final entry in _stagedManifest.entries) {
      try {
        final product = GameData.products.firstWhere((p) => p.id == entry.key);
        if (product.baseShippingTimeSeconds > maxBaseTime) {
          maxBaseTime = product.baseShippingTimeSeconds;
        }
        totalUnits += entry.value;
      } catch (_) {}
    }

    if (totalUnits <= 0) return 0.0;

    final baseTransitTime = maxBaseTime * math.sqrt(1.0 + 0.04 * (totalUnits - 1));

    final fleet = currentFleetTier;
    double effectiveSpeedMultiplier =
        fleet.speedMultiplier * _state.logisticsSpeedMultiplier;
    final hasActiveContract = _state.corporateContracts.any(
      (c) => c.status == ContractStatus.active || c.status == ContractStatus.shipping,
    );
    if (hasActiveContract && _state.hasCorporateContractFastTrack) {
      effectiveSpeedMultiplier *= ResearchConstants.logisticsContractSpeedBonus;
    }

    return (baseTransitTime / effectiveSpeedMultiplier).clamp(1.0, 86400.0);
  }

  /// Adds a quantity of product to the staged manifest.
  /// Hard guards against fleet caps (varieties, per-type, total payload) and available stock.
  bool addToManifest(String productId, int quantity) {
    if (quantity <= 0) return false;

    // Check product exists
    final product = GameData.getProduct(productId);
    if (product == null) return false;

    final currentStaged = _stagedManifest[productId] ?? 0;
    final availableInInventory = state.getProductCount(productId);
    if (currentStaged + quantity > availableInInventory) return false;

    final fleet = currentFleetTier;
    final isNewVariety = !_stagedManifest.containsKey(productId);

    // Variety cap check
    if (isNewVariety && _stagedManifest.length >= fleet.maxProductVarieties) {
      return false;
    }

    // Per-type cap check
    if (currentStaged + quantity > fleet.maxUnitsPerType) {
      return false;
    }

    // Total payload capacity check
    if (manifestTotalUnits + quantity > fleet.maxPayloadUnits) {
      return false;
    }

    _stagedManifest[productId] = currentStaged + quantity;
    notifyListeners();
    return true;
  }

  /// Removes a product from the staged manifest completely.
  void removeFromManifest(String productId) {
    if (_stagedManifest.containsKey(productId)) {
      _stagedManifest.remove(productId);
      notifyListeners();
    }
  }

  /// Updates quantity of a staged product. If newQuantity <= 0, removes the product.
  bool updateManifestQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromManifest(productId);
      return true;
    }

    final fleet = currentFleetTier;
    if (newQuantity > fleet.maxUnitsPerType) return false;

    final isNewVariety = !_stagedManifest.containsKey(productId);
    if (isNewVariety && _stagedManifest.length >= fleet.maxProductVarieties) {
      return false;
    }

    final currentStaged = _stagedManifest[productId] ?? 0;
    final newTotalPayload = manifestTotalUnits - currentStaged + newQuantity;
    if (newTotalPayload > fleet.maxPayloadUnits) return false;

    final available = state.getProductCount(productId);
    if (newQuantity > available) return false;

    _stagedManifest[productId] = newQuantity;
    notifyListeners();
    return true;
  }

  /// Sets the staged quantity for a product to the maximum possible within available stock and fleet caps.
  void setManifestMaxForProduct(String productId) {
    final available = state.getProductCount(productId);
    if (available <= 0) return;

    final fleet = currentFleetTier;
    final isNewVariety = !_stagedManifest.containsKey(productId);
    if (isNewVariety && _stagedManifest.length >= fleet.maxProductVarieties) {
      return;
    }

    final currentStaged = _stagedManifest[productId] ?? 0;
    final remainingPayload = fleet.maxPayloadUnits - (manifestTotalUnits - currentStaged);
    final maxPerType = fleet.maxUnitsPerType;

    final maxPossible = [available, maxPerType, remainingPayload].reduce(math.min);
    if (maxPossible > 0) {
      _stagedManifest[productId] = maxPossible;
      notifyListeners();
    }
  }

  /// Clears all staged items in the manifest.
  void clearManifest() {
    if (_stagedManifest.isNotEmpty) {
      _stagedManifest.clear();
      notifyListeners();
    }
  }

  /// Dispatches the consolidated shipping manifest as a single ShippingOrder taking 1 fleet slot.
  /// If inventory dropped prior to dispatch (e.g. from Auto-Sell), quantities are auto-clamped.
  bool dispatchManifest({void Function(String message)? onStockAdjusted}) {
    if (_stagedManifest.isEmpty) return false;

    if (!_state.canShipMore(_state.activeShippingOrders.length)) {
      if (kDebugMode) {
        GameLogger.warning(
          'Logistics fleet at capacity: ${_state.activeShippingOrders.length} / ${_state.maxSimultaneousShipments}',
        );
      }
      return false;
    }

    // Auto-clamp to current inventory stock
    final clampedManifest = <String, int>{};
    bool wasAdjusted = false;

    for (final entry in _stagedManifest.entries) {
      final available = _state.getProductCount(entry.key);
      if (available <= 0) {
        wasAdjusted = true;
        continue;
      }
      final clampedQty = math.min(entry.value, available);
      if (clampedQty < entry.value) {
        wasAdjusted = true;
      }
      clampedManifest[entry.key] = clampedQty;
    }

    if (clampedManifest.isEmpty) {
      _stagedManifest.clear();
      notifyListeners();
      if (wasAdjusted && onStockAdjusted != null) {
        onStockAdjusted('Manifest items are no longer available in inventory.');
      }
      return false;
    }

    double maxBaseTime = 0.0;
    int totalUnits = 0;
    double totalRevenue = 0.0;
    final shippingItems = <ShippingItem>[];
    final newProducts = Map<String, int>.from(_state.products);

    for (final entry in clampedManifest.entries) {
      final product = GameData.products.firstWhere((p) => p.id == entry.key);
      if (product.baseShippingTimeSeconds > maxBaseTime) {
        maxBaseTime = product.baseShippingTimeSeconds;
      }
      totalUnits += entry.value;
      totalRevenue += product.sellPrice * entry.value;
      shippingItems.add(ShippingItem(productId: entry.key, quantity: entry.value));

      final remaining = (newProducts[entry.key] ?? 0) - entry.value;
      if (remaining <= 0) {
        newProducts.remove(entry.key);
      } else {
        newProducts[entry.key] = remaining;
      }
    }

    final baseTransitTime = maxBaseTime * math.sqrt(1.0 + 0.04 * (totalUnits - 1));
    final fleet = currentFleetTier;
    double effectiveSpeedMultiplier =
        fleet.speedMultiplier * _state.logisticsSpeedMultiplier;
    final hasActiveContract = _state.corporateContracts.any(
      (c) => c.status == ContractStatus.active || c.status == ContractStatus.shipping,
    );
    if (hasActiveContract && _state.hasCorporateContractFastTrack) {
      effectiveSpeedMultiplier *= ResearchConstants.logisticsContractSpeedBonus;
    }

    final totalShippingTime =
        (baseTransitTime / effectiveSpeedMultiplier).clamp(1.0, 86400.0);

    final shippingOrder = ShippingOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      items: shippingItems,
      startTime: DateTime.now(),
      totalShippingTime: totalShippingTime,
      totalRevenue: totalRevenue,
    );

    final newShippingOrders = List<ShippingOrder>.from(_state.activeShippingOrders)
      ..add(shippingOrder);

    _state = _state.copyWith(
      products: newProducts,
      activeShippingOrders: newShippingOrders,
    );

    _stagedManifest.clear();

    _persistenceService.markDirty('products');
    _persistenceService.markDirty('shipping');

    notifyListeners();
    _saveGameStateOptimized();
    _startUpdateTimer();

    if (wasAdjusted && onStockAdjusted != null) {
      onStockAdjusted('Manifest quantities were adjusted to match available inventory.');
    }

    return true;
  }

  /// Helper for unit tests to directly set the manifest state
  @visibleForTesting
  void testSetManifest(Map<String, int> manifest) {
    _stagedManifest.clear();
    _stagedManifest.addAll(manifest);
    notifyListeners();
  }

  /// Main update method - coordinates all production and shipping updates
  /// This is the central orchestrator for all game progress updates
  void updateProductions() {
    try {
      // Check and process auto-buy tick (v1.5.0)
      _processAutoBuyTick();
      
      // Check and process auto-build ticks for all tiers (v1.5.0 Phase 2)
      _processAutoBuildTicks();

      // Check and process auto-sell tick (Phase 9B: Auto-Sell Dispatchers)
      _processAutoSellTick();

      // Check and process corporate contracts expiry and refills (Phase 2)
      _processContractsTick();
      
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

  /// Handle queued task logic - start if active tracks < maxParallel
  void _handleQueuedTask(
    ProductionTask task,
    List<ProductionTask> activeTasks,
  ) {
    // Determine max parallel for this product's tier
    int maxParallel = 1;
    final product = GameData.getProduct(task.productId);
    if (product != null) {
      final tier = product.levelId.name;
      final autoBuildEnabled = _state.autoBuildEnabled[tier] ?? false;
      final machinesOwned = _state.autoBuildMachinesOwned[tier] ?? 0;
      if (autoBuildEnabled && machinesOwned > 0) {
        maxParallel = getAutoBuildThroughputLevel(tier);
      }
    }

    // Count how many active tracks are running for this product
    final activeCount = activeTasks.where(
      (otherTask) =>
          otherTask.productId == task.productId && !otherTask.isQueued,
    ).length;

    if (activeCount < maxParallel) {
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

    // Build material prices map from game data (with client reputation discounts)
    final materialPrices = <String, double>{};
    for (final material in GameData.materials) {
      final discount = _state.getMaterialDiscount(material.id);
      materialPrices[material.id] = material.buyPrice * (1.0 - discount);
    }

    // Perform auto-buy tick using pooled-capacity model with money constraints
    final materialsCopy = Map<String, int>.from(_state.materials);
    final currentBuysPerTick = (AutoBuyConstants.buysPerMachinePerTick *
            getAutoBuyIntakeMultiplier(_state.autoBuyIntakeLevel))
        .floor();
    final result = machine_buyer.performAutoBuyTick(
      inventory: materialsCopy,
      currentMoney: _state.money,
      materialPrices: materialPrices,
      machinesEnabled: _state.autoBuyMachinesOwned,
      buysPerMachinePerTick: currentBuysPerTick,
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
      
      final throughputLevel = getAutoBuildThroughputLevel(tier);
      final result = machine_builder.performAutoBuildTick(
        productInventory: productsCopy,
        materialInventory: materialsCopy,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: queuedProductCounts,
        machinesEnabled: machineCount,
        buildsPerMachinePerTick: throughputLevel,
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
            // Queue individual items across parallel tracks based on throughput
            int maxParallel = getAutoBuildThroughputLevel(tier);
            
            for (int i = 0; i < builtCount; i++) {
              final productTasks = newProductions.where((t) => t.productId == productId).toList();
              productTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
              
              final endTimes = productTasks.map((t) => t.startTime.add(Duration(seconds: t.durationSeconds.round()))).toList();
              endTimes.sort((a, b) => b.compareTo(a)); // Descending order (latest first)
              
              DateTime startTime = DateTime.now();
              bool shouldQueue = false;
              
              if (endTimes.length >= maxParallel) {
                shouldQueue = true;
                startTime = endTimes[maxParallel - 1];
                if (startTime.isBefore(DateTime.now())) {
                  startTime = DateTime.now();
                  shouldQueue = false;
                }
              }
              
              final adjustedTime = getAdjustedProductionTime(
                productId,
                product.productionTimeSeconds,
              );
              
              final task = ProductionTask(
                id: '${DateTime.now().microsecondsSinceEpoch}_autobuild_${tier}_$i',
                productId: productId,
                startTime: startTime,
                durationSeconds: adjustedTime,
                quantity: 1, // Single unit for UI visibility
                isQueued: shouldQueue,
              );
              
              newProductions.add(task);
              
              if (kDebugMode && i == 0 && (product.productionTimeSeconds - adjustedTime).abs() > 0.01) {
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
        
        double updatedWear = _state.maintenanceWear;
        if (_state.isOverclockEngaged) {
          updatedWear = math.max(
            0.0,
            updatedWear - ResearchConstants.wearPerAutoBuildTick,
          );
        }

        _state = _state.copyWith(
          materials: updatedMaterials,
          products: updatedProducts,
          activeProductions: newProductions,
          lastAutoBuildTick: newLastTicks,
          maintenanceWear: updatedWear,
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

  DateTime? _lastAutoSellTick;

  /// Records an automated sales dispatch or contract fulfillment in the recent activity log (Phase 14)
  void _recordAutoSellDispatch({
    required AutoSellActionType actionType,
    required String title,
    required Map<String, int> items,
    required double totalRevenue,
    String? clientOrBatchName,
  }) {
    final entry = AutoSellLogEntry(
      id: 'sell_log_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      actionType: actionType,
      title: title,
      items: Map<String, int>.from(items),
      totalRevenue: totalRevenue,
      clientOrBatchName: clientOrBatchName,
    );
    final updatedLog = [entry, ..._state.autoSellRecentLog];
    if (updatedLog.length > 10) {
      updatedLog.removeRange(10, updatedLog.length);
    }
    _state = _state.copyWith(autoSellRecentLog: updatedLog);
    _persistenceService.markDirty('auto_sell_log');
    _saveGameStateOptimized();
  }

  /// Process auto-sell tick if enabled and interval has elapsed (Phase 12: Sales Hub Selling Automation)
  /// Dispatches real logistics shipments taking 1 fleet slot, respecting whitelist, reserve, and carrier limits.
  void _processAutoSellTick({bool force = false}) {
    // Skip if not enabled or no machines owned
    if (!_state.autoSellEnabled || _state.autoSellMachinesOwned <= 0) {
      return;
    }

    final now = DateTime.now();
    if (!force && _lastAutoSellTick != null) {
      final elapsed = now.difference(_lastAutoSellTick!).inSeconds;
      if (elapsed < 5) {
        return; // 5-second tick interval matching auto-buy and auto-build
      }
    }

    // Check fleet slot capacity
    if (!_state.canShipMore(_state.activeShippingOrders.length)) {
      return;
    }

    // 1. Prioritize B2B Corporate Contract fulfillment if enabled (bypasses min reserve)
    if (_state.autoSellFulfillContracts) {
      for (final contract in _state.corporateContracts) {
        if (contract.status != ContractStatus.available || contract.isExpired) {
          continue;
        }
        if (contract.canFulfill(_state.products)) {
          final shipped = shipContract(contract.id);
          if (shipped) {
            _lastAutoSellTick = now;
            _recordAutoSellDispatch(
              actionType: AutoSellActionType.b2bContract,
              title: contract.title,
              items: contract.requiredProducts,
              totalRevenue: contract.cashReward,
              clientOrBatchName: contract.title,
            );
            if (kDebugMode) {
              GameLogger.info(
                'Auto-sell tick: fulfilled contract ${contract.title}',
              );
            }
            return;
          }
        }
      }
    }

    // 2. Dispatch Storefront Batch if enabled (strictly respects autoSellMinReserve)
    if (_state.autoSellBatchDispatch) {
      final fleet = currentFleetTier;
      int maxBatchUnits = math.min(
        _state.autoSellMachinesOwned * _state.autoSellThroughputLevel,
        fleet.maxPayloadUnits,
      );

      final eligibleProductIds = _state.autoSellWhitelistedProductIds
          .where((id) => ((_state.products[id] ?? 0) - _state.autoSellMinReserve) > 0)
          .toList();

      if (eligibleProductIds.isEmpty) {
        return;
      }

      const tierOrder = [
        ProductLevel.basicParts,
        ProductLevel.intermediate,
        ProductLevel.complex,
        ProductLevel.retail,
      ];
      final batch = <String, int>{};
      for (final tier in tierOrder) {
        if (maxBatchUnits <= 0) break;
        final tierProds = GameData.products.where((p) => p.levelId == tier);
        for (final prod in tierProds) {
          if (maxBatchUnits <= 0) break;
          if (!_state.autoSellWhitelistedProductIds.contains(prod.id)) continue;
          final stock = _state.products[prod.id] ?? 0;
          final available = math.max(0, stock - _state.autoSellMinReserve);
          if (available <= 0) continue;
          if (batch.length >= fleet.maxProductVarieties &&
              !batch.containsKey(prod.id)) {
            continue;
          }
          final take = math.min(
            available,
            math.min(maxBatchUnits, fleet.maxUnitsPerType),
          );
          if (take > 0) {
            batch[prod.id] = take;
            maxBatchUnits -= take;
          }
        }
      }

      if (maxBatchUnits > 0) {
        for (final id in _state.autoSellWhitelistedProductIds) {
          if (maxBatchUnits <= 0) break;
          if (batch.containsKey(id)) continue;
          final stock = _state.products[id] ?? 0;
          final available = math.max(0, stock - _state.autoSellMinReserve);
          if (available <= 0) continue;
          if (batch.length >= fleet.maxProductVarieties) continue;
          final take = math.min(
            available,
            math.min(maxBatchUnits, fleet.maxUnitsPerType),
          );
          if (take > 0) {
            batch[id] = take;
            maxBatchUnits -= take;
          }
        }
      }

      if (batch.isEmpty) {
        return;
      }

      double maxBaseTime = 0.0;
      int totalUnits = 0;
      double totalRevenue = 0.0;
      final shippingItems = <ShippingItem>[];
      final newProducts = Map<String, int>.from(_state.products);

      for (final entry in batch.entries) {
        final product = GameData.products.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => GameData.products.first,
        );
        if (product.baseShippingTimeSeconds > maxBaseTime) {
          maxBaseTime = product.baseShippingTimeSeconds;
        }
        totalUnits += entry.value;
        totalRevenue += product.sellPrice * entry.value;
        shippingItems.add(
          ShippingItem(productId: entry.key, quantity: entry.value),
        );

        final remaining = (newProducts[entry.key] ?? 0) - entry.value;
        if (remaining <= 0) {
          newProducts.remove(entry.key);
        } else {
          newProducts[entry.key] = remaining;
        }
      }

      final baseTransitTime =
          maxBaseTime * math.sqrt(1.0 + 0.04 * (totalUnits - 1));
      double effectiveSpeedMultiplier =
          fleet.speedMultiplier * _state.logisticsSpeedMultiplier;
      final hasActiveContract = _state.corporateContracts.any(
        (c) =>
            c.status == ContractStatus.active ||
            c.status == ContractStatus.shipping,
      );
      if (hasActiveContract && _state.hasCorporateContractFastTrack) {
        effectiveSpeedMultiplier *=
            ResearchConstants.logisticsContractSpeedBonus;
      }

      final totalShippingTime =
          (baseTransitTime / effectiveSpeedMultiplier).clamp(1.0, 86400.0);

      final orderId = DateTime.now().microsecondsSinceEpoch.toString();
      final shippingOrder = ShippingOrder(
        id: orderId,
        items: shippingItems,
        startTime: DateTime.now(),
        totalShippingTime: totalShippingTime,
        totalRevenue: totalRevenue,
      );

      final newShippingOrders =
          List<ShippingOrder>.from(_state.activeShippingOrders)..add(shippingOrder);

      // Prepend to autoSellRecentLog capped at 10
      final logEntry = AutoSellLogEntry(
        id: 'dispatch_$orderId',
        timestamp: now,
        actionType: AutoSellActionType.batchDispatch,
        title: 'Storefront Batch #$orderId',
        items: batch,
        totalRevenue: totalRevenue,
        clientOrBatchName: 'Storefront',
      );
      final updatedLog = [logEntry, ..._state.autoSellRecentLog];
      if (updatedLog.length > 10) {
        updatedLog.removeRange(10, updatedLog.length);
      }

      _state = _state.copyWith(
        products: newProducts,
        activeShippingOrders: newShippingOrders,
        autoSellRecentLog: updatedLog,
      );

      _persistenceService.markDirty('products');
      _persistenceService.markDirty('shipping');
      _persistenceService.markDirty('auto_sell_log');
      notifyListeners();
      _saveGameStateOptimized();
      _startUpdateTimer();
      _lastAutoSellTick = now;

      if (kDebugMode) {
        GameLogger.info(
          'Auto-sell tick: dispatched batch $orderId with $totalUnits units for \$${totalRevenue.toStringAsFixed(2)} taking 1 fleet slot',
        );
      }
    }
  }

  /// Generates real-time information for the UI on the next action selling automation will take
  AutoSellNextAction getAutoSellNextAction() {
    if (!_state.autoSellEnabled || _state.autoSellMachinesOwned <= 0) {
      return AutoSellNextAction(
        actionType: AutoSellActionType.idleDisabled,
        title: 'Selling Automation Paused',
        subtitle: _state.autoSellMachinesOwned <= 0
            ? 'Purchase auto-sell dispatchers in Machines tab'
            : 'Master power switch is turned off',
        stagedItems: const {},
        estimatedRevenue: 0.0,
        estimatedTransitSeconds: 0.0,
        isReady: false,
      );
    }

    if (!_state.canShipMore(_state.activeShippingOrders.length)) {
      return AutoSellNextAction(
        actionType: AutoSellActionType.waitingFleet,
        title: 'Couriers In Transit',
        subtitle:
            'Waiting for available fleet slot (${_state.activeShippingOrders.length}/${_state.maxSimultaneousShipments})',
        stagedItems: const {},
        estimatedRevenue: 0.0,
        estimatedTransitSeconds: 0.0,
        isReady: false,
      );
    }

    // Check B2B corporate contracts if enabled (bypasses min reserve)
    if (_state.autoSellFulfillContracts) {
      for (final contract in _state.corporateContracts) {
        if (contract.status == ContractStatus.available &&
            !contract.isExpired &&
            contract.canFulfill(_state.products)) {
          final transitSeconds = _calculateContractShippingTime(contract);
          return AutoSellNextAction(
            actionType: AutoSellActionType.b2bContract,
            title: 'Fulfill B2B Contract',
            subtitle: 'Priority corporate fulfillment: ${contract.title}',
            stagedItems: Map<String, int>.from(contract.requiredProducts),
            estimatedRevenue: contract.cashReward,
            estimatedTransitSeconds: transitSeconds,
            isReady: true,
            clientOrBatchName: contract.title,
          );
        }
      }
    }

    // Check Storefront batch dispatch if enabled (strictly respects autoSellMinReserve)
    if (_state.autoSellBatchDispatch) {
      final fleet = currentFleetTier;
      int maxBatchUnits = math.min(
        _state.autoSellMachinesOwned * _state.autoSellThroughputLevel,
        fleet.maxPayloadUnits,
      );

      final eligibleProductIds = _state.autoSellWhitelistedProductIds
          .where((id) => ((_state.products[id] ?? 0) - _state.autoSellMinReserve) > 0)
          .toList();

      if (eligibleProductIds.isEmpty) {
        return AutoSellNextAction(
          actionType: AutoSellActionType.waitingStock,
          title: 'Waiting for Inventory',
          subtitle: _state.autoSellWhitelistedProductIds.isEmpty
              ? 'No products selected in whitelist'
              : _state.autoSellMinReserve > 0
                  ? 'All whitelisted stock at or below reserve (${_state.autoSellMinReserve})'
                  : 'No whitelisted products currently in stock',
          stagedItems: const {},
          estimatedRevenue: 0.0,
          estimatedTransitSeconds: 0.0,
          isReady: false,
        );
      }

      const tierOrder = [
        ProductLevel.basicParts,
        ProductLevel.intermediate,
        ProductLevel.complex,
        ProductLevel.retail,
      ];
      final batch = <String, int>{};
      for (final tier in tierOrder) {
        if (maxBatchUnits <= 0) break;
        final tierProds = GameData.products.where((p) => p.levelId == tier);
        for (final prod in tierProds) {
          if (maxBatchUnits <= 0) break;
          if (!_state.autoSellWhitelistedProductIds.contains(prod.id)) continue;
          final stock = _state.products[prod.id] ?? 0;
          final available = math.max(0, stock - _state.autoSellMinReserve);
          if (available <= 0) continue;
          if (batch.length >= fleet.maxProductVarieties &&
              !batch.containsKey(prod.id)) {
            continue;
          }
          final take = math.min(
            available,
            math.min(maxBatchUnits, fleet.maxUnitsPerType),
          );
          if (take > 0) {
            batch[prod.id] = take;
            maxBatchUnits -= take;
          }
        }
      }

      if (maxBatchUnits > 0) {
        for (final id in _state.autoSellWhitelistedProductIds) {
          if (maxBatchUnits <= 0) break;
          if (batch.containsKey(id)) continue;
          final stock = _state.products[id] ?? 0;
          final available = math.max(0, stock - _state.autoSellMinReserve);
          if (available <= 0) continue;
          if (batch.length >= fleet.maxProductVarieties) continue;
          final take = math.min(
            available,
            math.min(maxBatchUnits, fleet.maxUnitsPerType),
          );
          if (take > 0) {
            batch[id] = take;
            maxBatchUnits -= take;
          }
        }
      }

      if (batch.isEmpty) {
        return const AutoSellNextAction(
          actionType: AutoSellActionType.waitingStock,
          title: 'Waiting for Inventory',
          subtitle: 'Available inventory exceeds carrier constraints',
          stagedItems: {},
          estimatedRevenue: 0.0,
          estimatedTransitSeconds: 0.0,
          isReady: false,
        );
      }

      double maxBaseTime = 0.0;
      int totalUnits = 0;
      double totalRevenue = 0.0;

      for (final entry in batch.entries) {
        final product = GameData.products.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => GameData.products.first,
        );
        if (product.baseShippingTimeSeconds > maxBaseTime) {
          maxBaseTime = product.baseShippingTimeSeconds;
        }
        totalUnits += entry.value;
        totalRevenue += product.sellPrice * entry.value;
      }

      final baseTransitTime =
          maxBaseTime * math.sqrt(1.0 + 0.04 * (totalUnits - 1));
      double effectiveSpeedMultiplier =
          fleet.speedMultiplier * _state.logisticsSpeedMultiplier;
      final hasActiveContract = _state.corporateContracts.any(
        (c) =>
            c.status == ContractStatus.active ||
            c.status == ContractStatus.shipping,
      );
      if (hasActiveContract && _state.hasCorporateContractFastTrack) {
        effectiveSpeedMultiplier *=
            ResearchConstants.logisticsContractSpeedBonus;
      }
      final totalShippingTime =
          (baseTransitTime / effectiveSpeedMultiplier).clamp(1.0, 86400.0);

      return AutoSellNextAction(
        actionType: AutoSellActionType.batchDispatch,
        title: 'Storefront Batch Dispatch',
        subtitle:
            'Assembling $totalUnits units (${batch.length} ${batch.length == 1 ? "type" : "types"}) for courier dispatch',
        stagedItems: batch,
        estimatedRevenue: totalRevenue,
        estimatedTransitSeconds: totalShippingTime,
        isReady: true,
        clientOrBatchName: 'Storefront Courier Batch',
      );
    }

    return const AutoSellNextAction(
      actionType: AutoSellActionType.waitingStock,
      title: 'Waiting for Inventory',
      subtitle: 'No dispatch modes currently enabled',
      stagedItems: {},
      estimatedRevenue: 0.0,
      estimatedTransitSeconds: 0.0,
      isReady: false,
    );
  }

  /// Trigger auto-sell tick directly for testing (Phase 9B)
  @visibleForTesting
  void processAutoSellTickForTest({bool force = true}) {
    _processAutoSellTick(force: force);
  }

  /// Phase 9A test helpers
  @visibleForTesting
  void setAutoShipRetail(bool value) {
    _state = _state.copyWith(autoShipRetail: value);
  }

  @visibleForTesting
  void setAutoShipManufacturing(bool value) {
    _state = _state.copyWith(autoShipManufacturing: value);
  }

  @visibleForTesting
  void addContractForTest(CorporateContract contract) {
    final list = List<CorporateContract>.from(_state.corporateContracts)..add(contract);
    _state = _state.copyWith(corporateContracts: list);
  }

  @visibleForTesting
  void testSetState(GameState state) {
    _state = state;
    notifyListeners();
  }

  @visibleForTesting
  void addDummyShippingOrderForTest() {
    final order = ShippingOrder(
      id: 'dummy_${DateTime.now().microsecondsSinceEpoch}',
      items: const [ShippingItem(productId: 'box', quantity: 1)],
      startTime: DateTime.now(),
      totalShippingTime: 60.0,
      totalRevenue: 10.0,
    );
    final orders = List<ShippingOrder>.from(_state.activeShippingOrders)..add(order);
    _state = _state.copyWith(activeShippingOrders: orders);
  }

  @visibleForTesting
  double calculateContractShippingTimeForTest(CorporateContract contract) {
    return _calculateContractShippingTime(contract);
  }

  @visibleForTesting
  void processContractsTickForTest() {
    _processContractsTick();
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
    final dupChance = _state.materialScienceDuplicationChance;
    final random = math.Random();

    for (final task in completedTasks) {
      try {
        final currentCount = newProducts[task.productId] ?? 0;
        const maxProducts = LimitsConstants.maxProducts;

        int bonusUnits = 0;
        if (dupChance > 0.0) {
          for (int q = 0; q < task.quantity; q++) {
            if (random.nextDouble() < dupChance) {
              bonusUnits++;
            }
          }
          if (bonusUnits > 0 && kDebugMode) {
            GameLogger.info(
              '🧬 Material Science duplicated $bonusUnits bonus unit(s) of ${task.productId}!',
            );
          }
        }
        final totalToAdd = task.quantity + bonusUnits;

        // Prevent overflow
        if (currentCount > maxProducts - totalToAdd) {
          if (kDebugMode) {
            GameLogger.warning(
              'Product overflow prevented: ${task.productId}, current: $currentCount, adding: $totalToAdd',
            );
          }
          // Add what we can without overflow
          newProducts[task.productId] = maxProducts;
        } else {
          newProducts[task.productId] = currentCount + totalToAdd;
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
  /// Phase 9A: Also handles B2B contract completion when linked shipping order finishes
  _MoneyAndHistory _processCompletedShipping(
    List<ShippingOrder> completedShipping,
  ) {
    double newMoney = _state.money;
    final newHistory = List<ShippingHistory>.from(_state.shippingHistory);
    final updatedContracts = List<CorporateContract>.from(_state.corporateContracts);
    final newReputation = Map<String, int>.from(_state.clientReputation);
    bool contractsChanged = false;

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

        // Phase 9A: If this is a B2B contract shipment, complete the contract
        if (order.contractId != null) {
          final contractIndex = updatedContracts
              .indexWhere((c) => c.id == order.contractId);
          if (contractIndex != -1) {
            final contract = updatedContracts[contractIndex];
            // Award reputation
            final currentRep = newReputation[contract.clientId] ?? 0;
            newReputation[contract.clientId] = currentRep + contract.repReward;
            // Update contract to completed
            updatedContracts[contractIndex] = contract.copyWith(
              status: ContractStatus.completed,
            );
            contractsChanged = true;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          GameLogger.error('Error completing shipping order ${order.id}', e);
        }
      }
    }

    // Update contracts and reputation if any B2B shipments completed
    if (contractsChanged) {
      _state = _state.copyWith(
        corporateContracts: updatedContracts,
        clientReputation: newReputation,
      );
      _persistenceService.markDirty('contracts');
      _persistenceService.markDirty('reputation');
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
        GameLogger.error('Error checking unlocks', e);
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

  /// Calculate adjusted production time incorporating Factory Overclocking (Phase 4)
  /// and Prestige Golden Shares speed multiplier (Phase 5).
  double getAdjustedProductionTime(String productId, double baseTime) {
    final speedMultiplier =
        _state.overclockSpeedMultiplier * _state.prestigeSpeedMultiplier;
    if (speedMultiplier <= 0) return baseTime;
    return (baseTime / speedMultiplier).clamp(0.1, 86400.0);
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

  // Static cached unmodifiable map of products by tier for UI display
  static final Map<ProductLevel, List<Product>> _productsByTierCache = Map.unmodifiable({
    ProductLevel.basicParts: GameData.getBasicPartsProducts(),
    ProductLevel.intermediate: GameData.getIntermediateProducts(),
    ProductLevel.complex: GameData.getComplexProducts(),
    ProductLevel.retail: GameData.getRetailProducts(),
  });

  // Get products organized by tiers for UI display (cached)
  Map<ProductLevel, List<Product>> get productsByTier => _productsByTierCache;

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

  // V1.4.11 Sell Quantity Preference Management (Phase 10: auto-clamped to carrier limit)
  int getSellQuantityPreference(String productId) {
    final maxAllowed = currentFleetTier.maxUnitsPerType;
    final savedPref = _state.sellQuantityPreferences[productId] ?? 1;
    return savedPref.clamp(1, maxAllowed);
  }

  void setSellQuantityPreference(String productId, int quantity) {
    final maxAllowed = currentFleetTier.maxUnitsPerType;
    if (quantity <= 0 || quantity > maxAllowed) {
      return;
    }
    // Allow 1, 5, or the tier's maximum per-type capacity
    if (quantity != 1 && quantity != 5 && quantity != maxAllowed) {
      return;
    }

    final newPreferences = Map<String, int>.from(
      _state.sellQuantityPreferences,
    );
    newPreferences[productId] = quantity;

    _state = _state.copyWith(sellQuantityPreferences: newPreferences);
    notifyListeners();
    _saveGameStateOptimized();
  }

  // V1.5.0 Auto-Buy Machine Management
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

  // =========================================================================
  // Phase 7: Machine Economy (Dynamic Pricing, Tier Limits, Salvage)
  // =========================================================================

  /// Calculate dynamic machine price: 1000 * 1.15^currentCount
  double getMachinePrice(String category, int currentCount) {
    return 1000 * math.pow(1.15, currentCount).toDouble();
  }

  /// Calculate machine salvage value: 50% of the price of the (currentCount - 1)-th machine, floored.
  /// If currentCount is 0, returns 0.
  double getMachineSalvageValue(String category, int currentCount) {
    if (currentCount <= 0) return 0.0;
    return (0.50 * getMachinePrice(category, currentCount - 1)).floorToDouble();
  }

  /// Get maximum machines allowed for a category based on current factory tier limit
  int getMachineTierLimit(String category) {
    return currentFactoryTier.machineLimit;
  }

  /// Get maximum throughput upgrade level allowed based on current factory tier limit.
  /// Scales with factory tier: Tier 1 -> 5, Tier 2 -> 10, Tier 3 -> 15, Tier 4 -> 20.
  int getMachineThroughputLimit([String? category]) {
    return currentFactoryTier.throughputLimit;
  }

  /// Salvage a machine in the given category ('autoBuy' or auto-build tier like 'basicParts')
  /// Decreases count by 1 and refunds salvage value.
  Future<bool> salvageMachine(String category) async {
    final int currentCount;
    if (category == 'autoBuy') {
      currentCount = _state.autoBuyMachinesOwned;
    } else if (category == 'autoSell') {
      currentCount = _state.autoSellMachinesOwned;
    } else {
      currentCount = _state.autoBuildMachinesOwned[category] ?? 0;
    }

    if (currentCount <= 0) {
      return false;
    }

    final salvageValue = getMachineSalvageValue(category, currentCount);
    final newMoney = _state.money + salvageValue;

    if (category == 'autoBuy') {
      _state = _state.copyWith(
        money: newMoney,
        autoBuyMachinesOwned: currentCount - 1,
      );
    } else if (category == 'autoSell') {
      _state = _state.copyWith(
        money: newMoney,
        autoSellMachinesOwned: currentCount - 1,
      );
    } else {
      final newMachines = Map<String, int>.from(_state.autoBuildMachinesOwned);
      newMachines[category] = currentCount - 1;
      _state = _state.copyWith(
        money: newMoney,
        autoBuildMachinesOwned: newMachines,
      );
    }

    notifyListeners();
    _persistenceService.markDirty('automation');
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Machine salvaged for $category! Refunded: \$${salvageValue.toStringAsFixed(2)}, Money remaining: \$${newMoney.toStringAsFixed(2)}',
      );
    }

    return true;
  }

  // =========================================================================
  // Phase 8: High-Throughput Automation (Intake & Throughput Upgrades)
  // =========================================================================

  /// Get current auto-buy intake level (default 1)
  int getAutoBuyIntakeLevel() => _state.autoBuyIntakeLevel;

  /// Calculate auto-buy intake multiplier based on level: 1.0 + (level - 1) * 0.25
  double getAutoBuyIntakeMultiplier(int level) =>
      1.0 + (math.max(1, level) - 1) * 0.25;

  /// Calculate upgrade cost for auto-buy intake: 1000 * 1.15^(level - 1)
  double getAutoBuyIntakeUpgradeCost() =>
      1000.0 * math.pow(1.15, _state.autoBuyIntakeLevel - 1).toDouble();

  /// Upgrade auto-buy intake level
  /// Checks money, deducts cost, increments autoBuyIntakeLevel, notifies listeners, and saves state.
  Future<bool> upgradeAutoBuyIntake() async {
    if (getAutoBuyIntakeLevel() >= getMachineThroughputLimit('autoBuy')) return false;
    
    final cost = getAutoBuyIntakeUpgradeCost();
    if (_state.money < cost) {
      return false;
    }

    final newMoney = _state.money - cost;
    final newLevel = _state.autoBuyIntakeLevel + 1;

    _state = _state.copyWith(
      money: newMoney,
      autoBuyIntakeLevel: newLevel,
    );

    notifyListeners();
    _persistenceService.markDirty('automation');
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-buy intake upgraded to Level $newLevel! Money remaining: \$${newMoney.toStringAsFixed(2)}',
      );
    }

    return true;
  }

  /// Get current auto-build throughput level for a given tier (default 1)
  int getAutoBuildThroughputLevel(String tier) =>
      _state.autoBuildThroughputLevel[tier] ?? 1;

  /// Calculate upgrade cost for auto-build throughput for a tier: 1000 * 1.15^(level - 1)
  double getAutoBuildThroughputUpgradeCost(String tier) {
    final level = getAutoBuildThroughputLevel(tier);
    return 1000.0 * math.pow(1.15, level - 1).toDouble();
  }

  void _recalculateQueueStartTimes(String tier) {
    final now = DateTime.now();
    final newProductions = List<ProductionTask>.from(_state.activeProductions);
    bool changed = false;

    final tierProducts = GameData.products.where((p) => p.levelId.name == tier).map((p) => p.id).toSet();
    
    final autoBuildEnabled = _state.autoBuildEnabled[tier] ?? false;
    final machinesOwned = _state.autoBuildMachinesOwned[tier] ?? 0;
    int maxParallel = 1;
    if (autoBuildEnabled && machinesOwned > 0) {
      maxParallel = getAutoBuildThroughputLevel(tier);
    }

    for (final productId in tierProducts) {
      final productTasks = newProductions.where((t) => t.productId == productId).toList();
      if (productTasks.isEmpty) continue;
      
      productTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
      
      final endTimes = <DateTime>[];
      
      for (int i = 0; i < productTasks.length; i++) {
        final task = productTasks[i];
        
        DateTime newStartTime;
        if (endTimes.length < maxParallel) {
          newStartTime = task.startTime.isBefore(now) ? task.startTime : now;
        } else {
          endTimes.sort(); 
          newStartTime = endTimes[0];
          if (newStartTime.isBefore(now)) {
            newStartTime = now;
          }
        }
        
        final newEndTime = newStartTime.add(Duration(seconds: task.durationSeconds.round()));
        
        if (newStartTime != task.startTime) {
          final updatedTask = ProductionTask(
            id: task.id,
            productId: task.productId,
            startTime: newStartTime,
            durationSeconds: task.durationSeconds,
            quantity: task.quantity,
            isQueued: newStartTime.isAfter(now),
          );
          
          final index = newProductions.indexWhere((t) => t.id == task.id);
          newProductions[index] = updatedTask;
          changed = true;
        }
        
        if (endTimes.length < maxParallel) {
          endTimes.add(newEndTime);
        } else {
          endTimes.sort();
          endTimes[0] = newEndTime;
        }
      }
    }

    if (changed) {
      _state = _state.copyWith(activeProductions: newProductions);
      _persistenceService.markDirty('productions');
    }
  }

  /// Upgrade auto-build throughput level for a tier
  /// Checks money, deducts cost, increments autoBuildThroughputLevel[tier], notifies listeners, and saves state.
  Future<bool> upgradeAutoBuildThroughput(String tier) async {
    // Cap throughput upgrade to current Factory Tier limit (Tier 1: 5, Tier 2: 10, Tier 3: 15, Tier 4: 20)
    if (getAutoBuildThroughputLevel(tier) >= getMachineThroughputLimit(tier)) return false;

    final cost = getAutoBuildThroughputUpgradeCost(tier);
    if (_state.money < cost) {
      return false;
    }

    final newMoney = _state.money - cost;
    final currentLevel = getAutoBuildThroughputLevel(tier);
    final newThroughputMap =
        Map<String, int>.from(_state.autoBuildThroughputLevel);
    newThroughputMap[tier] = currentLevel + 1;

    _state = _state.copyWith(
      money: newMoney,
      autoBuildThroughputLevel: newThroughputMap,
    );

    _recalculateQueueStartTimes(tier);

    notifyListeners();
    _persistenceService.markDirty('automation');
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-build throughput for $tier upgraded to Level ${newThroughputMap[tier]}! Money remaining: \$${newMoney.toStringAsFixed(2)}',
      );
    }

    return true;
  }

  // =========================================================================
  // Phase 9B: Auto-Sell Dispatchers (Storefront Automation)
  // =========================================================================

  /// Toggle auto-sell on/off (Phase 9B: Auto-Sell Dispatchers)
  void toggleAutoSell() {
    _state = _state.copyWith(autoSellEnabled: !_state.autoSellEnabled);
    notifyListeners();
    _persistenceService.markDirty('game_state');
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-sell toggled: ${_state.autoSellEnabled ? "ON" : "OFF"}',
      );
    }
  }

  /// Buy one auto-sell machine with dynamic pricing and tier limits
  /// Returns true if purchase was successful, false if limit reached or not enough money
  Future<bool> buyAutoSellMachine() async {
    final currentCount = _state.autoSellMachinesOwned;
    if (currentCount >= getMachineTierLimit('autoSell')) {
      return false; // Reached factory tier limit
    }

    final price = getMachinePrice('autoSell', currentCount);
    if (_state.money < price) {
      return false; // Not enough money
    }

    final newMoney = _state.money - price;
    final newCount = currentCount + 1;

    _state = _state.copyWith(
      money: newMoney,
      autoSellMachinesOwned: newCount,
    );
    notifyListeners();

    _persistenceService.markDirty('game_state');
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-sell machine purchased! Count: $newCount, Money remaining: \$${newMoney.toStringAsFixed(2)}',
      );
    }

    return true;
  }

  /// Get current auto-sell throughput level (default 1)
  int getAutoSellThroughputLevel() => _state.autoSellThroughputLevel;

  /// Calculate upgrade cost for auto-sell throughput: 1000 * 1.15^(level - 1)
  double getAutoSellThroughputUpgradeCost() =>
      1000.0 * math.pow(1.15, _state.autoSellThroughputLevel - 1).toDouble();

  /// Upgrade auto-sell throughput level
  /// Checks money, deducts cost, increments autoSellThroughputLevel, notifies listeners, and saves state.
  Future<bool> upgradeAutoSellThroughput() async {
    if (getAutoSellThroughputLevel() >= getMachineThroughputLimit('autoSell')) return false;
    
    final cost = getAutoSellThroughputUpgradeCost();
    if (_state.money < cost) {
      return false;
    }

    final newMoney = _state.money - cost;
    final newLevel = _state.autoSellThroughputLevel + 1;

    _state = _state.copyWith(
      money: newMoney,
      autoSellThroughputLevel: newLevel,
    );

    notifyListeners();
    _persistenceService.markDirty('game_state');
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-sell throughput upgraded to Level $newLevel! Money remaining: \$${newMoney.toStringAsFixed(2)}',
      );
    }

    return true;
  }

  /// Set auto-sell throughput level directly (for testing/dev)
  void setAutoSellThroughputLevel(int level) {
    _state = _state.copyWith(autoSellThroughputLevel: level);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Set auto-sell machine count directly (for testing/dev)
  void setAutoSellMachineCount(int count) {
    _state = _state.copyWith(autoSellMachinesOwned: count);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Set auto-sell enabled directly (for testing/dev)
  void setAutoSellEnabled(bool enabled) {
    _state = _state.copyWith(autoSellEnabled: enabled);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Reset auto-sell tick timer (for testing/dev)
  void resetAutoSellTickTimer() {
    _lastAutoSellTick = null;
  }

  // =========================================================================
  // Selling Automation Setup & Whitelist API (Phase 12)
  // =========================================================================

  /// Toggle product auto-sell whitelist inclusion
  void toggleProductAutoSellWhitelist(String productId) {
    final set = Set<String>.from(_state.autoSellWhitelistedProductIds);
    if (set.contains(productId)) {
      set.remove(productId);
    } else {
      set.add(productId);
    }
    _state = _state.copyWith(autoSellWhitelistedProductIds: set);
    _persistenceService.markDirty('auto_sell_whitelist');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Explicitly set product auto-sell whitelist permission
  void setProductAutoSellWhitelist(String productId, bool allowed) {
    final set = Set<String>.from(_state.autoSellWhitelistedProductIds);
    if (allowed) {
      set.add(productId);
    } else {
      set.remove(productId);
    }
    _state = _state.copyWith(autoSellWhitelistedProductIds: set);
    _persistenceService.markDirty('auto_sell_whitelist');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Whitelist all products (or clear whitelist)
  void setAllProductsAutoSellWhitelist(bool allowAll) {
    final Set<String> newSet =
        allowAll ? GameData.products.map((p) => p.id).toSet() : const {};
    _state = _state.copyWith(autoSellWhitelistedProductIds: newSet);
    _persistenceService.markDirty('auto_sell_whitelist');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Whitelist or unwhitelist all products in a specific tier
  void setTierAutoSellWhitelist(ProductLevel tier, bool allowed) {
    final set = Set<String>.from(_state.autoSellWhitelistedProductIds);
    final tierProducts = GameData.products.where((p) => p.levelId == tier);
    for (final prod in tierProducts) {
      if (allowed) {
        set.add(prod.id);
      } else {
        set.remove(prod.id);
      }
    }
    _state = _state.copyWith(autoSellWhitelistedProductIds: set);
    _persistenceService.markDirty('auto_sell_whitelist');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Check if a product is allowed in auto-sell whitelist
  bool isProductWhitelistedForAutoSell(String productId) {
    return _state.autoSellWhitelistedProductIds.contains(productId);
  }

  /// Enable or disable storefront batch auto-dispatch
  void setAutoSellBatchDispatch(bool enabled) {
    _state = _state.copyWith(autoSellBatchDispatch: enabled);
    _persistenceService.markDirty('game_state');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Enable or disable corporate B2B contracts auto-fulfillment
  void setAutoSellFulfillContracts(bool enabled) {
    _state = _state.copyWith(autoSellFulfillContracts: enabled);
    _persistenceService.markDirty('game_state');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Toggle storefront batch auto-dispatch
  void toggleAutoSellBatchDispatch() {
    setAutoSellBatchDispatch(!_state.autoSellBatchDispatch);
  }

  /// Toggle corporate B2B contracts auto-fulfillment
  void toggleAutoSellFulfillContracts() {
    setAutoSellFulfillContracts(!_state.autoSellFulfillContracts);
  }

  /// Alias for master toggle
  void toggleAutoSellMaster() => toggleAutoSell();

  /// Set minimum inventory reserve threshold for auto-sell (Phase 14)
  void setAutoSellMinReserve(int reserve) {
    final newReserve = math.max(0, reserve);
    _state = _state.copyWith(autoSellMinReserve: newReserve);
    _persistenceService.markDirty('game_state');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Increment or decrement auto-sell minimum reserve threshold (Phase 14)
  void incrementAutoSellMinReserve(int delta) {
    final newReserve = math.max(0, _state.autoSellMinReserve + delta);
    setAutoSellMinReserve(newReserve);
  }

  /// Clear recent auto-sell logs (dev/testing)
  void clearAutoSellLog() {
    _state = _state.copyWith(autoSellRecentLog: const []);
    _persistenceService.markDirty('auto_sell_log');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Set auto-buy intake level directly (for testing/dev)
  void setAutoBuyIntakeLevel(int level) {
    _state = _state.copyWith(autoBuyIntakeLevel: level);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Set auto-build throughput level for a tier directly (for testing/dev)
  void setAutoBuildThroughputLevel(String tier, int level) {
    final newMap = Map<String, int>.from(_state.autoBuildThroughputLevel);
    newMap[tier] = level;
    _state = _state.copyWith(autoBuildThroughputLevel: newMap);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Buy one auto-buy machine with dynamic pricing and tier limits
  /// Returns true if purchase was successful, false if limit reached or not enough money
  Future<bool> buyAutoBuyMachine() async {
    final currentCount = _state.autoBuyMachinesOwned;
    if (currentCount >= getMachineTierLimit('autoBuy')) {
      return false; // Reached factory tier limit
    }

    final price = getMachinePrice('autoBuy', currentCount);
    if (_state.money < price) {
      return false; // Not enough money
    }

    // Deduct cost
    final newMoney = _state.money - price;
    final newCount = currentCount + 1;

    _state = _state.copyWith(
      money: newMoney,
      autoBuyMachinesOwned: newCount,
    );
    notifyListeners();
    
    // Mark automation data as dirty for incremental save
    _persistenceService.markDirty('automation');
    await _saveGameStateOptimized(); // Await to ensure save completes

    if (kDebugMode) {
      GameLogger.info('Auto-buy machine purchased! Count: $newCount, Money remaining: \$${newMoney.toStringAsFixed(2)}');
    }

    return true;
  }

  /// Increase auto-buy resource capacity by 10 (uncapped)
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
        final material = GameData.getMaterial(resourceId);
        return material?.name ?? resourceId;
      }
    }
    
    return 'All at cap'; // All resources at cap
  }

  // V1.5.0 Phase 2: Auto-Build Machine Management
  
  /// Toggle auto-build machines on/off for a specific tier
  void toggleAutoBuild(String tier) {
    final newEnabled = Map<String, bool>.from(_state.autoBuildEnabled);
    newEnabled[tier] = !(newEnabled[tier] ?? false);
    
    _state = _state.copyWith(autoBuildEnabled: newEnabled);
    
    // Reshape the queue to match the new throughput (1 if off, X if on)
    _recalculateQueueStartTimes(tier);
    
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Auto-build toggled for $tier: ${newEnabled[tier]! ? "ON" : "OFF"}',
      );
    }
  }

  /// Buy one auto-build machine for a specific tier with dynamic pricing and tier limits
  /// Returns true if purchase was successful, false if limit reached or not enough money
  Future<bool> buyAutoBuildMachine(String tier) async {
    final currentCount = _state.autoBuildMachinesOwned[tier] ?? 0;
    if (currentCount >= getMachineTierLimit(tier)) {
      return false; // Reached factory tier limit
    }

    final price = getMachinePrice(tier, currentCount);
    if (_state.money < price) {
      return false; // Not enough money
    }

    // Deduct cost
    final newMoney = _state.money - price;
    final newMachines = Map<String, int>.from(_state.autoBuildMachinesOwned);
    newMachines[tier] = currentCount + 1;
    
    _state = _state.copyWith(
      money: newMoney,
      autoBuildMachinesOwned: newMachines,
    );
    notifyListeners();
    
    // Mark automation data as dirty for incremental save
    _persistenceService.markDirty('automation');
    await _saveGameStateOptimized(); // Await to ensure save completes

    if (kDebugMode) {
      GameLogger.info('Auto-build machine for $tier purchased! Count: ${newMachines[tier]}, Money remaining: \$${newMoney.toStringAsFixed(2)}');
    }

    return true;
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

  /// Set auto-buy machine count directly (for testing)
  void setAutoBuyMachineCount(int count) {
    _state = _state.copyWith(autoBuyMachinesOwned: count);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Increment auto-build machines for a tier (for testing)
  void incrementAutoBuildMachines(String tier) {
    final newMachines = Map<String, int>.from(_state.autoBuildMachinesOwned);
    newMachines[tier] = (newMachines[tier] ?? 0) + 1;
    _state = _state.copyWith(autoBuildMachinesOwned: newMachines);
    notifyListeners();
    _saveGameStateOptimized();
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
    
    _state = _state.copyWith(
      money: math.min(_state.money + amount, LimitsConstants.maxMoney),
    );
    
    // Check for newly unlocked products after adding money
    _checkAndUpdateUnlocks();
    
    notifyListeners();
    _saveGameStateOptimized();
    
    if (kDebugMode) {
      GameLogger.info('Dev: Added \$${amount.toStringAsFixed(2)} to balance (total: \$${_state.money.toStringAsFixed(2)})');
    }
  }

  /// Dev method: Set money directly (for testing)
  void setMoney(double amount) {
    _state = _state.copyWith(money: amount);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Dev method: Add material directly to inventory (for testing)
  void addMaterialToInventory(String materialId, int quantity) {
    if (quantity <= 0) return;
    final newMaterials = Map<String, int>.from(_state.materials);
    newMaterials[materialId] = (newMaterials[materialId] ?? 0) + quantity;
    _state = _state.copyWith(materials: newMaterials);
    notifyListeners();
    _saveGameStateOptimized();
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
        contractId: order.contractId,
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
    _state = _state.copyWith(
      money: math.min(_state.money + 1000000, LimitsConstants.maxMoney),
    );
    
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

  /// Dev method: Verify and fix database schema (for "no such column" errors)
  Future<void> verifyAndFixDatabaseSchema() async {
    try {
      if (kDebugMode) {
        GameLogger.info('Dev: Verifying and fixing database schema...');
      }
      
      await _persistenceService.verifyAndFixSchema();
      
      // Reload the game state to ensure everything is in sync
      _state = await _persistenceService.loadGameState();
      
      notifyListeners();
      
      if (kDebugMode) {
        GameLogger.info('Dev: Schema verification completed');
      }
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Dev: Schema verification failed: $e');
      }
      rethrow;
    }
  }

  /// Dev method: Reset database completely (WARNING: Deletes all data!)
  Future<void> resetDatabase() async {
    try {
      if (kDebugMode) {
        GameLogger.warning('Dev: RESETTING DATABASE - ALL DATA WILL BE LOST!');
      }
      
      await _persistenceService.resetDatabase();
      _isDeveloperModeUnlocked = false;
      
      // Reload the game state (will be fresh/default state)
      _state = await _persistenceService.loadGameState();
      
      // Reinitialize unlock state
      _initializeUnlockState();
      _checkAndUpdateUnlocks();
      
      notifyListeners();
      
      if (kDebugMode) {
        GameLogger.warning('Dev: Database reset complete - game state restored to default');
      }
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Dev: Database reset failed: $e');
      }
      rethrow;
    }
  }

  // ==========================================
  // Factory Tier Methods (Phase 1)
  // ==========================================

  /// Current factory tier configuration
  FactoryTier get currentFactoryTier =>
      GameData.getFactoryTier(_state.factoryTier);

  /// Next factory tier configuration (null if at max tier)
  FactoryTier? get nextFactoryTier =>
      GameData.getNextFactoryTier(_state.factoryTier);

  /// Checks if player can afford and has met shipping requirements for next tier
  bool get canUpgradeFactoryTier {
    final next = nextFactoryTier;
    if (next == null) return false;
    return _state.canUpgradeFactoryTier(next);
  }

  /// Upgrades factory license to next tier
  Future<bool> upgradeFactoryTier() async {
    final next = nextFactoryTier;
    if (next == null) return false;
    if (!_state.canUpgradeFactoryTier(next)) return false;

    final newMoney = _state.money - next.upgradeCost;
    _state = _state.copyWith(
      money: newMoney,
      factoryTier: next.tierNumber,
    );

    // Re-evaluate unlock status with the new tier
    _checkAndUpdateUnlocks();
    notifyListeners();
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Successfully upgraded to Factory Tier ${next.tierNumber}: ${next.name}',
      );
    }
    return true;
  }

  /// Dev method: Set factory tier directly
  Future<void> setFactoryTierForDev(int tier) async {
    if (tier < 1 || tier > GameData.factoryTiers.length) return;
    _state = _state.copyWith(factoryTier: tier);
    _checkAndUpdateUnlocks();
    notifyListeners();
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('Dev: Set factory tier to $tier');
    }
  }

  // ==========================================
  // Logistics Fleet Methods (Phase 2)
  // ==========================================

  /// Current fleet tier configuration
  LogisticsFleetTier get currentFleetTier =>
      GameData.getFleetTier(_state.fleetTier);

  /// Next fleet tier configuration (null if at max tier)
  LogisticsFleetTier? get nextFleetTier =>
      GameData.getNextFleetTier(_state.fleetTier);

  /// Checks if player can afford next fleet tier
  bool get canUpgradeFleet {
    final next = nextFleetTier;
    if (next == null) return false;
    return _state.canUpgradeFleet(next);
  }

  /// Checks if the current logistics fleet carrier can hold the given shipment specification (Phase 10)
  bool canCarrierHold({
    required int totalUnits,
    int varietyCount = 1,
    int maxUnitsInSingleType = 0,
  }) {
    final fleet = currentFleetTier;
    if (totalUnits > fleet.maxPayloadUnits) return false;
    if (varietyCount > fleet.maxProductVarieties) return false;
    final maxSingle =
        maxUnitsInSingleType > 0 ? maxUnitsInSingleType : totalUnits;
    if (maxSingle > fleet.maxUnitsPerType) return false;
    return true;
  }

  /// Upgrades fleet to next tier
  Future<bool> upgradeFleet() async {
    final next = nextFleetTier;
    if (next == null) return false;
    if (!_state.canUpgradeFleet(next)) return false;

    final newMoney = _state.money - next.upgradeCost;
    _state = _state.copyWith(
      money: newMoney,
      fleetTier: next.tierNumber,
    );

    _persistenceService.markDirty('fleet');
    notifyListeners();
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        'Successfully upgraded Logistics Fleet to Tier ${next.tierNumber}: ${next.name}',
      );
    }
    return true;
  }

  /// Dev method: Set fleet tier directly
  Future<void> setFleetTierForDev(int tier) async {
    if (tier < 1 || tier > GameData.fleetTiers.length) return;
    _state = _state.copyWith(fleetTier: tier);
    _persistenceService.markDirty('fleet');
    notifyListeners();
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('Dev: Set fleet tier to $tier');
    }
  }

  // ==========================================
  // Corporate Contracts & Reputation Methods (Phase 2)
  // ==========================================

  /// Get effective price of a material taking client reputation discounts into account
  double getEffectiveMaterialPrice(String materialId) {
    final material = GameData.getMaterial(materialId);
    if (material == null) return 0.0;
    final discount = _state.getMaterialDiscount(materialId);
    return material.buyPrice * (1.0 - discount);
  }

  /// Phase 9A: Auto-ship B2B contracts when toggles are enabled
  void _processAutoShipTick() {
    if (!_state.autoShipRetail && !_state.autoShipManufacturing) return;

    for (final contract in _state.corporateContracts) {
      if (contract.status != ContractStatus.available) continue;
      if (contract.isExpired) continue;

      final shouldAutoShip =
          (contract.contractType == ContractType.retail && _state.autoShipRetail) ||
          (contract.contractType == ContractType.manufacturing && _state.autoShipManufacturing);

      if (!shouldAutoShip) continue;
      if (!contract.canFulfill(_state.products)) continue;
      if (!_state.canShipMore(_state.activeShippingOrders.length)) break;

      shipContract(contract.id);
    }
  }

  void _processContractsTick() {
    bool stateChanged = false;
    final now = DateTime.now();
    final updatedContracts = <CorporateContract>[];

    // Check existing contracts for expiration
    for (final contract in _state.corporateContracts) {
      if (contract.status == ContractStatus.available ||
          contract.status == ContractStatus.active) {
        if (now.isAfter(contract.expiresAt)) {
          // Expired contracts get purged to open up slots for new contracts
          stateChanged = true;
          continue;
        }
      }
      // Retain completed contracts up to 5 minutes
      if (contract.status == ContractStatus.completed) {
        if (now.difference(contract.expiresAt).inMinutes > 5) {
          stateChanged = true;
          continue;
        }
      }
      updatedContracts.add(contract);
    }

    // Refill contracts based on tier-scaled max slots
    final maxSlots = _state.maxContractSlots;
    final openCount = updatedContracts
        .where((c) =>
            c.status == ContractStatus.available ||
            c.status == ContractStatus.active ||
            c.status == ContractStatus.shipping)
        .length;

    if (openCount < maxSlots) {
      final needed = maxSlots - openCount;
      for (int i = 0; i < needed; i++) {
        final newContract = _generateNewContract(updatedContracts);
        if (newContract != null) {
          updatedContracts.add(newContract);
          stateChanged = true;
        }
      }
    }

    if (stateChanged) {
      _state = _state.copyWith(corporateContracts: updatedContracts);
      _persistenceService.markDirty('contracts');
      notifyListeners();
    }

    // Process auto-ship after contract state is updated
    _processAutoShipTick();
  }

  /// Initial contracts generation helper
  void _checkAndGenerateInitialContracts() {
    final maxSlots = _state.maxContractSlots;
    final openCount = _state.corporateContracts
        .where((c) =>
            c.status == ContractStatus.available ||
            c.status == ContractStatus.active ||
            c.status == ContractStatus.shipping)
        .length;

    if (openCount < maxSlots) {
      final list = List<CorporateContract>.from(_state.corporateContracts);
      final needed = maxSlots - openCount;
      for (int i = 0; i < needed; i++) {
        final c = _generateNewContract(list);
        if (c != null) list.add(c);
      }
      _state = _state.copyWith(corporateContracts: list);
      _persistenceService.markDirty('contracts');
    }
  }

  /// Generates a single contract matched to the player's tier and unlocked items
  /// Phase 9A: Now generates either Retail or Manufacturing contracts (50/50 split)
  CorporateContract? _generateNewContract(List<CorporateContract> existing) {
    if (GameData.corporateClients.isEmpty) return null;

    final client = _pickClientForNewContract(existing);
    final random = math.Random();

    // 50/50 split between Retail and Manufacturing
    final isRetail = random.nextBool();

    if (isRetail) {
      return _generateRetailContract(client, random);
    } else {
      return _generateManufacturingContract(client, random);
    }
  }

  /// Generates a Retail contract targeting finished/complex products
  /// Single-product, small quantities (5-25), premium pricing
  CorporateContract? _generateRetailContract(
    CorporateClient client,
    math.Random random,
  ) {
    // Retail targets complex and retail-level products
    final retailProducts = client.demandedProductIds
        .where((id) => _state.isProductUnlocked(id))
        .where((id) {
          final product = GameData.getProduct(id);
          return product != null &&
              (product.levelId == ProductLevel.complex ||
               product.levelId == ProductLevel.retail);
        })
        .toList();

    // Fallback: any unlocked complex/retail product from any client
    List<String> targetPool = retailProducts;
    if (targetPool.isEmpty) {
      targetPool = _state.unlockedProducts
          .where((id) {
            final product = GameData.getProduct(id);
            return product != null &&
                (product.levelId == ProductLevel.complex ||
                 product.levelId == ProductLevel.retail);
          })
          .toList();
    }
    // Last fallback: any unlocked product or starter product
    if (targetPool.isEmpty) {
      targetPool = _state.unlockedProducts.toList();
    }
    if (targetPool.isEmpty) {
      targetPool = ['box'];
    }
    if (targetPool.isEmpty) return null;

    final productId = targetPool[random.nextInt(targetPool.length)];
    final product = GameData.getProduct(productId);
    if (product == null) return null;

    // Retail: 5-25 units
    final qty = 5 + random.nextInt(21); // 5 to 25

    // Premium pricing: 1.6x market price
    final clientBonusMultiplier = _state.getContractBonusMultiplier(client.id);
    final cashReward =
        (product.sellPrice * qty * 1.6 * (1.0 + clientBonusMultiplier)).roundToDouble();

    final repReward = 75; // Retail contracts give premium reputation

    final durationMinutes = 20 + (_state.factoryTier * 5);
    final now = DateTime.now();

    return CorporateContract(
      id: '${now.microsecondsSinceEpoch}_${client.id}_retail',
      clientId: client.id,
      title: '${client.name} Retail Order',
      description:
          'Premium retail fulfillment: ship ${product.name} units to ${client.name} distribution.',
      contractType: ContractType.retail,
      requiredProducts: {productId: qty},
      cashReward: cashReward,
      repReward: repReward,
      expiresAt: now.add(Duration(minutes: durationMinutes)),
      status: ContractStatus.available,
      createdAt: now,
    );
  }

  /// Generates a Manufacturing contract targeting intermediate/basic parts
  /// Multi-product (1-4 types scaling with tier), large quantities (50-200), bulk pricing
  CorporateContract? _generateManufacturingContract(
    CorporateClient client,
    math.Random random,
  ) {
    // Manufacturing targets basic and intermediate parts
    final mfgProducts = client.demandedProductIds
        .where((id) => _state.isProductUnlocked(id))
        .where((id) {
          final product = GameData.getProduct(id);
          return product != null &&
              (product.levelId == ProductLevel.basicParts ||
               product.levelId == ProductLevel.intermediate);
        })
        .toList();

    // Fallback: any unlocked basic/intermediate product
    List<String> targetPool = mfgProducts;
    if (targetPool.isEmpty) {
      targetPool = _state.unlockedProducts
          .where((id) {
            final product = GameData.getProduct(id);
            return product != null &&
                (product.levelId == ProductLevel.basicParts ||
                 product.levelId == ProductLevel.intermediate);
          })
          .toList();
    }
    // Last fallback: any unlocked product or starter product
    if (targetPool.isEmpty) {
      targetPool = _state.unlockedProducts.toList();
    }
    if (targetPool.isEmpty) {
      targetPool = ['box'];
    }
    if (targetPool.isEmpty) return null;

    // Product count scales with factory tier: T1-2: 1-2, T3: 2-3, T4: 2-4
    int maxProductTypes;
    switch (_state.factoryTier) {
      case 1:
      case 2:
        maxProductTypes = 1 + random.nextInt(2); // 1-2
        break;
      case 3:
        maxProductTypes = 2 + random.nextInt(2); // 2-3
        break;
      case 4:
        maxProductTypes = 2 + random.nextInt(3); // 2-4
        break;
      default:
        maxProductTypes = 1;
    }
    maxProductTypes = math.min(maxProductTypes, targetPool.length);

    // Shuffle and pick products
    final shuffled = List<String>.from(targetPool)..shuffle(random);
    final selectedProducts = shuffled.take(maxProductTypes).toList();

    // Build requiredProducts map with 50-200 units each
    final requiredProducts = <String, int>{};
    double totalCashReward = 0;
    int totalRepReward = 0;

    for (final productId in selectedProducts) {
      final product = GameData.getProduct(productId);
      if (product == null) continue;

      final qty = 50 + random.nextInt(151); // 50 to 200
      requiredProducts[productId] = qty;

      // Bulk pricing: 1.2x market price
      final clientBonusMultiplier = _state.getContractBonusMultiplier(client.id);
      totalCashReward +=
          product.sellPrice * qty * 1.2 * (1.0 + clientBonusMultiplier);
      totalRepReward += 30; // 30 rep per product line
    }

    if (requiredProducts.isEmpty) return null;

    final durationMinutes = 20 + (_state.factoryTier * 5);
    final now = DateTime.now();

    // Build description listing all required products
    final productNames = requiredProducts.entries
        .map((e) {
          final p = GameData.getProduct(e.key);
          return '${e.value}x ${p?.name ?? e.key}';
        })
        .join(', ');

    return CorporateContract(
      id: '${now.microsecondsSinceEpoch}_${client.id}_mfg',
      clientId: client.id,
      title: '${client.name} Bulk Manufacturing',
      description: 'Industrial bulk order: $productNames.',
      contractType: ContractType.manufacturing,
      requiredProducts: requiredProducts,
      cashReward: totalCashReward.roundToDouble(),
      repReward: totalRepReward,
      expiresAt: now.add(Duration(minutes: durationMinutes)),
      status: ContractStatus.available,
      createdAt: now,
    );
  }

  CorporateClient _pickClientForNewContract(List<CorporateContract> existing) {
    final counts = <String, int>{};
    for (final c in GameData.corporateClients) {
      counts[c.id] = 0;
    }
    for (final contract in existing) {
      if (contract.status == ContractStatus.available ||
          contract.status == ContractStatus.active ||
          contract.status == ContractStatus.shipping) {
        counts[contract.clientId] = (counts[contract.clientId] ?? 0) + 1;
      }
    }
    CorporateClient best = GameData.corporateClients.first;
    int min = counts[best.id] ?? 0;
    for (final c in GameData.corporateClients) {
      final count = counts[c.id] ?? 0;
      if (count < min) {
        min = count;
        best = c;
      }
    }
    return best;
  }

  /// Ship a B2B contract: Lock & Ship fulfillment model (Phase 9A)
  /// One-step flow: available → shipping → completed (when shipping timer finishes)
  /// Deducts ALL required products at once, creates a shipping order consuming 1 fleet slot
  bool shipContract(String contractId) {
    try {
      final index =
          _state.corporateContracts.indexWhere((c) => c.id == contractId);
      if (index == -1) return false;

      final contract = _state.corporateContracts[index];
      if (contract.status != ContractStatus.available || contract.isExpired) {
        return false;
      }

      // Check ALL required products are in inventory
      if (!contract.canFulfill(_state.products)) {
        if (kDebugMode) {
          GameLogger.warning('Cannot ship contract ${contract.id}: insufficient inventory');
        }
        return false;
      }

      // Check fleet slot availability
      if (!_state.canShipMore(_state.activeShippingOrders.length)) {
        if (kDebugMode) {
          GameLogger.warning(
            'Cannot ship contract: fleet at capacity ${_state.activeShippingOrders.length} / ${_state.maxSimultaneousShipments}',
          );
        }
        return false;
      }

      // Deduct ALL items from inventory at once
      final newProducts = Map<String, int>.from(_state.products);
      for (final entry in contract.requiredProducts.entries) {
        final current = newProducts[entry.key] ?? 0;
        final remaining = current - entry.value;
        if (remaining <= 0) {
          newProducts.remove(entry.key);
        } else {
          newProducts[entry.key] = remaining;
        }
      }

      // Calculate shipping time
      final totalShippingTime = _calculateContractShippingTime(contract);

      // Create shipping order
      final orderId = DateTime.now().microsecondsSinceEpoch.toString();
      final shippingItems = contract.requiredProducts.entries
          .map((e) => ShippingItem(productId: e.key, quantity: e.value))
          .toList();

      final shippingOrder = ShippingOrder(
        id: orderId,
        items: shippingItems,
        startTime: DateTime.now(),
        totalShippingTime: totalShippingTime,
        totalRevenue: contract.cashReward,
        contractId: contract.id,
      );

      // Update contract status to shipping
      final updatedContracts =
          List<CorporateContract>.from(_state.corporateContracts);
      updatedContracts[index] = contract.copyWith(
        status: ContractStatus.shipping,
        shippingOrderId: orderId,
      );

      // Add shipping order to active orders
      final newShippingOrders =
          List<ShippingOrder>.from(_state.activeShippingOrders)
            ..add(shippingOrder);

      _state = _state.copyWith(
        products: newProducts,
        corporateContracts: updatedContracts,
        activeShippingOrders: newShippingOrders,
      );

      _persistenceService.markDirty('products');
      _persistenceService.markDirty('contracts');
      _persistenceService.markDirty('shipping');
      notifyListeners();
      _saveGameStateOptimized();
      _startUpdateTimer();
      return true;
    } catch (e) {
      if (kDebugMode) {
        GameLogger.error('Error shipping contract $contractId', e);
      }
      return false;
    }
  }

  /// Calculate shipping time for a B2B contract
  double _calculateContractShippingTime(CorporateContract contract) {
    double rawTime = 0;
    for (final entry in contract.requiredProducts.entries) {
      final product = GameData.getProduct(entry.key);
      if (product != null) {
        rawTime += product.calculateShippingTime(entry.value);
      }
    }

    // Manufacturing gets 0.75x shipping time bonus (25% faster)
    if (contract.contractType == ContractType.manufacturing) {
      rawTime *= 0.75;
    }

    final fleet = GameData.getFleetTier(_state.fleetTier);
    double effectiveSpeedMultiplier =
        fleet.speedMultiplier * _state.logisticsSpeedMultiplier;

    // Apply contract fast-track bonus if applicable
    if (_state.hasCorporateContractFastTrack) {
      effectiveSpeedMultiplier *= ResearchConstants.logisticsContractSpeedBonus;
    }

    return (rawTime / effectiveSpeedMultiplier).clamp(1.0, 86400.0);
  }

  /// Dev controls for contracts & rep
  void devAddReputation(String clientId, int amount) {
    final rep = Map<String, int>.from(_state.clientReputation);
    rep[clientId] = (rep[clientId] ?? 0) + amount;
    _state = _state.copyWith(clientReputation: rep);
    _persistenceService.markDirty('reputation');
    notifyListeners();
    _saveGameStateOptimized();
  }

  void devRefreshContracts() {
    final list = <CorporateContract>[];
    for (int i = 0; i < _state.maxContractSlots; i++) {
      final c = _generateNewContract(list);
      if (c != null) list.add(c);
    }
    _state = _state.copyWith(corporateContracts: list);
    _persistenceService.markDirty('contracts');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Toggle auto-ship for retail B2B contracts
  void toggleAutoShipRetail() {
    _state = _state.copyWith(autoShipRetail: !_state.autoShipRetail);
    _persistenceService.markDirty('game_state');
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Toggle auto-ship for manufacturing B2B contracts
  void toggleAutoShipManufacturing() {
    _state = _state.copyWith(autoShipManufacturing: !_state.autoShipManufacturing);
    _persistenceService.markDirty('game_state');
    notifyListeners();
    _saveGameStateOptimized();
  }

  // ==================================================
  // PHASE 4: R&D LAB & TECHNOLOGY TREE METHODS
  // ==================================================

  /// Deconstruct a quantity of an assembled product into Research Points (RP)
  bool deconstructProduct(String productId, int quantity) {
    if (productId.isEmpty || quantity <= 0) {
      if (kDebugMode) {
        GameLogger.warning(
          'Invalid deconstruct parameters: productId=$productId, quantity=$quantity',
        );
      }
      return false;
    }

    final product = GameData.getProduct(productId);
    if (product == null) {
      if (kDebugMode) {
        GameLogger.warning('Product not found for deconstruction: $productId');
      }
      return false;
    }

    final currentOwned = _state.getProductCount(productId);
    if (currentOwned < quantity) {
      if (kDebugMode) {
        GameLogger.warning(
          'Insufficient inventory to deconstruct: $productId, owned: $currentOwned, needed: $quantity',
        );
      }
      return false;
    }

    final newProducts = Map<String, int>.from(_state.products);
    final remaining = currentOwned - quantity;
    if (remaining <= 0) {
      newProducts.remove(productId);
    } else {
      newProducts[productId] = remaining;
    }

    final rpPerUnit = GameData.getResearchPointsForProduct(productId);
    final totalRpGained = rpPerUnit * quantity;
    final updatedRp = _state.researchPoints + totalRpGained;

    _state = _state.copyWith(
      products: newProducts,
      researchPoints: updatedRp,
    );

    _persistenceService.markDirty('products');
    _persistenceService.markDirty('technologies');
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        '🧪 Deconstructed $quantity x ${product.name} (+$totalRpGained RP, total: $updatedRp RP)',
      );
    }

    return true;
  }

  /// Research or upgrade a technology node
  bool researchTechnology(String techId) {
    final tech = GameData.getTechnology(techId);
    if (tech == null) {
      if (kDebugMode) {
        GameLogger.warning('Technology not found: $techId');
      }
      return false;
    }

    final currentLevel = _state.getTechLevel(techId);
    if (currentLevel >= tech.maxLevel) {
      if (kDebugMode) {
        GameLogger.warning(
          'Technology already at max level ($currentLevel/${tech.maxLevel}): $techId',
        );
      }
      return false;
    }

    final nextLevelInfo = tech.levels[currentLevel];
    if (_state.researchPoints < nextLevelInfo.rpCost) {
      if (kDebugMode) {
        GameLogger.warning(
          'Insufficient RP for $techId Level ${nextLevelInfo.level}: have ${_state.researchPoints}, need ${nextLevelInfo.rpCost}',
        );
      }
      return false;
    }

    if (_state.factoryTier < nextLevelInfo.requiredFactoryTier) {
      if (kDebugMode) {
        GameLogger.warning(
          'Factory Tier ${nextLevelInfo.requiredFactoryTier} required for $techId Level ${nextLevelInfo.level} (current: Tier ${_state.factoryTier})',
        );
      }
      return false;
    }

    final newRp = _state.researchPoints - nextLevelInfo.rpCost;
    final newTechLevels = Map<String, int>.from(_state.techLevels);
    newTechLevels[techId] = currentLevel + 1;

    _state = _state.copyWith(
      researchPoints: newRp,
      techLevels: newTechLevels,
    );

    _persistenceService.markDirty('technologies');
    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        '🔬 Researched ${tech.name} Level ${currentLevel + 1} (${nextLevelInfo.title}) for ${nextLevelInfo.rpCost} RP',
      );
    }

    return true;
  }

  /// Toggle Factory Overclocking on or off
  bool toggleOverclock(bool enable) {
    if (enable) {
      if (_state.getTechLevel('factory_overclocking') < 2) {
        if (kDebugMode) {
          GameLogger.warning(
            'Factory Overclocking Level 2 required to engage overdrive toggle',
          );
        }
        return false;
      }
      if (_state.maintenanceWear <= 0.0) {
        if (kDebugMode) {
          GameLogger.warning(
            'Cannot engage overclock: maintenance checkup required',
          );
        }
        return false;
      }
    }

    _state = _state.copyWith(overclockActive: enable);
    notifyListeners();
    _saveGameStateOptimized();
    return true;
  }

  /// Perform Diagnostic Maintenance Checkup to restore wear back to 100%
  bool performMaintenanceCheckup() {
    const fee = ResearchConstants.maintenanceCheckupFee;
    if (_state.money < fee) {
      if (kDebugMode) {
        GameLogger.warning(
          'Insufficient cash for maintenance checkup (cost: \$$fee, have: \$${_state.money})',
        );
      }
      return false;
    }

    if (_state.maintenanceWear >= 1.0) {
      if (kDebugMode) {
        GameLogger.info('Factory already at 100% maintenance condition');
      }
      return false;
    }

    _state = _state.copyWith(
      money: _state.money - fee,
      maintenanceWear: 1.0,
    );

    notifyListeners();
    _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info(
        '🔧 Factory Maintenance Checkup completed for \$$fee. Equipment condition restored to 100%.',
      );
    }

    return true;
  }

  /// Developer / Test helpers for Phase 4
  void devAddResearchPoints(int amount) {
    _state = _state.copyWith(
      researchPoints: math.max(0, _state.researchPoints + amount),
    );
    _persistenceService.markDirty('technologies');
    notifyListeners();
    _saveGameStateOptimized();
  }

  void devSetTechLevel(String techId, int level) {
    final newTechLevels = Map<String, int>.from(_state.techLevels);
    newTechLevels[techId] = level;
    _state = _state.copyWith(techLevels: newTechLevels);
    _persistenceService.markDirty('technologies');
    notifyListeners();
    _saveGameStateOptimized();
  }

  void devSetMaintenanceWear(double wear) {
    _state = _state.copyWith(
      maintenanceWear: wear.clamp(0.0, 1.0),
    );
    notifyListeners();
    _saveGameStateOptimized();
  }

  void devSetMoney(double amount) {
    _state = _state.copyWith(money: amount);
    notifyListeners();
    _saveGameStateOptimized();
  }

  /// Initiate Initial Public Offering (IPO / Prestige)
  /// Requires Net Worth >= $1,000,000.
  /// Converts valuation into Golden Shares, resets run data, and begins next corporate chapter.
  Future<bool> initiateIPO() async {
    if (!_state.canInitiateIPO) {
      if (kDebugMode) {
        GameLogger.warning(
          'Cannot initiate IPO: Net worth \$${_state.netWorth.toStringAsFixed(2)} < \$${PrestigeConstants.ipoNetWorthThreshold}',
        );
      }
      return false;
    }

    final awardedShares = _state.pendingGoldenShares;
    final newGoldenShares = _state.goldenShares + awardedShares;
    final newLifetimeShares = _state.lifetimeGoldenShares + awardedShares;
    final newPrestigeCount = _state.prestigeCount + 1;
    final newLifetimeUnits = _state.lifetimeUnitsShipped + _state.currentRunUnitsShipped;
    final newLifetimeRev = _state.lifetimeRevenue + _state.currentRunRevenue;
    final startingCash = _state.hasPrestigePerk(PrestigeConstants.perkAngelSeedCapital)
        ? PrestigeConstants.angelSeedCapitalAmount
        : 100.0;

    // Build the reset game state preserving persistent prestige stats and unlocked perks
    var newState = GameState(
      money: startingCash,
      materials: const {},
      products: const {},
      activeProductions: const [],
      activeShippingOrders: const [],
      shippingHistory: const [],
      machines: const {},
      buildQuantityPreferences: _state.buildQuantityPreferences,
      buyQuantityPreferences: _state.buyQuantityPreferences,
      sellQuantityPreferences: _state.sellQuantityPreferences,
      unlockedProducts: const {},
      productUnlockStatus: const {},
      autoBuyMachinesOwned: 0,
      autoBuyEnabled: false,
      lastAutoBuyTick: null,
      autoBuyResourceCapacity: 10,
      autoBuildMachinesOwned: const {},
      autoBuildEnabled: const {},
      lastAutoBuildTick: const {},
      autoBuildProductCapacity: const {},
      factoryTier: 1,
      fleetTier: 1,
      clientReputation: _state.clientReputation,
      corporateContracts: const [],
      researchPoints: 0,
      techLevels: const {},
      overclockActive: false,
      maintenanceWear: 1.0,
      prestigeCount: newPrestigeCount,
      goldenShares: newGoldenShares,
      lifetimeGoldenShares: newLifetimeShares,
      lifetimeRevenue: newLifetimeRev,
      lifetimeUnitsShipped: newLifetimeUnits,
      unlockedPrestigePerks: Set<String>.from(_state.unlockedPrestigePerks),
      redeemedCodes: _state.redeemedCodes,
    );

    // Recompute unlocked products based on new reset state (tier 1, no research, but may have prototype blueprints if perk owned)
    ProductUnlockService.clearCache();
    final initialUnlocked = ProductUnlockService.getAllUnlockedProducts(newState);
    newState = newState.copyWith(unlockedProducts: initialUnlocked);

    _state = newState;

    // Reset persistence
    if (!_isTestMode) {
      await _persistenceService.resetRunDataForPrestige(_state);
    }

    notifyListeners();

    if (kDebugMode) {
      GameLogger.info(
        '🔔 IPO Complete! Awarded $awardedShares Golden Shares. Total: $newGoldenShares. Starting Cash: \$$startingCash.',
      );
    }

    return true;
  }

  /// Unlock a Prestige / Venture Perk using Golden Shares
  Future<bool> unlockPrestigePerk(String perkId) async {
    if (_state.hasPrestigePerk(perkId)) {
      if (kDebugMode) {
        GameLogger.warning('Prestige perk $perkId already unlocked');
      }
      return false;
    }

    final perk = GameData.getPrestigePerk(perkId);
    if (perk == null) {
      if (kDebugMode) {
        GameLogger.warning('Prestige perk $perkId not found');
      }
      return false;
    }

    if (_state.goldenShares < perk.goldenShareCost) {
      if (kDebugMode) {
        GameLogger.warning(
          'Insufficient Golden Shares for perk $perkId: need ${perk.goldenShareCost}, have ${_state.goldenShares}',
        );
      }
      return false;
    }

    final newUnlockedPerks = Set<String>.from(_state.unlockedPrestigePerks)..add(perkId);
    final newShares = _state.goldenShares - perk.goldenShareCost;

    // If prototype blueprints unlocked, immediately recalculate unlocked products
    _state = _state.copyWith(
      goldenShares: newShares,
      unlockedPrestigePerks: newUnlockedPerks,
    );
    ProductUnlockService.clearCache();
    final newUnlockedProducts = ProductUnlockService.getAllUnlockedProducts(_state);

    _state = _state.copyWith(
      unlockedProducts: newUnlockedProducts,
    );

    _persistenceService.markDirty('prestige');
    notifyListeners();
    await _saveGameStateOptimized();

    if (kDebugMode) {
      GameLogger.info('🌟 Prestige perk ${perk.name} unlocked! Remaining Golden Shares: $newShares');
    }

    return true;
  }

  /// Developer / Test helpers for Phase 5
  void devAddGoldenShares(int amount) {
    final newShares = math.max(0, _state.goldenShares + amount);
    final newLifetime = math.max(_state.lifetimeGoldenShares, _state.lifetimeGoldenShares + amount);
    _state = _state.copyWith(
      goldenShares: newShares,
      lifetimeGoldenShares: newLifetime,
    );
    _persistenceService.markDirty('prestige');
    notifyListeners();
    _saveGameStateOptimized();
  }

  void devUnlockPrestigePerk(String perkId) {
    final newUnlocked = Set<String>.from(_state.unlockedPrestigePerks)..add(perkId);
    _state = _state.copyWith(
      unlockedPrestigePerks: newUnlocked,
    );
    ProductUnlockService.clearCache();
    final newUnlockedProducts = ProductUnlockService.getAllUnlockedProducts(_state);
    _state = _state.copyWith(
      unlockedProducts: newUnlockedProducts,
    );
    _persistenceService.markDirty('prestige');
    notifyListeners();
    _saveGameStateOptimized();
  }

  void devSetShippingHistory(List<ShippingHistory> history) {
    _state = _state.copyWith(shippingHistory: history);
    notifyListeners();
  }
}





