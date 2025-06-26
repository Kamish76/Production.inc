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

// Product that can be produced and sold
class Product {
  final String id;
  final String name;
  final String description;
  final double sellPrice;
  final String emoji;
  final Map<String, int> requiredMaterials; // materialId -> quantity needed
  final double productionTimeSeconds;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.sellPrice,
    required this.emoji,
    required this.requiredMaterials,
    required this.productionTimeSeconds,
  });
}

// Machine for automation (future feature)
class Machine {
  final String id;
  final String name;
  final String description;
  final Map<String, int> requiredMaterials; // materialId -> quantity needed to craft
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
  materialBuyer,  // Auto-buys materials
  producer,       // Auto-produces items
  seller,         // Auto-sells products
}
