import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';
import '../constants/game_constants.dart';

/// Service for evaluating and managing product unlock conditions
///
/// This service implements the progressive unlock system introduced in v1.4.18.
/// Products are unlocked based on different criteria depending on their tier:
///
/// **Basic Parts**: Unlocked when player has sufficient raw materials
/// **Intermediate Parts**: Unlocked when player has produced ALL required basic parts
/// **Complex Parts**: Unlocked when player has produced ALL required intermediate parts
/// **Retail Products**: Unlocked when player has produced ALL required components
///
/// The unlock system creates a natural progression where players discover
/// new products by gathering materials and progressing through production tiers.
/// This prevents overwhelming new players while maintaining engagement through
/// constant discovery and progression.
///
/// ## Unlock Philosophy:
/// - **Discovery-Driven**: Players learn about products by gathering materials
/// - **Logical Progression**: Basic → Intermediate → Complex → Retail unlocking
/// - **Production-Ready**: Only unlock when player can actually produce the item
/// - **Material-Driven**: Encourages exploration of material combinations
///
/// ## Performance Considerations:
/// - Results are cached based on game state hash to avoid repeated calculations
/// - Unlock checks are called frequently during gameplay updates
/// - Complex tier checking involves recursive dependency verification
/// - Cache is invalidated when relevant game state changes
class ProductUnlockService {
  // Cache for unlock condition results to avoid repeated calculations
  static final Map<String, bool> _unlockCache = {};
  static String? _lastGameStateHash;

  /// Clear the unlock cache when game state changes significantly
  static void clearCache() {
    _unlockCache.clear();
    _lastGameStateHash = null;
  }

  /// Generate a hash key for the current game state to detect changes
  static String _generateGameStateHash(GameState gameState) {
    final materialsHash = gameState.materials.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    final producedHash = gameState.unlockedProducts.join(',');
    return '$materialsHash|$producedHash';
  }

  /// Check if cache is still valid for the current game state
  static bool _isCacheValid(GameState gameState) {
    final currentHash = _generateGameStateHash(gameState);
    final isValid = _lastGameStateHash == currentHash;

    if (!isValid) {
      _lastGameStateHash = currentHash;
      _unlockCache.clear();
    }

    return isValid;
  }

  /// Evaluates unlock conditions for a specific product (with caching)
  ///
  /// This is the main entry point for checking if a product should be visible
  /// to the player. The method delegates to tier-specific checkers based on
  /// the product's level.
  ///
  /// **Performance Enhancement (v1.4.19):**
  /// Results are cached based on game state to avoid repeated expensive calculations.
  /// Cache is automatically invalidated when materials or production history changes.
  ///
  /// **Parameters:**
  /// - [productId]: The unique identifier of the product to check
  /// - [gameState]: Current game state containing materials, products, and progress
  ///
  /// **Returns:**
  /// - `true` if the product should be unlocked and visible to the player
  /// - `false` if the product should remain hidden
  ///
  /// **Throws:**
  /// - [Exception] if the product ID is not found in game data
  ///
  /// **Example:**
  /// ```dart
  /// bool canSeeBox = ProductUnlockService.isProductUnlocked('box', gameState);
  /// if (canSeeBox) {
  ///   // Show box in build products screen
  /// }
  /// ```
  static bool isProductUnlocked(String productId, GameState gameState) {
    // Check cache validity and use cached result if available
    if (_isCacheValid(gameState) && _unlockCache.containsKey(productId)) {
      return _unlockCache[productId]!;
    }

    final product = GameData.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    // Calculate unlock condition based on product tier
    final bool isUnlocked;
    switch (product.levelId) {
      case ProductLevel.basicParts:
        isUnlocked = _checkBasicPartsUnlockConditions(productId, gameState);
        break;
      case ProductLevel.intermediate:
        isUnlocked = _checkIntermediatePartsUnlockConditions(
          productId,
          gameState,
        );
        break;
      case ProductLevel.complex:
        isUnlocked = _checkComplexPartsUnlockConditions(productId, gameState);
        break;
      case ProductLevel.retail:
        isUnlocked = _checkRetailProductsUnlockConditions(productId, gameState);
        break;
      case ProductLevel.material:
        isUnlocked = true; // Materials are always unlocked
        break;
    }

    // Cache the result for future queries
    _unlockCache[productId] = isUnlocked;
    return isUnlocked;
  }

