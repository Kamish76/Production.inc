/// Auto-Buy Machine service
///
/// Implements pooled-capacity buying logic: all enabled machines pool their
/// per-tick buying capacity and apply it as a single batch per tick.
///
/// Algorithm:
/// - totalBuys = machinesEnabled × buysPerMachinePerTick
/// - Process resources in resourceOrder sequentially
/// - For each resource: buy min(remaining pooled buys, deficit to reach resourceCap)
/// - Skip resources already at or above resourceCap
/// - Wrap back to top of resourceOrder if pooled buys remain and resources still have deficits
library;

import 'dart:math' as math;

/// Performs one tick of auto-buy purchases using pooled-capacity model.
///
/// Parameters:
/// - [inventory]: Current resource inventory (resource name -> amount).
///   Will be modified in-place.
/// - [machinesEnabled]: Number of enabled auto-buy machines (>= 0).
/// - [buysPerMachinePerTick]: Number of items one machine buys per tick (>= 0).
/// - [resourceOrder]: Ordered list of resource names to process.
/// - [resourceCap]: Per-resource soft cap (machines aim to fill to this level).
///
/// Returns: Total number of items purchased this tick.
///
/// Edge cases:
/// - Negative inputs are clamped to zero.
/// - If inventory doesn't contain a resource in resourceOrder, it's initialized to 0.
/// - If all resources are at or above resourceCap, remaining pooled buys are unused.
/// - Wraps back to top of resourceOrder if pooled buys remain after one pass.
int performAutoBuyTick({
  required Map<String, int> inventory,
  required int machinesEnabled,
  required int buysPerMachinePerTick,
  required List<String> resourceOrder,
  required int resourceCap,
}) {
  // Clamp inputs to non-negative
  final safeEnabled = math.max(0, machinesEnabled);
  final safeBuysPerMachine = math.max(0, buysPerMachinePerTick);
  final safeCap = math.max(0, resourceCap);

  // Calculate pooled buying capacity
  int pooledBuys = safeEnabled * safeBuysPerMachine;
  if (pooledBuys == 0 || resourceOrder.isEmpty) {
    return 0; // Nothing to buy
  }

  int totalPurchased = 0;
  const maxPasses = 1000; // Safety limit to prevent infinite loops
  int passCount = 0;

  // Keep processing resources in order until pooled buys exhausted or all resources at cap
  while (pooledBuys > 0 && passCount < maxPasses) {
    passCount++;
    bool anyPurchased = false;

    for (final resource in resourceOrder) {
      if (pooledBuys == 0) break;

      // Initialize resource if not in inventory
      final currentAmount = inventory[resource] ?? 0;
      inventory[resource] = currentAmount;

      // Calculate deficit (how much more we can buy before hitting cap)
      final deficit = math.max(0, safeCap - currentAmount);
      if (deficit == 0) {
        continue; // Resource at or above cap, skip
      }

      // Buy up to the deficit, limited by remaining pooled buys
      final buyAmount = math.min(pooledBuys, deficit);
      inventory[resource] = currentAmount + buyAmount;
      pooledBuys -= buyAmount;
      totalPurchased += buyAmount;
      anyPurchased = true;
    }

    // If we made a full pass without buying anything, all resources are at cap
    if (!anyPurchased) {
      break;
    }
  }

  return totalPurchased;
}
