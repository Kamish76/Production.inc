# Production.INC v2.0 Major Update — Active Task Backlog & Release Roadmap (`TODO_SEP_23.md`)

> **Document Purpose**: This file serves as the active, granular task backlog and implementation tracker for finalizing the **Version 2.0 (v2.0 Major Update)** of **Production.INC**.
>
> 🚀 **Version 2.0 Context**: Core **Phases 1 through 5** are fully implemented (see [`FUTURE_PLANS.md`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/FUTURE_PLANS.md)). To guarantee rapid, agile, and modular delivery, remaining features and fixes are partitioned into bite-sized, single-responsibility phases: **Phase 6** (Immediate Priority: Usability & Fixes), **Phase 7** (Machine Caps & Dynamic Pricing), **Phase 8** (Batch Throughput & Bulk Procurement), **Phase 9** (Auto-Sell Dispatchers), **Phase 10** (Logistics Fleet Payload Limits), and **Phase 11** (Multi-Product Manifest Cart).

---

## 🗺️ Version 2.0 Active Finalization Roadmap

| Phase | System / Feature | Target Area | Status | Impact in v2.0 |
| :---: | :--- | :--- | :---: | :--- |
| **6** | **Current Priority: Usability, Ergonomics & Critical Fixes** | All Screens & Controls | ⏳ **Active Focus** | Resolves identified friction points: fleet counter on sell screen, lazy-loaded contracts archive, auto-buy buffer uncapping, unified machine cards, and RAM optimization. |
| **7** | **Machine Economy & Dynamic Pricing: Tier Limits & Salvage** | Control Screen (`Machines` Tab) & Engine | 📋 **Planned** | Implements tier-based machine ownership caps (10/20/30/40), exponential price scaling ($1,000 base, 1.18x–1.20x curve), and 50% machine salvage refund. |
| **8** | **High-Throughput Automation: Batch Crafting & Bulk Procurement** | Crafting Engine & Procurement Loop | 📋 **Planned** | Symmetrical production rate upgrades: Auto-Build Batch Throughput (items crafted/tick) and Auto-Buy Intake Multipliers (materials purchased/tick). |
| **9** | **Automated Outbound Distribution: Auto-Sell Dispatchers** | Machines Tab & Storefront Loop | 📋 **Planned** | Unlocks timid Tier 1 Auto-Sell (1 unit/tick baseline), batch fulfillment upgrades, and direct storefront retail sales (0 fleet slots consumed). |
| **10** | **Logistics Fleet Overhaul: Payload Capacities & Variety Caps** | Shipping Screen & Fleet Engine | 📋 **Planned** | Adds physical payload capacity (20 $\to$ 600 units) and variety limits (2 $\to$ 12 types) across Bikes, Vans, Trucks, and Planes so carrier tiers truly matter. |
| **11** | **Commercial Dispatch Manifest: Multi-Product Bulk Selling UI** | Sell Products Screen | 📋 **Planned** | Adds docked manifest staging tray, interactive review drawer, multi-product selection, and consolidated single-carrier dispatches. |

---

## 🛠️ Phase 6: Usability, Ergonomics & Critical System Fixes (⏳ Active Priority)

### 🎯 Objective & Overview
Phase 6 is the immediate active implementation priority for **Production.INC**, directly addressing player-reported friction points, UI ergonomics, and performance bottlenecks identified during gameplay testing. It focuses on resolving critical usability issues before adding further machine economy layers.

> [!IMPORTANT]
> **Active Focus**: This phase is prioritized for current implementation. All tasks below represent high-leverage fixes and ergonomics improvements that stabilize the existing core loop.

---

### 📋 Phase 6 Implementation Checklist

