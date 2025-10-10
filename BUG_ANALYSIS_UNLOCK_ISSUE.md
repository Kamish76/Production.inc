# Bug Analysis: Newly Unlocked Items Not Showing in Build Section

## Issue Description
When starting a new game and buying materials, newly unlocked basic parts are correctly identified as unlocked (evidenced by the basic parts counter incrementing), but they don't appear in the build section. This creates a confusing player experience where the UI suggests items are unlocked but they remain invisible.

## Root Cause Analysis

### The Problem
The unlock system has a **conceptual misunderstanding** between "materials purchased" and "items produced". 

### Key Data Structures
```dart
// In GameState
final Map<String, int> materials;  // Raw materials bought (cardboard, plastic, metals, etc.)
final Map<String, int> products;   // Items produced (box, wires, circuits, etc.)
final Set<String> unlockedProducts; // Products that should be visible
```

### The Bug Flow

1. **New Game Start**
   - `materials = {}` (empty)
   - `products = {}` (empty)
   - `unlockedProducts = {}` (empty)

2. **Player Buys Materials**
   ```dart
   buyMaterial('cardboard', 5)
   buyMaterial('basic_metals', 3)
   buyMaterial('plastic', 2)
   ```
   - `materials = {'cardboard': 5, 'basic_metals': 3, 'plastic': 2}` ✅
   - `products = {}` (still empty - nothing produced yet) ✅
   - `_checkAndUpdateUnlocks()` is called

3. **Unlock Check Occurs**
   ```dart
   // ProductUnlockService checks basic parts
   _checkBasicPartsUnlockConditions('box', gameState)
   // Returns true because cardboard >= 3
   
   _checkBasicPartsUnlockConditions('wires', gameState)
   // Returns true because basic_metals >= 2 && plastic >= 1
   ```
   - `unlockedProducts = {'box', 'wires', 'circuits'}` ✅
   - **These items are correctly marked as unlocked!**

4. **The Problem Emerges**
   - The build screen shows these items should be unlocked
   - **But there's a caching/display issue**

### Where The Actual Bug Is

After further analysis, I need to check if there's a **UI rendering issue** or a **cache synchronization problem**. Let me investigate:

## Hypothesis 1: Cache Invalidation Issue

The `ProductUnlockService` uses a cache that's based on game state hash:

```dart
static String _generateGameStateHash(GameState gameState) {
  final materialsHash = gameState.materials.entries
      .map((e) => '${e.key}:${e.value}')
      .join(',');
  final producedHash = gameState.unlockedProducts.join(',');
  return '$materialsHash|$producedHash';
}
```

**Potential Issue**: The cache invalidation happens, but the UI might not be properly notified or the cached `productUnlockStatus` map in the game state might not be updated.

## Hypothesis 2: State Update Timing

Looking at `_checkAndUpdateUnlocks()`:

```dart
void _checkAndUpdateUnlocks() {
  final newlyUnlocked = ProductUnlockService.updateUnlockStatus(_state);
  
  if (newlyUnlocked.isNotEmpty) {
    // Updates _state
    _state = _state.copyWith(
      unlockedProducts: updatedUnlockedProducts,
      productUnlockStatus: updatedUnlockStatus,
    );
    
    // Notifications
    _showUnlockNotifications(newlyUnlocked);
    _persistenceService.markDirty('unlocked_products');
    notifyListeners(); // <-- This should trigger UI update
  }
}
```

But wait - looking at `buyMaterial()`:

```dart
_state = _state.copyWith(
  money: _state.money - totalCost,
  materials: newMaterials,
);

// Check for newly unlocked products after material purchase
_checkAndUpdateUnlocks();

// Mark materials as dirty
_persistenceService.markDirty('materials');

notifyListeners(); // <-- Called AFTER _checkAndUpdateUnlocks
_saveGameStateOptimized();
```

**The Real Issue**: `notifyListeners()` is called inside `_checkAndUpdateUnlocks()` ONLY if new products are unlocked, but it's also called in `buyMaterial()` after the unlock check. This seems fine...

## Hypothesis 3: Build Screen Filter Logic Issue

Let me check how the build screen filters products:

From the semantic search, I found:
```dart
// In build_products_screen.dart
final unlockedProducts = gameService.getUnlockedProductsByTier(tierLevel);
```