  /// Check unlock conditions for basic parts (material threshold based)
  ///
  /// Basic parts are unlocked when the player has gathered sufficient raw materials
  /// to produce them. Each basic part has specific material requirements that serve
  /// as thresholds for unlocking.
  ///
  /// **Unlock Strategy:**
  /// Basic parts unlock when players have enough materials to actually produce them,
  /// plus a small buffer to ensure they can meaningfully engage with the production.
  /// This prevents unlocking items that players cannot immediately use.
  ///
  /// **Material Thresholds:**
  /// - Box: ≥3 cardboard (production threshold)
  /// - Wires: ≥2 basic_metals + ≥1 plastic
  /// - Circuits: ≥3 basic_metals + ≥2 plastic
  /// - Plastic Enclosure: ≥4 plastic
  /// - Metal Enclosure: ≥2 basic_metals + ≥1 plastic
  /// - Lens: ≥1 glass + ≥2 advanced_metals
  /// - Battery: ≥2 advanced_metals + ≥1 plastic + requires wires production
  /// - Solar Cells: ≥2 advanced_metals + ≥2 glass + requires wires production
  /// - Gears: ≥1 basic_metals
  /// - Sound Driver: ≥2 advanced_metals + ≥1 basic_metals
  ///
  /// **Special Cases:**
  /// Some basic parts (battery, solar cells) require production of other basic parts
  /// in addition to raw materials, creating mini-dependencies within the tier.
  static bool _checkBasicPartsUnlockConditions(
    String productId,
    GameState gameState,
  ) {
    switch (productId) {
      case 'box':
        return gameState.getMaterialCount('cardboard') >=
            UnlockThresholds.boxCardboardThreshold;

      case 'wires':
        return gameState.getMaterialCount('basic_metals') >=
                UnlockThresholds.wiresBasicMetalsThreshold &&
            gameState.getMaterialCount('plastic') >=
                UnlockThresholds.wiresPlasticThreshold;

      case 'circuits':
        return gameState.getMaterialCount('basic_metals') >=
                UnlockThresholds.circuitsBasicMetalsThreshold &&
            gameState.getMaterialCount('plastic') >=
                UnlockThresholds.circuitsPlasticThreshold;

      case 'enclosure_plastic':
        return gameState.getMaterialCount('plastic') >=
            UnlockThresholds.plasticEnclosurePlasticThreshold;

      case 'metal_enclosure':
        return gameState.getMaterialCount('basic_metals') >=
                UnlockThresholds.metalEnclosureBasicMetalsThreshold &&
            gameState.getMaterialCount('plastic') >=
                UnlockThresholds.metalEnclosurePlasticThreshold;

      case 'lens':
        return gameState.getMaterialCount('glass') >=
                UnlockThresholds.lensGlassThreshold &&
            gameState.getMaterialCount('advanced_metals') >=
                UnlockThresholds.lensAdvancedMetalsThreshold;

      case 'battery':
        return gameState.getMaterialCount('advanced_metals') >=
                UnlockThresholds.batteryAdvancedMetalsThreshold &&
            gameState.getMaterialCount('plastic') >=
                UnlockThresholds.batteryPlasticThreshold &&
            gameState.hasProduced('wires');

      case 'solar_cells':
        return gameState.getMaterialCount('advanced_metals') >=
                UnlockThresholds.solarCellsAdvancedMetalsThreshold &&
            gameState.getMaterialCount('glass') >=
                UnlockThresholds.solarCellsGlassThreshold &&
            gameState.hasProduced('wires');

      case 'gears':
        return gameState.getMaterialCount('basic_metals') >=
            UnlockThresholds.gearsBasicMetalsThreshold;

      case 'sound_driver':
        return gameState.getMaterialCount('advanced_metals') >=
                UnlockThresholds.soundDriverAdvancedMetalsThreshold &&
            gameState.getMaterialCount('basic_metals') >=
                UnlockThresholds.soundDriverBasicMetalsThreshold;

      default:
        return false;
    }
  }

