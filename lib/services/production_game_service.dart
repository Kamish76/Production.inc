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
    
    // Consume materials
    final newMaterials = Map<String, int>.from(_state.materials);
    for (final entry in requiredMaterials.entries) {
      newMaterials[entry.key] = (newMaterials[entry.key] ?? 0) - entry.value;
    }
    
    // Create production task
    final task = ProductionTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: productId,
      startTime: DateTime.now(),
      durationSeconds: product.productionTimeSeconds,
      quantity: quantity,
    );
    
    final newProductions = List<ProductionTask>.from(_state.activeProductions);
    newProductions.add(task);
    
    _state = _state.copyWith(
      materials: newMaterials,
      activeProductions: newProductions,
    );
    
    notifyListeners();
    return true;
  }
  
  // Sell products
  bool sellProduct(String productId, int quantity) {
    final product = GameData.getProduct(productId);
    if (product == null) return false;
    
    final available = _state.getProductCount(productId);
    if (available < quantity) return false;
    
    final totalRevenue = product.sellPrice * quantity;
    
    final newProducts = Map<String, int>.from(_state.products);
    newProducts[productId] = available - quantity;
    if (newProducts[productId]! <= 0) {
      newProducts.remove(productId);
    }
    
    _state = _state.copyWith(
      money: _state.money + totalRevenue,
      products: newProducts,
    );
    
    notifyListeners();
    return true;
  }
  
  // Check and complete finished productions
  void updateProductions() {
    final completedTasks = <ProductionTask>[];
    final activeTasks = <ProductionTask>[];
    
    for (final task in _state.activeProductions) {
      if (task.isCompleted) {
        completedTasks.add(task);
      } else {
        activeTasks.add(task);
      }
    }
    
    if (completedTasks.isEmpty) return;
    
    // Add completed products to inventory
    final newProducts = Map<String, int>.from(_state.products);
    for (final task in completedTasks) {
      newProducts[task.productId] = (newProducts[task.productId] ?? 0) + task.quantity;
    }
    
    _state = _state.copyWith(
      products: newProducts,
      activeProductions: activeTasks,
    );
    
    notifyListeners();
  }
  
  // Get material info
  Material? getMaterial(String id) => GameData.getMaterial(id);
  Product? getProduct(String id) => GameData.getProduct(id);
  
  // Get all available items
  List<Material> get allMaterials => GameData.materials;
  List<Product> get allProducts => GameData.products;
}
