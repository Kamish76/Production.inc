# Production.INC v2.0 Major Update — Active Task Backlog & Release Roadmap (`TODO_SEP_23.md`)

> **Document Purpose**: This file serves as the active, granular task backlog and implementation tracker for finalizing the **Version 2.0 (v2.0 Major Update)** of **Production.INC**.
>
> 🚀 **Version 2.0 Context**: While core **Phases 1 through 5** are fully implemented (see [`FUTURE_PLANS.md`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/FUTURE_PLANS.md)), this tracker drives the finalization of the v2.0 release: **Phase 6** (Testing, Ergonomics & Memory Polish) and **Phase 7** (Machine & Automation Overhaul).

---

## 🗺️ Version 2.0 Active Finalization Roadmap

| Phase | System / Feature | Target Area | Status | Impact in v2.0 |
| :---: | :--- | :--- | :---: | :--- |
| **6** | **Final Testing, Ergonomics & Systems Polish** | All Screens & Controls | ⏳ **In Exploration & Checklist** | Unifies machine UI, uncaps autobuy, adds fleet visibility, and optimizes memory with lazy loading. |
| **7** | **Machine & Automation Overhaul: Dynamic Scaling & Upgrades** | Control Screen (`Machines` Tab) & Engine | 📋 **Planned & Approved** | Implements tier-based machine caps, exponential price scaling (1.15x–1.2x), batch build throughput, bulk autobuy intake multipliers, and machine salvage. |

---

## 🛠️ Phase 6: Final Testing, Ergonomics & Systems Polish (⏳ Exploration & Checklist)

### 🎯 Objective & Overview
Phase 6 represents the comprehensive refinement, ergonomic tuning, and memory optimization pass for **Production.INC**. While new features from Phases 1–5 are active and undergoing end-to-end playtesting, this phase addresses UI friction points, streamlines machine automation, improves real-time operational feedback, and implements lazy rendering for performance.

> [!NOTE]
> **Status**: Specification and exploration stage. No code modifications are applied yet while user verification and AI gameplay testing exploration are ongoing.

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

## ⚙️ Phase 7: Machine & Automation Overhaul: Tier Limits, Dynamic Scaling & Batch Upgrades (📋 Planned)

### 🎯 Objective & Overview
Phase 7 delivers a comprehensive game-economy overhaul to the machinery and automation systems. While the current automated loops operate reliably, flat static pricing ($1,000.00 forever) and unlimited machine scaling allow players to easily out-scale the early-to-mid game economy. Phase 7 introduces **Tier-Gated Machine Limits**, **Compounding Dynamic Price Scaling**, and symmetrical automation upgrades: **Batch Build Throughput** (items crafted per tick) and **Auto-Buy Intake Multiplier** (bulk procurement per tick) to make factory automation deeply strategic and proportional to player progression.

> [!NOTE]
> **Status**: Design and specification phase. No code modifications are implemented yet until review and approval.

---

### 📋 Phase 7 Core Features & Specifications

#### 1. 🏭 Tier-Gated Machine Ownership Limits
To align machinery scaling with factory expansion milestones, machine purchasing is restricted by the current **Factory Tier** (`FactoryTier.id`):

| Factory Tier | Tier Name | Machine Limit (per category) | Progression Focus |
| :---: | :--- | :---: | :--- |
| **Tier 1** | Garage Workshop 🏚️ | **10 Machines** | Early manual bootstrapping & basic parts |
| **Tier 2** | Light Assembly Facility 🏭 | **20 Machines** | Intermediate automation & retail shipping |
| **Tier 3** | Precision Manufacturing Plant 🔬 | **30 Machines** | Complex mechatronics & B2B contracts |
| **Tier 4** | Megafactory Cleanroom 🚀 | **40 Machines** *(or 50)* | Mass production flagships & R&D lab |

- **Scope of Limit**:
  - The cap applies per machine category:
    - Auto-Buy Machines: Up to the tier limit (e.g., 10 in Tier 1, 20 in Tier 2).
    - Auto-Build Machines: Up to the tier limit per crafting tier category (`basicParts`, `intermediate`, `complex`).
- **UI Feedback**:
  - Machine count badges display tier limits: `Machines: 7 / 10 (Tier Limit)`.
  - Once capped, the "Buy Machine" button safely disables with tooltip: *"Factory Tier Limit Reached — Upgrade Tier to expand machine capacity"*.

---

#### 2. 📈 Compounding Dynamic Price Scaling (Exponential Multiplier)
Replacing the flat $1,000.00 cost with an exponential curve so machine pricing naturally matches the player's escalating revenue.

