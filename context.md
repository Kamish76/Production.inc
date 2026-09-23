# Production.INC — Agent & Developer Context Guide (`context.md`)

> **Note for AI Agents & Developers**: This document serves as the single source of truth for understanding the architecture, design principles, critical rules, common pitfalls, and development workflows of **Production.INC**. Read this before making architectural or code modifications.

---

## 🎮 1. Project Overview

* **Game Title**: Production.INC
* **Genre**: Mobile Industrial Tycoon / Factory Automation & Supply Chain Simulator
* **Core Loop**:
  1. **Source**: Purchase raw materials (Cardboard, Metals, Plastic, Glass).
  2. **Manufacture**: Build basic parts $\to$ intermediate parts $\to$ complex assemblies $\to$ retail electronics.
  3. **Distribute**: Sell finished goods $\to$ dispatch delivery logistics via the Shipping system.
  4. **Automate & Expand**: Deploy Auto-Buy and Auto-Build machines via the Control Center and unlock higher factory tiers.
* **Target Platforms**: Android (Primary, targeting Google Play Console), Web, Desktop (Windows/macOS).

---

## 🏗️ 2. Architecture & File Structure

The project follows a clean **Layered Architecture (UI $\to$ Service/Logic $\to$ State/Data)** utilizing the `Provider` state management pattern:

```text
Game1/
├── assets/
│   └── images/                     # App icons and visual assets
├── lib/
│   ├── main.dart                   # App entrypoint, Provider setup, route registration
│   ├── constants/
│   │   └── game_constants.dart     # Centralized colors, timing constants, economy values
│   ├── models/
│   │   ├── game_models.dart        # Immutable models: Material, Product, Machine, ShippingOrder
│   │   ├── game_data.dart          # Static catalogs: definitions of all materials, recipes, machines
│   │   └── game_state.dart         # Runtime player state: money, inventories, unlocked IDs, machine states
│   ├── services/
│   │   ├── production_game_service.dart # Central coordinator (ChangeNotifier), main game loops & economy
│   │   ├── product_unlock_service.dart  # Recipe unlocking conditions & state caching
│   │   ├── machine_builder.dart         # Auto-build machine worker logic
│   │   ├── machine_buyer.dart           # Auto-buy machine worker logic
│   │   └── game_persistence_service.dart# SQLite database handling, migrations, auto-save
│   ├── screens/
│   │   ├── main_game_screen.dart   # Bottom navigation host & app shell
│   │   ├── buy_materials_screen.dart # Material purchase screen with bulk buy
│   │   ├── build_products_screen.dart# Production queue management & tier panels
│   │   ├── sell_products_screen.dart # Manual and bulk order dispatch
│   │   ├── shipping_screen.dart    # Active delivery timers & shipment history
│   │   ├── control_screen.dart     # Automation center: Machines tab & Tiers tab
│   │   └── settings_screen.dart    # Audio, debug tools, database repair, save management
│   └── widgets/                    # Reusable component library (TierExpansionPanel, GameCard, OrderCard, etc.)
├── docs/                           # Technical documentation, bug reports, and design specs
├── context.md                      # This agent guide
└── FUTURE_PLANS.md                 # Design plans, roadmap, and upcoming game systems
```

---

## ⚙️ 3. Core Tech Stack & Dependencies

* **Flutter SDK**: `^3.7.0` (Dart 3)
* **State Management**: `provider: ^6.1.2` (`ChangeNotifierProvider` around `ProductionGameService`)
* **Persistence**:
  * `sqflite: ^2.4.1` (Android/iOS database)
  * `sqflite_common_ffi: ^2.3.6` (Desktop/testing database support)
  * `shared_preferences: ^2.3.2` (Lightweight UI preferences, tab memory, expansion states)
* **Routing**: `go_router: ^16.3.0`
* **Logging**: `logger: ^2.6.2`

---

## ⚠️ 4. Critical Engineering Rules & Gotchas

### 🚨 Rule 1: Database Migrations & Schema Changes (HIGH RISK)
* **History**: A previous migration bug wiped player save files because a table (`auto_build_machines`) was missing in older saves.
* **Requirements**:
  * Never alter table columns or add tables without updating the database version in [`lib/services/game_persistence_service.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/game_persistence_service.dart).
  * Always provide an explicit `onUpgrade` SQL migration script for every incremental version step.
  * Always ensure fallback default values exist if new columns are loaded from an older save.
  * Keep the "Repair Database" dev tool functional in [`lib/services/production_game_service.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart).

### 🚨 Rule 2: Proactive Flutter Hot Reload / Hot Restart
Whenever modifying any `.dart` file under `lib/`:
1. Use the Dart MCP tools (`dtd` / `vm_service` / `hot_reload` / `hot_restart`) to reflect changes live in any running debug session.
2. Trigger `hot_reload` immediately after UI widget tweaks.
3. Trigger `hot_restart` when changing core services, static models in `game_data.dart`, or `initState()`.

### 🚨 Rule 3: Material vs. Intermediate Product Consumption
* Basic parts (e.g. `wires`, `circuits`, `box`) can act as **both finished sellable goods and raw materials** for higher-tier products.
* In [`lib/services/production_game_service.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart) and [`lib/services/machine_builder.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/machine_builder.dart), always maintain the distinct tracking between raw materials (`materialsInventory`) and manufactured components (`productsInventory`) so items are never leaked or wiped during recipe consumption.

### 🚨 Rule 4: Unlock State Synchronization
* Whenever auto-buy purchases materials or auto-build finishes an item, `_checkAndUpdateUnlocks()` **must** be invoked, followed by `notifyListeners()`.
* Failure to call unlock checks will result in items remaining locked even when requirements are satisfied.

### 🚨 Rule 5: Unique ID Generation
* Any dynamic entities (e.g., shipping orders, machine instances) must use microsecond precision timestamps + type prefixes (e.g. `order_${DateTime.now().microsecondsSinceEpoch}`) to guarantee collision-free database keys.

---

## 🎨 5. UI/UX & Design Guidelines

* **Theme & Colors**:
  * Backgrounds use deep industrial blues/dark slate gradients (`Color(0xFF1A1A2E)` to `Color(0xFF16213E)`).
  * Accent highlights: Cyan/Teal for Automation/Control, Orange for Shipping, Green for Materials/Economy, Purple for Tiers/R&D.
* **Component Architecture**:
  * Prefer small, decomposed widgets in `lib/widgets/` rather than monster 1,000-line screen files.
  * Use `GameCard`, `TierExpansionPanel`, and `GameProgressIndicator` for consistent visuals and animations.
* **Safe Layouts**:
  * Always wrap scrollable cards in `ListView` or `SingleChildScrollView` to prevent `RenderFlex` overflow errors on smaller phone screens.

---

## 🧪 6. Testing & Validation Workflow

Before committing any major changes:
1. **Analyze**: Run static analysis via `dart analyze` or the `analyze_files` MCP tool.
2. **Run Tests**: Execute existing unit/widget tests under `test/`:
   ```bash
   flutter test
   ```
3. **Database Integrity**: Verify `database_integrity_check.dart` passes when modifying persistence models.
