# Production.INC — Future Plans & Feature Roadmap (`FUTURE_PLANS.md`)

> **Document Purpose**: This document outlines the strategic roadmap, planned gameplay expansions, and architectural milestones for **Production.INC**. It details how to evolve the game from a straightforward assembly loop into a rich, deeply satisfying industrial tycoon experience.

---

## 🗺️ Roadmap At-A-Glance

| Phase | System / Feature | Target Area | Status | Impact |
| :---: | :--- | :--- | :---: | :--- |
| **1** | **Factory Tiers & Expansion Licensing** | Control Screen (`Tiers` Tab) | ✅ **Completed** | Solves early-game rushing; gates progress with rewarding factory milestones. |
| **2** | **B2B Corporate Contracts & Dynamic Shipping** | Shipping Screen | 🎯 **Next Priority** | Transforms passive shipping into an active, high-margin logistics game. |
| **3** | **New Industry Branches (Robotics & Clean Energy)** | `game_data.dart`, Build Screen | 📋 Planned | Expands product catalog with modern, high-tech manufacturing chains. |
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

## 🚚 Phase 2: B2B Corporate Contracts & Dynamic Logistics

### 🎯 Objective
Elevate [`lib/screens/shipping_screen.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/shipping_screen.dart) from a passive order timer into an engaging commercial dispatch center.

### 🧩 Core Mechanics
1. **Corporate Client Contracts**:
   * AI corporations (e.g. *Apex Telecom*, *Solaria Energy*, *Nova Robotics*) post timed bulk requests.
   * *Example*: *"Apex Telecom needs 30 Power Banks within 25 minutes. Reward: $7,500 (1.4x standard sell price) + 50 Apex Rep."*
2. **Reputation Levels**:
   * Fulfilling contracts builds standing with specific clients.
   * Higher reputation unlocks permanent discounts on client-supplied raw materials or exclusive high-tier assembly blueprints.
3. **Logistics Fleet Upgrades**:
   * Upgrade your fleet from **Courier Bikes** $\to$ **Delivery Vans** $\to$ **Freight Trucks** $\to$ **Cargo Planes**.
   * Reduces `baseShippingTimeSeconds` and increases maximum simultaneous shipments.

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
