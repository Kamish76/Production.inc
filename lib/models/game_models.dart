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