- **Pricing Formula**:
  $$\text{Purchase Cost}(N) = \text{Base Price} \times (\text{Multiplier})^N$$
  *Where $N$ is the number of machines already owned (or current upgrade level), and $\text{Base Price} = \$1,000.00$.*

- **Multiplier Analysis & Value Comparison**:
  Below is a comparison of price progression across different multiplier options:

  | Owned ($N$) | Flat (Current) | **1.15x (Smooth)** | **1.18x (Balanced)** | **1.20x (Standard)** | **1.25x (Steep)** |
  | :---: | :---: | :---: | :---: | :---: | :---: |
  | **#1** | $1,000 | $1,000 | $1,000 | $1,000 | $1,000 |
  | **#2** | $1,000 | $1,150 | $1,180 | $1,200 | $1,250 |
  | **#3** | $1,000 | $1,323 | $1,392 | $1,440 | $1,563 |
  | **#5** | $1,000 | $1,749 | $1,939 | $2,074 | $2,441 |
  | **#8** | $1,000 | $2,660 | $3,185 | $3,583 | $4,768 |
  | **#10** | $1,000 | $3,518 | $4,436 | $5,160 | $7,451 |
  | **#15** | $1,000 | $7,076 | $10,147 | $12,839 | $22,737 |
  | **#20** | $1,000 | $14,232 | $23,212 | $31,948 | $69,389 |

  > [!TIP]
  > **Recommendation**: 
  > - **1.18x – 1.20x** provides an ideal balance. At machine #10 ($4,436–$5,160), it demands genuine investment from Tier 1 revenue without feeling impossible, while machine #20 ($23k–$31k) aligns smoothly with Tier 2/3 profit margins.

---

#### 3. ⚡ New Machine Upgrade: Batch Build Throughput (Items Built Per Tick)
Currently, an auto-build machine produces 1 unit per cycle tick regardless of queue size. This upgrade allows machines to multi-process items in batches.

- **How It Works**:
  - **Base Level 1**: 1 item built per cycle tick.
  - **Level 2**: 2 items built per cycle tick.
  - **Level 3**: 3 items built per cycle tick.
  - **Level $K$**: $K$ items built per cycle tick.
- **Example Scenario**:
  - A player queues **20 Wires**.
  - At **Level 1** (1 item/tick): Requires **20 ticks** to complete.
  - Upgraded to **Level 5** (5 items/tick): Requires only **4 ticks** to complete all 20 Wires!
- **Material Consumption & Constraints**:
  - Each tick consumes materials for as many items as the machine can craft up to its batch limit.
  - If a player has materials for only 3 items but throughput is 5, the machine cleanly builds 3 items and consumes available materials without stalling.
- **Upgrade Pricing & Gating**:
  - **Base Upgrade Price**: $\$1,000.00$ (equal to base machine cost).
  - **Price Scaling**: Follows the identical price multiplier formula:
    $$\text{Upgrade Cost} = \$1,000.00 \times (\text{Multiplier})^{\text{Level} - 1}$$
  - **Tier Limit**: Max throughput level is capped by the current Factory Tier limit (e.g., Level 10 max at Tier 1, Level 20 at Tier 2).

---

#### 4. 🛒 New Machine Upgrade: Auto-Buy Intake Multiplier (Bulk Procurement Logistics) (✅ Approved)
Symmetric to the Auto-Build batch throughput upgrade, this upgrade amplifies raw material intake volume per tick so automated buying keeps up with accelerated manufacturing lines without requiring machine counts beyond factory tier limits.

- **Current Baseline**:
  $$\text{Total Items Per Tick} = \text{Machines Owned} \times \text{Base Intake (5 items)}$$
  *Example: 10 machines buy 50 items/tick; 20 machines buy 100 items/tick.*
  Materials are allocated in priority order (`cardboard` $\to$ `plastic` $\to$ `basic_metals` $\to$ `glass` $\to$ `advanced_metals`) up to configured capacity limits.
- **The Upgraded Formula**:
  $$\text{Total Purchases Per Tick} = \left\lfloor \text{Machines Owned} \times \text{Base Rate (5)} \times \text{Intake Multiplier}(\text{Level}) \right\rfloor$$
  *(Equivalently: $\text{Effective Rate Per Machine} = 5 \times \text{Multiplier}$)*
