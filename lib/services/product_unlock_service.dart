import '../models/game_state.dart';
import '../models/game_data.dart';
import '../models/game_models.dart';

/// Service for evaluating and managing product unlock conditions
/// Implements the progressive unlock system for v1.4.18
class ProductUnlockService {
  /// Evaluates unlock conditions for a specific product
  static bool isProductUnlocked(String productId, GameState gameState) {
    final product = GameData.products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    // Check unlock conditions based on product tier and specific rules
    switch (product.levelId) {
      case ProductLevel.basicParts:
        return _checkBasicPartsUnlockConditions(productId, gameState);
      case ProductLevel.intermediate:
        return _checkIntermediatePartsUnlockConditions(productId, gameState);
      case ProductLevel.complex:
        return _checkComplexPartsUnlockConditions(productId, gameState);
      case ProductLevel.retail:
        return _checkRetailProductsUnlockConditions(productId, gameState);
      case ProductLevel.material:
        return true; // Materials are always unlocked
    }
  }

  /// Check unlock conditions for basic parts (material threshold based)
  static bool _checkBasicPartsUnlockConditions(
    String productId,
    GameState gameState,
  ) {
    switch (productId) {
      case 'box':
        return gameState.getMaterialCount('cardboard') >= 3;

      case 'wires':
        return gameState.getMaterialCount('basic_metals') >= 2 &&
            gameState.getMaterialCount('plastic') >= 1;

      case 'circuits':
        return gameState.getMaterialCount('basic_metals') >= 3 &&
            gameState.getMaterialCount('plastic') >= 2;

      case 'enclosure_plastic':
        return gameState.getMaterialCount('plastic') >= 4;

      case 'metal_enclosure':
        return gameState.getMaterialCount('basic_metals') >= 2 &&
            gameState.getMaterialCount('plastic') >= 1;

      case 'lens':
        return gameState.getMaterialCount('glass') >= 1 &&
            gameState.getMaterialCount('advanced_metals') >= 2;

      case 'battery':
        return gameState.getMaterialCount('advanced_metals') >= 2 &&
            gameState.getMaterialCount('plastic') >= 1 &&
            gameState.hasProduced('wires');

      case 'solar_cells':
        return gameState.getMaterialCount('advanced_metals') >= 2 &&
            gameState.getMaterialCount('glass') >= 2 &&
            gameState.hasProduced('wires');

      case 'gears':
        return gameState.getMaterialCount('basic_metals') >= 1;

      case 'sound_driver':
        return gameState.getMaterialCount('advanced_metals') >= 2 &&
            gameState.getMaterialCount('basic_metals') >= 1;

      default:
        return false;
    }
  }

  /// Check unlock conditions for intermediate parts (has produced logic)
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

  /// Check unlock conditions for complex parts (has produced logic)
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

  /// Check unlock conditions for retail products (has produced logic)
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
