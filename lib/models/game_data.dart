import 'game_models.dart';

// Production.INC Game Data - starting with cardboard -> box

class GameData {
  // Foundation materials (as specified in concept)
  static const List<Material> materials = [
    Material(
      id: 'cardboard',
      name: 'Cardboard',
      description: 'Basic material for making boxes',
      buyPrice: 1.0,
      emoji: '📄',
    ),

    // Phase 1: Base materials for speaker production (wood removed)
    Material(
      id: 'basic_metals',
      name: 'Basic Metals',
      description: 'Iron, steel, copper - essential for wires and circuits',
      buyPrice: 3.0,
      emoji: '🔩',
    ),
    Material(
      id: 'advanced_metals',
      name: 'Advanced Metals',
      description: 'Specialized alloys and rare metals for magnets and drivers',
      buyPrice: 8.0,
      emoji: '⚡',
    ),
    Material(
      id: 'plastic',
      name: 'Plastic',
      description: 'Versatile polymer for insulation and housings',
      buyPrice: 2.0,
      emoji: '🧱',
    ),

    // v1.4.0 Phase 1: New material
    Material(
      id: 'glass',
      name: 'Glass',
      description: 'Glass sheets for screens and lenses',
      buyPrice: 5.0,
      emoji: '🪟',
    ),
  ];