- **Approved Progression Model (Additive +25% / +0.25x per level)**:

  | Upgrade Level | Multiplier Rate | Effective Yield per Machine | 10 Machines Yield |
  | :---: | :---: | :---: | :---: |
  | **Level 1** *(Base)* | **1.00x** | 5.0 items / machine | **50 items / tick** |
  | **Level 2** | **1.25x** | 6.25 $\approx$ 6 items / machine | **62 items / tick** |
  | **Level 3** | **1.50x** | 7.5 $\approx$ 7 items / machine | **75 items / tick** |
  | **Level 4** | **1.75x** | 8.75 $\approx$ 8 items / machine | **87 items / tick** |
  | **Level 5** | **2.00x** | 10.0 items / machine | **100 items / tick** |
  | **Level 10** | **3.25x** | 16.25 $\approx$ 16 items / machine | **162 items / tick** |

- **Upgrade Economics & Gating**:
  - **Base Upgrade Cost**: $\$1,000.00$ (equal to base machine cost).
  - **Price Scaling**: Follows the identical $1.20\times$ compounding multiplier:
    $$\text{Upgrade Cost} = \$1,000.00 \times (1.20)^{\text{Level} - 1}$$
  - **Tier Limit**: Maximum upgrade level is capped by the current Factory Tier limit (Tier 1 = Level 10, Tier 2 = Level 20).
- **Distinction from Capacity & Cash Safety**:
  - *Intake Multiplier* controls **throughput speed** (materials arriving per tick).
  - *Resource Capacity* controls **warehouse storage limits** (buffer ceiling before pausing).
  - *Cash Protection*: Auto-buy respects the player's wallet balance; if total cost exceeds available funds, it buys proportionally without debt or stalling.
- **UI Integration**:
  - Auto-Buy card displays live throughput telemetry:
    `⚡ Intake Rate: 75 items/tick (10 machines × 5 × 1.50x Lv 3)`
  - Clear upgrade action button: `Upgrade Procurement (Lv 4: 1.75x) — $1,728`.

---

#### 5. ♻️ Machine Decommission & Salvage System (50% Refund) (✅ Approved)
Allows players to decommission and scrap owned machinery in exchange for liquid capital, giving players full flexibility to rebalance their factory floors across progression tiers.

- **Refund Mechanics**:
  - Selling back an Auto-Buy or Auto-Build machine awards a **50% cash refund** calculated from the last purchase price:
    $$\text{Salvage Value}(N) = \left\lfloor 0.50 \times \left( \$1,000.00 \times (1.20)^{N - 1} \right) \right\rfloor$$
    *Where $N$ is the current count of machines owned in that category.*
- **Strategic Impact**:
  - Frees up valuable machine capacity within factory tier limits when retooling production lines (e.g., selling Tier 1 Basic auto-builders to make room for Tier 3 Complex auto-builders).
  - Provides emergency liquidity during capital-intensive contract deadlines or tier licensing upgrades.
- **Safety Modal & UI Feedback**:
  - Decommission action button located in the machine controls card header with a protective confirmation dialog (`"Salvage 1 Machine for +$X.XX?"`).
  - Immediately restores available tier capacity headroom, updates live production rates, and persists state atomically.

---

### 💡 Suggested Additions to the Feature (Awaiting User Approval)

> [!IMPORTANT]
> The items in this section are design proposals. None of these items will be scheduled or implemented until explicitly reviewed and approved by the user.

- [ ] **Proposal A: Compounding Bulk Machine Purchase (`Buy +5`, `Buy Max`)**:
  - With exponential pricing, buying multiple machines manually requires repeatedly clicking through escalating prices.
  - Implementation: Add `+5` and `Max` buttons calculating total cost via geometric series summation:
    $$S_n = \text{Base} \times r^k \times \frac{r^n - 1}{r - 1}$$
  - *Status*: ⏳ **Awaiting Approval**

- [ ] **Proposal B: Operational Maintenance Overhead (Running Cost per Tick)**:
  - Add small operational costs ($1.00 – $2.50 per active machine per tick) deducted from cash flow.
  - Gives tactical meaning to turning machines on/off when idling or unoptimized.
  - *Status*: ⏳ **Awaiting Approval**

- [ ] **Proposal C: Prestige Perk Synergy ("Industrial Discount" & "Modular Robotics")**:
  - Introduce Golden Share perks in the Wall Street Prestige Store:
    1. *Modular Standard (🌟 6 Shares)*: Reduces machine price compounding multiplier by -0.04 (e.g., 1.20x $\to$ 1.16x).
    2. *Factory Over-Licensing (🌟 8 Shares)*: Increases the machine limit of every tier by +10.
  - *Status*: ⏳ **Awaiting Approval**
