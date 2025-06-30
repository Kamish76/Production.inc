import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';

// Production.INC Game Service - handles all game logic
class ProductionGameService extends ChangeNotifier {
  GameState _state = const GameState();
  Timer? _updateTimer;

  GameState get state => _state;

  ProductionGameService() {
    // Start update timer to check for completed productions
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      updateProductions();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  // Buy materials
  bool buyMaterial(String materialId, int quantity) {
    final material = GameData.getMaterial(materialId);
    if (material == null) return false;

    final totalCost = material.buyPrice * quantity;
    if (!_state.canAfford(totalCost)) return false;

    final newMaterials = Map<String, int>.from(_state.materials);
    newMaterials[materialId] = (newMaterials[materialId] ?? 0) + quantity;

    _state = _state.copyWith(
      money: _state.money - totalCost,
      materials: newMaterials,
    );

    notifyListeners();
    return true;
  }

  // Start production of a product
  bool startProduction(String productId, int quantity) {
    final product = GameData.getProduct(productId);
    if (product == null) return false;

    // Check if we have enough materials
    final requiredMaterials = <String, int>{};
    for (final entry in product.requiredMaterials.entries) {
      requiredMaterials[entry.key] = entry.value * quantity;
    }

    if (!_state.hasMaterialsFor(requiredMaterials)) return false;

    // Consume materials and products
    final newMaterials = Map<String, int>.from(_state.materials);
    final newProducts = Map<String, int>.from(_state.products);

    for (final entry in requiredMaterials.entries) {
      final itemId = entry.key;
      final needed = entry.value;

      // Try to consume from materials first
      final availableMaterials = newMaterials[itemId] ?? 0;
      if (availableMaterials >= needed) {
        newMaterials[itemId] = availableMaterials - needed;
        if (newMaterials[itemId]! <= 0) {
          newMaterials.remove(itemId);
        }
      } else {
        // Consume all materials first, then from products
        var remaining = needed;
        if (availableMaterials > 0) {
          newMaterials.remove(itemId);
          remaining -= availableMaterials;
        }

        // Consume remaining from products
        final availableProducts = newProducts[itemId] ?? 0;
        newProducts[itemId] = availableProducts - remaining;
        if (newProducts[itemId]! <= 0) {
          newProducts.remove(itemId);
        }
      }
    }

    // Create production task
    final task = ProductionTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: productId,
      startTime: DateTime.now(),
      durationSeconds: product.productionTimeSeconds * quantity,
      quantity: quantity,
    );

    final newProductions = List<ProductionTask>.from(_state.activeProductions);
    newProductions.add(task);

    _state = _state.copyWith(
      materials: newMaterials,
      products: newProducts,
      activeProductions: newProductions,
    );

    notifyListeners();
    return true;
  }

  // Sell products (now creates shipping orders)
  bool sellProduct(String productId, int quantity) {
    final product = GameData.getProduct(productId);
    if (product == null) return false;

    final available = _state.getProductCount(productId);
    if (available < quantity) return false;

    // Calculate shipping time using the new formula from Product model
    final totalShippingTime = product.calculateShippingTime(quantity);

    final totalRevenue = product.sellPrice * quantity;

    // Remove products from inventory
    final newProducts = Map<String, int>.from(_state.products);
    newProducts[productId] = available - quantity;
    if (newProducts[productId]! <= 0) {
      newProducts.remove(productId);
    }

    // Create shipping order
    final shippingOrder = ShippingOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: [ShippingItem(productId: productId, quantity: quantity)],
      startTime: DateTime.now(),
      totalShippingTime: totalShippingTime,
      totalRevenue: totalRevenue,
    );

    final newShippingOrders = List<ShippingOrder>.from(
      _state.activeShippingOrders,
    );
    newShippingOrders.add(shippingOrder);

    _state = _state.copyWith(
      products: newProducts,
      activeShippingOrders: newShippingOrders,
    );

    notifyListeners();
    return true;
  }

  // Check and complete finished productions and shipping orders
  void updateProductions() {
    final completedTasks = <ProductionTask>[];
    final activeTasks = <ProductionTask>[];
    final completedShipping = <ShippingOrder>[];
    final activeShipping = <ShippingOrder>[];

    // Check production tasks
    for (final task in _state.activeProductions) {
      if (task.isCompleted) {
        completedTasks.add(task);
      } else {
        activeTasks.add(task);
      }
    }

    // Check shipping orders
    for (final order in _state.activeShippingOrders) {
      if (order.isCompleted) {
        completedShipping.add(order);
      } else {
        activeShipping.add(order);
      }
    }

    // Always notify listeners if there are active productions/shipping for progress updates
    if (completedTasks.isNotEmpty ||
        completedShipping.isNotEmpty ||
        _state.activeProductions.isNotEmpty ||
        _state.activeShippingOrders.isNotEmpty) {
      // Add completed products to inventory
      final newProducts = Map<String, int>.from(_state.products);
      for (final task in completedTasks) {
        newProducts[task.productId] =
            (newProducts[task.productId] ?? 0) + task.quantity;
      }

      // Add revenue from completed shipping orders and create history
      double newMoney = _state.money;
      final newHistory = List<ShippingHistory>.from(_state.shippingHistory);

      for (final order in completedShipping) {
        newMoney += order.totalRevenue;

        // Add to history
        final history = ShippingHistory(
          id: order.id,
          items: order.items,
          completedTime: DateTime.now(),
          totalRevenue: order.totalRevenue,
        );
        newHistory.add(history);
      }

      _state = _state.copyWith(
        money: newMoney,
        products: newProducts,
        activeProductions: activeTasks,
        activeShippingOrders: activeShipping,
        shippingHistory: newHistory,
      );

      notifyListeners();
    }
  }

  // Get material info
  Material? getMaterial(String id) => GameData.getMaterial(id);
  Product? getProduct(String id) => GameData.getProduct(id);

  // Get all available items
  List<Material> get allMaterials => GameData.materials;
  List<Product> get allProducts => GameData.products;

  // Get products categorized by tier/level
  List<Product> get basicPartsProducts => GameData.getBasicPartsProducts();
  List<Product> get intermediateProducts => GameData.getIntermediateProducts();
  List<Product> get complexProducts => GameData.getComplexProducts();
  List<Product> get retailProducts => GameData.getRetailProducts();

  // Get products organized by tiers for UI display
  Map<ProductLevel, List<Product>> get productsByTier => {
    ProductLevel.basicParts: basicPartsProducts,
    ProductLevel.intermediate: intermediateProducts,
    ProductLevel.complex: complexProducts,
    ProductLevel.retail: retailProducts,
  };

  // Get tier display name
  String getTierName(ProductLevel level) => GameData.getLevelName(level);
}
