# Production.INC — Factory Tycoon (v2.0.0)

[![Flutter Version](https://img.shields.io/badge/Flutter-3.7%2B-blue.svg)](https://flutter.dev/)
[![Version](https://img.shields.io/badge/Version-2.0.0%2B20-green.svg)](pubspec.yaml)
[![Tests](https://img.shields.io/badge/Tests-314%2F314%20Passing-brightgreen.svg)](test/)
[![Analysis](https://img.shields.io/badge/Analysis-0%20Issues-brightgreen.svg)](analysis_options.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Production.INC** is an end-to-end industrial tycoon and supply chain simulation game built with Flutter. Transform a modest garage workshop into an automated multi-branch megafactory, fulfill corporate B2B requisitions, research breakthrough technologies, dispatch carrier transport fleets, and take your manufacturing empire public on Wall Street!

---

## 🎮 Core Game Systems (Version 2.0)

### 🏭 1. Factory Tiers & Expansion Licensing
Progress through 4 distinct facility tiers that unlock new manufacturing recipes, expand machine limits, and scale your industrial operations:
1. **Tier 1 (Garage Workshop 🏚️)**: Humble beginnings with manual assembly and basic electronics.
2. **Tier 2 (Light Assembly Facility 🏭)**: Intermediate component fabrication and first commercial corporate contracts.
3. **Tier 3 (Precision Manufacturing Plant 🔬)**: Complex mechatronics, advanced robotics, and heavy freight logistics.
4. **Tier 4 (Megafactory Cleanroom 🚀)**: High-tech flagship cleanrooms, clean energy systems, and global air freight.

### 🌐 2. Three Industry Branches & Dynamic Catalog
Manufacture across three specialized industrial sectors:
- **Consumer Electronics**: Circuit boards, microprocessors, camera modules, tablets, and flagship smartphones.
- **Robotics & Mechatronics**: Precision servos, microcontrollers, sensor arrays, and commercial robotic kits.
- **Clean Energy Systems**: Solar cells, lithium battery packs, power inverters, and utility-scale solar panels.

### 🤖 3. Full-Spectrum Automation Engine
Automate your factory floor from raw materials intake to retail storefront sales:
- **Auto-Buy Machines**: Automatically procure raw materials with intake multipliers to feed rapid assembly lines.
- **Auto-Build Machines**: Batch manufacturing throughput constructs multiple units per tick.
- **Auto-Sell Storefront Dispatchers**: Hands-free walk-in customer sales consuming **0 fleet slots**, leaving transport carriers free for bulk contracts.
- **Dynamic $1.20^N$ Machine Economy**: Factory tier ownership caps, exponential price scaling, and 50% capital salvage refunds.

### 🚚 4. Commercial Logistics & Shipping Manifest
- **Tiered Logistics Fleet**: Upgrade from *Courier Bikes (🚲)* $\to$ *Delivery Vans (🚐)* $\to$ *Freight Trucks (🚚)* $\to$ *Cargo Planes (✈️)*, scaling transit velocity (+150%) and payload capacities up to 600 units.
- **Bulk Shipping Manifest Cart**: Multi-product staging cart with interactive review drawer and square-root consolidated transit times.
- **B2B Corporate Contracts**: Partner with AI clients (*Apex Telecom*, *Solaria Energy*, *Nova Robotics*), fulfill bulk Lock & Ship requisitions, and climb corporate reputation tiers for permanent discounts and cash bonuses.

### 🧪 5. R&D Laboratory & Technology Tree
- **Deconstruction Bay**: Convert surplus manufactured goods into Science Points.
- **4 Tech Branches**: Assembly Line Velocity, Procurement Logistics, Fleet Efficiency, and Storage Mastery.

### 🌟 6. Prestige / Initial Public Offering (IPO)
- Liquidate your company on Wall Street for **Golden Shares**.
- Compounding permanent multipliers on production speed and market valuation for endless replayability.

---

## 📱 Game Screens Overview

1. **Buy Materials Screen**: Purchase raw materials (Cardboard, Metals, Plastic, Glass, Advanced Metals, Rare Minerals) with bulk multipliers and client discount badges.
2. **Build Products Screen**: Manage manual and automated production queues across Electronics, Robotics, and Clean Energy branches.
3. **Sell Products Screen (Sales Hub)**: Manual retail sales, docked Bulk Manifest Tray, and corporate B2B Requisitions feed with Lock & Ship fulfillment.
4. **Shipping Screen**: Active fleet operations, countdown timers, carrier upgrades, and historical shipping logs.
5. **Control Center Screen**: Tabbed industrial management center:
   - **Machines Tab**: Auto-Buy, Auto-Build, and Auto-Sell controls, throughput upgrades, and machine salvage.
   - **Tiers Tab**: Factory tier roadmap, licensing requirements, and facility upgrades.
   - **R&D Lab Tab**: Deconstruction Bay and 4-branch Technology Tree.
   - **Prestige Tab**: Wall Street IPO valuation, Golden Shares ledger, and company liquidation.
6. **Settings Screen**: Audio, haptics, dark theme, database diagnostics, and safe data resets.

---

## 🏗️ Technical Architecture

The project follows a clean **Layered Architecture (UI $\to$ Service/Logic $\to$ State/Data)** powered by Flutter's `Provider`:

```text
Game1/
├── assets/
│   └── images/                     # App icons and visual assets
├── lib/
│   ├── main.dart                   # Entry point, Provider configuration, theme
│   ├── constants/
│   │   └── game_constants.dart     # Centralized colors, timing constants, economy values
│   ├── models/
│   │   ├── game_models.dart        # Immutable models: Material, Product, Machine, CorporateContract
│   │   ├── game_data.dart          # Catalogs: recipes, factory tiers, fleet tiers, AI corporations
│   │   └── game_state.dart         # Player state: treasury, inventory, machine levels, R&D tech
│   ├── services/
│   │   ├── production_game_service.dart # Central coordinator, tick loops, and economy
│   │   ├── product_unlock_service.dart  # Recipe unlocking conditions & state caching
│   │   ├── machine_builder.dart         # Auto-build worker logic
│   │   ├── machine_buyer.dart           # Auto-buy worker logic
│   │   └── game_persistence_service.dart# SQLite database handling, v13 migrations, auto-save
│   ├── screens/                    # Core screens (Buy, Build, Sell, Shipping, Control, Settings)
│   └── widgets/                    # Reusable components (ItemCard, MachineCard, ManifestTray, etc.)
├── docs/                           # Central documentation hub and sprint archives
│   ├── DOCUMENTATION_INDEX.md      # Master documentation index
│   └── sprints/                    # Historical sprint archives (01_legacy to 04_v2.0)
├── tool/                           # Database integrity & diagnostic scripts
└── test/                           # 314 automated unit, widget, and integration tests
```

### 🛡️ Reliability & Invariants
- **100% Offline Single-Player**: Zero network dependencies, zero telemetry tracking, and zero dangerous Android runtime permissions.
- **SQLite Database Integrity**: Automated non-destructive migrations (v1 through v13) preserving existing save data.
- **Memory Conservation**: Aggressive widget list recycling (`addAutomaticKeepAlives: false`) and lazy-loaded drawers ensuring consistent 60 FPS performance on low-end hardware.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) `^3.7.0` (Dart 3+)
- Android Studio / VS Code with Flutter extension
- Android device or emulator (Android 7.0+ / API 24+)

### Installation & Run
```bash
# Clone the repository
git clone <repository-url>
cd Game1

# Install dependencies
flutter pub get

# Run the game in debug mode
flutter run
```

### Running Tests & Static Analysis
```bash
# Run the complete test suite (314 tests)
flutter test

# Run static analysis (0 warnings / 0 lints)
flutter analyze
```

### Building for Release
```bash
# Build Android App Bundle (.aab) for Google Play Console
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Build Release APK
flutter build apk --release
```

---

## 📚 Documentation

For complete architectural specifications, API references, and development guidelines, explore the [Documentation Index](docs/DOCUMENTATION_INDEX.md):

- [Development Guide](docs/DEVELOPMENT_GUIDE.md) — Coding conventions, git workflow, and style guide.
- [API Documentation](docs/API_DOCUMENTATION.md) — Service methods, state signatures, and event contracts.
- [Database Schema](docs/DATABASE_SCHEMA.md) — SQLite schema tables and version migration history.
- [Sprint 4 (v2.0 Major Update)](docs/sprints/04_v2.0_major_update/README.md) — Complete 12-phase specification and verification report.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
