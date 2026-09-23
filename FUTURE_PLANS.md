# Production.INC — Future Plans & Feature Roadmap (`FUTURE_PLANS.md`)

> **Document Purpose**: This document outlines the strategic roadmap, planned gameplay expansions, and architectural milestones for **Production.INC**. It details how to evolve the game from a straightforward assembly loop into a rich, deeply satisfying industrial tycoon experience.

---

## 🗺️ Roadmap At-A-Glance

| Phase | System / Feature | Target Area | Status | Impact |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Factory Tiers & Expansion Licensing** | Control Screen (`Tiers` Tab) | ✅ **Completed** | Solves early-game rushing; gates progress with rewarding factory milestones. |
| **2** | **B2B Corporate Contracts & Dynamic Shipping** | Shipping Screen | ✅ **Completed** | Transforms passive shipping into an active, high-margin logistics game. |
| **3** | **New Industry Branches (Robotics & Clean Energy)** | `game_data.dart`, Build & Sell Screens | ✅ **Completed** | Expands product catalog with 11 high-tech components, flagships, and branch filters. |
| **4** | **R&D Lab & Technology Tree** | New Screen / Control Center | 🎯 **Next Priority** | Gives utility to surplus inventory through permanent efficiency perks. |
| **5** | **Prestige / IPO (Initial Public Offering)** | Endgame System | 💡 Concept | Infinite replayability with Golden Shares and global multipliers. |

---

## 🏭 Phase 1: Factory Tiers & Expansion Licensing (✅ Completed)

### 🎯 Objective & Outcome
Replaced the placeholder in [`lib/screens/control_screen.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart) with the complete **Factory Tiers & Expansion Licensing** progression system.

### 📦 Delivered Features & Architecture
- **Tier Model & Catalog**: Added [`FactoryTier`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_models.dart) and 4 tiers in [`GameData.factoryTiers`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_data.dart):
  1. **Tier 1 (Garage Workshop 🏚️)**: Starting tier, Basic Parts crafting, auto-buy capacity capped at 25.
  2. **Tier 2 (Light Assembly Facility 🏭)**: $2,500 Cash + 20 Boxes & 15 Wires shipped. Unlocks Intermediate Parts & Retail items, auto-buy capacity up to 50.
  3. **Tier 3 (Precision Manufacturing Plant 🔬)**: $25,000 Cash + 25 Speakers & 20 Batteries shipped. Unlocks Complex Parts & Advanced Retail, auto-buy capacity up to 100.
  4. **Tier 4 (Megafactory Cleanroom 🚀)**: $150,000 Cash + 50 Smartphones & 30 Solar Panels shipped. Unlocks Flagship Retail items (Smartphone) & Tier 3 Auto-build, auto-buy capacity up to 250.
- **Database v7 Migration**: Non-destructive automated migration `_migrateToVersion7` added to [`GamePersistenceService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/game_persistence_service.dart) preserving existing saves.
- **Unlock Gating & Machine Limits**: [`ProductUnlockService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/product_unlock_service.dart) gates intermediate/complex/flagship items by tier while preserving previously unlocked products. [`ProductionGameService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart) enforces auto-buy capacity caps per tier.
- **Interactive UI**: Added [`FactoryTierCard`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/factory_tier_card.dart) with live progress bars, license acquisition button with celebration feedback, and visual 4-tier roadmap timeline.
- **Test Verification**: Verified with full test suite (72/72 tests passing, 0 analyzer errors).

---

## 🚚 Phase 2: B2B Corporate Contracts & Dynamic Logistics (✅ Completed)

### 🎯 Objective & Outcome
Elevated [`lib/screens/shipping_screen.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/shipping_screen.dart) from a basic order timer into a full 3-tab **Commercial Dispatch & Corporate Logistics Center**.

### 📦 Delivered Features & Architecture
- **Corporate Clients Catalog**: Added 3 distinct AI corporations in [`lib/models/game_data.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_data.dart):
  1. **Apex Telecom (📡)**: Demands telecom and mobile goods (wires, circuits, power banks, smartphones). Sells `plastic` and `advanced_metals` at discounted rates.
  2. **Solaria Energy (☀️)**: Demands clean power hardware (batteries, solar cells, power supplies). Sells `glass` and `basic_metals` at discounted rates.
  3. **Nova Robotics (🤖)**: Demands robotics mechatronics (gears, motors, sensors, robot kits). Sells `basic_metals` and `cardboard` at discounted rates.
