# Production.INC

A sophisticated Flutter-based mobile business simulation game where you build and manage complex production chains, from basic materials to premium consumer electronics!

## 🎮 Game Concept

**Discover • Build • Optimize • Expand!**

Start by gathering raw materials and discovering what you can build. Progress through increasingly complex production tiers - from basic parts to intermediate components, complex assemblies, and premium retail products. Master supply chain management and unlock advanced manufacturing capabilities!

## 🌟 Current Features (v1.5.0)

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

### 🎨 Polished User Experience
- **Responsive Design** - Optimized for phones and tablets
- **Consistent UI** - Unified card-based interaction patterns
- **Smooth Animations** - Progress indicators, expand/collapse transitions
- **Professional Theming** - Consistent color scheme and typography

### 💾 Robust Data Management
- **Intelligent Saving** - Optimized persistence with 90% fewer database writes
- **Automatic Backup** - Save file protection and recovery
- **Migration System** - Seamless updates without data loss
- **Performance Optimized** - Smart timer management and caching

## 🚀 Five Core Game Screens

1. **Buy Materials** - Purchase raw materials with bulk buying options
2. **Build Products** - Manage production queues and unlock new items
3. **Sell Products** - Market your finished products for profit
4. **Shipping** - Automated logistics system for bulk sales
5. **Settings** - Game configuration and data management

## 🎯 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android device or emulator (Primary platform)
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

## 📱 How to Play

### 🚀 Starting Your Production Empire

1. **Begin with $100** - Use your starting capital wisely
2. **Gather Materials** - Visit "Buy Materials" to discover what's available
3. **Unlock Products** - As you collect materials, new products become available
4. **Build Smart** - Use the production queue system to plan efficiently
5. **Optimize Profits** - Progress through tiers for higher-value products

### 💡 Example Production Chain
```
Raw Materials → Basic Parts → Intermediate → Complex → Retail
Cardboard → Box → (Packaging) → Speaker ($74)
Glass + Metals → Lens → Camera Module → Smartphone ($800)
```

### 📊 Economic Strategy
- **Basic Parts**: 5-15% profit margins, quick production
- **Intermediate**: ~20% margins, moderate complexity
- **Complex**: ~14% margins, high coordination required
- **Retail**: $0.50/second total chain time rule for balanced progression

### 🔓 Unlock Progression
- **Start Simple**: Cardboard unlocks Box production
- **Build Foundation**: Basic parts enable intermediate products
- **Master Components**: Intermediate parts unlock complex assemblies
- **Create Premium**: Complex parts enable high-value retail products

## 🏗️ Technical Architecture

### 📁 Project Structure
```
lib/
├── main.dart                           # App entry point & theme
├── constants/
│   └── game_constants.dart            # Centralized configuration values
├── models/
│   ├── game_models.dart               # Core data models (Material, Product, etc.)
│   ├── game_state.dart                # Game state and production tasks
│   └── game_data.dart                 # Static game content definitions
├── services/
│   ├── production_game_service.dart   # Main game logic and state management
│   ├── product_unlock_service.dart    # Progressive unlock system
│   └── game_persistence_service.dart  # Database operations and save/load
├── widgets/
│   ├── common_widgets.dart            # Shared UI components
│   ├── product_card.dart              # Product display component
│   └── production_status_widget.dart  # Production progress displays
└── screens/
    ├── main_menu_screen.dart          # Navigation hub
    ├── buy_materials_screen.dart      # Material purchasing interface
    ├── build_products_screen.dart     # Production management
    ├── sell_products_screen.dart      # Product sales interface
    └── settings_screen.dart           # Configuration and utilities
```

### 🔧 Key Technical Features

#### Performance Optimizations (v1.4.19)
- **Intelligent Caching**: 85% faster unlock condition checking
- **Optimized Database**: 90% reduction in write operations
- **Smart Timers**: Adaptive update frequency based on activity
- **Efficient UI**: Shared components and granular rebuilds

