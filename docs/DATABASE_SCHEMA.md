# Database Schema Documentation

This document provides comprehensive documentation for the Production.Inc SQLite database schema.

## Database Version: 5 (Current)

**Location**: `production_inc_save.db` in app's database directory  
**Backup**: `production_inc_backup.db` (automatic backup before major operations)

## Core Tables

### game_state
Primary table storing high-level game configuration and progress.

```sql
CREATE TABLE game_state (
  id INTEGER PRIMARY KEY,
  money REAL NOT NULL DEFAULT 100.0,
  current_production_time REAL NOT NULL DEFAULT 0.0,
  game_version TEXT NOT NULL DEFAULT '1.0.0'
);
```

**Purpose**: Stores global game state including player money and game version for migration tracking.

---

### materials
Stores current quantity of all raw materials in player inventory.

```sql
CREATE TABLE materials (
  id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 0
);
```

**Sample Data**:
- `cardboard`: 45
- `plastic`: 23  
- `basic_metals`: 67
- `advanced_metals`: 12
- `wires`: 88
- `glass`: 5

---

### products
Stores current quantity of all manufactured products in player inventory.

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 0
);
```

**Categories**:
- Basic parts: `box`, `sound_driver`, `wires`, `circuits`, etc.
- Intermediate parts: `processor`, `display_screen`, `image_sensor`, `camera_module`
- Retail products: `speaker`, `power_bank`, `solar_panel`, `camera`, `smartphone`

---

## Production System Tables

### active_productions
Tracks all currently active and queued production tasks.

```sql
CREATE TABLE active_productions (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  start_time INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL,
  is_queued INTEGER DEFAULT 0
);
```

**Queue System**: 
- `is_queued = 0`: Active production (started)
- `is_queued = 1`: Waiting in queue

**Process**: Only one task per product type can be active. Additional tasks queue automatically.

---

## Shipping System Tables

### active_shipping_orders
Tracks shipping orders currently in transit.

```sql
CREATE TABLE active_shipping_orders (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  completion_time INTEGER NOT NULL
);
```

### shipping_order_items
Individual product items within shipping orders.

```sql
CREATE TABLE shipping_order_items (
  order_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  FOREIGN KEY (order_id) REFERENCES active_shipping_orders (id)
);
```

### shipping_history
Completed shipping orders (last 100 entries).

```sql
CREATE TABLE shipping_history (
  id TEXT PRIMARY KEY,
  total_value REAL NOT NULL,
  completion_date INTEGER NOT NULL
);
```

### shipping_history_items
Products sold in completed shipping orders.

```sql
CREATE TABLE shipping_history_items (
  history_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  FOREIGN KEY (history_id) REFERENCES shipping_history (id)
);
```

---

## User Preference Tables

### build_quantity_preferences
Remembers player's preferred build quantities for each product.

```sql
CREATE TABLE build_quantity_preferences (
  product_id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 1
);
```

### buy_quantity_preferences
Remembers player's preferred purchase quantities for materials.

```sql
CREATE TABLE buy_quantity_preferences (
  material_id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 1
);
```

### sell_quantity_preferences
Remembers player's preferred sell quantities for products.

```sql
CREATE TABLE sell_quantity_preferences (
  product_id TEXT PRIMARY KEY,
  quantity INTEGER NOT NULL DEFAULT 1
);
```

---

## Progressive Unlock System

### unlocked_products
Tracks which products have been discovered and unlocked (v1.4.18+).

```sql
CREATE TABLE unlocked_products (
  product_id TEXT PRIMARY KEY,
  unlocked_at INTEGER NOT NULL
);
```

**Unlock Criteria**:
- **Basic Parts**: When player has sufficient raw materials
- **Intermediate Parts**: When player has produced ALL required basic parts  
- **Complex Parts**: When player has produced ALL required intermediate parts
- **Retail Products**: When player has produced ALL required components

---

## Database Migration History

### Version 1 → 2 (v1.4.10)
- Added `active_productions.is_queued` column for queue system
- Added `build_quantity_preferences` table

### Version 2 → 3 (v1.4.11) 
- Added `buy_quantity_preferences` table
- Added `sell_quantity_preferences` table

### Version 3 → 4 (v1.4.11 continued)
- Schema validation and cleanup

### Version 4 → 5 (v1.4.18)
- Added `unlocked_products` table for progressive unlock system

---

## Performance Characteristics

### Save Operations (v1.4.8 Optimization)
- **Incremental Saves**: Only modified tables are written
- **Dirty State Tracking**: Monitors which data has changed
- **Transaction Batching**: Groups related operations
- **Backup System**: Automatic backup before major operations

### Query Patterns
- **High Frequency**: `materials`, `products`, `active_productions` (every update cycle)
- **Medium Frequency**: Preference tables (user interactions)
- **Low Frequency**: Shipping history (order completions)

### Storage Efficiency
- **Typical Save File**: 50-200 KB
- **Production Queue**: ~1-50 active tasks
- **Shipping History**: Limited to last 100 orders
- **Unlock State**: ~30 product unlock records

---

## Backup and Recovery

### Automatic Backup
- Created before database migrations
- Created before major save operations
- Located at `production_inc_backup.db`

### Recovery Process
1. Detect corrupted primary database
2. Restore from backup automatically
3. Log recovery operation for debugging
4. Continue normal operation

### Data Integrity
- Foreign key constraints enforced
- Transaction rollback on errors
- Corruption detection during startup
- Validation of critical game state values

---

*This schema documentation reflects Production.Inc database as of v1.4.19. Keep updated as schema evolves.*
