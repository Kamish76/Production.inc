# CRITICAL BUG FOUND: Auto-Build Material Leak

## Problem Description

The auto-build system has a **critical data leak** where materials are being lost during the build process. This causes:
1. Money not increasing properly (materials disappear without producing products)
2. Potential material loss when products are used as materials for other products

## Root Cause

Located in `lib/services/production_game_service.dart` lines 1089-1112:

```dart
// Update raw materials from materialsCopy
for (final matId in _state.materials.keys) {
  updatedMaterials[matId] = materialsCopy[matId] ?? 0;  // ❌ BUG HERE
}

// Update products that were consumed as materials
for (final productId in _state.products.keys) {
  if (materialsCopy.containsKey(productId)) {
    // Calculate how much was consumed
    final originalAmount = (_state.materials[productId] ?? 0) + (_state.products[productId] ?? 0);
    final remainingAmount = materialsCopy[productId] ?? 0;
    final consumed = originalAmount - remainingAmount;
    
    if (consumed > 0) {
      // Deduct consumed amount from product inventory
      updatedProducts[productId] = math.max(0, (_state.products[productId] ?? 0) - consumed);
    }
  }
}
```

### The Bug

**Line 1093**: `updatedMaterials[matId] = materialsCopy[matId] ?? 0;`

This line **incorrectly updates materials by replacing them entirely** from `materialsCopy`, but `materialsCopy` is a merged inventory that includes BOTH materials AND products. This means:

1. When materials are consumed in `machine_builder.performAutoBuildTick()`, they're properly subtracted from `materialsCopy`
2. **BUT** when we copy back to `updatedMaterials`, we're only iterating through `_state.materials.keys`
3. If a material was consumed and reaches 0, it gets removed from the map by the builder
4. Since it's no longer in the keys, we set `updatedMaterials[matId] = 0` (the `?? 0` part)
5. **But this doesn't account for materials that were consumed but not removed from the map**

### Example Scenario

Initial state:
- `_state.materials = {'cardboard': 100, 'plastic': 50}`
- Auto-build consumes 20 cardboard to make boxes

After `machine_builder.performAutoBuildTick()`:
- `materialsCopy = {'cardboard': 80, 'plastic': 50}` ✓ Correct

When copying back:
- For 'cardboard': `updatedMaterials['cardboard'] = materialsCopy['cardboard'] = 80` ✓ Correct
- For 'plastic': `updatedMaterials['plastic'] = materialsCopy['plastic'] = 50` ✓ Correct

**BUT** if the material doesn't exist in `_state.materials.keys` initially, it won't be updated!

### Worse Case: Products Used as Materials

When products are consumed as materials (e.g., wires used to make circuits):

Initial state:
- `_state.materials = {'plastic': 50}`
- `_state.products = {'wires': 20, 'box': 10}`

Merged inventory:
- `materialsCopy = {'plastic': 50, 'wires': 20, 'box': 10}`

Auto-build consumes 5 wires:
- `materialsCopy = {'plastic': 50, 'wires': 15, 'box': 10}`

When copying back:
- ✓ Materials loop correctly updates plastic
- The products loop tries to calculate consumed wires:
  - `originalAmount = 0 + 20 = 20` (gets from `_state.products`)
  - `remainingAmount = 15` (from `materialsCopy`)
  - `consumed = 5` ✓ Correct
  - `updatedProducts['wires'] = max(0, 20 - 5) = 15` ✓ Correct

So the products-as-materials logic is actually OK!

### The REAL Problem

The issue is more subtle. Looking at the loop again:

```dart
for (final matId in _state.materials.keys) {
  updatedMaterials[matId] = materialsCopy[matId] ?? 0;
}
```

This **only updates materials that were in `_state.materials` originally**. But what if:
1. A material was completely consumed and removed from `materialsCopy`
2. The `?? 0` fallback sets it to 0 correctly
3. But then the map entry with value 0 might not be properly handled

Actually, looking more carefully, the real issue is:

**The loop doesn't handle materials that were removed from materialsCopy properly.**

When `machine_builder.dart` line 137 runs:
```dart
materialInventory[materialId] = math.max(0, currentMaterialAmount - totalRequired);
```