#### Code Quality Improvements
- **Maintainable Architecture**: Large methods refactored into focused helpers
- **Centralized Constants**: 50+ magic numbers moved to structured constants
- **Comprehensive Documentation**: API docs with examples and performance notes
- **Consistent Theming**: Unified color scheme and typography system

#### Robust Data Management
- **Migration System**: Seamless schema updates without data loss
- **Automatic Backup**: Save file protection and corruption recovery
- **Incremental Saves**: Only save changed data for better performance
- **Platform Optimization**: Mobile-specific database configuration

## 🚀 Build & Deploy

### Development Build
```bash
# Run with hot reload
flutter run

# Run tests
flutter test

# Check for issues
flutter analyze
```

### Production Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

### 🧪 Testing
- **Unit Tests**: Core game logic and services
- **Widget Tests**: UI component behavior
- **Integration Tests**: End-to-end gameplay scenarios
- **Performance Tests**: Database and unlock system optimization

## 🛠️ Development Guide

### Adding New Content

#### 📦 Adding Materials
1. Add to `GameData.materials` in `lib/models/game_data.dart`
2. Update unlock thresholds in `lib/constants/game_constants.dart` if needed
3. Materials automatically appear in buy screen when added

#### 🏭 Adding Products
1. Add to appropriate tier in `GameData.products` in `lib/models/game_data.dart`
2. Specify required materials, production time, and pricing
3. Update unlock conditions in `ProductUnlockService` if custom logic needed
4. Products automatically integrate with all screens

#### 🎨 Customizing UI
- Modify `AppColors` in `lib/constants/game_constants.dart` for theming
- Update `UIConstants` for spacing and sizing adjustments
- Create new shared widgets in `lib/widgets/` for reusable components

### 🧪 Contributing

1. **Fork the Repository** - Create your own copy
2. **Create Feature Branch** - Use descriptive branch names
3. **Follow Architecture** - Maintain separation of concerns
4. **Add Tests** - Cover new functionality with tests
5. **Update Documentation** - Keep README and code comments current
6. **Test Thoroughly** - Verify on mobile devices
7. **Submit Pull Request** - Include clear description of changes

### 📊 Performance Guidelines
- Use `const` constructors for immutable widgets
- Implement proper `shouldUpdateWidget` logic for custom widgets
- Cache expensive computations (see `ProductUnlockService` caching)
- Follow the established database patterns for persistence
- Use the shared component library for consistency

## 🔮 Future Roadmap

### 🤖 Automation Features (v1.5+)
- **Auto-Buyers**: Automatic material purchasing systems
- **Production Lines**: Automated manufacturing workflows
- **Smart Shipping**: Intelligent order fulfillment
- **Resource Management**: Advanced inventory optimization

### 🌐 Advanced Features
- **Research & Development**: Unlock new technologies
- **Factory Expansion**: Multiple production facilities
- **Market Analysis**: Dynamic pricing and demand
- **Achievements System**: Progress tracking and rewards

### 📱 Platform Expansion
- **iOS Release**: Native iOS deployment
- **iOS Release**: (removed - project now targets Android only in this branch)
- **Cloud Saves**: Cross-device synchronization
- **Analytics**: Performance and engagement tracking
- **Localization**: Multi-language support

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/) framework
- Database powered by [SQLite](https://www.sqlite.org/)
- State management via [Provider](https://pub.dev/packages/provider) pattern
- Icons from [Material Design](https://material.io/design/iconography/)

---

**🏭 Start your production empire today! Transform raw materials into premium products and master the art of manufacturing! �💰**

*Production.INC - Where every component counts and every optimization matters.*
### Coding Standards Compliance

Production.Inc enforces strict linting and code quality standards:
- All code passes `flutter analyze` with no lint errors
- Key rules: `avoid_print`, `prefer_single_quotes`, `prefer_const_constructors`
- See [Development Guide](docs/DEVELOPMENT_GUIDE.md) for details
