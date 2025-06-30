// Production.INC Game State

import 'game_models.dart';

// Represents a production task in progress
class ProductionTask {
  final String id;
  final String productId;
  final DateTime startTime;
  final double durationSeconds;
  final int quantity;

  const ProductionTask({
    required this.id,
    required this.productId,
    required this.startTime,
    required this.durationSeconds,
    required this.quantity,
  });

  bool get isCompleted {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return elapsed >= durationSeconds;
  }

  double get progress {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inMilliseconds / 1000.0;
    return (elapsed / durationSeconds).clamp(0.0, 1.0);
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

  const GameState({
    this.money = 100.0, // Starting money
    this.materials = const {},
    this.products = const {},
    this.activeProductions = const [],
    this.activeShippingOrders = const [],
    this.shippingHistory = const [],
    this.machines = const {},
  });

  GameState copyWith({
    double? money,
    Map<String, int>? materials,
    Map<String, int>? products,
    List<ProductionTask>? activeProductions,
    List<ShippingOrder>? activeShippingOrders,
    List<ShippingHistory>? shippingHistory,
    Map<String, int>? machines,
  }) {
    return GameState(
      money: money ?? this.money,
      materials: materials ?? this.materials,
      products: products ?? this.products,
      activeProductions: activeProductions ?? this.activeProductions,
      activeShippingOrders: activeShippingOrders ?? this.activeShippingOrders,
      shippingHistory: shippingHistory ?? this.shippingHistory,
      machines: machines ?? this.machines,
    );
  }

  // Helper methods
  int getMaterialCount(String materialId) => materials[materialId] ?? 0;
  int getProductCount(String productId) => products[productId] ?? 0;
  bool canAfford(double price) => money >= price;

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
}