  // Foundation products (as specified in concept)
  static const List<Product> products = [
    // Original foundation product
    Product(
      id: 'box',
      name: 'Box',
      description: 'Simple cardboard box',
      sellPrice: 4.0,
      emoji: '📦',
      requiredMaterials: {'cardboard': 3},
      productionTimeSeconds: 3.0,
      baseShippingTimeSeconds: 2.0,
      levelId: ProductLevel.basicParts,
    ),

    // Phase 1: Basic parts for speaker production
    Product(
      id: 'wires',
      name: 'Wires',
      description: 'Insulated copper wires for electrical connections',
      sellPrice: 9.0,
      emoji: '🔌',
      requiredMaterials: {'basic_metals': 2, 'plastic': 1},
      productionTimeSeconds: 5.0,
      baseShippingTimeSeconds: 3.0,
      levelId: ProductLevel.basicParts,
    ),
    Product(
      id: 'circuits',
      name: 'Circuits',
      description: 'Basic electronic circuits and circuit boards',
      sellPrice: 15.0,
      emoji: '💾',
      requiredMaterials: {'basic_metals': 3, 'plastic': 2},
      productionTimeSeconds: 5.0,
      baseShippingTimeSeconds: 4.0,
      levelId: ProductLevel.basicParts,
    ),
    Product(
      id: 'enclosure_plastic',
      name: 'Plastic Enclosure',
      description: 'Durable plastic housing for electronics',
      sellPrice: 10.0,
      emoji: '📱',
      requiredMaterials: {'plastic': 4},
      productionTimeSeconds: 6.0,
      baseShippingTimeSeconds: 3.5,
      levelId: ProductLevel.basicParts,
    ),
    Product(
      id: 'sound_driver',
      name: 'Sound Driver',
      description: 'High-quality speaker driver with magnetic assembly',
      sellPrice: 22.0,
      emoji: '🔊',
      requiredMaterials: {'advanced_metals': 2, 'basic_metals': 1},
      productionTimeSeconds: 15.0,
      baseShippingTimeSeconds: 6.0,
      levelId: ProductLevel.basicParts,
    ),

    // v1.4.0 Phase 1: New basic parts
    Product(
      id: 'metal_enclosure',
      name: 'Metal Enclosure',
      description: 'Durable metal housing',
      sellPrice: 9.0,
      emoji: '🏠',
      requiredMaterials: {'basic_metals': 2, 'plastic': 1},
      productionTimeSeconds: 7.0,
      baseShippingTimeSeconds: 3.0,
      levelId: ProductLevel.basicParts,
    ),
    Product(
      id: 'lens',
      name: 'Lens',
      description: 'Precision glass lens',
      sellPrice: 24.0,
      emoji: '🔍',
      requiredMaterials: {'glass': 1, 'advanced_metals': 2},
      productionTimeSeconds: 10.0,
      baseShippingTimeSeconds: 4.0,
      levelId: ProductLevel.basicParts,
    ),
    Product(
      id: 'battery',
      name: 'Battery',
      description: 'Rechargeable battery pack',
      sellPrice: 23.0,
      emoji: '🔋',
      requiredMaterials: {'advanced_metals': 2, 'plastic': 1, 'wires': 1},
      productionTimeSeconds: 12.0,
      baseShippingTimeSeconds: 5.0,
      levelId: ProductLevel.basicParts,
    ),

    // v1.4.0 Phase 1: New intermediate parts
    Product(
      id: 'display_screen',
      name: 'Display Screen',
      description: 'LCD/LED display',
      sellPrice: 77.0,
      emoji: '📺',
      requiredMaterials: {
        'glass': 2,
        'circuits': 1,
        'metal_enclosure': 1,
        'wires': 1,
      },
      productionTimeSeconds: 20.0,
      baseShippingTimeSeconds: 8.0,
      levelId: ProductLevel.intermediate,
    ),
    Product(
      id: 'processor',
      name: 'Processor',
      description: 'Electronic processor unit',
      sellPrice: 98.0,
      emoji: '🖥️',
      requiredMaterials: {
        'advanced_metals': 3,
        'circuits': 2,
        'enclosure_plastic': 1,
        'wires': 2,
      },
      productionTimeSeconds: 25.0,
      baseShippingTimeSeconds: 10.0,
      levelId: ProductLevel.intermediate,
    ),

    // Phase 3: Retail products - Speaker (plastic only)
    Product(
      id: 'speaker',
      name: 'Speaker',
      description: 'High-quality speaker with plastic enclosure',
      sellPrice: 146.0,
      emoji: '🔈',
      requiredMaterials: {
        'wires': 2,
        'circuits': 1,
        'sound_driver': 1,
        'enclosure_plastic': 1,
        'box': 2, // Added packaging requirement
      },
      productionTimeSeconds: 25.0,
      baseShippingTimeSeconds: 8.0,
      levelId: ProductLevel.retail,
    ),

    // v1.4.0 Phase 1: New retail products
    Product(
      id: 'power_bank',
      name: 'Power Bank',
      description: 'Portable battery charger',
      sellPrice: 169.0,
      emoji: '🔌',
      requiredMaterials: {
        'circuits': 1,
        'enclosure_plastic': 1,
        'basic_metals': 1,
        'wires': 1,
        'battery': 2,
        'box': 1, // Added packaging requirement
      },
      productionTimeSeconds: 35.0,
      baseShippingTimeSeconds: 12.0,
      levelId: ProductLevel.retail,
    ),

    // v1.4.1 Phase 2: New basic parts - Advanced Components
    Product(
      id: 'solar_cells',
      name: 'Solar Cells',
      description: 'Photovoltaic cells for renewable energy',
      sellPrice: 38.0,
      emoji: '☀️',
      requiredMaterials: {'advanced_metals': 2, 'glass': 2, 'wires': 1},
      productionTimeSeconds: 15.0,
      baseShippingTimeSeconds: 6.0,
      levelId: ProductLevel.basicParts,
    ),

    // v1.4.17: New basic part - Mechanical Systems
    Product(
      id: 'gears',
      name: 'Gears',
      description: 'Precision mechanical gears for clockwork mechanisms',
      sellPrice: 5.0,
      emoji: '⚙️',
      requiredMaterials: {'basic_metals': 1},
      productionTimeSeconds: 2.0,
      baseShippingTimeSeconds: 1.0,
      levelId: ProductLevel.basicParts,
    ),

    // v1.4.1 Phase 2: New intermediate parts
    Product(
      id: 'image_sensor',
      name: 'Image Sensor',
      description: 'Digital camera sensor',
      sellPrice: 149.0,
      emoji: '📸',
      requiredMaterials: {
        'advanced_metals': 3,
        'circuits': 2,
        'lens': 1,
        'wires': 2,
      },
      productionTimeSeconds: 30.0,
      baseShippingTimeSeconds: 12.0,
      levelId: ProductLevel.intermediate,
    ),

    // v1.4.17: New intermediate part - Mechanical Systems
    Product(
      id: 'gear_mechanism',
      name: 'Gear Mechanism',
      description: 'Precision clockwork mechanism with springs and gears',
      sellPrice: 25.0,
      emoji: '🕰️',
      requiredMaterials: {'gears': 2, 'advanced_metals': 1, 'basic_metals': 1},
      productionTimeSeconds: 15.0,
      baseShippingTimeSeconds: 6.0,
      levelId: ProductLevel.intermediate,
    ),

    // v1.4.1 Phase 2: New retail products
    Product(
      id: 'solar_panel',
      name: 'Solar Panel',
      description: 'Solar power generator',
      sellPrice: 250.0,
      emoji: '🌞',
      requiredMaterials: {
        'circuits': 2,
        'metal_enclosure': 1,
        'basic_metals': 1,
        'wires': 2,
        'solar_cells': 3,
        'box': 4, // Added packaging requirement
      },
      productionTimeSeconds: 45.0,
      baseShippingTimeSeconds: 15.0,
      levelId: ProductLevel.retail,
    ),

    // v1.4.2 Phase 3: New complex parts
    Product(
      id: 'camera_module',
      name: 'Camera Module',
      description: 'Complete camera system',
      sellPrice: 330.0,
      emoji: '📷',
      requiredMaterials: {
        'lens': 1,
        'image_sensor': 1,
        'processor': 1,
        'battery': 1,
        'metal_enclosure': 1,
        'wires': 2,
      },
      productionTimeSeconds: 50.0,
      baseShippingTimeSeconds: 18.0,
      levelId: ProductLevel.complex,
    ),

    // v1.4.2 Phase 3: New retail products
    Product(
      id: 'camera',
      name: 'Digital Camera',
      description: 'Digital camera device',
      sellPrice: 353.0,
      emoji: '📹',
      requiredMaterials: {
        'circuits': 1,
        'processor': 1,
        'metal_enclosure': 1,
        'basic_metals': 1,
        'wires': 1,
        'battery': 1,
        'image_sensor': 1,
        'box': 2, // Added packaging requirement
      },
      productionTimeSeconds: 60.0,
      baseShippingTimeSeconds: 22.0,
      levelId: ProductLevel.retail,
    ),

    // v1.4.3 Phase 4: Premium Products
    Product(
      id: 'smartphone',
      name: 'Smartphone',
      description: 'Advanced mobile device',
      sellPrice: 765.0,
      emoji: '📱',
      requiredMaterials: {
        'circuits': 2,
        'processor': 1,
        'metal_enclosure': 1,
        'basic_metals': 2,
        'wires': 3,
        'battery': 1,
        'sound_driver': 1,
        'display_screen': 1,
        'enclosure_plastic': 1,
        'camera_module': 1,
        'box': 1, // Added packaging requirement
      },
      productionTimeSeconds: 90.0,
      baseShippingTimeSeconds: 35.0,
      levelId: ProductLevel.retail,
    ),

    // v1.4.17 Phase 1: Mechanical System - Retail Products
    Product(
      id: 'wall_clock',
      name: 'Analog Wall Clock',
      description: 'Classic analog timepiece with gear mechanism',
      sellPrice: 74.0,
      emoji: '🕰️',
      requiredMaterials: {
        'gear_mechanism': 1,
        'metal_enclosure': 1,
        'enclosure_plastic': 1,
        'plastic': 1,
        'box': 1,
      },
      productionTimeSeconds: 31.0,
      baseShippingTimeSeconds: 12.0,
      levelId: ProductLevel.retail,
    ),

    Product(
      id: 'toy_robot',
      name: 'Toy Robot',
      description: 'Interactive mechanical toy with gear movement',
      sellPrice: 154.0,
      emoji: '🤖',
      requiredMaterials: {
        'gears': 3,
        'circuits': 1,
        'battery': 1,
        'enclosure_plastic': 2,
        'wires': 2,
        'box': 2,
      },
      productionTimeSeconds: 54.0,
      baseShippingTimeSeconds: 22.0,
      levelId: ProductLevel.retail,
    ),
  ];

