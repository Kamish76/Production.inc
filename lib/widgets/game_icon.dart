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

  /// Factory constructor for an automation machine or tool.
  factory GameIcon.forMachine({
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

  /// Factory constructor for a logistics fleet carrier.
  factory GameIcon.forFleet({
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

  // --- Registered Asset Mappings ---

  // Batch 1: Core Foundation (Materials & Starter Products)
  static const Map<String, String> _materialAssetMap = {
    'cardboard': 'assets/images/icons/materials/mat_cardboard.svg',
    'basic_metals': 'assets/images/icons/materials/mat_basic_metals.svg',
    'plastic': 'assets/images/icons/materials/mat_plastic.svg',
    'glass': 'assets/images/icons/materials/mat_glass.svg',
    'advanced_metals': 'assets/images/icons/materials/mat_advanced_metals.svg',
  };

  static const Map<String, String> _productAssetMap = {
    // Batch 1: Core Foundation (Starter Products)
    'box': 'assets/images/icons/products/prod_box.svg',
    'prod_box': 'assets/images/icons/products/prod_box.svg',
    'wires': 'assets/images/icons/products/prod_wires.svg',
    'prod_wires': 'assets/images/icons/products/prod_wires.svg',
    'circuits': 'assets/images/icons/products/prod_circuits.svg',
    'prod_circuits': 'assets/images/icons/products/prod_circuits.svg',
    'enclosure_plastic': 'assets/images/icons/products/prod_enclosure_plastic.svg',
    'prod_enclosure_plastic': 'assets/images/icons/products/prod_enclosure_plastic.svg',
    'metal_enclosure': 'assets/images/icons/products/prod_metal_enclosure.svg',
    'prod_metal_enclosure': 'assets/images/icons/products/prod_metal_enclosure.svg',

    // Batch 3: Tier 2 Intermediates & Early Retail
    'sound_driver': 'assets/images/icons/products/prod_sound_driver.svg',
    'prod_sound_driver': 'assets/images/icons/products/prod_sound_driver.svg',
    'lens': 'assets/images/icons/products/prod_lens.svg',
    'prod_lens': 'assets/images/icons/products/prod_lens.svg',
    'battery': 'assets/images/icons/products/prod_battery.svg',
    'prod_battery': 'assets/images/icons/products/prod_battery.svg',
    'gears': 'assets/images/icons/products/prod_gears.svg',
    'prod_gears': 'assets/images/icons/products/prod_gears.svg',
    'solar_cells': 'assets/images/icons/products/prod_solar_cells.svg',
    'prod_solar_cells': 'assets/images/icons/products/prod_solar_cells.svg',
    'display_screen': 'assets/images/icons/products/prod_display_screen.svg',
    'prod_display_screen': 'assets/images/icons/products/prod_display_screen.svg',
    'processor': 'assets/images/icons/products/prod_processor.svg',
    'prod_processor': 'assets/images/icons/products/prod_processor.svg',
    'gear_mechanism': 'assets/images/icons/products/prod_gear_mechanism.svg',
    'prod_gear_mechanism': 'assets/images/icons/products/prod_gear_mechanism.svg',
    'speaker': 'assets/images/icons/products/prod_speaker.svg',
    'prod_speaker': 'assets/images/icons/products/prod_speaker.svg',
    'power_bank': 'assets/images/icons/products/prod_power_bank.svg',
    'prod_power_bank': 'assets/images/icons/products/prod_power_bank.svg',
  };

  // Batch 2: Factory Machinery & Logistics Fleet
  static const Map<String, String> _machineAssetMap = {
    'mach_auto_buy': 'assets/images/icons/machines/mach_auto_buy.svg',
    'auto_buy': 'assets/images/icons/machines/mach_auto_buy.svg',
    'buyer': 'assets/images/icons/machines/mach_auto_buy.svg',
    'mach_build_basic': 'assets/images/icons/machines/mach_build_basic.svg',
    'build_basic': 'assets/images/icons/machines/mach_build_basic.svg',
    'basic_assembler': 'assets/images/icons/machines/mach_build_basic.svg',
    'basicParts': 'assets/images/icons/machines/mach_build_basic.svg',
    'mach_build_intermediate': 'assets/images/icons/machines/mach_build_intermediate.svg',
    'build_intermediate': 'assets/images/icons/machines/mach_build_intermediate.svg',
    'intermediate_assembler': 'assets/images/icons/machines/mach_build_intermediate.svg',
    'intermediate': 'assets/images/icons/machines/mach_build_intermediate.svg',
    'mach_build_complex': 'assets/images/icons/machines/mach_build_complex.svg',
    'build_complex': 'assets/images/icons/machines/mach_build_complex.svg',
    'complex_assembler': 'assets/images/icons/machines/mach_build_complex.svg',
    'complex': 'assets/images/icons/machines/mach_build_complex.svg',
    'mach_auto_sell': 'assets/images/icons/machines/mach_auto_sell.svg',
    'auto_sell': 'assets/images/icons/machines/mach_auto_sell.svg',
    'basic_seller': 'assets/images/icons/machines/mach_auto_sell.svg',
    'tool_maintenance': 'assets/images/icons/machines/tool_maintenance.svg',
    'maintenance': 'assets/images/icons/machines/tool_maintenance.svg',
    'tool_salvage': 'assets/images/icons/machines/tool_salvage.svg',
    'salvage': 'assets/images/icons/machines/tool_salvage.svg',
  };

  static const Map<String, String> _fleetAssetMap = {
    'fleet_courier_bike': 'assets/images/icons/fleet/fleet_courier_bike.svg',
    'courier_bike': 'assets/images/icons/fleet/fleet_courier_bike.svg',
    'bike': 'assets/images/icons/fleet/fleet_courier_bike.svg',
    'fleet_1': 'assets/images/icons/fleet/fleet_courier_bike.svg',
    'tier_1': 'assets/images/icons/fleet/fleet_courier_bike.svg',
    'fleet_delivery_van': 'assets/images/icons/fleet/fleet_delivery_van.svg',
    'delivery_van': 'assets/images/icons/fleet/fleet_delivery_van.svg',
    'van': 'assets/images/icons/fleet/fleet_delivery_van.svg',
    'fleet_2': 'assets/images/icons/fleet/fleet_delivery_van.svg',
    'tier_2': 'assets/images/icons/fleet/fleet_delivery_van.svg',
    'fleet_freight_truck': 'assets/images/icons/fleet/fleet_freight_truck.svg',
    'freight_truck': 'assets/images/icons/fleet/fleet_freight_truck.svg',
    'truck': 'assets/images/icons/fleet/fleet_freight_truck.svg',
    'fleet_3': 'assets/images/icons/fleet/fleet_freight_truck.svg',
    'tier_3': 'assets/images/icons/fleet/fleet_freight_truck.svg',
    'fleet_cargo_plane': 'assets/images/icons/fleet/fleet_cargo_plane.svg',
    'cargo_plane': 'assets/images/icons/fleet/fleet_cargo_plane.svg',
    'plane': 'assets/images/icons/fleet/fleet_cargo_plane.svg',
    'fleet_4': 'assets/images/icons/fleet/fleet_cargo_plane.svg',
    'tier_4': 'assets/images/icons/fleet/fleet_cargo_plane.svg',
  };

  /// Resolves an item ID (material, product, machine, or fleet) to its asset path if registered.
  static String? resolveAssetPath(String id) {
    if (_materialAssetMap.containsKey(id)) return _materialAssetMap[id];
    if (_productAssetMap.containsKey(id)) return _productAssetMap[id];
    if (_machineAssetMap.containsKey(id)) return _machineAssetMap[id];
    if (_fleetAssetMap.containsKey(id)) return _fleetAssetMap[id];

    // Check with prefixes stripped if supplied
    if (id.startsWith('mat_')) {
      final cleanId = id.substring(4);
      if (_materialAssetMap.containsKey(cleanId)) return _materialAssetMap[cleanId];
    } else if (id.startsWith('prod_')) {
      final cleanId = id.substring(5);
      if (_productAssetMap.containsKey(cleanId)) return _productAssetMap[cleanId];
    } else if (id.startsWith('mach_')) {
      final cleanId = id.substring(5);
      if (_machineAssetMap.containsKey(cleanId)) return _machineAssetMap[cleanId];
    } else if (id.startsWith('tool_')) {
      final cleanId = id.substring(5);
      if (_machineAssetMap.containsKey(cleanId)) return _machineAssetMap[cleanId];
    } else if (id.startsWith('fleet_')) {
      final cleanId = id.substring(6);
      if (_fleetAssetMap.containsKey(cleanId)) return _fleetAssetMap[cleanId];
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