- **Standing & Reputation System**: Standing progression from *Neutral* (0) $\to$ *Partner* (Level 1: 5% material discount) $\to$ *Preferred Vendor* (Level 2: 10% discount, +5% contract cash bonus) $\to$ *Strategic Alliance* (Level 3: 15% discount, +10% bonus) $\to$ *Executive Partner* (Level 4: 20% discount, +15% bonus). Integrated into manual purchase and auto-buy loops.
- **Dynamic B2B Contracts**: Autonomously generated timed bulk contracts tailored to player's factory tier and unlocked products. Supports single-click partial deliveries or complete fulfillment, with cash payouts, reputation awards, and automatic shipment history logging.
- **Logistics Fleet Upgrades**: Upgradeable 4-tier fleet (*Courier Bikes* $\to$ *Delivery Vans* $\to$ *Freight Trucks* $\to$ *Cargo Planes*) scaling shipping speeds up to +150% (2.5x speed) and expanding concurrent dispatch slots from 2 up to 12.
- **Commercial Dispatch UI**: Transformed [`shipping_screen.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/shipping_screen.dart) into a responsive 3-tab layout:
  - **Contracts Tab**: Live corporate contracts feed, countdown timers, delivery actions, and client standing breakdown.
  - **Fleet & Dispatch Tab**: Active fleet overview, upgrade purchasing card, and real-time shipment dispatch slots.
  - **History Tab**: Filterable completed shipping logs distinguishing B2B contracts from direct market shipments.
- **Database v8 Migration**: Added `_migrateToVersion8` in [`GamePersistenceService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/game_persistence_service.dart), creating `corporate_contracts` and `client_reputation` tables and persisting `fleet_tier` with incremental saving.
- **Test Suite**: Created [`test/phase2_b2b_logistics_test.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/test/phase2_b2b_logistics_test.dart) covering fleet tiers, reputation discounts, contract life cycles, and DB roundtrips (10/10 tests passing).

---

## 🔬 Phase 3: New Industry Branches & Complex Recipes (✅ Completed)

### 🎯 Objective & Outcome
Expanded Production.INC's manufacturing ecosystem with two complete technological branches: **Robotics & Smart Automation** and **Renewable Energy & Grid Storage**, adding 11 new products with interconnected crafting trees, progressive unlock logic, corporate demand synergy, and responsive industry branch filtering in the Build and Sell screens.

### 📦 Delivered Features & Architecture
- **Industry Branch Architecture**: Added [`IndustryBranch`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_models.dart) enum (`consumerTech`, `robotics`, `cleanEnergy`) with extension helpers for display names, emojis, and styling, non-breaking with default `consumerTech`.
- **Robotics & Automation Branch (`IndustryBranch.robotics`)**:
  1. **Silicon Wafer (`silicon_wafer`)**: Basic part ($32.00) crafted from 2 Glass + 1 Advanced Metals. Unlocks when player gathers required glass and metals.
  2. **Copper Coils (`copper_coils`)**: Basic part ($12.00) crafted from 2 Basic Metals. Unlocks once wires are produced.
  3. **Servo Motor (`servo_motor`)**: Intermediate part ($78.00) crafted from 2 Copper Coils + 2 Gears + 1 Circuits.
  4. **Microcontroller (`microcontroller`)**: Intermediate part ($115.00) crafted from 1 Silicon Wafer + 2 Circuits + 2 Wires.
  5. **Chassis Alloy (`chassis_alloy`)**: Intermediate part ($65.00) crafted from 1 Metal Enclosure + 2 Advanced Metals + 2 Basic Metals.
  6. **Cleaning Drone (`cleaning_drone`)**: Retail consumer robot ($480.00) crafted from 1 Chassis Alloy + 1 Microcontroller + 2 Servo Motors + 1 Battery + 2 Boxes.
  7. **Robotic Arm (`robotic_arm`)**: Tier 3+ Retail industrial manipulator ($1,250.00) crafted from 2 Chassis Alloys + 4 Servo Motors + 2 Microcontrollers + 1 Gear Mechanism + 4 Boxes.
- **Renewable Energy & Grid Storage Branch (`IndustryBranch.cleanEnergy`)**:
  1. **Inverter Unit (`inverter_unit`)**: Intermediate part ($92.00) crafted from 2 Copper Coils + 2 Circuits + 2 Wires + 1 Metal Enclosure.
  2. **Storage Cell (`storage_cell`)**: Intermediate part ($120.00) crafted from 2 Batteries + 2 Advanced Metals + 1 Plastic Enclosure.
  3. **Home Powerwall (`home_powerwall`)**: Tier 3+ Retail storage unit ($850.00) crafted from 3 Storage Cells + 1 Inverter Unit + 2 Metal Enclosures + 3 Boxes.
  4. **Wind Turbine Generator (`wind_turbine_generator`)**: Tier 4 Megafactory Flagship ($2,100.00) crafted from 4 Copper Coils + 2 Inverter Units + 2 Gear Mechanisms + 2 Chassis Alloys + 5 Boxes.
- **Tier Gating & Unlock System**:
  - `ProductUnlockService` extended to support `silicon_wafer` and `copper_coils` material thresholds.
  - Tier 4 Megafactory Cleanroom gates `wind_turbine_generator` along with `smartphone`.
  - Tier 3 Precision Tech Plant gates `robotic_arm` and `home_powerwall`.
  - Upgraded `_generateGameStateHash` to track product inventory changes for cache invalidation.
- **Auto-Build Automation**: Integrated all new basic and intermediate parts into [`AutoBuildConstants.productOrderByTier`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/constants/game_constants.dart), ordered smoothly by cycle times.
- **B2B Corporate Client Synergy**:
  - **Nova Robotics**: Now demands precision robotics products (`copper_coils`, `servo_motor`, `microcontroller`, `chassis_alloy`, `cleaning_drone`, `robotic_arm`, `gears`, `gear_mechanism`, `toy_robot`).
  - **Solaria Energy**: Now demands clean power products (`inverter_unit`, `storage_cell`, `home_powerwall`, `wind_turbine_generator`, `battery`, `solar_cells`, `solar_panel`).
  - **Apex Telecom**: Now demands microelectronics (`silicon_wafer`, `microcontroller`, `processor`, `smartphone`).
- **Interactive UI Filtering**:
  - Added horizontal Industry Branch filter chips (`All Branches 🌐`, `Consumer Tech 📱`, `Robotics 🤖`, `Clean Energy ⚡`) to [`BuildProductsScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/build_products_screen.dart) and [`SellProductsScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/sell_products_screen.dart).
  - Resolved all deprecated `withOpacity()` occurrences with modern `.withValues(alpha: ...)`.
- **Test Suite**: Created [`test/phase3_industry_branches_test.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/test/phase3_industry_branches_test.dart) (9/9 tests passing; 46/46 combined regression test pass; 0 analyzer warnings).t ($850).
  * `wind_turbine_generator`: Clean energy generator ($2,100).

