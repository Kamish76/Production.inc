import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized widget for rendering in-game icon assets with graceful fallback to Unicode emojis.
///
/// Automatically resolves custom SVG assets when available (e.g., Batch 1: Core Foundation),
/// while seamlessly falling back to the standard emoji glyph if the asset is missing or not yet drawn.
class GameIcon extends StatelessWidget {
  final String? assetPath;
  final String? itemId;
  final String fallbackEmoji;
  final double size;
  final BoxFit fit;

  const GameIcon({
    super.key,
    this.assetPath,
    this.itemId,
    required this.fallbackEmoji,
    this.size = 24.0,
    this.fit = BoxFit.contain,
  });

  /// Factory constructor for a raw material item.
  factory GameIcon.forMaterial({
    Key? key,
    required String id,
    required String fallbackEmoji,
    double size = 24.0,
    BoxFit fit = BoxFit.contain,
  }) {
    return GameIcon(
      key: key,
      itemId: id,
      fallbackEmoji: fallbackEmoji,
      size: size,
      fit: fit,
    );
  }

  /// Factory constructor for a manufactured product item.
  factory GameIcon.forProduct({
    Key? key,
    required String id,
    required String fallbackEmoji,
    double size = 24.0,
    BoxFit fit = BoxFit.contain,
  }) {
    return GameIcon(
      key: key,
      itemId: id,
      fallbackEmoji: fallbackEmoji,
      size: size,
      fit: fit,
    );
  }

  // --- Registered Asset Mappings (Batch 1: Core Foundation) ---

  static const Map<String, String> _materialAssetMap = {
    'cardboard': 'assets/images/icons/materials/mat_cardboard.svg',
    'basic_metals': 'assets/images/icons/materials/mat_basic_metals.svg',
    'plastic': 'assets/images/icons/materials/mat_plastic.svg',
    'glass': 'assets/images/icons/materials/mat_glass.svg',
    'advanced_metals': 'assets/images/icons/materials/mat_advanced_metals.svg',
  };

  static const Map<String, String> _productAssetMap = {
    'box': 'assets/images/icons/products/prod_box.svg',
    'wires': 'assets/images/icons/products/prod_wires.svg',
    'circuits': 'assets/images/icons/products/prod_circuits.svg',
    'enclosure_plastic': 'assets/images/icons/products/prod_enclosure_plastic.svg',
    'metal_enclosure': 'assets/images/icons/products/prod_metal_enclosure.svg',
  };

  /// Resolves an item ID (material or product) to its asset path if registered.
  static String? resolveAssetPath(String id) {
    if (_materialAssetMap.containsKey(id)) return _materialAssetMap[id];
    if (_productAssetMap.containsKey(id)) return _productAssetMap[id];

    // Check with prefixes stripped if supplied
    if (id.startsWith('mat_')) {
      final cleanId = id.substring(4);
      if (_materialAssetMap.containsKey(cleanId)) return _materialAssetMap[cleanId];
    } else if (id.startsWith('prod_')) {
      final cleanId = id.substring(5);
      if (_productAssetMap.containsKey(cleanId)) return _productAssetMap[cleanId];
    }

    return null;
  }

  /// Returns true if the given item ID has a registered custom image asset.
  static bool hasAsset(String id) {
    return resolveAssetPath(id) != null;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPath = assetPath ?? (itemId != null ? resolveAssetPath(itemId!) : null);

    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      if (resolvedPath.endsWith('.svg')) {
        return SvgPicture.asset(
          resolvedPath,
          width: size,
          height: size,
          fit: fit,
          placeholderBuilder: (context) => _buildFallbackEmoji(),
          errorBuilder: (context, error, stackTrace) => _buildFallbackEmoji(),
        );
      }

      return Image.asset(
        resolvedPath,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackEmoji();
        },
      );
    }

    return _buildFallbackEmoji();
  }

  Widget _buildFallbackEmoji() {
    return Text(
      fallbackEmoji,
      style: TextStyle(
        fontSize: size * 0.85,
        height: 1.0,
      ),
      textAlign: TextAlign.center,
    );
  }
}
