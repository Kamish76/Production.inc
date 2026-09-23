# Production.INC — Future Plans & Feature Roadmap (`FUTURE_PLANS.md`)

> **Document Purpose**: This document outlines the strategic roadmap, planned gameplay expansions, and architectural milestones for **Production.INC**. It details how to evolve the game from a straightforward assembly loop into a rich, deeply satisfying industrial tycoon experience.

---

## 🗺️ Roadmap At-A-Glance

| Phase | System / Feature | Target Area | Status | Impact |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Factory Tiers & Expansion Licensing** | Control Screen (`Tiers` Tab) | ✅ **Completed** | Solves early-game rushing; gates progress with rewarding factory milestones. |
| **2** | **B2B Corporate Contracts & Dynamic Shipping** | Shipping Screen | ✅ **Completed** | Transforms passive shipping into an active, high-margin logistics game. |
| **3** | **New Industry Branches (Robotics & Clean Energy)** | `game_data.dart`, Build Screen | 🎯 **Next Priority** | Expands product catalog with modern, high-tech manufacturing chains. |
| **4** | **R&D Lab & Technology Tree** | New Screen / Control Center | 💡 Concept | Gives utility to surplus inventory through permanent efficiency perks. |
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

## 🔬 Phase 3: New Industry Branches & Complex Recipes

### 🎯 Objective
Diversify production beyond standard smartphones and speakers into specialized manufacturing paths in [`lib/models/game_data.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_data.dart).

### 1. Robotics & Smart Automation Branch
* **New Materials**: Silicon Wafer (from Glass + Metals), Copper Coils.
* **New Intermediate Parts**:
  * `servo_motor`: Precision electric motor.
  * `microcontroller`: Programmable logic chip.
  * `chassis_alloy`: Lightweight reinforced frame.
* **New Retail Products**:
  * `cleaning_drone`: Automated household drone ($480).
  * `robotic_arm`: Industrial factory manipulator ($1,250).

### 2. Renewable Energy & Grid Storage Branch
* **New Intermediate Parts**:
  * `inverter_unit`: Power conversion electronics.
  * `storage_cell`: High-density power storage.
* **New Retail Products**:
  * `home_powerwall`: Residential battery storage unit ($850).
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