#### 1. 🏷️ Selling Products Screen: Logistics Fleet Capacity Visibility
- [ ] **Fleet Capacity Metric on Financial Card**:
  - Update [`FinancialStatusDisplay`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/financial_status_display.dart) (specifically when rendered in `FinancialDisplayMode.portfolio` on [`SellProductsScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/sell_products_screen.dart)) to display an ongoing fleet counter beside `Total Products` and `Portfolio Value`.
  - Format: `Fleets in Transit: X / Max` (e.g., `🚚 2/4` or `Fleets: 2/6 Active`).
  - Provide immediate visual feedback on whether transport lines are fully saturated without requiring the player to switch back and forth between the Sell and Shipping screens.
  - Responsive column layout with subtle divider bars matching existing financial metrics.

#### 2. 📋 B2B Bulk Requisitions: Auto-Sorting & Lazy-Loaded Archive
- [ ] **Completed Requisition Auto-Deprioritization**:
  - In [`ShippingScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/shipping_screen.dart) (`B2B Contracts` tab), automatically sort contracts so fulfilled/completed requisitions sink to the bottom of the list below active contracts.
- [ ] **Lazy-Loaded "Fulfilled Requisitions" Collapsible Section**:
  - Move fulfilled orders into a dedicated collapsible accordion/drawer (`Completed Requisitions (${fulfilled.length})`).
  - **Memory Optimization (RAM Conservation)**: Dynamically build contract item widgets *only* when the accordion is expanded (avoiding full widget instantiation and off-screen state holding in memory when collapsed).
  - Use `ListView.builder` with `shrinkWrap: true` or conditional child instantiation so completed orders don't bloat the widget tree or heap size during long play sessions.

#### 3. ⚙️ Machine Controls: Capacity Uncapping & UI Design Unification
- [ ] **Auto-Buy Resource Capacity Uncapping**:
  - Remove or raise the artificial capacity ceiling on auto-buy (currently capped at 20-25 or tier-restricted) in [`ProductionGameService.increaseAutoBuyCapacity`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart).
  - Align with auto-build machines behavior, allowing players to scale resource buffers freely as their late-game economy demands.
- [ ] **Unified Machine Controls UI Architecture**:
  - Standardize the design between **Auto-Buy Machines** and **Auto-Build Machines** in [`ControlScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart) (`Machines` tab).
  - Unify components into consistent modular cards (matching styling, border radiuses, dark gradients, and elevation).
  - Uniform layout structure for both machine types:
    - **Header**: Machine Icon + Title + Active/Paused Status Badge + Master Toggle Switch.
    - **Fleet/Machine Count**: Stepper / Quantity badge with standardized `Buy Machine ($1,000)` action button.
    - **Capacity Stepper**: Identical `[-]` / `[+]` button styling, accent color coding, and capacity unit labels.
    - **Telemetry / Status Strip**: Dynamic info pill showing active throughput (e.g., `Buying X materials every 5s` vs `Building Y items every cycle`).

#### 4. ⚡ Memory Optimization & Garbage Collection Pass (✅ Approved)
- [ ] **RAM & List Recycling Optimization**:
  - Audit `ListView` implementations across all main tabs ([`BuildProductsScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/build_products_screen.dart), [`SellProductsScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/sell_products_screen.dart), [`ShippingScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/shipping_screen.dart), [`ControlScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart)).
  - Apply efficient list recycling properties (`findChildIndexCallback`, `addRepaintBoundaries: true`, `addAutomaticKeepAlives: false` where appropriate).
  - Clean up discarded controllers and unmount heavy off-screen widgets to guarantee solid 60 FPS performance and avoid heap bloating during long play sessions.

#### 5. 🔔 Cross-Screen Logistics Notification Badges (✅ Approved)
- [ ] **Bottom Navigation & Screen Notification Badges**:
  - Display real-time badge counters on the bottom navigation bar on [`MainGameScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/main_game_screen.dart):
    - Highlight when logistics fleet dispatch slots become free and ready for dispatch.
    - Highlight when an active corporate contract is fulfilled and ready to claim.
  - Keeps the player continuously informed of factory throughput across screens without needing manual tab-checking.

---

### 💡 Suggested Additions to Phase 6 (Awaiting User Approval)

> [!IMPORTANT]
> The items in this section are design proposals. None of these items will be scheduled or implemented until explicitly reviewed and approved by the user.

- [ ] **Proposal A: Batch Purchase Options for Machinery**:
  - Add quick purchase multipliers (`x1`, `x5`, `Max`) for Auto-Buy and Auto-Build machines to avoid excessive button tapping during late-game expansions.
  - *Status*: ⏳ **Awaiting Approval**

- [ ] **Proposal B: Order Fulfillment Visual Micro-Interactions**:
  - Add subtle animated transitions (e.g., checkmark fade and gentle slide) when a contract is completed and moves to the fulfilled section.
  - *Status*: ⏳ **Awaiting Approval**

- [ ] **Proposal C: Quick Reserve Thresholds on Sell Screen**:
  - Allow players to set a "Keep Minimum" reserve quantity for intermediate parts so mass-selling finished goods does not accidentally wipe out materials needed for auto-build cycles or R&D deconstruction.
  - *Status*: ⏳ **Awaiting Approval**

- [ ] **Proposal D: End-to-End Regression Test Suite**:
  - Comprehensive automated integration tests covering the complete lifecycle: Garage Workshop $\to$ B2B Shipping $\to$ R&D Lab Overclocking $\to$ Megafactory $\to$ Wall Street IPO reset.
  - *Status*: ⏳ **Awaiting Approval**

---

## ⚙️ Phase 7: Machine Economy & Dynamic Pricing: Tier Limits & Salvage (📋 Planned)

### 🎯 Objective & Overview
Phase 7 establishes healthy economic fundamentals for factory machinery. Currently, machines cost a flat $1,000 forever with no caps, allowing players to out-scale the early game easily. Phase 7 implements **Tier-Gated Machine Caps**, **Compounding Dynamic Price Scaling**, and a **50% Machine Salvage Refund**.

> [!NOTE]
> **Status**: Planned and specified. Pure economy, pricing, and salvage pass—does not modify crafting rates or add new machine types.

---

### 📋 Phase 7 Core Features & Specifications

#### 1. 🏭 Tier-Gated Machine Ownership Limits
Restricts maximum machine purchasing based on current Factory Tier (`FactoryTier.id`):

| Factory Tier | Tier Name | Machine Limit (per category) | Progression Focus |
| :---: | :--- | :---: | :--- |
| **Tier 1** | Garage Workshop 🏚️ | **10 Machines** | Early manual bootstrapping & basic parts |
| **Tier 2** | Light Assembly Facility 🏭 | **20 Machines** | Intermediate automation & retail shipping |
| **Tier 3** | Precision Manufacturing Plant 🔬 | **30 Machines** | Complex mechatronics & B2B contracts |
| **Tier 4** | Megafactory Cleanroom 🚀 | **40 Machines** | Mass production flagships & R&D lab |

- Cap applies per machine category (`Auto-Buy`, `Auto-Build Basic`, `Auto-Build Intermediate`, `Auto-Build Complex`).
- UI feedback: Machine badge displays `Machines: 7 / 10 (Tier Limit)`. Once reached, the Buy button disables with an informative tooltip.

#### 2. 📈 Compounding Dynamic Price Scaling (1.20x Curve)
Replaces flat $1,000.00 pricing with an exponential scaling formula:
$$\text{Purchase Cost}(N) = \$1,000.00 \times (1.20)^N$$
*Where $N$ is the number of machines already owned in that category.*

| Owned ($N$) | Base Price | 1.20x Cost (Next Machine) | Total Capital Invested |
| :---: | :---: | :---: | :---: |
| **#1** | $1,000 | $1,000 | $1,000 |
| **#2** | $1,000 | $1,200 | $2,200 |
| **#3** | $1,000 | $1,440 | $3,640 |
| **#5** | $1,000 | $2,074 | $7,442 |
| **#10** | $1,000 | $5,160 | $25,959 |
| **#20** | $1,000 | $31,948 | $186,688 |

#### 3. ♻️ Machine Decommission & Salvage System (50% Refund)
Allows players to scrap owned machines to reclaim capital and free up tier capacity slots:
$$\text{Salvage Value}(N) = \left\lfloor 0.50 \times \left( \$1,000.00 \times (1.20)^{N - 1} \right) \right\rfloor$$
- Protective confirmation dialog: `"Salvage 1 Machine for +$X.XX?"`.
- Immediately restores tier capacity headroom and updates state atomically.

---

### 📋 Phase 7 Implementation Checklist
- [ ] Add tier machine cap validation in [`ProductionGameService.buyAutoBuyMachine`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart) and auto-build purchasing methods.
- [ ] Implement exponential price calculation helper `getMachinePrice(category, currentCount)`.
- [ ] Implement `salvageMachine(category)` awarding 50% refund.
- [ ] Update UI cards in [`ControlScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart) with tier limit counters and salvage action buttons.
- [ ] Unit tests covering tier cap enforcement, price escalation, and salvage refunds.

---

## ⚡ Phase 8: High-Throughput Automation: Batch Crafting & Bulk Procurement (📋 Planned)

### 🎯 Objective & Overview
Phase 8 scales factory output speed without violating the machine caps introduced in Phase 7. It adds symmetrical throughput upgrades to existing machinery: **Batch Build Throughput** (crafting multiple items per cycle tick) and **Auto-Buy Intake Multipliers** (purchasing raw materials in bulk bursts).

---

### 📋 Phase 8 Core Features & Specifications

#### 1. 🔨 Auto-Build Batch Throughput (Items Built Per Tick)
Allows an auto-build machine to process items in batches rather than 1 unit per cycle:
- **Level 1 (Base)**: 1 item built per cycle tick.
- **Level 2**: 2 items built per cycle tick.
- **Level $K$**: $K$ items built per cycle tick (Capped by Factory Tier limit).
- **Consumption Safety**: If resources only cover 3 items but throughput is 5, machine crafts 3 items cleanly without stalling.
- **Upgrade Cost**: $\$1,000.00 \times (1.20)^{\text{Level} - 1}$.

#### 2. 🛒 Auto-Buy Intake Multiplier (Bulk Material Procurement Logistics)
Amplifies raw material intake volume per tick so buying keeps up with accelerated crafting:
$$\text{Purchases Per Tick} = \left\lfloor \text{Machines Owned} \times 5 \times \text{Multiplier}(\text{Level}) \right\rfloor$$
- Progression: **Level 1 (1.00x / 50 items for 10 machines)** $\to$ **Level 2 (1.25x / 62 items)** $\to$ **Level 3 (1.50x / 75 items)** $\to$ **Level 5 (2.00x / 100 items)**.
- Upgrade Cost: Follows identical compounding curve: $\$1,000.00 \times (1.20)^{\text{Level} - 1}$.
- Respects player cash balance and stops buying when warehouses reach capacity limits.

---

### 📋 Phase 8 Implementation Checklist
- [ ] Add `autoBuildThroughputLevel` and `autoBuyIntakeLevel` state variables in [`GameState`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_state.dart).
- [ ] Update `_processAutoBuildQueue` to process items up to the batch throughput limit.
- [ ] Update `_processAutoBuy` to multiply raw material purchase volume by the intake multiplier.
- [ ] Add upgrade action buttons with live throughput telemetry pills to machine cards.
- [ ] Unit tests for batch production, partial material consumption, and intake multipliers.

---

## 📦 Phase 9: Automated Outbound Distribution: Auto-Sell Dispatchers (📋 Planned)

### 🎯 Objective & Overview
Phase 9 completes the industrial automation loop (**Auto-Buy $\to$ Auto-Build $\to$ Auto-Sell**). It introduces **Auto-Sell Dispatchers** to automate finished goods sales, featuring an early Tier 1 unlock with a gentle, timid baseline.

---

### 📋 Phase 9 Core Features & Specifications

#### 1. 🏪 Early Tier 1 Timid Baseline (Hands-Free Early Game)
- **Unlocked at Tier 1 (Garage Workshop)**: Provides immediate passive income early on.
- **Timid Starting Baseline**: Deliberately small—**each machine automatically sells only 1 product unit per cycle tick** (e.g. 1 unit every 5s).
- *Example*: 3 Auto-Sell machines sell only 3 units total per tick. Generates steady cash flow to feed raw material purchases without draining manual wholesale stocks.

#### 2. 📈 Auto-Sell Batch Fulfillment Throughput Upgrades
- **Throughput Formula**: $\text{Units Sold Per Tick} = \text{Machines Owned} \times \text{Fulfillment Level}$.
- Level 1: 1 unit / machine / tick $\to$ Level 2: 2 units / machine / tick $\to$ Level $K$.
- Machine cost and upgrade costs follow the standard $1,000 base with $1.20\times$ compounding curve.

#### 3. 🚚 Zero-Fleet-Slot Storefront Pipeline (Fleet Protection)
- Auto-Sell operates as **direct local storefront walk-in sales** (**0 fleet slots consumed**).
- *Critical Game Balance*: Guarantees that Auto-Sell never jams the player's 2 bike slots, preserving fleet carriers for strategic B2B corporate contracts and manual wholesale dispatches.

#### 4. 🛡️ Inventory Reserve Protections
- Auto-Sell only targets finished manufactured products (never raw materials or items below configured reserve thresholds).
- Prioritizes lowest-tier products first to protect high-tier goods.

---

### 📋 Phase 9 Implementation Checklist
- [ ] Add `autoSellMachines` and `autoSellThroughputLevel` to [`GameState`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_state.dart).
- [ ] Add `_processAutoSell` loop in [`ProductionGameService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart) selling eligible inventory per cycle tick.
- [ ] Create `AutoSellMachineCard` in `Machines` tab of [`ControlScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/control_screen.dart).
- [ ] Unit tests verifying auto-sell execution, zero-fleet-slot isolation, and inventory reserve safety.

---

## 🚚 Phase 10: Logistics Fleet Overhaul: Payload Capacities & Variety Caps (📋 Planned)

### 🎯 Objective & Overview
Phase 10 gives physical meaning to carrier fleet tiers (**Courier Bikes $\to$ Delivery Vans $\to$ Freight Trucks $\to$ Cargo Planes**). It implements **Carrier Payload Capacity** and **Product Variety Caps**, preventing early-game mass dumping and making fleet upgrades essential for moving high-volume factory output.

---

### 📋 Phase 10 Core Features & Specifications

#### 1. 📦 Carrier Fleet Payload & Variety Matrix

| Fleet Tier | Carrier Name | Max Product Varieties | Max Units / Type | Total Payload Capacity | Speed Multiplier | Concurrent Slots | Progression Role |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Tier 1** | **Courier Bikes 🚲** | **2 Types** | **10 Units** | **20 Units Max** | 1.0x (Base) | 2 Slots | Early-game small parcel runs; strictly limited payloads |
| **Tier 2** | **Delivery Vans 🚐** | **4 Types** | **20 Units** | **60 Units Max** | 1.25x (+25%) | 4 Slots | Suburban retail distribution; handles mixed intermediate batches |
| **Tier 3** | **Freight Trucks 🚚** | **7 Types** | **50 Units** | **200 Units Max** | 1.60x (+60%) | 7 Slots | Regional industrial transport; bulk clears whole factory branches |
| **Tier 4** | **Cargo Planes ✈️** | **12 Types** *(All)* | **100 Units** | **600 Units Max** | 2.50x (+150%) | 12 Slots | Global air freight; heavy mass liquidation for Megafactory runs |

- **Why This Matters**: A starter bike can no longer ship 100 items. To move 60+ items, players must upgrade to Delivery Vans; to move 200+ items across diverse product lines, players must acquire Freight Trucks.

#### 2. 📋 Fleet UI & Payload Enforcement
- Update [`FleetUpgradeCard`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/fleet_upgrade_card.dart) to display payload capacity and max product variety badges.
- Enforce per-shipment payload and variety constraints in [`ProductionGameService.sellProduct`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart).

---

### 📋 Phase 10 Implementation Checklist
- [ ] Add `maxPayloadUnits`, `maxProductVarieties`, and `maxUnitsPerType` fields to [`LogisticsFleetTier`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/models/game_models.dart).
- [ ] Update `GameData.fleetTiers` with calibrated payload limits.
- [ ] Update `FleetUpgradeCard` UI with visual payload badges.
- [ ] Enforce payload limits in `sellProduct` validation logic.
- [ ] Unit tests for fleet payload limits and upgrade transitions.

---

## 🛒 Phase 11: Commercial Dispatch Manifest: Multi-Product Bulk Selling UI (📋 Planned)

### 🎯 Objective & Overview
Phase 11 delivers the user-facing **Shipping Manifest Builder (Bulk Sell Cart)** on the Sell Products Screen. Players can stage multiple product varieties into a single shipment, adjust quantities, review projected revenue, and dispatch a consolidated carrier.

---

### 📋 Phase 11 Core Features & Specifications

#### 1. 🛒 Staged Shipping Manifest State Engine
- Staging state in [`ProductionGameService`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/services/production_game_service.dart):
  - `addToManifest(productId, quantity)`
  - `removeFromManifest(productId)`
  - `updateManifestQuantity(productId, quantity)`
  - `clearManifest()`
  - `dispatchManifest()` — validates fleet payload limits, creates a consolidated `ShippingOrder`, and initiates transit.

#### 2. 🎨 Docked Manifest Tray & Review Drawer UI
- **Docked Manifest Tray**: Renders above bottom navigation on [`SellProductsScreen`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/screens/sell_products_screen.dart):
  - Live summary: `📦 3 Varieties • 18 / 60 Units • Total: $1,420.00`.
  - Action buttons: `Review Manifest` and `🚚 Dispatch Carrier`.
- **Interactive Review Drawer**:
  - Itemized rows with product thumbnail, unit price, and subtotal.
  - Stepper controls: `[-]` decrement, `[+]` increment, `[Max]` fill, `[🗑️]` remove.
  - Carrier payload visual progress bar.

#### 3. ⏱️ Consolidated Multi-Item Transit Calculation
Mixed-cargo transit time formula:
$$\text{Base Transit Time} = \max_{p \in \text{Manifest}}(\text{baseTime}(p)) \times \left(1 + 0.04 \times (\text{Total Units} - 1)\right)^{0.5}$$
$$\text{Actual Shipping Time} = \frac{\text{Base Transit Time}}{\text{Fleet Speed Multiplier} \times \text{Tech Multipliers}}$$
- Dispatches as **1 consolidated carrier run taking 1 fleet slot**, rather than dozens of separate runs.

---

### 📋 Phase 11 Implementation Checklist
- [ ] Implement manifest state and methods in `ProductionGameService`.
- [ ] Build `ShippingManifestTray` widget for `SellProductsScreen`.
- [ ] Build `ShippingManifestDrawer` bottom sheet with stepper controls.
- [ ] Update `ItemCard` in Sell mode with "Add to Manifest" chips and staged count pills.
- [ ] Create `test/phase11_bulk_manifest_test.dart` validating staging, dispatch, and settlement.

