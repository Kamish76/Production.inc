# Production.INC

A Flutter-based mobile business simulation game where you buy materials, build products, and sell them for profit!

## Game Concept

**Buy • Build • Sell • Automate!**

Start with basic materials like cardboard, transform them into products like boxes, and sell them to make money. As you progress, unlock machines to automate your production line!

## Current Features (Foundation)

### Materials
- **Cardboard** - Basic material for production (Buy price: $2.00)

### Products  
- **Box** - Made from 1 cardboard (Sell price: $5.00, Production time: 3 seconds)

### Three Core Game Windows

1. **Buy Materials** - Purchase raw materials for production
2. **Build Products** - Convert materials into sellable products
3. **Sell Products** - Sell your finished products for profit

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

1. **Start with $100** - Use this to buy your first materials
2. **Buy Cardboard** - Go to "Buy Materials" and purchase cardboard sheets
3. **Build Boxes** - Use "Build Products" to convert cardboard into boxes (takes 3 seconds)
4. **Sell for Profit** - Use "Sell Products" to sell your boxes for $5 each
5. **Reinvest** - Use your profits to buy more materials and expand production

### Profit Calculation
- Buy 1 Cardboard: $2.00
- Make 1 Box: $0 (just time)
- Sell 1 Box: $5.00
- **Profit per Box: $3.00**

## Future Features (Automation)

The game is designed to expand with automation machines:
- **Auto Cardboard Buyer** - Automatically purchases materials
- **Box Production Machine** - Automated box manufacturing
- **Auto Box Seller** - Automatically sells products

## Game Architecture

```
lib/
├── main.dart                           # App entry point
├── models/
│   ├── game_models.dart               # Material, Product, Machine models
│   ├── game_state.dart                # Game state and production tasks
│   └── game_data.dart                 # Game data definitions
├── services/
│   └── production_game_service.dart   # Game logic and state management
└── screens/
    ├── main_menu_screen.dart          # Main menu
    ├── buy_materials_screen.dart      # Material purchasing
    ├── build_products_screen.dart     # Production management
    ├── sell_products_screen.dart      # Product sales
    └── settings_screen.dart           # Game settings
```

## Development

### Adding New Materials
1. Add to `GameData.materials` in `game_data.dart`
2. Materials automatically appear in buy screen

### Adding New Products
1. Add to `GameData.products` in `game_data.dart`
2. Specify required materials and production time
3. Products automatically appear in build and sell screens

### Game State
- Managed by `ProductionGameService` using Provider pattern
- Automatic production updates every 500ms
- Persistent state (future feature)

## Build for Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement new materials, products, or automation features
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

---

**Start your production empire today!** 🏭📦💰
