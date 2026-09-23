// Production.INC Game State

import 'game_models.dart';
import 'game_data.dart';

// Represents a production task in progress
class ProductionTask {
  final String id;
  final String productId;
  final DateTime startTime;
  final double durationSeconds;
  final int quantity;
  final bool isQueued; // New field for queue system

  const ProductionTask({
    required this.id,
    required this.productId,
    required this.startTime,
    required this.durationSeconds,
    required this.quantity,
    this.isQueued = false,
  });

  bool get isCompleted {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return elapsed >= durationSeconds;
  }

  double get progress {
    if (isQueued) return 0.0; // Queued items show 0% progress
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return (elapsed / durationSeconds).clamp(0.0, 1.0);
  }

  // Create a copy with updated fields for queue management
  ProductionTask copyWith({
    String? id,
    String? productId,
    DateTime? startTime,
    double? durationSeconds,
    int? quantity,
    bool? isQueued,
  }) {
    return ProductionTask(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      quantity: quantity ?? this.quantity,
      isQueued: isQueued ?? this.isQueued,
    );
  }
}

// Main game state - player's current situation
class GameState {
  final double money;
  final Map<String, int> materials; // materialId -> quantity owned
  final Map<String, int> products; // productId -> quantity owned
  final List<ProductionTask> activeProductions;
  final List<ShippingOrder> activeShippingOrders;
  final List<ShippingHistory> shippingHistory;
  final Map<String, int> machines; // machineId -> quantity owned (future)
  final Map<String, int>
  buildQuantityPreferences; // productId -> preferred quantity (1 or 10)
  final Map<String, int>
  buyQuantityPreferences; // materialId -> preferred quantity (1, 5, or 10)
  final Map<String, int>
  sellQuantityPreferences; // productId -> preferred quantity (1, 5, or 10)
  final Set<String> unlockedProducts; // productId -> unlocked status
  final Map<String, bool>
  productUnlockStatus; // productId -> unlock status cache for performance
  
  // Auto-Buy Machine state (v1.5.0 - in development)
  final int autoBuyMachinesOwned; // Number of auto-buy machines owned
  final bool autoBuyEnabled; // Master on/off toggle for auto-buy machines
  final DateTime? lastAutoBuyTick; // Last time auto-buy tick was processed
  final int autoBuyResourceCapacity; // Player-configurable capacity per resource (increments of 10)

  // Auto-Build Machine state (v1.5.0 Phase 2 - in development)
  final Map<String, int> autoBuildMachinesOwned; // tier -> number of machines (e.g., 'basicParts' -> 2)
  final Map<String, bool> autoBuildEnabled; // tier -> on/off toggle (e.g., 'basicParts' -> true)
  final Map<String, DateTime?> lastAutoBuildTick; // tier -> last tick time
  final Map<String, int> autoBuildProductCapacity; // tier -> capacity setting (e.g., 'basicParts' -> 10)

  // Factory Tier progression state (Phase 1)
  final int factoryTier; // Current factory license tier (1: Garage, 2: Light Assembly, 3: Precision, 4: Megafactory)

  // Phase 2: B2B Corporate Contracts & Dynamic Logistics state
  final int fleetTier; // Logistics Fleet Tier (1: Bikes, 2: Vans, 3: Trucks, 4: Planes)
  final Map<String, int> clientReputation; // clientId -> reputation points
  final List<CorporateContract> corporateContracts; // Active/available corporate contracts

  const GameState({
    this.money = 100.0, // Starting money
    this.materials = const {},
    this.products = const {},
    this.activeProductions = const [],
    this.activeShippingOrders = const [],
    this.shippingHistory = const [],
    this.machines = const {},
    this.buildQuantityPreferences = const {},
    this.buyQuantityPreferences = const {},
    this.sellQuantityPreferences = const {},
    this.unlockedProducts = const {},
    this.productUnlockStatus = const {},
    this.autoBuyMachinesOwned = 0,
    this.autoBuyEnabled = false,
    this.lastAutoBuyTick,
    this.autoBuyResourceCapacity = 10, // Default starting capacity
    required this.autoBuildMachinesOwned, // Required - default to empty map
    required this.autoBuildEnabled, // Required - default to empty map
    required this.lastAutoBuildTick, // Required - default to empty map
    required this.autoBuildProductCapacity, // Required - default to empty map
    this.factoryTier = 1, // Default to Tier 1: Garage Workshop
    this.fleetTier = 1, // Default to Tier 1: Courier Bikes
    this.clientReputation = const {},
    this.corporateContracts = const [],
  });