And in the service:
```dart
List<Product> getUnlockedProductsByTier(ProductLevel tier) {
  final tierProducts = productsByTier[tier] ?? [];
  return tierProducts
      .where((product) => isProductUnlocked(product.id))
      .toList();
}

bool isProductUnlocked(String productId) {
  // Use cached status for performance, fallback to service check
  return _state.productUnlockStatus[productId] ??
      ProductUnlockService.isProductUnlocked(productId, _state);
}
```

## THE ACTUAL BUG

I found it! The issue is in the **state update flow**:

1. When `buyMaterial()` is called, it updates the state with new materials
2. Then calls `_checkAndUpdateUnlocks()`
3. `_checkAndUpdateUnlocks()` calls `ProductUnlockService.updateUnlockStatus(_state)`
4. But `updateUnlockStatus()` uses the OLD state before the material purchase!

**NO WAIT** - that's not it either. The `_state` is already updated with new materials before `_checkAndUpdateUnlocks()` is called.

## Let Me Check The Actual Bug

The bug description says:
- "newly unlocked items won't show on build section"
- "but would be identified as unlocked since basic parts counter increments"

This suggests the **counter increments** but the **items don't show**. This is a **UI display issue**, not a logic issue!

## THE REAL BUG: Missing notifyListeners() in _checkAndUpdateUnlocks()

Looking more carefully at the code:

```dart
void _checkAndUpdateUnlocks() {
  try {
    final newlyUnlocked = ProductUnlockService.updateUnlockStatus(_state);

    if (newlyUnlocked.isNotEmpty) {
      // ... update state ...
      
      _persistenceService.markDirty('unlocked_products');
      
      // notifyListeners() is called HERE inside _checkAndUpdateUnlocks()
      // BUT it's inside the if (newlyUnlocked.isNotEmpty) block
      
      if (kDebugMode) {
        GameLogger.info('Unlocked new products: ${newlyUnlocked.join(', ')}');
      }
    }
    // If no new unlocks, notifyListeners() is NOT called!
  } catch (e) {
    if (kDebugMode) {
      print('Error checking unlocks: $e');
    }
  }
}
```

Wait, I need to check if `notifyListeners()` is actually called in `_checkAndUpdateUnlocks()`. Let me re-read the code...

Actually, looking at the code excerpt I have, I don't see `notifyListeners()` explicitly in `_checkAndUpdateUnlocks()` in the section I read! But it's called in `buyMaterial()` after, so that should be fine...

## Final Analysis: The ProductUnlockService Cache Issue

I believe the actual bug is this:

When `ProductUnlockService.updateUnlockStatus()` is called, it checks:
```dart
final wasUnlocked = gameState.isProductUnlocked(product.id);
final isNowUnlocked = isProductUnlocked(product.id, gameState);
```

The first call uses `gameState.isProductUnlocked()` which checks the `unlockedProducts` set.
The second call uses `ProductUnlockService.isProductUnlocked()` which checks unlock conditions.

**The cache invalidation happens in `_isCacheValid()`**, which generates a hash including materials. When materials change, the cache should be cleared.

But here's the subtle bug: The cache is cleared when the hash changes, but if the UI reads from `_state.productUnlockStatus` map, that map is only updated when `newlyUnlocked.isNotEmpty`.

## Solution Required

The fix needs to ensure that:
1. When materials are purchased, the unlock check runs with the NEW material state
2. The `productUnlockStatus` cache in GameState is updated
3. The UI is notified to re-render
4. The ProductUnlockService cache is properly invalidated

## Recommended Fix

Add explicit cache clearing in `buyMaterial()`:

```dart
bool buyMaterial(String materialId, int quantity) {
  // ... existing code ...
  
  _state = _state.copyWith(
    money: _state.money - totalCost,
    materials: newMaterials,
  );
  
  // EXPLICITLY CLEAR THE UNLOCK CACHE BEFORE CHECKING
  ProductUnlockService.clearCache();
  
  // Check for newly unlocked products after material purchase
  _checkAndUpdateUnlocks();
  
  // ... rest of the code ...
}
```

This ensures that when `_checkAndUpdateUnlocks()` runs, it's using a fresh unlock evaluation with the new materials.
