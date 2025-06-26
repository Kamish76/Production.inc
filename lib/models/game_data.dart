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
  ];

  // Foundation products (as specified in concept)
  static const List<Product> products = [
    Product(
      id: 'box',
      name: 'Box',
      description: 'Simple cardboard box',
      sellPrice: 5.0,
      emoji: '📦',
      requiredMaterials: {'cardboard': 3},
      productionTimeSeconds: 3.0,
    ),
  ];

  // Future machines for automation
  static const List<Machine> machines = [
    Machine(
      id: 'buyer',
      name: 'Auto Materials Buyer',
      description: 'Automatically buys materials based on set amount per item, per machine can only buy 10 materials per item',
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
}
