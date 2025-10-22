/// Auto-Build Machine service
///
/// Implements pooled-capacity building logic: all enabled machines pool their
/// per-tick building capacity and apply it as a single batch per tick, per tier.
///
/// Algorithm:
/// - totalBuilds = machinesEnabled × buildsPerMachinePerTick
/// - Process products in productOrder sequentially
/// - For each product: check if unlocked, check materials, build min(remaining pooled builds, deficit to reach productCap, materials available)
/// - Skip products already at or above productCap or not unlocked
/// - Wrap back to top of productOrder if pooled builds remain and products still have deficits
library;

import 'dart:math' as math;

/// Result of an auto-build tick operation
class AutoBuildTickResult {
  final int itemsBuilt;
  final Map<String, int> materialsConsumed; // materialId -> quantity consumed

  const AutoBuildTickResult({
    required this.itemsBuilt,
    required this.materialsConsumed,
  });
}

/// Performs one tick of auto-build production using pooled-capacity model.
///
/// Parameters:
/// - [productInventory]: Current product inventory (product name -> amount).
///   Will be modified in-place.
/// - [materialInventory]: Current material inventory (material name -> amount).
///   Will be modified in-place as materials are consumed.
/// - [productRecipes]: Map of product name -> required materials (materialId -> quantity).
/// - [unlockedProducts]: Set of product IDs that are unlocked for building.
/// - [queuedProductCounts]: Map of product name -> count of items currently in production queue.
///   Used to calculate total (inventory + queued) against capacity.
/// - [machinesEnabled]: Number of enabled auto-build machines for this tier (>= 0).
/// - [buildsPerMachinePerTick]: Number of products one machine builds per tick (>= 0).
/// - [productOrder]: Ordered list of product names to process.
/// - [productCap]: Per-product soft cap (machines aim to fill to this level).
///
/// Returns: AutoBuildTickResult with items built and materials consumed.
///
/// Edge cases:
/// - Negative inputs are clamped to zero.
/// - If productInventory doesn't contain a product in productOrder, it's initialized to 0.
/// - If materialInventory doesn't contain a material, it's treated as 0.
/// - If all products (inventory + queued) are at or above productCap, remaining pooled builds are unused.
/// - If materials run out, stops building immediately (mid-tick).
/// - If product is not unlocked, it's skipped.
/// - Wraps back to top of productOrder if pooled builds remain after one pass.
AutoBuildTickResult performAutoBuildTick({
  required Map<String, int> productInventory,
  required Map<String, int> materialInventory,
  required Map<String, Map<String, int>> productRecipes,
  required Set<String> unlockedProducts,
  required Map<String, int> queuedProductCounts,
  required int machinesEnabled,
  required int buildsPerMachinePerTick,
  required List<String> productOrder,
  required int productCap,
}) {
  // Clamp negative inputs to zero
  final safeBuildsPerMachine = math.max(0, buildsPerMachinePerTick);
  final safeMachinesEnabled = math.max(0, machinesEnabled);
  final safeProductCap = math.max(0, productCap);

  // Calculate total pooled building capacity
  int pooledBuildsRemaining = safeMachinesEnabled * safeBuildsPerMachine;

  // Track total items built and materials consumed
  int totalItemsBuilt = 0;
  final Map<String, int> totalMaterialsConsumed = {};

  // If no pooled capacity or no products to build, return early
  if (pooledBuildsRemaining <= 0 || productOrder.isEmpty) {
    return const AutoBuildTickResult(
      itemsBuilt: 0,
      materialsConsumed: {},
    );
  }

  // Main building loop: iterate through productOrder until pooled builds exhausted
  // or all products are at cap
  bool anyProductBuilt = true;
  while (pooledBuildsRemaining > 0 && anyProductBuilt) {
    anyProductBuilt = false;

    for (final productId in productOrder) {
      // Check if pooled capacity exhausted
      if (pooledBuildsRemaining <= 0) break;

      // Check if product is unlocked
      if (!unlockedProducts.contains(productId)) continue;

      // Initialize product inventory if not present
      productInventory.putIfAbsent(productId, () => 0);

      // Calculate total amount: inventory + queued production
      final currentInventory = productInventory[productId]!;
      final queuedAmount = queuedProductCounts[productId] ?? 0;
      final totalAmount = currentInventory + queuedAmount;

      // Calculate deficit (how many more until cap, considering both inventory and queue)
      final deficit = math.max(0, safeProductCap - totalAmount);

      // Skip if total (inventory + queue) is at or above cap
      if (deficit <= 0) continue;

      // Get recipe for this product
      final recipe = productRecipes[productId];
      if (recipe == null || recipe.isEmpty) continue; // No recipe, skip

      // Calculate how many we can afford to build based on materials
      int maxAffordable = double.maxFinite.toInt();
      for (final entry in recipe.entries) {
        final materialId = entry.key;
        final requiredPerUnit = entry.value;
        final availableMaterial = materialInventory[materialId] ?? 0;

        if (requiredPerUnit <= 0) continue;

        final affordableCount = availableMaterial ~/ requiredPerUnit;
        maxAffordable = math.min(maxAffordable, affordableCount);
      }

      // If can't afford even one unit, skip this product
      if (maxAffordable <= 0) continue;

      // Calculate actual build amount: min of (pooled builds, deficit, affordable)
      final buildAmount = math.min(
        pooledBuildsRemaining,
        math.min(deficit, maxAffordable),
      );

      if (buildAmount > 0) {
        // Add products to inventory (Note: In the actual game, these will be queued as production tasks)
        productInventory[productId] = currentInventory + buildAmount;

        // Consume materials
        for (final entry in recipe.entries) {
          final materialId = entry.key;
          final requiredPerUnit = entry.value;
          final totalRequired = requiredPerUnit * buildAmount;

          final currentMaterialAmount = materialInventory[materialId] ?? 0;
          materialInventory[materialId] = math.max(0, currentMaterialAmount - totalRequired);

          // Track total materials consumed
          totalMaterialsConsumed[materialId] = (totalMaterialsConsumed[materialId] ?? 0) + totalRequired;
        }

        // Update counters
        pooledBuildsRemaining -= buildAmount;
        totalItemsBuilt += buildAmount;
        anyProductBuilt = true;
      }
    }
  }

  return AutoBuildTickResult(
    itemsBuilt: totalItemsBuilt,
    materialsConsumed: totalMaterialsConsumed,
  );
}
