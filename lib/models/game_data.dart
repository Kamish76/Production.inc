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
      industryBranch: IndustryBranch.cleanEnergy,
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
      industryBranch: IndustryBranch.cleanEnergy,
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
      industryBranch: IndustryBranch.cleanEnergy,
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
      industryBranch: IndustryBranch.robotics,
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
      industryBranch: IndustryBranch.robotics,
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
      industryBranch: IndustryBranch.cleanEnergy,
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
      industryBranch: IndustryBranch.robotics,
    ),

    // =========================================================================
    // Phase 3: Robotics & Smart Automation Branch
    // =========================================================================

    // Basic Parts (Base Feedstocks)
    Product(
      id: 'silicon_wafer',
      name: 'Silicon Wafer',
      description: 'Ultra-pure crystallized silicon disc sliced for microchips',
      sellPrice: 32.0,
      emoji: '💿',
      requiredMaterials: {'glass': 2, 'advanced_metals': 1},
      productionTimeSeconds: 12.0,
      baseShippingTimeSeconds: 5.0,
      levelId: ProductLevel.basicParts,
      industryBranch: IndustryBranch.robotics,
    ),

    Product(
      id: 'copper_coils',
      name: 'Copper Coils',
      description: 'High-conductivity electromagnetic copper windings',
      sellPrice: 12.0,
      emoji: '🧲',
      requiredMaterials: {'basic_metals': 2},
      productionTimeSeconds: 4.0,
      baseShippingTimeSeconds: 2.0,
      levelId: ProductLevel.basicParts,
      industryBranch: IndustryBranch.robotics,
    ),

    // Intermediate Mechatronic Parts
    Product(
      id: 'servo_motor',
      name: 'Servo Motor',
      description: 'High-torque precision motorized actuator for robotic joints',
      sellPrice: 78.0,
      emoji: '🦾',
      requiredMaterials: {
        'copper_coils': 2,
        'gears': 2,
        'circuits': 1,
      },
      productionTimeSeconds: 18.0,
      baseShippingTimeSeconds: 7.0,
      levelId: ProductLevel.intermediate,
      industryBranch: IndustryBranch.robotics,
    ),

    Product(
      id: 'microcontroller',
      name: 'Microcontroller',
      description: 'Embedded computing unit with logic gates and integrated flash',
      sellPrice: 115.0,
      emoji: '🔲',
      requiredMaterials: {
        'silicon_wafer': 1,
        'circuits': 2,
        'wires': 2,
      },
      productionTimeSeconds: 22.0,
      baseShippingTimeSeconds: 8.0,
      levelId: ProductLevel.intermediate,
      industryBranch: IndustryBranch.robotics,
    ),

    Product(
      id: 'chassis_alloy',
      name: 'Chassis Alloy',
      description: 'Lightweight reinforced structural alloy frame',
      sellPrice: 65.0,
      emoji: '🛡️',
      requiredMaterials: {
        'metal_enclosure': 1,
        'advanced_metals': 2,
        'basic_metals': 2,
      },
      productionTimeSeconds: 20.0,
      baseShippingTimeSeconds: 8.0,
      levelId: ProductLevel.intermediate,
      industryBranch: IndustryBranch.robotics,
    ),

    // Robotics Retail Products
    Product(
      id: 'cleaning_drone',
      name: 'Cleaning Drone',
      description: 'Autonomous smart vacuum drone with lidar mapping',
      sellPrice: 480.0,
      emoji: '🛸',
      requiredMaterials: {
        'chassis_alloy': 1,
        'microcontroller': 1,
        'servo_motor': 2,
        'battery': 1,
        'box': 2,
      },
      productionTimeSeconds: 65.0,
      baseShippingTimeSeconds: 25.0,
      levelId: ProductLevel.retail,
      industryBranch: IndustryBranch.robotics,
    ),

    Product(
      id: 'robotic_arm',
      name: 'Robotic Arm',
      description: 'Multi-axis precision industrial manipulator for automated assembly',
      sellPrice: 1250.0,
      emoji: '🤖',
      requiredMaterials: {
        'chassis_alloy': 2,
        'servo_motor': 4,
        'microcontroller': 2,
        'gear_mechanism': 1,
        'box': 4,
      },
      productionTimeSeconds: 110.0,
      baseShippingTimeSeconds: 45.0,
      levelId: ProductLevel.retail,
      industryBranch: IndustryBranch.robotics,
    ),

    // =========================================================================
    // Phase 3: Renewable Energy & Grid Storage Branch
    // =========================================================================

    // Intermediate Power Hardware
    Product(
      id: 'inverter_unit',
      name: 'Inverter Unit',
      description: 'High-efficiency DC-to-AC pure sine power converter',
      sellPrice: 92.0,
      emoji: '⚡',
      requiredMaterials: {
        'copper_coils': 2,
        'circuits': 2,
        'wires': 2,
        'metal_enclosure': 1,
      },
      productionTimeSeconds: 24.0,
      baseShippingTimeSeconds: 9.0,
      levelId: ProductLevel.intermediate,
      industryBranch: IndustryBranch.cleanEnergy,
    ),

    Product(
      id: 'storage_cell',
      name: 'Storage Cell',
      description: 'High-density solid-state electrochemical energy cell',
      sellPrice: 120.0,
      emoji: '🪫',
      requiredMaterials: {
        'battery': 2,
        'advanced_metals': 2,
        'enclosure_plastic': 1,
      },
      productionTimeSeconds: 28.0,
      baseShippingTimeSeconds: 10.0,
      levelId: ProductLevel.intermediate,
      industryBranch: IndustryBranch.cleanEnergy,
    ),

    // Renewable Energy Retail Products
    Product(
      id: 'home_powerwall',
      name: 'Home Powerwall',
      description: 'Whole-home smart backup battery and energy management system',
      sellPrice: 850.0,
      emoji: '🔋',
      requiredMaterials: {
        'storage_cell': 3,
        'inverter_unit': 1,
        'metal_enclosure': 2,
        'box': 3,
      },
      productionTimeSeconds: 80.0,
      baseShippingTimeSeconds: 32.0,
      levelId: ProductLevel.retail,
      industryBranch: IndustryBranch.cleanEnergy,
    ),

    Product(
      id: 'wind_turbine_generator',
      name: 'Wind Turbine Generator',
      description: 'Commercial clean energy wind generator with variable pitch blades',
      sellPrice: 2100.0,
      emoji: '💨',
      requiredMaterials: {
        'copper_coils': 4,
        'inverter_unit': 2,
        'gear_mechanism': 2,
        'chassis_alloy': 2,
        'box': 5,
      },
      productionTimeSeconds: 140.0,
      baseShippingTimeSeconds: 55.0,
      levelId: ProductLevel.retail,
      industryBranch: IndustryBranch.cleanEnergy,
    ),

    // =========================================================================
    // Phase 5: Prestige Prototype Product Line
    // =========================================================================
    Product(
      id: 'quantum_processor',
      name: 'Quantum Processor',
      description: 'Superconducting qubit processing unit operating near absolute zero',
      sellPrice: 1800.0,
      emoji: '💠',
      requiredMaterials: {
        'microcontroller': 2,
        'silicon_wafer': 2,
        'advanced_metals': 3,
      },
      productionTimeSeconds: 24.0,
      baseShippingTimeSeconds: 10.0,
      levelId: ProductLevel.intermediate,
      industryBranch: IndustryBranch.consumerTech,
      isPrototype: true,
    ),

    Product(
      id: 'quantum_core',
      name: 'Quantum Core',
      description: 'Zero-point magnetic confinement clean energy reactor cell',
      sellPrice: 4200.0,
      emoji: '⚛️',
      requiredMaterials: {
        'quantum_processor': 1,
        'storage_cell': 3,
        'copper_coils': 2,
      },
      productionTimeSeconds: 32.0,
      baseShippingTimeSeconds: 14.0,
      levelId: ProductLevel.complex,
      industryBranch: IndustryBranch.cleanEnergy,
      isPrototype: true,
    ),

    Product(
      id: 'orbital_satellite',
      name: 'Orbital Satellite',
      description: 'Commercial micro-satellite payload with quantum communications array',
      sellPrice: 18500.0,
      emoji: '🛰️',
      requiredMaterials: {
        'quantum_processor': 1,
        'quantum_core': 1,
        'chassis_alloy': 2,
        'solar_panel': 2,
        'box': 5,
      },
      productionTimeSeconds: 55.0,
      baseShippingTimeSeconds: 25.0,
      levelId: ProductLevel.retail,
      industryBranch: IndustryBranch.robotics,
      isPrototype: true,
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

  // Phase 3: Helper methods to filter products by industry branch
  static List<Product> getProductsByBranch(IndustryBranch branch) {
    return products.where((p) => p.industryBranch == branch).toList();
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

  // Factory Tiers configuration (Phase 1)
  static const List<FactoryTier> factoryTiers = [
    FactoryTier(
      tierNumber: 1,
      name: 'Garage Workshop',
      description: 'Small-scale manual crafting & basic parts production',
      emoji: '🏚️',
      upgradeCost: 0.0,
      autoBuyCapacityLimit: 25,
      perkHighlights: [
        'Manual crafting of basic components',
        'Auto-buy capacity up to 25 units',
        'Tier 1 Auto-build supported',
      ],
      allowedProductLevels: {
        ProductLevel.material,
        ProductLevel.basicParts,
      },
    ),
    FactoryTier(
      tierNumber: 2,
      name: 'Light Assembly Facility',
      description: 'Commercial facility with intermediate sub-assemblies',
      emoji: '🏭',
      upgradeCost: 2500.0,
      requiredShippedProducts: {
        'box': 20,
        'wires': 15,
      },
      autoBuyCapacityLimit: 50,
      perkHighlights: [
        'Unlocks Intermediate Parts (Displays, Processors, Motors, Inverters)',
        'Unlocks entry Retail items (Speaker, Power Bank, Wall Clock, Cleaning Drone)',
        'Auto-buy capacity increased to 50 units',
      ],
      allowedProductLevels: {
        ProductLevel.material,
        ProductLevel.basicParts,
        ProductLevel.intermediate,
        ProductLevel.retail,
      },
    ),
    FactoryTier(
      tierNumber: 3,
      name: 'Precision Tech Plant',
      description: 'High-precision manufacturing with cleanroom assembly',
      emoji: '🔬',
      upgradeCost: 25000.0,
      requiredShippedProducts: {
        'speaker': 25,
        'battery': 20,
      },
      autoBuyCapacityLimit: 100,
      perkHighlights: [
        'Unlocks Complex Parts (Camera Modules)',
        'Unlocks advanced Retail items (Cameras, Solar Panels, Powerwalls, Robotic Arms)',
        'Tier 2 Auto-build supported',
        'Auto-buy capacity increased to 100 units',
      ],
      allowedProductLevels: {
        ProductLevel.material,
        ProductLevel.basicParts,
        ProductLevel.intermediate,
        ProductLevel.complex,
        ProductLevel.retail,
      },
    ),
    FactoryTier(
      tierNumber: 4,
      name: 'Megafactory Cleanroom',
      description: 'State-of-the-art enterprise flagship production line',
      emoji: '🚀',
      upgradeCost: 150000.0,
      requiredShippedProducts: {
        'smartphone': 50,
        'solar_panel': 30,
      },
      autoBuyCapacityLimit: 250,
      perkHighlights: [
        'Unlocks Flagship Retail items (Smartphone, Wind Turbine Generator)',
        'Tier 3 Auto-build supported',
        'Auto-buy capacity increased to 250 units',
        'Maximum automation throughput',
      ],
      allowedProductLevels: {
        ProductLevel.material,
        ProductLevel.basicParts,
        ProductLevel.intermediate,
        ProductLevel.complex,
        ProductLevel.retail,
      },
    ),
  ];

  static FactoryTier getFactoryTier(int tierNumber) {
    return factoryTiers.firstWhere(
      (t) => t.tierNumber == tierNumber,
      orElse: () => factoryTiers.first,
    );
  }

  static FactoryTier? getNextFactoryTier(int currentTierNumber) {
    try {
      return factoryTiers.firstWhere((t) => t.tierNumber == currentTierNumber + 1);
    } catch (_) {
      return null;
    }
  }

  // Phase 2: Corporate Clients Catalog
  static const List<CorporateClient> corporateClients = [
    CorporateClient(
      id: 'apex_telecom',
      name: 'Apex Telecom',
      tagline: 'Global Mobile & Connectivity Infrastructure',
      description:
          'Apex supplies worldwide network communications and seeks bulk consumer electronic units.',
      emoji: '📡',
      primaryColorHex: 0xFF00E5FF,
      discountMaterialIds: ['plastic', 'advanced_metals'],
      demandedProductIds: [
        'wires',
        'circuits',
        'display_screen',
        'processor',
        'power_bank',
        'smartphone',
        'speaker',
        'silicon_wafer',
        'microcontroller',
      ],
    ),
    CorporateClient(
      id: 'solaria_energy',
      name: 'Solaria Energy',
      tagline: 'Clean Energy & Smart Grid Solutions',
      description:
          'Solaria leads the transition to sustainable energy, contracting for battery units and solar hardware.',
      emoji: '☀️',
      primaryColorHex: 0xFFFFB300,
      discountMaterialIds: ['glass', 'basic_metals'],
      demandedProductIds: [
        'battery',
        'solar_cells',
        'solar_panel',
        'circuits',
        'inverter_unit',
        'storage_cell',
        'home_powerwall',
        'wind_turbine_generator',
      ],
    ),
    CorporateClient(
      id: 'nova_robotics',
      name: 'Nova Robotics',
      tagline: 'Industrial Automation & Mechatronics',
      description:
          'Nova engineers cutting-edge robotics and requires precision sensors, gears, and smart actuators.',
      emoji: '🤖',
      primaryColorHex: 0xFFB388FF,
      discountMaterialIds: ['basic_metals', 'cardboard'],
      demandedProductIds: [
        'gears',
        'gear_mechanism',
        'camera_module',
        'toy_robot',
        'lens',
        'copper_coils',
        'servo_motor',
        'microcontroller',
        'chassis_alloy',
        'cleaning_drone',
        'robotic_arm',
      ],
    ),
  ];

  static CorporateClient? getCorporateClient(String id) {
    try {
      return corporateClients.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // Phase 2: Logistics Fleet Tiers Catalog
  static const List<LogisticsFleetTier> fleetTiers = [
    LogisticsFleetTier(
      tierNumber: 1,
      name: 'Courier Bikes',
      description: 'Nimble city bicycle couriers for rapid local parcels',
      emoji: '🚲',
      upgradeCost: 0.0,
      speedMultiplier: 1.0,
      maxSimultaneousShipments: 2,
      perkHighlights: [
        'Starting delivery fleet',
        '2 concurrent shipping dispatches',
      ],
    ),
    LogisticsFleetTier(
      tierNumber: 2,
      name: 'Delivery Vans',
      description: 'Commercial cargo vans equipped for express suburban delivery',
      emoji: '🚐',
      upgradeCost: 1500.0,
      speedMultiplier: 1.25,
      maxSimultaneousShipments: 4,
      perkHighlights: [
        '+25% shipping speed',
        '4 concurrent shipping dispatches',
      ],
    ),
    LogisticsFleetTier(
      tierNumber: 3,
      name: 'Freight Trucks',
      description:
          'Heavy-duty commercial semi-trucks for high-volume regional transport',
      emoji: '🚚',
      upgradeCost: 12500.0,
      speedMultiplier: 1.6,
      maxSimultaneousShipments: 7,
      perkHighlights: [
        '+60% shipping speed',
        '7 concurrent shipping dispatches',
      ],
    ),
    LogisticsFleetTier(
      tierNumber: 4,
      name: 'Cargo Planes',
      description:
          'Dedicated air freight logistics network for instant mass shipping',
      emoji: '✈️',
      upgradeCost: 75000.0,
      speedMultiplier: 2.5,
      maxSimultaneousShipments: 12,
      perkHighlights: [
        '+150% shipping speed',
        '12 concurrent shipping dispatches',
      ],
    ),
  ];

  static LogisticsFleetTier getFleetTier(int tierNumber) {
    return fleetTiers.firstWhere(
      (f) => f.tierNumber == tierNumber,
      orElse: () => fleetTiers.first,
    );
  }

  static LogisticsFleetTier? getNextFleetTier(int currentTierNumber) {
    try {
      return fleetTiers.firstWhere((f) => f.tierNumber == currentTierNumber + 1);
    } catch (_) {
      return null;
    }
  }

  // Phase 4: Technology Tree Definitions
  static const List<TechNode> technologies = [
    TechNode(
      id: 'material_science',
      name: 'Material Science',
      description:
          'Quantum alloy bonding and molecular replication to duplicate manufactured outputs.',
      emoji: '🧬',
      branch: TechBranch.materialScience,
      levels: [
        TechLevelInfo(
          level: 1,
          title: 'Molecular Recycling',
          description:
              '5% chance to duplicate an assembled product without consuming input materials.',
          rpCost: 50,
          requiredFactoryTier: 1,
          perkValue: 0.05,
        ),
        TechLevelInfo(
          level: 2,
          title: 'Catalytic Synthesis',
          description:
              '10% chance to duplicate an assembled product without consuming input materials.',
          rpCost: 150,
          requiredFactoryTier: 2,
          perkValue: 0.10,
        ),
        TechLevelInfo(
          level: 3,
          title: 'Zero-Point Replicator',
          description:
              '15% chance to duplicate an assembled product without consuming input materials.',
          rpCost: 400,
          requiredFactoryTier: 3,
          perkValue: 0.15,
        ),
      ],
    ),
    TechNode(
      id: 'factory_overclocking',
      name: 'Factory Overclocking',
      description:
          'Supercharge machine servos for accelerated production with periodic maintenance checkups.',
      emoji: '⚡',
      branch: TechBranch.factoryOverclocking,
      levels: [
        TechLevelInfo(
          level: 1,
          title: 'Tuned Actuators',
          description: 'Permanently accelerates production speeds by +15%.',
          rpCost: 75,
          requiredFactoryTier: 1,
          perkValue: 1.15,
        ),
        TechLevelInfo(
          level: 2,
          title: 'Coolant Overdrive',
          description:
              'Accelerates production speeds by +25%. Unlocks Overclock toggle in R&D Lab.',
          rpCost: 200,
          requiredFactoryTier: 2,
          perkValue: 1.25,
        ),
        TechLevelInfo(
          level: 3,
          title: 'Plasma Turbocharging',
          description:
              'Accelerates production speeds by +40% with heavy-duty thermal insulation.',
          rpCost: 500,
          requiredFactoryTier: 3,
          perkValue: 1.40,
        ),
      ],
    ),
    TechNode(
      id: 'logistics_optimization',
      name: 'Logistics Optimization',
      description:
          'Autonomous freight scheduling and quantum dispatch algorithms for lightning shipping.',
      emoji: '🚀',
      branch: TechBranch.logisticsOptimization,
      levels: [
        TechLevelInfo(
          level: 1,
          title: 'Priority Dispatch',
          description:
              'Shipping transit times reduced by 15% across all shipments.',
          rpCost: 60,
          requiredFactoryTier: 1,
          perkValue: 1.15,
        ),
        TechLevelInfo(
          level: 2,
          title: 'Dynamic Courier Fast-Track',
          description:
              'Shipping transit times reduced by 30% + corporate contracts receive extra 25% transit speed.',
          rpCost: 175,
          requiredFactoryTier: 2,
          perkValue: 1.30,
        ),
        TechLevelInfo(
          level: 3,
          title: 'Quantum Hyperlane Logistics',
          description:
              'Shipping transit times reduced by 40% + corporate fast-track + 1 extra concurrent dispatch slot.',
          rpCost: 450,
          requiredFactoryTier: 3,
          perkValue: 1.40,
        ),
      ],
    ),
  ];

  static TechNode? getTechnology(String techId) {
    try {
      return technologies.firstWhere((t) => t.id == techId);
    } catch (_) {
      return null;
    }
  }

  // Phase 4: Product Research Point Valuations (Deconstruction Yield)
  static const Map<String, int> productResearchPoints = {
    // Basic Parts
    'box': 1,
    'wires': 2,
    'gears': 3,
    'copper_coils': 2,
    'silicon_wafer': 4,
    'sound_driver': 4,
    'lens': 3,

    // Intermediate Parts
    'circuits': 6,
    'enclosure_plastic': 5,
    'metal_enclosure': 7,
    'display_screen': 8,
    'processor': 10,
    'image_sensor': 9,
    'gear_mechanism': 8,
    'servo_motor': 9,
    'microcontroller': 14,
    'chassis_alloy': 8,
    'inverter_unit': 12,
    'storage_cell': 15,

    // Complex Parts & Retail
    'camera_module': 16,
    'battery': 12,
    'solar_cells': 10,
    'speaker': 20,
    'power_bank': 28,
    'wall_clock': 24,
    'toy_robot': 30,
    'camera': 45,
    'cleaning_drone': 45,
    'solar_panel': 55,
    'home_powerwall': 90,
    'robotic_arm': 130,
    'smartphone': 180,
    'wind_turbine_generator': 250,
    // Phase 5: Prototypes
    'quantum_processor': 120,
    'quantum_core': 260,
    'orbital_satellite': 600,
  };

  static int getResearchPointsForProduct(String productId) {
    return productResearchPoints[productId] ?? 1;
  }

  // =========================================================================
  // Phase 5: Prestige / Venture Capital Perks Catalog
  // =========================================================================
  static const List<PrestigePerk> prestigePerks = [
    PrestigePerk(
      id: 'instant_machines',
      name: 'Instant Machine Licensing',
      description: 'Acquire auto-buy and auto-build machinery immediately without tier prerequisites.',
      emoji: '⚙️',
      goldenShareCost: 5,
      perkHighlights: [
        'Immediate auto-buy machine purchases',
        'Immediate auto-build machine assembly',
        'Bypass factory tier machine gating',
      ],
    ),
    PrestigePerk(
      id: 'prototype_blueprints',
      name: 'Prototype Tech Blueprints',
      description: 'Unlock exclusive high-margin prototype line: Quantum Processor, Quantum Core, and Orbital Satellite.',
      emoji: '🔬',
      goldenShareCost: 10,
      perkHighlights: [
        'Unlocks 3 cutting-edge prototype products',
        'Industry-leading profit margins',
        'Orbital Satellite sells for \$18,500/unit',
      ],
    ),
    PrestigePerk(
      id: 'angel_seed_capital',
      name: 'Angel Investor Seed Capital',
      description: 'Begin all post-IPO production runs with \$2,500.00 cash instead of \$100.00.',
      emoji: '💼',
      goldenShareCost: 8,
      perkHighlights: [
        '\$2,500.00 starting cash per run',
        'Instant early-game bootstrapping',
        'Rapid first-hour expansion',
      ],
    ),
    PrestigePerk(
      id: 'quantum_warp_dispatch',
      name: 'Quantum Warp Logistics',
      description: 'Global 25% shipping transit speed reduction and +1 additional simultaneous shipment dispatch slot.',
      emoji: '🌌',
      goldenShareCost: 12,
      perkHighlights: [
        '+25% global shipping speed',
        '+1 concurrent shipment dispatch slot',
        'Stacks with fleet and tech tree bonuses',
      ],
    ),
  ];

  static PrestigePerk? getPrestigePerk(String perkId) {
    try {
      return prestigePerks.firstWhere((p) => p.id == perkId);
    } catch (_) {
      return null;
    }
  }
}