  GameState copyWith({
    double? money,
    Map<String, int>? materials,
    Map<String, int>? products,
    List<ProductionTask>? activeProductions,
    List<ShippingOrder>? activeShippingOrders,
    List<ShippingHistory>? shippingHistory,
    Map<String, int>? machines,
    Map<String, int>? buildQuantityPreferences,
    Map<String, int>? buyQuantityPreferences,
    Map<String, int>? sellQuantityPreferences,
    Set<String>? unlockedProducts,
    Map<String, bool>? productUnlockStatus,
    int? autoBuyMachinesOwned,
    bool? autoBuyEnabled,
    DateTime? lastAutoBuyTick,
    int? autoBuyResourceCapacity,
    Map<String, int>? autoBuildMachinesOwned,
    Map<String, bool>? autoBuildEnabled,
    Map<String, DateTime?>? lastAutoBuildTick,
    Map<String, int>? autoBuildProductCapacity,
    int? factoryTier,
    int? fleetTier,
    Map<String, int>? clientReputation,
    List<CorporateContract>? corporateContracts,
  }) {
    return GameState(
      money: money ?? this.money,
      materials: materials ?? this.materials,
      products: products ?? this.products,
      activeProductions: activeProductions ?? this.activeProductions,
      activeShippingOrders: activeShippingOrders ?? this.activeShippingOrders,
      shippingHistory: shippingHistory ?? this.shippingHistory,
      machines: machines ?? this.machines,
      buildQuantityPreferences:
          buildQuantityPreferences ?? this.buildQuantityPreferences,
      buyQuantityPreferences:
          buyQuantityPreferences ?? this.buyQuantityPreferences,
      sellQuantityPreferences:
          sellQuantityPreferences ?? this.sellQuantityPreferences,
      unlockedProducts: unlockedProducts ?? this.unlockedProducts,
      productUnlockStatus: productUnlockStatus ?? this.productUnlockStatus,
      autoBuyMachinesOwned: autoBuyMachinesOwned ?? this.autoBuyMachinesOwned,
      autoBuyEnabled: autoBuyEnabled ?? this.autoBuyEnabled,
      lastAutoBuyTick: lastAutoBuyTick ?? this.lastAutoBuyTick,
      autoBuyResourceCapacity: autoBuyResourceCapacity ?? this.autoBuyResourceCapacity,
      autoBuildMachinesOwned: autoBuildMachinesOwned ?? this.autoBuildMachinesOwned,
      autoBuildEnabled: autoBuildEnabled ?? this.autoBuildEnabled,
      lastAutoBuildTick: lastAutoBuildTick ?? this.lastAutoBuildTick,
      autoBuildProductCapacity: autoBuildProductCapacity ?? this.autoBuildProductCapacity,
      factoryTier: factoryTier ?? this.factoryTier,
      fleetTier: fleetTier ?? this.fleetTier,
      clientReputation: clientReputation ?? this.clientReputation,
      corporateContracts: corporateContracts ?? this.corporateContracts,
    );
  }

  // Helper methods
  int getMaterialCount(String materialId) => materials[materialId] ?? 0;
  int getProductCount(String productId) => products[productId] ?? 0;
  bool canAfford(double price) => money >= price;
  bool isProductUnlocked(String productId) =>
      unlockedProducts.contains(productId);

  bool hasMaterialsFor(Map<String, int> required) {
    for (final entry in required.entries) {
      final materialCount = getMaterialCount(entry.key);
      final productCount = getProductCount(entry.key);
      final totalAvailable = materialCount + productCount;

      if (totalAvailable < entry.value) {
        return false;
      }
    }
    return true;
  }

  // Check if player has ever produced a specific product (for unlock logic)
  bool hasProduced(String productId) {
    return getProductCount(productId) > 0;
  }

  // Calculate total quantity of a product shipped across all shipping history
  int getShippedProductCount(String productId) {
    int total = 0;
    for (final order in shippingHistory) {
      for (final item in order.items) {
        if (item.productId == productId) {
          total += item.quantity;
        }
      }
    }
    return total;
  }

  // Check if player meets all prerequisites to upgrade to next tier
  bool canUpgradeFactoryTier(FactoryTier nextTier) {
    if (money < nextTier.upgradeCost) {
      return false;
    }
    for (final entry in nextTier.requiredShippedProducts.entries) {
      if (getShippedProductCount(entry.key) < entry.value) {
        return false;
      }
    }
    return true;
  }

  // Phase 2: Reputation and Logistics Helper Methods
  int getReputation(String clientId) => clientReputation[clientId] ?? 0;

  int getReputationLevel(String clientId) {
    final rep = getReputation(clientId);
    if (rep >= 1500) return 4;
    if (rep >= 700) return 3;
    if (rep >= 300) return 2;
    if (rep >= 100) return 1;
    return 0;
  }

  String getReputationTitle(String clientId) {
    switch (getReputationLevel(clientId)) {
      case 4:
        return 'Executive Partner';
      case 3:
        return 'Strategic Alliance';
      case 2:
        return 'Preferred Vendor';
      case 1:
        return 'Partner';
      default:
        return 'Neutral';
    }
  }

  double getMaterialDiscount(String materialId) {
    double bestDiscount = 0.0;
    for (final client in GameData.corporateClients) {
      if (client.discountMaterialIds.contains(materialId)) {
        final level = getReputationLevel(client.id);
        final discount = level * 0.05; // 0%, 5%, 10%, 15%, 20%
        if (discount > bestDiscount) {
          bestDiscount = discount;
        }
      }
    }
    return bestDiscount;
  }

  double getContractBonusMultiplier(String clientId) {
    final level = getReputationLevel(clientId);
    if (level >= 4) return 0.15;
    if (level == 3) return 0.10;
    if (level == 2) return 0.05;
    return 0.0;
  }

  int get maxSimultaneousShipments {
    return GameData.getFleetTier(fleetTier).maxSimultaneousShipments;
  }

  bool canShipMore(int currentActiveOrders) {
    return currentActiveOrders < maxSimultaneousShipments;
  }

  bool canUpgradeFleet(LogisticsFleetTier nextTier) {
    return money >= nextTier.upgradeCost;
  }
}