  /// Check unlock conditions for intermediate parts (production-based logic)
  ///
  /// Intermediate parts represent the next level of complexity after basic parts.
  /// They are unlocked when the player has successfully produced ALL basic parts
  /// required for their manufacture. This ensures players have experience with
  /// the component supply chain before attempting more complex products.
  ///
  /// **Unlock Strategy:**
  /// Unlike basic parts which unlock based on raw materials, intermediate parts
  /// require actual production experience. Players must have produced (not just
  /// purchased) all required basic parts to unlock an intermediate part.
  ///
  /// **Dependency Logic:**
  /// 1. Examine all required materials for the intermediate part
  /// 2. For each material that is also a basic part product:
  ///    - Check if player has produced it (hasProduced() returns true)
  ///    - If any required basic part hasn't been produced, keep locked
  /// 3. Raw materials don't require production checks
  ///
  /// **Examples:**
  /// - Display Screen: Requires circuits, wires, lens → Must have produced all three
  /// - Processor: Requires circuits, advanced_metals → Must have produced circuits
  /// - Image Sensor: Requires advanced_metals, circuits, lens, wires → Must have produced circuits, lens, wires
  ///
  /// **Performance Note:**
  /// This method performs recursive lookups to verify component production status.
  /// Results should be cached for frequently checked products.
  static bool _checkIntermediatePartsUnlockConditions(
    String productId,
    GameState gameState,
  ) {
    final product = GameData.products.firstWhere((p) => p.id == productId);

    // For intermediate parts, check if player has produced ALL required basic parts
    for (final materialId in product.requiredMaterials.keys) {
      final requiredProduct =
          GameData.products.where((p) => p.id == materialId).firstOrNull;

      // If it's a basic part, check if it has been produced
      if (requiredProduct?.levelId == ProductLevel.basicParts) {
        if (!gameState.hasProduced(materialId)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Check unlock conditions for complex parts (intermediate production-based logic)
  ///
  /// Complex parts represent high-end manufacturing components that require
  /// mastery of intermediate part production. They unlock when the player has
  /// produced ALL required intermediate parts, representing the culmination
  /// of the component manufacturing progression.
  ///
  /// **Unlock Strategy:**
  /// Similar to intermediate parts, but focusing on intermediate-level dependencies.
  /// Players must demonstrate competence with intermediate part production before
  /// accessing complex manufacturing capabilities.
  ///
  /// **Dependency Logic:**
  /// 1. Examine all required materials for the complex part
  /// 2. For each material that is an intermediate part:
  ///    - Check if player has produced it (hasProduced() returns true)
  ///    - If any required intermediate part hasn't been produced, keep locked
  /// 3. Basic parts and raw materials don't require production checks
  ///
  /// **Current Complex Parts:**
  /// - Camera Module: Requires multiple intermediate parts (display_screen, processor, image_sensor)
  ///   Only unlocks when player has produced display screens, processors, and image sensors
  ///
  /// **Design Intent:**
  /// Complex parts serve as gateways to premium retail products, ensuring players
  /// have developed sufficient manufacturing expertise before attempting the most
  /// sophisticated product assembly.
  static bool _checkComplexPartsUnlockConditions(
    String productId,
    GameState gameState,
  ) {
    final product = GameData.products.firstWhere((p) => p.id == productId);

    // For complex parts, check if player has produced ALL required intermediate parts
    for (final materialId in product.requiredMaterials.keys) {
      final requiredProduct =
          GameData.products.where((p) => p.id == materialId).firstOrNull;

      // If it's an intermediate part, check if it has been produced
      if (requiredProduct?.levelId == ProductLevel.intermediate) {
        if (!gameState.hasProduced(materialId)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Check unlock conditions for retail products (complete supply chain mastery)
  ///
  /// Retail products represent the final consumer goods that players manufacture
  /// for profit. They unlock when the player has produced ALL required components
  /// across all tiers, demonstrating complete mastery of the supply chain.
  ///
  /// **Unlock Strategy:**
  /// Retail products require the most comprehensive unlock conditions, checking
  /// production history for ALL component types (basic, intermediate, complex).
  /// This ensures players have developed complete manufacturing competence.
  ///
  /// **Dependency Logic:**
  /// 1. Examine all required materials for the retail product
  /// 2. For each material that is a manufactured product (any tier):
  ///    - Check if player has produced it (hasProduced() returns true)
  ///    - If any required component hasn't been produced, keep locked
  /// 3. Raw materials don't require production checks
  ///
  /// **Examples:**
  /// - Speaker: Requires wires, circuits, sound_driver, enclosure_plastic, box
  ///   Must have produced: wires, circuits, sound_driver (all basic parts)
  /// - Smartphone: Requires complex supply chain including camera_module
  ///   Must have produced: ALL basic parts, intermediate parts, AND complex parts
  ///
  /// **Economic Impact:**
  /// This system ensures retail products unlock gradually as players progress,
  /// preventing immediate access to high-value items and maintaining game balance.
  /// Players must invest in the complete production ecosystem to access premium products.
  static bool _checkRetailProductsUnlockConditions(
    String productId,
    GameState gameState,
  ) {
    final product = GameData.products.firstWhere((p) => p.id == productId);

    // For retail products, check if player has produced ALL required components
    for (final materialId in product.requiredMaterials.keys) {
      final requiredProduct =
          GameData.products.where((p) => p.id == materialId).firstOrNull;

      // If it's a product component (not a raw material), check if it has been produced
      if (requiredProduct != null) {
        if (!gameState.hasProduced(materialId)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Updates unlock status for all products and returns newly unlocked products
  static Set<String> updateUnlockStatus(GameState gameState) {
    final newlyUnlocked = <String>{};

    for (final product in GameData.products) {
      final wasUnlocked = gameState.isProductUnlocked(product.id);
      final isNowUnlocked = isProductUnlocked(product.id, gameState);

      if (!wasUnlocked && isNowUnlocked) {
        newlyUnlocked.add(product.id);
      }
    }

    return newlyUnlocked;
  }

  /// Gets all currently unlocked products
  static Set<String> getAllUnlockedProducts(GameState gameState) {
    final unlockedProducts = <String>{};

    for (final product in GameData.products) {
      if (isProductUnlocked(product.id, gameState)) {
        unlockedProducts.add(product.id);
      }
    }

    return unlockedProducts;
  }

  /// Gets unlock progress for a specific tier (unlocked count / total count)
  static ({int unlocked, int total}) getTierUnlockProgress(
    ProductLevel tier,
    GameState gameState,
  ) {
    final tierProducts =
        GameData.products.where((p) => p.levelId == tier).toList();
    final unlockedCount =
        tierProducts.where((p) => isProductUnlocked(p.id, gameState)).length;

    return (unlocked: unlockedCount, total: tierProducts.length);
  }

  /// Gets a formatted string for tier progress display
  static String getTierProgressString(ProductLevel tier, GameState gameState) {
    final progress = getTierUnlockProgress(tier, gameState);

    if (progress.unlocked == progress.total) {
      return '✓'; // All unlocked
    } else {
      return '${progress.unlocked}/${progress.total}'; // X/Y format
    }
  }
}
