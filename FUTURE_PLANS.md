# Production.INC — Future Plans & Feature Roadmap (`FUTURE_PLANS.md`)

> **Document Purpose**: This document outlines the strategic roadmap, planned gameplay expansions, and architectural milestones for **Production.INC**. It details how to evolve the game from a straightforward assembly loop into a rich, deeply satisfying industrial tycoon experience.

---

## 🗺️ Roadmap At-A-Glance

| Phase | System / Feature | Target Area | Status | Impact |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **Factory Tiers & Expansion Licensing** | Control Screen (`Tiers` Tab) | ✅ **Completed** | Solves early-game rushing; gates progress with rewarding factory milestones. |
| **2** | **B2B Corporate Contracts & Dynamic Shipping** | Shipping Screen | ✅ **Completed** | Transforms passive shipping into an active, high-margin logistics game. |
| **3** | **New Industry Branches (Robotics & Clean Energy)** | `game_data.dart`, Build & Sell Screens | ✅ **Completed** | Expands product catalog with 11 high-tech components, flagships, and branch filters. |
| **4** | **R&D Lab & Technology Tree** | Control Center (`R&D Lab` Tab) | ✅ **Completed** | Gives utility to surplus inventory through permanent efficiency perks. |
| **5** | **Prestige / IPO (Initial Public Offering)** | Control Screen (`Prestige 🌟` Tab) | ✅ **Completed** | Infinite replayability with Golden Shares and global multipliers. |

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

## 🧪 Phase 4: R&D Lab & Technology Tree (✅ Completed)

### 🎯 Objective & Outcome
Transformed surplus manufactured goods into high-value **Research Points (RP)** through the **Component Deconstruction Bay**, powering a permanent 3-branch **Technology Tree** with active factory overdrive controls, diagnostics maintenance, and automated logistics fast-tracking in the Control Center.

### 📦 Delivered Features & Architecture
- **Component Deconstruction Bay**:
  - All 27 manufactured products assigned calibrated Research Point valuations scaled by tier (e.g., basic `box`: 1 RP, intermediate `circuits`: 6 RP, high-tech `robotic_arm`: 130 RP, flagship `wind_turbine_generator`: 250 RP).
  - Batch deconstruction selector (`1`, `5`, `10`, `All`) with responsive branch filtering (`All Branches`, `Consumer Tech`, `Robotics`, `Clean Energy`) and live yield previews.
  - Safely decrements player inventory and credits Research Points in atomic operations.
- **3 Technology Branches (3 Levels each)**:
  1. **Material Science (🧬)**:
     - Level 1 (50 RP, Tier 1): *Molecular Recycling* (5% chance to duplicate product on assembly without consuming materials).
     - Level 2 (150 RP, Tier 2): *Polymer Restructuring* (10% duplication chance).
     - Level 3 (400 RP, Tier 3): *Zero-Point Replicator* (15% duplication chance).
     - Seamlessly integrated into manual crafting and automated auto-build completion loops.
  2. **Factory Overclocking (⚡)**:
     - Level 1 (75 RP, Tier 1): *Tuned Actuators* (Permanent passive +15% build speed boost across all products).
     - Level 2 (200 RP, Tier 2): *Coolant Overdrive* (+25% build speed; unlocks the interactive Overclock toggle in the Control Center).
     - Level 3 (500 RP, Tier 3): *Plasma Turbocharging* (+40% build speed with heavy-duty thermal capacity).
     - **Wear Degradation & Diagnostic Maintenance**: Running active overclocking degrades equipment health over production ticks. If wear reaches 0%, overclock safely auto-throttles to prevent burnout. Players perform Diagnostic Checkups ($50 fee) to restore wear to 100% pristine condition.
  3. **Logistics Optimization (🚀)**:
     - Level 1 (60 RP, Tier 1): *Priority Dispatch* (15% shipping transit speed reduction across all orders).
     - Level 2 (175 RP, Tier 2): *Dynamic Courier Fast-Track* (30% shipping speed reduction + active B2B corporate contracts receive an extra +15% speed boost).
     - Level 3 (450 RP, Tier 3): *Quantum Hyperlane Logistics* (40% shipping speed reduction + contract fast-tracking + 1 extra concurrent dispatch slot).
- **Control Center 3-Section UI Evolution**:
  - Expanded [`lib/screens/control_screen.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart) from 2 segments (`Machines`, `Tiers`) to 3 (`Machines`, `Tiers`, `R&D Lab`).
  - Added R&D Department header banner with glowing RP counter badge (`🧪 X RP`).
  - Implemented responsive sub-tab pills to toggle between [`TechTreeCard`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/tech_tree_card.dart) and [`DeconstructionBayCard`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/deconstruction_bay_card.dart).
  - Built interactive Factory Overdrive & Diagnostics Maintenance panel directly into the Tech Tree with real-time condition gauges, master toggle switch, and service action button.
- **Database v9 Non-Destructive Migration**:
  - Added `_migrateToVersion9` in [`GamePersistenceService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/game_persistence_service.dart).
  - Created `researched_technologies` table (`tech_id`, `level`, `researched_at`).
  - Added `research_points`, `overclock_active`, and `maintenance_wear` columns to `core_game_state` with incremental dirty tracking.
