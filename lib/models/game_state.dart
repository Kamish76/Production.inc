// Production.INC Game State

import 'game_models.dart';
import 'game_data.dart';
import 'auto_sell_log_entry.dart';
import '../constants/game_constants.dart';

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
  final int autoBuyIntakeLevel; // Intake capacity level (Phase 8: High-Throughput Automation)

  // Auto-Build Machine state (v1.5.0 Phase 2 - in development)
  final Map<String, int> autoBuildMachinesOwned; // tier -> number of machines (e.g., 'basicParts' -> 2)
  final Map<String, bool> autoBuildEnabled; // tier -> on/off toggle (e.g., 'basicParts' -> true)
  final Map<String, DateTime?> lastAutoBuildTick; // tier -> last tick time
  final Map<String, int> autoBuildProductCapacity; // tier -> capacity setting (e.g., 'basicParts' -> 10)
  final Map<String, int> autoBuildThroughputLevel; // tier -> throughput level (Phase 8: High-Throughput Automation)

  // Phase 9A: Auto-Ship toggles for B2B contracts
  final bool autoShipRetail; // Auto-ship retail B2B contracts when fulfillable
  final bool autoShipManufacturing; // Auto-ship manufacturing B2B contracts when fulfillable

  // Phase 9B & Phase 14: Auto-Sell Dispatchers state
  final int autoSellMachinesOwned; // Number of auto-sell dispatchers owned
  final bool autoSellEnabled; // Master on/off toggle for auto-sell dispatchers
  final int autoSellThroughputLevel; // Throughput level multiplier for auto-sell
  final Set<String> autoSellWhitelistedProductIds; // Product IDs permitted to be automatically sold
  final bool autoSellBatchDispatch; // Auto-dispatch assembled batches via shipping fleet
  final bool autoSellFulfillContracts; // Auto-fulfill eligible B2B corporate contracts
  final int autoSellMinReserve; // Global minimum stock threshold preserved across whitelisted products
  final List<AutoSellLogEntry> autoSellRecentLog; // Recent automated dispatches and contract fulfillments (max 10)

  // Factory Tier progression state (Phase 1)
  final int factoryTier; // Current factory license tier (1: Garage, 2: Light Assembly, 3: Precision, 4: Megafactory)

  // Phase 2: B2B Corporate Contracts & Dynamic Logistics state
  final int fleetTier; // Logistics Fleet Tier (1: Bikes, 2: Vans, 3: Trucks, 4: Planes)
  final Map<String, int> clientReputation; // clientId -> reputation points
  final List<CorporateContract> corporateContracts; // Active/available corporate contracts

  // Phase 4: R&D Lab & Technology Tree state
  final int researchPoints; // Available Research Points (RP)
  final Map<String, int> techLevels; // techId -> researched level (0 if unresearched)
  final bool overclockActive; // Overclocking toggle state
  final double maintenanceWear; // 1.0 (100% pristine) down to 0.0 (overclock paused until checkup)

  // Phase 5: Prestige / Initial Public Offering (IPO) state
  final int prestigeCount; // Number of IPOs completed
  final int goldenShares; // Current Golden Shares held
  final int lifetimeGoldenShares; // All-time Golden Shares earned
  final double lifetimeRevenue; // All-time revenue accrued across all prestiges
  final int lifetimeUnitsShipped; // All-time units shipped across all prestiges
  final Set<String> unlockedPrestigePerks; // Unlocked perk IDs
  final Set<String> redeemedCodes; // Persistent redeemed codes (e.g. PRODUCTION2026)

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
    this.autoBuyIntakeLevel = 1,
    required this.autoBuildMachinesOwned, // Required - default to empty map
    required this.autoBuildEnabled, // Required - default to empty map
    required this.lastAutoBuildTick, // Required - default to empty map
    required this.autoBuildProductCapacity, // Required - default to empty map
    this.autoBuildThroughputLevel = const {},
    this.autoShipRetail = false,
    this.autoShipManufacturing = false,
    this.autoSellMachinesOwned = 0,
    this.autoSellEnabled = false,
    this.autoSellThroughputLevel = 1,
    this.autoSellWhitelistedProductIds = const {},
    this.autoSellBatchDispatch = true,
    this.autoSellFulfillContracts = true,
    this.autoSellMinReserve = 0,
    this.autoSellRecentLog = const [],
    this.factoryTier = 1, // Default to Tier 1: Garage Workshop
    this.fleetTier = 1, // Default to Tier 1: Courier Bikes
    this.clientReputation = const {},
    this.corporateContracts = const [],
    this.researchPoints = 0,
    this.techLevels = const {},
    this.overclockActive = false,
    this.maintenanceWear = 1.0,
    this.prestigeCount = 0,
    this.goldenShares = 0,
    this.lifetimeGoldenShares = 0,
    this.lifetimeRevenue = 0.0,
    this.lifetimeUnitsShipped = 0,
    this.unlockedPrestigePerks = const {},
    this.redeemedCodes = const {},
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
    int? autoBuyIntakeLevel,
    Map<String, int>? autoBuildMachinesOwned,
    Map<String, bool>? autoBuildEnabled,
    Map<String, DateTime?>? lastAutoBuildTick,
    Map<String, int>? autoBuildProductCapacity,
    Map<String, int>? autoBuildThroughputLevel,
    bool? autoShipRetail,
    bool? autoShipManufacturing,
    int? autoSellMachinesOwned,
    bool? autoSellEnabled,
    int? autoSellThroughputLevel,
    Set<String>? autoSellWhitelistedProductIds,
    bool? autoSellBatchDispatch,
    bool? autoSellFulfillContracts,
    int? autoSellMinReserve,
    List<AutoSellLogEntry>? autoSellRecentLog,
    int? factoryTier,
    int? fleetTier,
    Map<String, int>? clientReputation,
    List<CorporateContract>? corporateContracts,
    int? researchPoints,
    Map<String, int>? techLevels,
    bool? overclockActive,
    double? maintenanceWear,
    int? prestigeCount,
    int? goldenShares,
    int? lifetimeGoldenShares,
    double? lifetimeRevenue,
    int? lifetimeUnitsShipped,
    Set<String>? unlockedPrestigePerks,
    Set<String>? redeemedCodes,
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
      autoBuyIntakeLevel: autoBuyIntakeLevel ?? this.autoBuyIntakeLevel,
      autoBuildMachinesOwned: autoBuildMachinesOwned ?? this.autoBuildMachinesOwned,
      autoBuildEnabled: autoBuildEnabled ?? this.autoBuildEnabled,
      lastAutoBuildTick: lastAutoBuildTick ?? this.lastAutoBuildTick,
      autoBuildProductCapacity: autoBuildProductCapacity ?? this.autoBuildProductCapacity,
      autoBuildThroughputLevel: autoBuildThroughputLevel ?? this.autoBuildThroughputLevel,
      autoShipRetail: autoShipRetail ?? this.autoShipRetail,
      autoShipManufacturing: autoShipManufacturing ?? this.autoShipManufacturing,
      autoSellMachinesOwned:
          autoSellMachinesOwned ?? this.autoSellMachinesOwned,
      autoSellEnabled: autoSellEnabled ?? this.autoSellEnabled,
      autoSellThroughputLevel:
          autoSellThroughputLevel ?? this.autoSellThroughputLevel,
      autoSellWhitelistedProductIds:
          autoSellWhitelistedProductIds ?? this.autoSellWhitelistedProductIds,
      autoSellBatchDispatch:
          autoSellBatchDispatch ?? this.autoSellBatchDispatch,
      autoSellFulfillContracts:
          autoSellFulfillContracts ?? this.autoSellFulfillContracts,
      autoSellMinReserve: autoSellMinReserve ?? this.autoSellMinReserve,
      autoSellRecentLog: autoSellRecentLog ?? this.autoSellRecentLog,
      factoryTier: factoryTier ?? this.factoryTier,
      fleetTier: fleetTier ?? this.fleetTier,
      clientReputation: clientReputation ?? this.clientReputation,
      corporateContracts: corporateContracts ?? this.corporateContracts,
      researchPoints: researchPoints ?? this.researchPoints,
      techLevels: techLevels ?? this.techLevels,
      overclockActive: overclockActive ?? this.overclockActive,
      maintenanceWear: maintenanceWear ?? this.maintenanceWear,
      prestigeCount: prestigeCount ?? this.prestigeCount,
      goldenShares: goldenShares ?? this.goldenShares,
      lifetimeGoldenShares: lifetimeGoldenShares ?? this.lifetimeGoldenShares,
      lifetimeRevenue: lifetimeRevenue ?? this.lifetimeRevenue,
      lifetimeUnitsShipped: lifetimeUnitsShipped ?? this.lifetimeUnitsShipped,
      unlockedPrestigePerks: unlockedPrestigePerks ?? this.unlockedPrestigePerks,
      redeemedCodes: redeemedCodes ?? this.redeemedCodes,
    );
  }


  // Helper methods
  bool isCodeRedeemed(String code) => redeemedCodes.contains(code.trim().toUpperCase());
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
    int maxShipments = GameData.getFleetTier(fleetTier).maxSimultaneousShipments;
    // Phase 4: Level 3 Logistics Optimization grants +1 concurrent dispatch slot
    if (getTechLevel('logistics_optimization') >= 3) {
      maxShipments += 1;
    }
    // Phase 5: Quantum Warp Dispatch grants +1 concurrent dispatch slot
    if (hasPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch)) {
      maxShipments += 1;
    }
    return maxShipments;
  }

  bool canShipMore(int currentActiveOrders) {
    return currentActiveOrders < maxSimultaneousShipments;
  }

  bool canUpgradeFleet(LogisticsFleetTier nextTier) {
    return money >= nextTier.upgradeCost;
  }

  /// Maximum number of concurrent B2B contract slots, scaling by factory tier.
  int get maxContractSlots {
    switch (factoryTier) {
      case 1: return 3;
      case 2: return 3;
      case 3: return 4;
      case 4: return 5;
      default: return 3;
    }
  }

  // Phase 4: R&D Lab & Technology Tree Helpers
  int getTechLevel(String techId) => techLevels[techId] ?? 0;

  double get materialScienceDuplicationChance {
    final level = getTechLevel('material_science');
    if (level <= 0) return 0.0;
    if (level >= ResearchConstants.materialScienceDuplicationChances.length) {
      return ResearchConstants.materialScienceDuplicationChances.last;
    }
    return ResearchConstants.materialScienceDuplicationChances[level];
  }

  bool get isOverclockEngaged =>
      overclockActive &&
      getTechLevel('factory_overclocking') >= 2 &&
      maintenanceWear > 0.0;

  double get overclockSpeedMultiplier {
    final level = getTechLevel('factory_overclocking');
    if (level <= 0) return 1.0;
    // Level 1: permanent passive +15%
    if (level == 1) return ResearchConstants.factoryOverclockSpeedMultipliers[1];
    // Level 2+: active if overclock toggle is engaged and wear > 0
    if (isOverclockEngaged) {
      if (level >= ResearchConstants.factoryOverclockSpeedMultipliers.length) {
        return ResearchConstants.factoryOverclockSpeedMultipliers.last;
      }
      return ResearchConstants.factoryOverclockSpeedMultipliers[level];
    }
    // Base passive level 1 boost when overclock toggle is off
    return ResearchConstants.factoryOverclockSpeedMultipliers[1];
  }

  double get logisticsSpeedMultiplier {
    final level = getTechLevel('logistics_optimization');
    double mult = 1.0;
    if (level > 0) {
      if (level >= ResearchConstants.logisticsSpeedMultipliers.length) {
        mult = ResearchConstants.logisticsSpeedMultipliers.last;
      } else {
        mult = ResearchConstants.logisticsSpeedMultipliers[level];
      }
    }
    // Phase 5: Quantum Warp Dispatch grants 1.25x speed bonus
    if (hasPrestigePerk(PrestigeConstants.perkQuantumWarpDispatch)) {
      mult *= PrestigeConstants.quantumWarpSpeedBonus;
    }
    return mult;
  }

  bool get hasCorporateContractFastTrack =>
      getTechLevel('logistics_optimization') >= 2;

  // =========================================================================
  // Phase 5: Prestige / Initial Public Offering (IPO) Helpers & Valuations
  // =========================================================================

  bool hasPrestigePerk(String perkId) => unlockedPrestigePerks.contains(perkId);

  /// Global production speed multiplier boosted by Golden Shares (+10% per share)
  double get prestigeSpeedMultiplier =>
      1.0 + (goldenShares * PrestigeConstants.speedBoostPerGoldenShare);

  /// Total market value of all materials currently held in inventory
  double get totalMaterialsMarketValue {
    double total = 0.0;
    for (final entry in materials.entries) {
      if (entry.value <= 0) continue;
      final mat = GameData.getMaterial(entry.key);
      total += entry.value * (mat?.buyPrice ?? 1.0);
    }
    return total;
  }

  /// Total market value of all finished manufactured products held in inventory
  double get totalProductsMarketValue {
    double total = 0.0;
    for (final entry in products.entries) {
      if (entry.value <= 0) continue;
      final prod = GameData.getProduct(entry.key);
      total += entry.value * (prod?.sellPrice ?? 4.0);
    }
    return total;
  }

  /// Total capital value invested in manufacturing automation machines
  double get totalMachineCapitalValue {
    double total = autoBuyMachinesOwned * AutoBuyConstants.machineCost;
    for (final count in autoBuildMachinesOwned.values) {
      total += count * AutoBuildConstants.machineCost;
    }
    total += autoSellMachinesOwned * 1000.0;
    return total;
  }

  /// Comprehensive Net Worth: Cash + Materials + Products + Automation Capital
  double get netWorth =>
      money +
      totalMaterialsMarketValue +
      totalProductsMarketValue +
      totalMachineCapitalValue;

  /// Player qualifies for IPO once total net worth exceeds $1,000,000
  bool get canInitiateIPO =>
      netWorth >= PrestigeConstants.ipoNetWorthThreshold;

  /// Total units shipped in current run
  int get currentRunUnitsShipped {
    int total = 0;
    for (final history in shippingHistory) {
      for (final item in history.items) {
        total += item.quantity;
      }
    }
    return total;
  }

  /// Total revenue generated in current run
  double get currentRunRevenue {
    double total = 0.0;
    for (final history in shippingHistory) {
      total += history.totalRevenue;
    }
    return total;
  }

  /// Projected Golden Shares earned upon conducting an IPO
  int get pendingGoldenShares {
    if (!canInitiateIPO) return 0;
    final fromNetWorth =
        (netWorth / PrestigeConstants.goldenShareNetWorthUnit).floor();
    final fromShipping =
        (currentRunUnitsShipped / PrestigeConstants.goldenShareUnitsShippedUnit).floor();
    return fromNetWorth + fromShipping;
  }

  /// Serialize GameState to JSON map
  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'materials': materials,
      'products': products,
      'machines': machines,
      'buildQuantityPreferences': buildQuantityPreferences,
      'buyQuantityPreferences': buyQuantityPreferences,
      'sellQuantityPreferences': sellQuantityPreferences,
      'unlockedProducts': unlockedProducts.toList(),
      'productUnlockStatus': productUnlockStatus,
      'autoBuyMachinesOwned': autoBuyMachinesOwned,
      'autoBuyEnabled': autoBuyEnabled,
      'lastAutoBuyTick': lastAutoBuyTick?.toIso8601String(),
      'autoBuyResourceCapacity': autoBuyResourceCapacity,
      'autoBuyIntakeLevel': autoBuyIntakeLevel,
      'autoBuildMachinesOwned': autoBuildMachinesOwned,
      'autoBuildEnabled': autoBuildEnabled,
      'lastAutoBuildTick': lastAutoBuildTick
          .map((k, v) => MapEntry(k, v?.toIso8601String())),
      'autoBuildProductCapacity': autoBuildProductCapacity,
      'autoBuildThroughputLevel': autoBuildThroughputLevel,
      'autoShipRetail': autoShipRetail,
      'autoShipManufacturing': autoShipManufacturing,
      'autoSellMachinesOwned': autoSellMachinesOwned,
      'autoSellEnabled': autoSellEnabled,
      'autoSellThroughputLevel': autoSellThroughputLevel,
      'autoSellWhitelistedProductIds': autoSellWhitelistedProductIds.toList(),
      'autoSellBatchDispatch': autoSellBatchDispatch,
      'autoSellFulfillContracts': autoSellFulfillContracts,
      'autoSellMinReserve': autoSellMinReserve,
      'autoSellRecentLog': autoSellRecentLog.map((e) => e.toJson()).toList(),
      'factoryTier': factoryTier,
      'fleetTier': fleetTier,
      'clientReputation': clientReputation,
      'researchPoints': researchPoints,
      'techLevels': techLevels,
      'overclockActive': overclockActive,
      'maintenanceWear': maintenanceWear,
      'prestigeCount': prestigeCount,
      'goldenShares': goldenShares,
      'lifetimeGoldenShares': lifetimeGoldenShares,
      'lifetimeRevenue': lifetimeRevenue,
      'lifetimeUnitsShipped': lifetimeUnitsShipped,
      'unlockedPrestigePerks': unlockedPrestigePerks.toList(),
      'redeemedCodes': redeemedCodes.toList(),
    };
  }

  /// Deserialize GameState from JSON map
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      money: (json['money'] as num?)?.toDouble() ?? 100.0,
      materials: (json['materials'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      products: (json['products'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      machines: (json['machines'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      buildQuantityPreferences:
          (json['buildQuantityPreferences'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      buyQuantityPreferences:
          (json['buyQuantityPreferences'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      sellQuantityPreferences:
          (json['sellQuantityPreferences'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      unlockedProducts: (json['unlockedProducts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      productUnlockStatus:
          (json['productUnlockStatus'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v as bool),
              ) ??
              const {},
      autoBuyMachinesOwned: json['autoBuyMachinesOwned'] as int? ??
          json['auto_buy_machines_owned'] as int? ??
          0,
      autoBuyEnabled: json['autoBuyEnabled'] as bool? ??
          json['auto_buy_enabled'] as bool? ??
          false,
      lastAutoBuyTick: json['lastAutoBuyTick'] != null
          ? DateTime.tryParse(json['lastAutoBuyTick'] as String)
          : null,
      autoBuyResourceCapacity: json['autoBuyResourceCapacity'] as int? ??
          json['auto_buy_resource_capacity'] as int? ??
          10,
      autoBuyIntakeLevel: json['autoBuyIntakeLevel'] as int? ??
          json['auto_buy_intake_level'] as int? ??
          1,
      autoBuildMachinesOwned:
          (json['autoBuildMachinesOwned'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      autoBuildEnabled:
          (json['autoBuildEnabled'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v as bool),
              ) ??
              const {},
      lastAutoBuildTick:
          (json['lastAutoBuildTick'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                    k, v != null ? DateTime.tryParse(v as String) : null),
              ) ??
              const {},
      autoBuildProductCapacity:
          (json['autoBuildProductCapacity'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      autoBuildThroughputLevel:
          (json['autoBuildThroughputLevel'] as Map<String, dynamic>? ??
                  json['auto_build_throughput_level'] as Map<String, dynamic>?)
              ?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      autoShipRetail: json['autoShipRetail'] as bool? ??
          json['auto_ship_retail'] as bool? ??
          false,
      autoShipManufacturing: json['autoShipManufacturing'] as bool? ??
          json['auto_ship_manufacturing'] as bool? ??
          false,
      autoSellMachinesOwned: json['autoSellMachinesOwned'] as int? ??
          json['auto_sell_machines_owned'] as int? ??
          0,
      autoSellEnabled: json['autoSellEnabled'] as bool? ??
          json['auto_sell_enabled'] as bool? ??
          false,
      autoSellThroughputLevel: json['autoSellThroughputLevel'] as int? ??
          json['auto_sell_throughput_level'] as int? ??
          1,
      autoSellWhitelistedProductIds:
          (json['autoSellWhitelistedProductIds'] as List<dynamic>? ??
                  json['auto_sell_whitelisted_product_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      autoSellBatchDispatch: json['autoSellBatchDispatch'] as bool? ??
          json['auto_sell_batch_dispatch'] as bool? ??
          true,
      autoSellFulfillContracts: json['autoSellFulfillContracts'] as bool? ??
          json['auto_sell_fulfill_contracts'] as bool? ??
          true,
      autoSellMinReserve: json['autoSellMinReserve'] as int? ??
          json['auto_sell_min_reserve'] as int? ??
          0,
      autoSellRecentLog: (json['autoSellRecentLog'] as List<dynamic>? ??
              json['auto_sell_recent_log'] as List<dynamic>?)
          ?.map((e) => AutoSellLogEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      factoryTier: json['factoryTier'] as int? ??
          json['factory_tier'] as int? ??
          1,
      fleetTier: json['fleetTier'] as int? ??
          json['fleet_tier'] as int? ??
          1,
      clientReputation:
          (json['clientReputation'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, (v as num).toInt()),
              ) ??
              const {},
      corporateContracts: const [],
      researchPoints: json['researchPoints'] as int? ??
          json['research_points'] as int? ??
          0,
      techLevels: (json['techLevels'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      overclockActive: json['overclockActive'] as bool? ??
          json['overclock_active'] as bool? ??
          false,
      maintenanceWear:
          (json['maintenanceWear'] as num?)?.toDouble() ??
              (json['maintenance_wear'] as num?)?.toDouble() ??
              1.0,
      prestigeCount: json['prestigeCount'] as int? ??
          json['prestige_count'] as int? ??
          0,
      goldenShares: json['goldenShares'] as int? ??
          json['golden_shares'] as int? ??
          0,
      lifetimeGoldenShares: json['lifetimeGoldenShares'] as int? ??
          json['lifetime_golden_shares'] as int? ??
          0,
      lifetimeRevenue:
          (json['lifetimeRevenue'] as num?)?.toDouble() ??
              (json['lifetime_revenue'] as num?)?.toDouble() ??
              0.0,
      lifetimeUnitsShipped: json['lifetimeUnitsShipped'] as int? ??
          json['lifetime_units_shipped'] as int? ??
          0,
      unlockedPrestigePerks:
          (json['unlockedPrestigePerks'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toSet() ??
              const {},
      redeemedCodes: (json['redeemedCodes'] as List<dynamic>? ??
              json['redeemed_codes'] as List<dynamic>?)
          ?.map((e) => e.toString().trim().toUpperCase())
          .toSet() ??
          const {},
    );
  }
}