---

## 🧪 Phase 4: R&D Lab & Technology Tree

### 🎯 Objective
Give players a strategic sink for surplus components instead of only selling them for raw cash.

### 🧩 Core Mechanics
* **Deconstruction for Science**: Feed surplus components into the R&D Lab to generate **Research Points (RP)**.
* **Tech Tree Branches**:
  * **Material Science**: 5% $\to$ 10% $\to$ 15% chance to duplicate an assembled product without consuming input materials.
  * **Factory Overclocking**: Ability to boost machine production by +25% at the cost of periodic maintenance checkups.
  * **Logistics Optimization**: Automatically fast-tracks shipping orders when high-priority contracts are active.

---

## 🌟 Phase 5: Prestige / Initial Public Offering (IPO)

### 🎯 Objective
Provide infinite endgame scaling once players reach the top manufacturing tier.

### 🧩 Core Mechanics
* When player net worth exceeds **$1,000,000**, they can initiate an **IPO (Take Production.INC Public)**.
* **What Resets**: Cash, material inventory, standard machines, base unlocked products.
* **What Persists**:
  * **Golden Shares / Venture Capital**: Currency earned based on lifetime revenue and total units shipped.
  * **Prestige Perks**:
    * +10% base production speed per Golden Share.
    * Instant machine unlocking at game start.
    * Exclusive "Prototype" product line (e.g. Quantum Processor, Orbital Satellite).

---

## 🎨 Technical & Visual Evolution

1. **Custom Artwork**: Replace emoji icons with sleek vector illustrations or isometric rendered sprites for all products and machines.
2. **Haptic & Audio Feedback**: Tactile click haptics on manual build completion and machine cycle ticks.
3. **Cloud Save & Sync**: Backup SQLite databases securely via Google Play Games Services / iCloud.