- **Developer & Test Suite**:
  - Added dev testing helpers: `devAddResearchPoints`, `devSetTechLevel`, `devSetMaintenanceWear`, `devSetMoney`.
  - Added UI developer controls for instant +250 RP, wear restoration, and critical wear simulation.
  - Created comprehensive test suite [`test/phase4_rnd_lab_test.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/test/phase4_rnd_lab_test.dart) (20/20 tests passing; 49/49 combined regression pass; 0 analyzer warnings).

---

## 🌟 Phase 5: Prestige / Initial Public Offering (IPO) (✅ Completed)

### 🎯 Objective & Outcome
Delivered the definitive endgame prestige loop for Production.INC. Players can take their manufacturing enterprise public on Wall Street once reaching **$1,000,000.00 Net Worth**, resetting run operations in exchange for **Golden Shares**, permanent global build speed multipliers (+10% per share), and high-impact **Venture Perks**.

### 📦 Delivered Features & Architecture
- **Dynamic Corporate Net Worth Valuation**:
  - Dynamically calculates total corporate asset valuation across four distinct asset classes:
    $$\text{Net Worth} = \text{Cash} + \text{Materials Market Value} + \text{Products Market Value} + \text{Machinery Capital}$$
  - Machine capital is evaluated at $1,000 per auto-buy and auto-build machine.
- **Golden Shares Yield Formula**:
  - Unlocks once $\text{Net Worth} \ge \$1,000,000.00$.
  - Golden Shares awarded upon ringing the opening bell:
    $$\text{Golden Shares} = \left\lfloor \frac{\text{Net Worth}}{\$100,000} \right\rfloor + \left\lfloor \frac{\text{Units Shipped}}{100} \right\rfloor$$
- **Global Build Speed Multiplier**:
  - Each Golden Share permanently increases global manufacturing build speed by +10% (`1.0 + goldenShares * 0.10`).
  - Stacks multiplicatively with factory overclocking and tier automation in `getAdjustedProductionTime`.
- **Venture Perks Catalog**:
  - Added 4 high-impact prestige perks in [`lib/models/game_data.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_data.dart) purchasable with Golden Shares:
    1. **Instant Machine Licensing (⚙️, 5 🌟)**: Bypasses factory tier constraints for auto-buy and auto-build machinery.
    2. **Prototype Tech Blueprints (🔬, 10 🌟)**: Unlocks exclusive high-margin prototype line: *Quantum Processor* ($1,800), *Quantum Core* ($4,200), and *Orbital Satellite* ($18,500).
    3. **Angel Investor Seed Capital (💼, 8 🌟)**: Begin all post-IPO production runs with $2,500.00 cash instead of $100.00.
    4. **Quantum Warp Logistics (🌌, 12 🌟)**: Global +25% shipping transit speed and +1 concurrent shipment dispatch slot.
- **Run Reset vs. Persistent Boundaries**:
  - **Reset on IPO**: Cash (resets to $100 or $2,500 if Angel perk owned), materials, products, active production queues, active shipping orders, factory tier (resets to 1), fleet tier (resets to 1), research points, and tech levels.
  - **Preserved Across IPOs**: Golden Shares held, all-time Golden Shares earned, prestige count, lifetime revenue, lifetime units shipped, unlocked prestige perks, prototype blueprints, and B2B client reputation standings.
- **Control Center 4th Tab (`Prestige 🌟`) & UI**:
  - Added 4th switcher tab `[Prestige 🌟]` to [`lib/screens/control_screen.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart) with a live gold badge indicator when eligible for IPO.
  - Built [`PrestigeCard`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/prestige_card.dart):
    - **Header Banner**: Current Golden Shares, speed multiplier badge (`+X% Build Speed`), completed IPOs, and lifetime shares.
    - **IPO Launchpad**: Live progress bar toward $1.0M, financial asset breakdown (Cash, Materials, Finished Goods, Machines), projected Golden Shares yield, and "Ring Bell & Go Public" action button.
    - **Confirmation & Celebration**: Dual-stage dialog detailing reset vs. persist boundaries with opening bell celebration.
    - **Venture Perks Store**: Interactive card catalog showing perk costs, highlights, and instant acquisition feedback.
    - **Prototype Flagship Showcase**: Visual blueprints display showing sell values, build times, and factory tier requirements.
- **Database v10 Non-Destructive Migration**:
  - Upgraded schema to database version 10 in [`GamePersistenceService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/game_persistence_service.dart).
  - Added `prestige_count`, `golden_shares`, `lifetime_golden_shares`, `lifetime_revenue`, and `lifetime_units_shipped` columns to `game_state`.
  - Created `prestige_perks` table (`perk_id`, `unlocked_at`).
  - Added dedicated `resetRunDataForPrestige` atomic transaction method.
- **Testing & Quality Assurance**:
  - Created [`test/phase5_prestige_ipo_test.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/test/phase5_prestige_ipo_test.dart) (15/15 tests passing).
  - 60/60 tests passing across all modern project test suites (`phase2_b2b_logistics_test.dart`, `phase3_industry_branches_test.dart`, `phase4_rnd_lab_test.dart`, `factory_tier_system_test.dart`, `phase5_prestige_ipo_test.dart`).
  - Clean static analysis with 0 warnings or errors (`flutter analyze`).

---

## 🎨 Technical & Visual Evolution

1. **Custom Artwork**: Replace emoji icons with sleek vector illustrations or isometric rendered sprites for all products and machines.
2. **Haptic & Audio Feedback**: Tactile click haptics on manual build completion and machine cycle ticks.
3. **Cloud Save & Sync**: Backup SQLite databases securely via Google Play Games Services / iCloud.