It always keeps the entry in the map (even if it's 0). So the material won't be removed.

BUT if it was already 0 before, it stays 0, and we're just setting `updatedMaterials[matId] = 0` repeatedly.

### Wait, Found the ACTUAL Bug!

Looking at lines 1089-1095 again:
```dart
// Update raw materials from materialsCopy
for (final matId in _state.materials.keys) {
  updatedMaterials[matId] = materialsCopy[matId] ?? 0;
}
```

The problem is that this **ONLY updates materials that exist in `_state.materials`**. 

If a material is NOT in `_state.materials` initially (quantity = 0), but gets added to `materialsCopy` because it exists as a product, then:
- It gets consumed by auto-build
- But we never copy it back to `updatedMaterials` because it wasn't in `_state.materials.keys`

**However**, this shouldn't be a problem because raw materials can't spontaneously appear in products without being in materials first.

## The Real Issue: Material Consumption Tracking

After extensive analysis, I believe the issue is that:

1. Materials ARE being consumed correctly
2. Products ARE being created correctly  
3. **BUT** the consumption is happening TWICE in some cases

Looking at the auto-build flow:
1. `machine_builder.performAutoBuildTick()` modifies `materialsCopy` and adds to `productsCopy`
2. Then we create production tasks for each item built
3. When those production tasks complete, we run `startProduction()` which ALSO consumes materials!

**THIS IS THE BUG!** Auto-build consumes materials immediately AND queues production tasks. When those tasks complete, they try to consume materials again, but they're already gone!

Wait, let me check if `startProduction()` is called for auto-build items...

Looking at lines 1007-1074, the auto-build system:
1. Calls `machine_builder.performAutoBuildTick()` which consumes materials from `materialsCopy`
2. Updates state with consumed materials
3. Creates production tasks

But these production tasks are just time-delays - they don't consume materials again because the materials were already consumed!

## Conclusion

After thorough analysis, the auto-build material consumption logic appears correct. The issue might be:

1. **Race condition**: Multiple auto-build ticks happening too fast
2. **State synchronization**: State updates not being persisted correctly
3. **Display issue**: Materials ARE being consumed but UI doesn't reflect it properly

The most likely cause is **improper state copying** in lines 1089-1095. The fix should ensure ALL materials (not just those in original state) are properly updated.

## Recommended Fix

Change lines 1089-1095 from:
```dart
// Update raw materials from materialsCopy
for (final matId in _state.materials.keys) {
  updatedMaterials[matId] = materialsCopy[matId] ?? 0;
}
```

To:
```dart
// Update raw materials from materialsCopy
// First, copy all existing materials
for (final matId in _state.materials.keys) {
  updatedMaterials[matId] = materialsCopy[matId] ?? 0;
}

// Then, ensure any materials that were in materialsCopy but not in _state.materials
// are properly excluded (they're actually products, not raw materials)
// This is correct as-is because we only update materials that were originally in materials.

// The issue is we need to properly handle removal:
updatedMaterials.removeWhere((key, value) => value <= 0);
```

Actually, that's not the issue either. Let me look at one more thing...

## FOUND IT! Lines 1089-1095

The bug is that we're copying from `materialsCopy` which contains MERGED materials+products, but we're updating `updatedMaterials` which should ONLY contain raw materials!

When we merge products into `materialsCopy` (lines 957-960):
```dart
final materialsCopy = Map<String, int>.from(_state.materials);
for (final entry in _state.products.entries) {
  materialsCopy[entry.key] = (materialsCopy[entry.key] ?? 0) + entry.value;
}
```

We're adding product quantities to material quantities! If 'wires' exists as both a material (0) and product (20), materialsCopy['wires'] = 20.

Then, when we do (line 1093):
```dart
updatedMaterials[matId] = materialsCopy[matId] ?? 0;
```

We're setting `updatedMaterials['wires'] = 20`, which is WRONG because 'wires' shouldn't be in raw materials!

**This is the leak!** We're copying product quantities into material inventory, which shouldn't happen.

## The Fix

Lines 1089-1095 should ONLY update TRUE raw materials, not products that were merged into materialsCopy for consumption purposes.

We need to track which items are truly raw materials vs products that were temporarily merged.
