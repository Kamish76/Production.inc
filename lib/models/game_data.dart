import 'game_models.dart';

// Production.INC Game Data - starting with cardboard -> box

class GameData {
  // Foundation materials (as specified in concept)
  static const List<Material> materials = [
    Material(
      id: 'cardboard',
      name: 'Cardboard',
      description: 'Basic material for making boxes',
      buyPrice: 2.0,
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
      requiredMaterials: {'cardboard': 1},
      productionTimeSeconds: 3.0,
    ),
  ];

  // Future machines for automation
  static const List<Machine> machines = [
    Machine(
      id: 'cardboard_buyer',
      name: 'Auto Cardboard Buyer',
      description: 'Automatically buys cardboard materials',
      purchasePrice: 500.0,
      emoji: '🤖',
      type: MachineType.materialBuyer,
    ),
    Machine(
      id: 'box_producer',
      name: 'Box Production Machine',
      description: 'Automatically produces boxes from cardboard',
      purchasePrice: 1000.0,
      emoji: '🏭',
      type: MachineType.producer,
    ),
    Machine(
      id: 'box_seller',
      name: 'Auto Box Seller',
      description: 'Automatically sells produced boxes',
      purchasePrice: 750.0,
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
