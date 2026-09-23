// Production.INC Game Models

// Material that can be bought
class Material {
  final String id;
  final String name;
  final String description;
  final double buyPrice;
  final String emoji;

  const Material({
    required this.id,
    required this.name,
    required this.description,
    required this.buyPrice,
    required this.emoji,
  });
}

// Product tier levels for categorization
enum ProductLevel {
  material, // Base materials that can be bought
  basicParts, // Basic components made from materials
  intermediate, // Intermediate parts made from basic parts
  complex, // Complex items made from intermediate parts
  retail, // Final products for selling only
}

// Industry branch specialization for production lines (Phase 3)
enum IndustryBranch {
  consumerTech, // Phones, cameras, speakers, foundation electronics
  robotics,     // Automation, mechatronics, drones, robotic arms
  cleanEnergy,  // Solar, power storage, renewable generators
}

extension IndustryBranchExtension on IndustryBranch {
  String get displayName {
    switch (this) {
      case IndustryBranch.consumerTech:
        return 'Consumer Tech';
      case IndustryBranch.robotics:
        return 'Robotics & Automation';
      case IndustryBranch.cleanEnergy:
        return 'Renewable Energy';
    }
  }

  String get shortName {
    switch (this) {
      case IndustryBranch.consumerTech:
        return 'Consumer';
      case IndustryBranch.robotics:
        return 'Robotics';
      case IndustryBranch.cleanEnergy:
        return 'Clean Energy';
    }
  }

  String get emoji {
    switch (this) {
      case IndustryBranch.consumerTech:
        return '📱';
      case IndustryBranch.robotics:
        return '🤖';
      case IndustryBranch.cleanEnergy:
        return '⚡';
    }
  }
}

// Product that can be produced and sold
class Product {
  final String id;
  final String name;
  final String description;
  final double sellPrice;
  final String emoji;
  final Map<String, int> requiredMaterials; // materialId -> quantity needed
  final double productionTimeSeconds;
  final double
  baseShippingTimeSeconds; // Base shipping time (was shippingTimeSeconds)
  final double
  shippingScalingFactor; // Per-item scaling factor (fixed at 0.9 for now)
  final ProductLevel levelId; // What tier/level this product belongs to
  final IndustryBranch industryBranch; // Phase 3: industry branch categorization

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.sellPrice,
    required this.emoji,
    required this.requiredMaterials,
    required this.productionTimeSeconds,
    required this.baseShippingTimeSeconds,
    required this.levelId,
    this.shippingScalingFactor = 0.9, // Fixed scaling factor
    this.industryBranch = IndustryBranch.consumerTech,
  });

  // Calculate total shipping time for a given quantity
  double calculateShippingTime(int quantity) {
    return baseShippingTimeSeconds + (quantity * shippingScalingFactor);
  }
}

// Machine for automation (future feature)
class Machine {
  final String id;
  final String name;
  final String description;
  final Map<String, int>
  requiredMaterials; // materialId -> quantity needed to craft
  final String emoji;
  final MachineType type;

  const Machine({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredMaterials,
    required this.emoji,
    required this.type,
  });
}

enum MachineType {
  materialBuyer, // Auto-buys materials
  producer, // Auto-produces items
  seller, // Auto-sells products
}

// Shipping system models
class ShippingItem {
  final String productId;
  final int quantity;

  const ShippingItem({required this.productId, required this.quantity});
}

// Represents a shipping order in progress
class ShippingOrder {
  final String id;
  final List<ShippingItem> items;
  final DateTime startTime;
  final double totalShippingTime;
  final double totalRevenue;

  const ShippingOrder({
    required this.id,
    required this.items,
    required this.startTime,
    required this.totalShippingTime,
    required this.totalRevenue,
  });

  // Helper method to calculate shipping time using new formula
  static double calculateTotalShippingTime(
    List<ShippingItem> items,
    List<Product> products,
  ) {
    double totalTime = 0.0;

    for (final item in items) {
      final product = products.firstWhere((p) => p.id == item.productId);
      totalTime += product.calculateShippingTime(item.quantity);
    }

    return totalTime;
  }

  bool get isCompleted {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return elapsed >= totalShippingTime;
  }

  double get progress {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return (elapsed / totalShippingTime).clamp(0.0, 1.0);
  }

  double get remainingTime {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return (totalShippingTime - elapsed).clamp(0.0, totalShippingTime);
  }
}

// Represents a completed shipping order for history
class ShippingHistory {
  final String id;
  final List<ShippingItem> items;
  final DateTime completedTime;
  final double totalRevenue;

  const ShippingHistory({
    required this.id,
    required this.items,
    required this.completedTime,
    required this.totalRevenue,
  });
}

// Factory Tier model for factory expansion and licensing progression
class FactoryTier {
  final int tierNumber;
  final String name;
  final String description;
  final String emoji;
  final double upgradeCost;
  final Map<String, int> requiredShippedProducts; // productId -> count required
  final int autoBuyCapacityLimit;
  final List<String> perkHighlights;
  final Set<ProductLevel> allowedProductLevels;