  // Future machines for automation
  static const List<Machine> machines = [
    Machine(
      id: 'buyer',
      name: 'Auto Materials Buyer',
      description:
          'Automatically buys materials based on set amount per item, per machine can only buy 10 materials per item',
      requiredMaterials: {'box': 5},
      emoji: '🤖',
      type: MachineType.materialBuyer,
    ),
    Machine(
      id: 'basic_assembler',
      name: 'Basic parts manufacturer',
      description: 'Auto produces basic parts until a set amount is reached',
      requiredMaterials: {'box': 10},
      emoji: '🏭',
      type: MachineType.producer,
    ),
    Machine(
      id: 'basic_seller',
      name: 'Basic parts seller',
      description: 'Sells surplus basic parts automatically',
      requiredMaterials: {'box': 7},
      emoji: '🛒',
      type: MachineType.seller,
    ),
  ];

  // Helper methods to find items by ID
  static Material? getMaterial(String id) {
    try {
      return materials.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  static Product? getProduct(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  static Machine? getMachine(String id) {
    try {
      return machines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  // Helper methods to filter products by level
  static List<Product> getProductsByLevel(ProductLevel level) {
    return products.where((p) => p.levelId == level).toList();
  }

  static List<Product> getMaterialProducts() =>
      getProductsByLevel(ProductLevel.material);
  static List<Product> getBasicPartsProducts() =>
      getProductsByLevel(ProductLevel.basicParts);
  static List<Product> getIntermediateProducts() =>
      getProductsByLevel(ProductLevel.intermediate);
  static List<Product> getComplexProducts() =>
      getProductsByLevel(ProductLevel.complex);
  static List<Product> getRetailProducts() =>
      getProductsByLevel(ProductLevel.retail);

  // Helper to get level name as string
  static String getLevelName(ProductLevel level) {
    switch (level) {
      case ProductLevel.material:
        return 'Material';
      case ProductLevel.basicParts:
        return 'Basic Parts';
      case ProductLevel.intermediate:
        return 'Intermediate';
      case ProductLevel.complex:
        return 'Complex';
      case ProductLevel.retail:
        return 'Retail';
    }
  }
}
