/// Auto-Buy Machine service
///
/// Implements pooled-capacity buying logic: all enabled machines pool their
/// per-tick buying capacity and apply it as a single batch per tick.
///
/// Algorithm:
/// - totalBuys = machinesEnabled × buysPerMachinePerTick
/// - Process resources in resourceOrder sequentially
/// - For each resource: buy min(remaining pooled buys, max affordable)
/// - Skip resources already at or above resourceCap
/// - Machines buy full batches even if exceeding cap (batch-purchase model)
/// - Wrap back to top of resourceOrder if pooled buys remain and resources still have deficits
library;

import 'dart:math' as math;

/// Result of an auto-buy tick operation
class AutoBuyTickResult {
  final int itemsPurchased;
  final double moneySpent;

  const AutoBuyTickResult({
    required this.itemsPurchased,
    required this.moneySpent,
  });
}

/// Performs one tick of auto-buy purchases using pooled-capacity model.
///
/// Parameters:
/// - [inventory]: Current resource inventory (resource name -> amount).
///   Will be modified in-place.
/// - [currentMoney]: Current player money available for purchases.
/// - [materialPrices]: Map of resource name -> buy price per unit.
/// - [machinesEnabled]: Number of enabled auto-buy machines (>= 0).
/// - [buysPerMachinePerTick]: Number of items one machine buys per tick (>= 0).
/// - [resourceOrder]: Ordered list of resource names to process.
/// - [resourceCap]: Per-resource soft cap (machines skip resources at or above this, but can exceed it with full batch purchases).
///
/// Returns: AutoBuyTickResult with items purchased and money spent.
///
/// Edge cases:
/// - Negative inputs are clamped to zero.
/// - If inventory doesn't contain a resource in resourceOrder, it's initialized to 0.
/// - If all resources are at or above resourceCap, remaining pooled buys are unused.
/// - If money runs out, stops buying immediately (mid-tick).
/// - Machines buy full batches even if it exceeds resourceCap (e.g., metal at 8, cap 10, batch 5 → buys 5, resulting in 13).
/// - Wraps back to top of resourceOrder if pooled buys remain after one pass.
AutoBuyTickResult performAutoBuyTick({
  required Map<String, int> inventory,
  required double currentMoney,
  required Map<String, double> materialPrices,
  required int machinesEnabled,
  required int buysPerMachinePerTick,
  required List<String> resourceOrder,
  required int resourceCap,
}) {
  // Clamp inputs to non-negative
  final safeEnabled = math.max(0, machinesEnabled);
  final safeBuysPerMachine = math.max(0, buysPerMachinePerTick);
  final safeCap = math.max(0, resourceCap);
  double moneyRemaining = math.max(0.0, currentMoney);

  // Calculate pooled buying capacity
  int pooledBuys = safeEnabled * safeBuysPerMachine;
  if (pooledBuys == 0 || resourceOrder.isEmpty) {
    return const AutoBuyTickResult(itemsPurchased: 0, moneySpent: 0.0);
  }

  int totalPurchased = 0;
  double totalSpent = 0.0;
  const maxPasses = 1000; // Safety limit to prevent infinite loops
  int passCount = 0;

  // Keep processing resources in order until pooled buys exhausted, money runs out, or all resources at cap
  while (pooledBuys > 0 && passCount < maxPasses) {
    passCount++;
    bool anyPurchased = false;

    for (final resource in resourceOrder) {
      if (pooledBuys == 0) break;

      // Get price for this resource
      final pricePerUnit = materialPrices[resource] ?? 0.0;
      if (pricePerUnit <= 0.0) {
        continue; // Skip resources with invalid/unknown prices
      }

      // Check if we can afford at least one unit
      if (moneyRemaining < pricePerUnit) {
        continue; // Can't afford this resource, try next one
      }

      // Initialize resource if not in inventory
      final currentAmount = inventory[resource] ?? 0;
      inventory[resource] = currentAmount;

      // Skip if already at or above cap
      if (currentAmount >= safeCap) {
        continue; // Resource at or above cap, skip
      }

      // Calculate how many we can buy, limited by:
      // 1. Remaining pooled buys
      // 2. Available money
      // Note: We don't limit by deficit - machines buy full batches even if exceeding cap
      final maxAffordable = (moneyRemaining / pricePerUnit).floor();
      final buyAmount = math.min(pooledBuys, maxAffordable);

      if (buyAmount <= 0) {
        continue; // Can't buy any of this resource
      }

      // Perform the purchase
      final cost = buyAmount * pricePerUnit;
      inventory[resource] = currentAmount + buyAmount;
      pooledBuys -= buyAmount;
      totalPurchased += buyAmount;
      totalSpent += cost;
      moneyRemaining -= cost;
      anyPurchased = true;
    }

    // If we made a full pass without buying anything, all resources are at cap or unaffordable
    if (!anyPurchased) {
      break;
    }
  }

  return AutoBuyTickResult(
    itemsPurchased: totalPurchased,
    moneySpent: totalSpent,
  );
}
