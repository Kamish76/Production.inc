# Widget Decomposition - Visual Structure

## Before Refactoring
```
build_products_screen.dart (1175 lines)
├── BuildProductsScreen (StatefulWidget)
└── _BuildProductsScreenState
    ├── Production Status Panel Logic (~95 lines)
    ├── Welcome Message Logic (~70 lines)
    ├── Product Card Logic (~340 lines)
    ├── Product Details Dialog Logic (~160 lines)
    ├── Grouped Production Item Logic (~110 lines)
    └── Other methods and helpers
```

## After Refactoring
```
build_products_screen.dart (360 lines)
├── BuildProductsScreen (StatefulWidget)
└── _BuildProductsScreenState
    ├── Uses: ProductionStatusPanel
    ├── Uses: WelcomeMessageCard
    ├── Uses: BuildProductCard
    └── Tier management logic

widgets/
├── production_status_panel.dart (180 lines)
│   ├── ProductionStatusPanel (StatefulWidget)
│   ├── GroupedProduction (Helper class)
│   └── Uses: GroupedProductionItem
│
├── grouped_production_item.dart (110 lines)
│   └── GroupedProductionItem (StatelessWidget)
│       ├── Progress bar display
│       ├── Time remaining calculation
│       └── Product info display
│
├── welcome_message_card.dart (70 lines)
│   └── WelcomeMessageCard (StatelessWidget)
│       └── Onboarding UI
│
├── build_product_card.dart (340 lines)
│   └── BuildProductCard (StatelessWidget)
│       ├── Material requirements display
│       ├── Production status indicators
│       ├── Available quantity display
│       └── Uses: ProductDetailsDialog
│
└── product_details_dialog.dart (160 lines)
    └── ProductDetailsDialog (StatelessWidget)
        ├── Product stats
        ├── Material requirements
        └── Tier information
```

## Widget Reusability Map

### High Reusability (Can be used in multiple screens)
- ✅ **ProductionStatusPanel** - Any screen showing active productions
- ✅ **GroupedProductionItem** - Any production display
- ✅ **WelcomeMessageCard** - Onboarding flows, tutorials
- ✅ **ProductDetailsDialog** - Product catalogs, inventory screens
- ✅ **BuildProductCard** - Product listings, catalogs

### Specialized (Screen-specific but still modular)
- ⚠️ **TierExpansionPanel** - Tier-based product organization (ready to apply)

## Data Flow

```
ProductionGameService
         ↓
BuildProductsScreen
         ↓
    ┌────┴────────────────┬─────────────┐
    ↓                     ↓             ↓
ProductionStatusPanel  WelcomeCard  BuildProductCard
    ↓                                   ↓
GroupedProductionItem           ProductDetailsDialog
```

## Integration Points

### BuildProductsScreen Responsibilities
1. Manage tier expansion state
2. Load/save tier preferences
3. Provide gameService to child widgets
4. Layout and overall screen structure

### Child Widget Responsibilities
1. **ProductionStatusPanel**: Display and manage production status
2. **WelcomeMessageCard**: Show onboarding message
3. **BuildProductCard**: Display product info and handle interactions
4. **ProductDetailsDialog**: Show detailed product information
5. **GroupedProductionItem**: Render individual production items

## Benefits of This Structure

### Maintainability
- Each file has a clear, single purpose
- Easy to find and modify specific components
- Reduced coupling between components

### Reusability
- Widgets can be used in other screens
- Common patterns extracted into reusable components
- Consistent UI across the app

### Testability
- Each widget can be tested independently
- Easier to mock dependencies
- Smaller, focused test suites

### Performance
- Widgets can be optimized individually
- Better widget tree structure
- Reduced rebuild scope

## Next Steps: Applying TierExpansionPanel

The `tier_expansion_panel.dart` widget is ready to be integrated. The current tier expansion logic in `build_products_screen.dart` can be replaced with this reusable component for even cleaner code.

### Current Implementation
```dart
// In _buildTierSection method
GestureDetector(
  onTap: () => _toggleTierExpansion(tierName),
  child: Container(
    // Tier header with manual expansion logic
  ),
)
```

### Future Implementation (with TierExpansionPanel)
```dart
TierExpansionPanel(
  title: tierName,
  initiallyExpanded: _tierExpanded[tierName] ?? true,
  onExpansionChanged: (expanded) => _saveTierPreference(tierName, expanded),
  child: // Tier content
)
```