  const FactoryTier({
    required this.tierNumber,
    required this.name,
    required this.description,
    required this.emoji,
    required this.upgradeCost,
    this.requiredShippedProducts = const {},
    required this.autoBuyCapacityLimit,
    required this.perkHighlights,
    required this.allowedProductLevels,
  });
}

// Phase 2: Corporate Client definition
class CorporateClient {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final String emoji;
  final int primaryColorHex;
  final List<String> discountMaterialIds;
  final List<String> demandedProductIds;

  const CorporateClient({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.emoji,
    required this.primaryColorHex,
    required this.discountMaterialIds,
    required this.demandedProductIds,
  });
}

// Status of a corporate contract
enum ContractStatus {
  available, // Offered to player, countdown to accept/fulfill
  active,    // Player accepted, active delivery timer running
  completed, // Fulfilled and rewards claimed
  expired,   // Time ran out
}

// Corporate contract model
class CorporateContract {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final String targetProductId;
  final int requiredQuantity;
  final int deliveredQuantity;
  final double cashReward;
  final int repReward;
  final DateTime expiresAt;
  final ContractStatus status;
  final DateTime createdAt;

  const CorporateContract({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.targetProductId,
    required this.requiredQuantity,
    this.deliveredQuantity = 0,
    required this.cashReward,
    required this.repReward,
    required this.expiresAt,
    this.status = ContractStatus.available,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progress => requiredQuantity > 0
      ? (deliveredQuantity / requiredQuantity).clamp(0.0, 1.0)
      : 0.0;

  bool get isReadyToComplete => deliveredQuantity >= requiredQuantity;

  CorporateContract copyWith({
    String? id,
    String? clientId,
    String? title,
    String? description,
    String? targetProductId,
    int? requiredQuantity,
    int? deliveredQuantity,
    double? cashReward,
    int? repReward,
    DateTime? expiresAt,
    ContractStatus? status,
    DateTime? createdAt,
  }) {
    return CorporateContract(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetProductId: targetProductId ?? this.targetProductId,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      deliveredQuantity: deliveredQuantity ?? this.deliveredQuantity,
      cashReward: cashReward ?? this.cashReward,
      repReward: repReward ?? this.repReward,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'title': title,
      'description': description,
      'target_product_id': targetProductId,
      'required_quantity': requiredQuantity,
      'delivered_quantity': deliveredQuantity,
      'cash_reward': cashReward,
      'rep_reward': repReward,
      'expires_at': expiresAt.millisecondsSinceEpoch,
      'status': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CorporateContract.fromMap(Map<String, dynamic> map) {
    ContractStatus parseStatus(String? name) {
      for (final s in ContractStatus.values) {
        if (s.name == name) return s;
      }
      return ContractStatus.available;
    }

    return CorporateContract(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      targetProductId: map['target_product_id'] as String,
      requiredQuantity: map['required_quantity'] as int,
      deliveredQuantity: (map['delivered_quantity'] as int?) ?? 0,
      cashReward: (map['cash_reward'] as num).toDouble(),
      repReward: map['rep_reward'] as int,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expires_at'] as int),
      status: parseStatus(map['status'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

// Logistics Fleet Tier model for Phase 2 dynamic shipping
class LogisticsFleetTier {
  final int tierNumber;
  final String name;
  final String description;
  final String emoji;
  final double upgradeCost;
  final double speedMultiplier; // e.g. 1.0, 1.25, 1.6, 2.5
  final int maxSimultaneousShipments; // e.g. 2, 4, 7, 12
  final List<String> perkHighlights;

  const LogisticsFleetTier({
    required this.tierNumber,
    required this.name,
    required this.description,
    required this.emoji,
    required this.upgradeCost,
    required this.speedMultiplier,
    required this.maxSimultaneousShipments,
    required this.perkHighlights,
  });
}

// Phase 4: R&D Lab & Technology Tree Models
enum TechBranch {
  materialScience,
  factoryOverclocking,
  logisticsOptimization,
}

extension TechBranchExtension on TechBranch {
  String get displayName {
    switch (this) {
      case TechBranch.materialScience:
        return 'Material Science';
      case TechBranch.factoryOverclocking:
        return 'Factory Overclocking';
      case TechBranch.logisticsOptimization:
        return 'Logistics Optimization';
    }
  }

  String get emoji {
    switch (this) {
      case TechBranch.materialScience:
        return '🧬';
      case TechBranch.factoryOverclocking:
        return '⚡';
      case TechBranch.logisticsOptimization:
        return '🚀';
    }
  }
}

class TechLevelInfo {
  final int level;
  final String title;
  final String description;
  final int rpCost;
  final int requiredFactoryTier;
  final double perkValue;

  const TechLevelInfo({
    required this.level,
    required this.title,
    required this.description,
    required this.rpCost,
    required this.requiredFactoryTier,
    required this.perkValue,
  });
}

class TechNode {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final TechBranch branch;
  final List<TechLevelInfo> levels;

  const TechNode({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.branch,
    required this.levels,
  });

  int get maxLevel => levels.length;

  TechLevelInfo? getLevelInfo(int level) {
    if (level <= 0 || level > levels.length) return null;
    return levels[level - 1];
  }

  TechLevelInfo? getNextLevelInfo(int currentLevel) {
    if (currentLevel >= levels.length) return null;
    return levels[currentLevel];
  }
}

