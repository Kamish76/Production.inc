# Product Unlock Persistence System

## Overview
The game now permanently saves which products are unlocked, so auto-build machines can continue building those products even after the game is restarted.

## How It Works

### 1. Unlock Detection
Products are automatically unlocked when conditions are met:
- **Basic Parts**: When player has sufficient raw materials
- **Intermediate Parts**: When player has produced ALL required basic parts
- **Complex Parts**: When player has produced ALL required intermediate parts
- **Retail Products**: When player has produced ALL required components

### 2. Automatic Unlock Checking
The system automatically checks for newly unlocked products:
- **After buying materials** (`buyMaterial()`)
- **After completing production tasks** (`_handlePostUpdateTasks()`)
- **After adding products via dev tools** (`addProductToInventory()`)

### 3. Persistence Flow

```
Product Unlock Detected
    ↓
Added to gameState.unlockedProducts (Set<String>)
    ↓
Marked as dirty: 'unlocked_products'
    ↓
Saved to database: unlocked_products table
    ↓
On game restart: Loaded from database
    ↓
Auto-build respects persisted unlocks
```

### 4. Database Schema

```sql
CREATE TABLE unlocked_products (
  product_id TEXT PRIMARY KEY,
  unlocked_at INTEGER NOT NULL
);
```

### 5. Key Components

#### ProductUnlockService
- `isProductUnlocked()`: Checks if a product is unlocked
  - **First checks**: `gameState.unlockedProducts` (persisted set)
  - **Then calculates**: Based on current materials/production
- `updateUnlockStatus()`: Detects newly unlocked products
- `getAllUnlockedProducts()`: Gets complete unlock status

#### ProductionGameService
- `_checkAndUpdateUnlocks()`: Checks for new unlocks and updates state
- `_initializeUnlockState()`: Loads unlock state on game start
- Automatically calls unlock checking after key operations

#### GamePersistenceService
- `_loadUnlockedProducts()`: Loads from database
- `_saveUnlockedProducts()`: Saves to database
- Integrates with incremental save system

## Example: Battery and Solar Cells

### Initial State
- `battery` and `solar_cells` are **locked**
- They require `wires` to be produced first

### Unlock Trigger
When player produces 1 `wires`:
1. Production task completes
2. `_handlePostUpdateTasks()` calls `_checkAndUpdateUnlocks()`
3. System detects `battery` and `solar_cells` conditions are now met
4. Adds them to `unlockedProducts` set
5. Saves to database
6. Logs: `🔓 Unlocked new products: battery, solar_cells`

### After Restart
1. Game loads from database
2. `_loadUnlockedProducts()` retrieves: `{battery, solar_cells, ...}`
3. `_initializeUnlockState()` sets up unlock cache
4. Auto-build can now build `battery` and `solar_cells` (if materials available)

## Benefits

### For Players
- Progress is preserved across sessions
- No need to re-unlock products after restart
- Auto-build machines maintain their capabilities

### For Auto-Build System
- `isProductUnlocked()` returns `true` for previously unlocked products
- Even if current conditions aren't met (e.g., consumed all wires)
- Machines can continue building advanced products

### For Development
- Dev tools automatically trigger unlock checking
- Adding products via `addProductToInventory()` unlocks dependent products
- Clear logging shows unlock events

## Monitoring Unlocks

### In Logs
```
💡 Initialized unlock state: 21 products unlocked
🔓 Unlocked new products: battery, solar_cells (Total unlocked: 23)
💡 Auto-build (basicParts): 10/10 products unlocked: box, wires, ..., battery, solar_cells, ...
```

### In Database
Query unlocked products:
```sql
SELECT product_id FROM unlocked_products;
```

### In Game State
```dart
gameService.state.unlockedProducts // Set<String>
gameService.isProductUnlocked('battery') // bool
```

## Important Notes

1. **Once unlocked, always unlocked**: Products stay unlocked even if conditions change
2. **Persists across sessions**: Database saves ensure restart preserves unlocks
3. **Automatic**: No manual intervention needed for persistence
4. **Performance optimized**: Uses cache to avoid repeated calculations
5. **Integrated with auto-build**: Auto-build automatically uses persisted unlocks

## Version History
- **v1.4.18**: Initial unlock system implementation
- **v1.5.0**: Enhanced for auto-build machine integration
- **v1.5.0+**: Added dev tool unlock checking for testing
