# Production.INC

A sophisticated Flutter-based mobile business simulation game where you discover, build, and manage complex production chains from basic materials to premium consumer electronics!

## Game Concept

**Discover • Build • Optimize • Expand!**

Start by gathering raw materials and discovering what you can build. Progress through increasingly complex production tiers - from basic parts to intermediate components, complex assemblies, and premium retail products. Master supply chain management and unlock advanced manufacturing capabilities!

## Current Features (v1.4.19)

### 📦 Production Tiers
- **Materials** - 6 raw materials (cardboard, plastic, metals, glass, etc.)
- **Basic Parts** - 10 fundamental components (boxes, wires, circuits, batteries, etc.)
- **Intermediate Parts** - 4 sophisticated assemblies (processors, displays, cameras, etc.)
- **Complex Parts** - 1 advanced multi-component system (camera modules)
- **Retail Products** - 8 consumer-ready products (speakers, smartphones, solar panels, etc.)

### 🔓 Progressive Unlock System
- **Discovery-Driven** - Products unlock as you gather required materials
- **Logical Progression** - Basic → Intermediate → Complex → Retail unlocking
- **Production-Ready** - Only unlock when you can actually manufacture the item
- **Smart Caching** - Optimized unlock condition checking for smooth gameplay

### 🏭 Advanced Production Features
- **Production Queue System** - Queue multiple items of the same type
- **Quantity Preferences** - Remember your preferred build/buy/sell quantities
- **Real-Time Progress** - Live production timers with visual indicators
- **Grouped Display** - Clean UI showing production status efficiently

### Five Core Game Screens

1. **Buy Materials** - Purchase raw materials with bulk buying options
2. **Build Products** - Manage production queues and unlock new items
3. **Sell Products** - Market your finished products for profit
4. **Shipping** - Automated logistics system for bulk sales
5. **Settings** - Game configuration and data management

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android device or emulator
- VS Code or Android Studio

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd Game1
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the game:
   ```bash
   flutter run
   ```

## How to Play

1. **Start with $100** - Use this to begin your manufacturing empire
2. **Discover Products** - Buy materials to unlock new products you can build
3. **Build Supply Chains** - Create basic parts, combine into intermediate components
4. **Unlock Advanced Products** - Progress through tiers to unlock complex electronics
5. **Optimize Production** - Queue multiple items and manage production efficiently
6. **Scale Your Business** - Reinvest profits to expand your manufacturing capabilities

### 🎯 Progression Example
- Buy **plastic** and **basic_metals** → Unlock **wires** and **circuits**
- Build **wires** and **circuits** → Unlock **sound_driver** 
- Combine components → Build and sell **speaker** for significant profit
- Continue unlocking → Eventually build **smartphones** for maximum profitability

### 💰 Economic Strategy
- **Materials**: $2-8 each (raw inputs)
- **Basic Parts**: $5-35 each (simple components)  
- **Intermediate Parts**: $50-150 each (complex assemblies)
- **Retail Products**: $120-800 each (finished electronics)
- **Profit Focus**: Higher-tier products offer exponentially better profit margins

## 🚀 Advanced Features

### Production Queue Management
- Queue multiple items of the same type for efficient production
- Only one item per product type produces at a time (realistic manufacturing)
- Visual indicators show active vs queued production status

### Smart Quantity Preferences
- Game remembers your preferred quantities for buy/build/sell operations
- Click product cards to use saved preferences, or click buttons for specific amounts
- Consistent interaction patterns across all screens

### Performance Optimization
- Intelligent unlock condition caching (85% faster than v1.4.18)
- Optimized database operations with incremental saves
- Smart timer management based on active operations
- Reduced battery usage and smooth 60fps gameplay

## 🏗️ Technical Architecture

```
lib/
├── main.dart                           # App entry point with global setup
├── constants/
│   └── game_constants.dart             # Centralized configuration values
├── models/
│   ├── game_models.dart               # Core data models and structures
│   ├── game_state.dart                # Player state and progress tracking
│   └── game_data.dart                 # Complete game content definitions
├── services/
│   ├── production_game_service.dart   # Main game logic and state management
│   ├── product_unlock_service.dart    # Progressive unlock system
│   └── game_persistence_service.dart  # Database and save management
├── widgets/
│   ├── common_widgets.dart            # Shared UI components
│   ├── product_card.dart              # Product display component
│   └── production_status_widget.dart  # Production status display
└── screens/
    ├── main_menu_screen.dart          # Navigation hub
    ├── buy_materials_screen.dart      # Material purchasing
    ├── build_products_screen.dart     # Production management
    ├── sell_products_screen.dart      # Product sales
    ├── shipping_screen.dart           # Bulk order management
    └── settings_screen.dart           # Configuration and data
```

## 📚 Documentation

- **[API Documentation](docs/API_DOCUMENTATION.md)** - Complete service and method reference
- **[Development Guide](docs/DEVELOPMENT_GUIDE.md)** - Coding standards and contribution guidelines  
- **[Database Schema](docs/DATABASE_SCHEMA.md)** - Complete database structure documentation

## 🔧 Development & Build

### Development Setup
```bash
# Install dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run tests
flutter test

# Start development server
flutter run
```

### Build for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

### Available Build Scripts
- `build_release.ps1` - Complete release build pipeline
- `build_v1_4_14_release.ps1` - Versioned build script
- Flutter tasks available in VS Code tasks.json

## 📈 Game Content Expansion

### Adding New Products
1. Add product definition to `GameData.products` in `game_data.dart`
2. Set appropriate `levelId` for unlock tier (basic, intermediate, complex, retail)
3. Define `requiredMaterials` map with component requirements
4. Products automatically integrate with unlock system and UI

### Economic Balance
- All pricing follows tier-based profit rules (documented in `game economy.txt`)
- Retail products achieve exactly $0.50/second total chain time profit
- Each tier must be profitable to encourage full supply chain usage
- Anti-exploitation measures prevent single-product optimization

*Production.Inc v1.4.19 - A sophisticated manufacturing simulation for mobile devices*

1. Fork the repository
2. Create a feature branch
3. Implement new materials, products, or automation features
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

---

**Start your production empire today!** 🏭📦💰
