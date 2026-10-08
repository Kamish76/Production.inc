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

  /// Factory constructor for an upgrade, research technology node, or prestige perk.
  factory GameIcon.forUpgrade({
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

  /// Factory constructor for a UI control, setting, or navigation icon.
  factory GameIcon.forUi({
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

  /// Factory constructor for an achievement or milestone badge.
  factory GameIcon.forBadge({
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

    // Batch 4: Advanced Consumer Electronics & Optics
    'camera': 'assets/images/icons/products/prod_camera.svg',
    'prod_camera': 'assets/images/icons/products/prod_camera.svg',
    'e_reader': 'assets/images/icons/products/prod_e_reader.svg',
    'prod_e_reader': 'assets/images/icons/products/prod_e_reader.svg',
    'electric_scooter': 'assets/images/icons/products/prod_electric_scooter.svg',
    'prod_electric_scooter': 'assets/images/icons/products/prod_electric_scooter.svg',
    'gaming_console': 'assets/images/icons/products/prod_gaming_console.svg',
    'prod_gaming_console': 'assets/images/icons/products/prod_gaming_console.svg',
    'laptop': 'assets/images/icons/products/prod_laptop.svg',
    'prod_laptop': 'assets/images/icons/products/prod_laptop.svg',
    'smartphone': 'assets/images/icons/products/prod_smartphone.svg',
    'prod_smartphone': 'assets/images/icons/products/prod_smartphone.svg',
    'smartwatch': 'assets/images/icons/products/prod_smartwatch.svg',
    'prod_smartwatch': 'assets/images/icons/products/prod_smartwatch.svg',
    'solar_panel': 'assets/images/icons/products/prod_solar_panel.svg',
    'prod_solar_panel': 'assets/images/icons/products/prod_solar_panel.svg',
    'telescope': 'assets/images/icons/products/prod_telescope.svg',
    'prod_telescope': 'assets/images/icons/products/prod_telescope.svg',
    'vr_headset': 'assets/images/icons/products/prod_vr_headset.svg',
    'prod_vr_headset': 'assets/images/icons/products/prod_vr_headset.svg',

    // Batch 5: Heavy Mobility, Robotics & Infrastructure
    'drone': 'assets/images/icons/products/prod_drone.svg',
    'prod_drone': 'assets/images/icons/products/prod_drone.svg',
    'cleaning_drone': 'assets/images/icons/products/prod_drone.svg',
    'prod_cleaning_drone': 'assets/images/icons/products/prod_drone.svg',
    'electric_car': 'assets/images/icons/products/prod_electric_car.svg',
    'prod_electric_car': 'assets/images/icons/products/prod_electric_car.svg',
    'fusion_reactor': 'assets/images/icons/products/prod_fusion_reactor.svg',
    'prod_fusion_reactor': 'assets/images/icons/products/prod_fusion_reactor.svg',
    'quantum_core': 'assets/images/icons/products/prod_fusion_reactor.svg',
    'prod_quantum_core': 'assets/images/icons/products/prod_fusion_reactor.svg',
    'high_speed_train': 'assets/images/icons/products/prod_high_speed_train.svg',
    'prod_high_speed_train': 'assets/images/icons/products/prod_high_speed_train.svg',
    'industrial_robot': 'assets/images/icons/products/prod_industrial_robot.svg',
    'prod_industrial_robot': 'assets/images/icons/products/prod_industrial_robot.svg',
    'robotic_arm': 'assets/images/icons/products/prod_industrial_robot.svg',
    'prod_robotic_arm': 'assets/images/icons/products/prod_industrial_robot.svg',
    'mining_drill': 'assets/images/icons/products/prod_mining_drill.svg',
    'prod_mining_drill': 'assets/images/icons/products/prod_mining_drill.svg',
    'robot_dog': 'assets/images/icons/products/prod_robot_dog.svg',
    'prod_robot_dog': 'assets/images/icons/products/prod_robot_dog.svg',
    'toy_robot': 'assets/images/icons/products/prod_robot_dog.svg',
    'prod_toy_robot': 'assets/images/icons/products/prod_robot_dog.svg',
    'space_satellite': 'assets/images/icons/products/prod_space_satellite.svg',
    'prod_space_satellite': 'assets/images/icons/products/prod_space_satellite.svg',
    'orbital_satellite': 'assets/images/icons/products/prod_space_satellite.svg',
    'prod_orbital_satellite': 'assets/images/icons/products/prod_space_satellite.svg',
    'supercomputer': 'assets/images/icons/products/prod_supercomputer.svg',
    'prod_supercomputer': 'assets/images/icons/products/prod_supercomputer.svg',
    'wind_turbine': 'assets/images/icons/products/prod_wind_turbine.svg',
    'prod_wind_turbine': 'assets/images/icons/products/prod_wind_turbine.svg',
    'wind_turbine_generator': 'assets/images/icons/products/prod_wind_turbine.svg',
    'prod_wind_turbine_generator': 'assets/images/icons/products/prod_wind_turbine.svg',

    // Batch 6: Advanced & Quantum Infrastructure
    'ai_core': 'assets/images/icons/products/prod_ai_core.svg',
    'prod_ai_core': 'assets/images/icons/products/prod_ai_core.svg',
    'nova_robotics': 'assets/images/icons/products/prod_ai_core.svg',
    'prod_nova_robotics': 'assets/images/icons/products/prod_ai_core.svg',
    'dyson_receiver': 'assets/images/icons/products/prod_dyson_receiver.svg',
    'prod_dyson_receiver': 'assets/images/icons/products/prod_dyson_receiver.svg',
    'solaria_energy': 'assets/images/icons/products/prod_dyson_receiver.svg',
    'prod_solaria_energy': 'assets/images/icons/products/prod_dyson_receiver.svg',
    'orbital_station': 'assets/images/icons/products/prod_orbital_station.svg',
    'prod_orbital_station': 'assets/images/icons/products/prod_orbital_station.svg',
    'particle_accelerator': 'assets/images/icons/products/prod_particle_accelerator.svg',
    'prod_particle_accelerator': 'assets/images/icons/products/prod_particle_accelerator.svg',
    'material_science': 'assets/images/icons/products/prod_particle_accelerator.svg',
    'prod_material_science': 'assets/images/icons/products/prod_particle_accelerator.svg',
    'quantum_computer': 'assets/images/icons/products/prod_quantum_computer.svg',
    'prod_quantum_computer': 'assets/images/icons/products/prod_quantum_computer.svg',
    'quantum_processor': 'assets/images/icons/products/prod_quantum_processor.svg',
    'prod_quantum_processor': 'assets/images/icons/products/prod_quantum_processor.svg',
    'space_probe': 'assets/images/icons/products/prod_space_probe.svg',
    'prod_space_probe': 'assets/images/icons/products/prod_space_probe.svg',
    'logistics_optimization': 'assets/images/icons/products/prod_space_probe.svg',
    'prod_logistics_optimization': 'assets/images/icons/products/prod_space_probe.svg',
    'space_telescope': 'assets/images/icons/products/prod_space_telescope.svg',
    'prod_space_telescope': 'assets/images/icons/products/prod_space_telescope.svg',
    'telecom_tower': 'assets/images/icons/products/prod_telecom_tower.svg',
    'prod_telecom_tower': 'assets/images/icons/products/prod_telecom_tower.svg',
    'apex_telecom': 'assets/images/icons/products/prod_telecom_tower.svg',
    'prod_apex_telecom': 'assets/images/icons/products/prod_telecom_tower.svg',
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
    'mach_build_retail': 'assets/images/icons/machines/mach_build_retail.svg',
    'build_retail': 'assets/images/icons/machines/mach_build_retail.svg',
    'retail_assembler': 'assets/images/icons/machines/mach_build_retail.svg',
    'retail': 'assets/images/icons/machines/mach_build_retail.svg',
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

  // Batch 7: Upgrades & Tech Tree Modules
  static const Map<String, String> _researchAssetMap = {
    'upg_automation_chip': 'assets/images/icons/research/upg_automation_chip.svg',
    'automation_chip': 'assets/images/icons/research/upg_automation_chip.svg',
    'instant_machines': 'assets/images/icons/research/upg_automation_chip.svg',
    'perk_instant_machines': 'assets/images/icons/research/upg_automation_chip.svg',

    'upg_eco_efficiency': 'assets/images/icons/research/upg_eco_efficiency.svg',
    'eco_efficiency': 'assets/images/icons/research/upg_eco_efficiency.svg',

    'upg_logistics_optimizer': 'assets/images/icons/research/upg_logistics_optimizer.svg',
    'logistics_optimizer': 'assets/images/icons/research/upg_logistics_optimizer.svg',
    'quantum_warp_dispatch': 'assets/images/icons/research/upg_logistics_optimizer.svg',
    'perk_quantum_warp_dispatch': 'assets/images/icons/research/upg_logistics_optimizer.svg',

    'upg_market_algorithm': 'assets/images/icons/research/upg_market_algorithm.svg',
    'market_algorithm': 'assets/images/icons/research/upg_market_algorithm.svg',
    'angel_seed_capital': 'assets/images/icons/research/upg_market_algorithm.svg',
    'perk_angel_seed_capital': 'assets/images/icons/research/upg_market_algorithm.svg',

    'upg_nanotech_infusion': 'assets/images/icons/research/upg_nanotech_infusion.svg',
    'nanotech_infusion': 'assets/images/icons/research/upg_nanotech_infusion.svg',
    'prototype_blueprints': 'assets/images/icons/research/upg_nanotech_infusion.svg',
    'perk_prototype_blueprints': 'assets/images/icons/research/upg_nanotech_infusion.svg',

    'upg_neural_accelerator': 'assets/images/icons/research/upg_neural_accelerator.svg',
    'neural_accelerator': 'assets/images/icons/research/upg_neural_accelerator.svg',

    'upg_overclock_boost': 'assets/images/icons/research/upg_overclock_boost.svg',
    'overclock_boost': 'assets/images/icons/research/upg_overclock_boost.svg',
    'factory_overclocking': 'assets/images/icons/research/upg_overclock_boost.svg',

    'upg_power_grid_overload': 'assets/images/icons/research/upg_power_grid_overload.svg',
    'power_grid_overload': 'assets/images/icons/research/upg_power_grid_overload.svg',

    'upg_quality_control': 'assets/images/icons/research/upg_quality_control.svg',
    'quality_control': 'assets/images/icons/research/upg_quality_control.svg',

    'upg_thermal_cooling': 'assets/images/icons/research/upg_thermal_cooling.svg',
    'thermal_cooling': 'assets/images/icons/research/upg_thermal_cooling.svg',
  };

  // Batch 8: Game UI, Controls & Achievement Badges
  static const Map<String, String> _uiAssetMap = {
    // UI Controls & System
    'ui_audio_off': 'assets/images/icons/ui/ui_audio_off.svg',
    'audio_off': 'assets/images/icons/ui/ui_audio_off.svg',
    'sound_off': 'assets/images/icons/ui/ui_audio_off.svg',
    'mute': 'assets/images/icons/ui/ui_audio_off.svg',

    'ui_audio_on': 'assets/images/icons/ui/ui_audio_on.svg',
    'audio_on': 'assets/images/icons/ui/ui_audio_on.svg',
    'sound_on': 'assets/images/icons/ui/ui_audio_on.svg',
    'audio': 'assets/images/icons/ui/ui_audio_on.svg',
    'volume': 'assets/images/icons/ui/ui_audio_on.svg',

    'ui_quest_target': 'assets/images/icons/ui/ui_quest_target.svg',
    'quest_target': 'assets/images/icons/ui/ui_quest_target.svg',
    'quest': 'assets/images/icons/ui/ui_quest_target.svg',
    'target': 'assets/images/icons/ui/ui_quest_target.svg',
    'milestone': 'assets/images/icons/ui/ui_quest_target.svg',

    'ui_save_cloud': 'assets/images/icons/ui/ui_save_cloud.svg',
    'save_cloud': 'assets/images/icons/ui/ui_save_cloud.svg',
    'cloud_save': 'assets/images/icons/ui/ui_save_cloud.svg',
    'save': 'assets/images/icons/ui/ui_save_cloud.svg',

    'ui_settings': 'assets/images/icons/ui/ui_settings.svg',
    'settings': 'assets/images/icons/ui/ui_settings.svg',
    'gear_settings': 'assets/images/icons/ui/ui_settings.svg',

    'ui_stats_analytics': 'assets/images/icons/ui/ui_stats_analytics.svg',
    'stats_analytics': 'assets/images/icons/ui/ui_stats_analytics.svg',
    'analytics': 'assets/images/icons/ui/ui_stats_analytics.svg',
    'stats': 'assets/images/icons/ui/ui_stats_analytics.svg',
    'statistics': 'assets/images/icons/ui/ui_stats_analytics.svg',

    // Achievement Badges
    'badge_interplanetary_reach': 'assets/images/icons/ui/badge_interplanetary_reach.svg',
    'interplanetary_reach': 'assets/images/icons/ui/badge_interplanetary_reach.svg',
    'badge_interplanetary': 'assets/images/icons/ui/badge_interplanetary_reach.svg',

    'badge_master_automation': 'assets/images/icons/ui/badge_master_automation.svg',
    'master_automation': 'assets/images/icons/ui/badge_master_automation.svg',
    'badge_automation': 'assets/images/icons/ui/badge_master_automation.svg',

    'badge_tycoon_trophy': 'assets/images/icons/ui/badge_tycoon_trophy.svg',
    'tycoon_trophy': 'assets/images/icons/ui/badge_tycoon_trophy.svg',
    'badge_tycoon': 'assets/images/icons/ui/badge_tycoon_trophy.svg',
    'trophy': 'assets/images/icons/ui/badge_tycoon_trophy.svg',

    'badge_zero_carbon': 'assets/images/icons/ui/badge_zero_carbon.svg',
    'zero_carbon': 'assets/images/icons/ui/badge_zero_carbon.svg',
    'badge_carbon': 'assets/images/icons/ui/badge_zero_carbon.svg',
  };

  /// Resolves an item ID (material, product, machine, fleet, upgrade, UI, or badge) to its asset path if registered.
  static String? resolveAssetPath(String id) {
    if (_materialAssetMap.containsKey(id)) return _materialAssetMap[id];
    if (_productAssetMap.containsKey(id)) return _productAssetMap[id];
    if (_machineAssetMap.containsKey(id)) return _machineAssetMap[id];
    if (_fleetAssetMap.containsKey(id)) return _fleetAssetMap[id];
    if (_researchAssetMap.containsKey(id)) return _researchAssetMap[id];
    if (_uiAssetMap.containsKey(id)) return _uiAssetMap[id];

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
    } else if (id.startsWith('client_')) {
      final cleanId = id.substring(7);
      if (_productAssetMap.containsKey(cleanId)) return _productAssetMap[cleanId];
      if (_materialAssetMap.containsKey(cleanId)) return _materialAssetMap[cleanId];
    } else if (id.startsWith('tech_')) {
      final cleanId = id.substring(5);
      if (_researchAssetMap.containsKey(cleanId)) return _researchAssetMap[cleanId];
      if (_productAssetMap.containsKey(cleanId)) return _productAssetMap[cleanId];
      if (_materialAssetMap.containsKey(cleanId)) return _materialAssetMap[cleanId];
      if (_machineAssetMap.containsKey(cleanId)) return _machineAssetMap[cleanId];
    } else if (id.startsWith('upg_')) {
      final cleanId = id.substring(4);
      if (_researchAssetMap.containsKey(cleanId)) return _researchAssetMap[cleanId];
    } else if (id.startsWith('perk_')) {
      final cleanId = id.substring(5);
      if (_researchAssetMap.containsKey(cleanId)) return _researchAssetMap[cleanId];
    } else if (id.startsWith('ui_')) {
      final cleanId = id.substring(3);
      if (_uiAssetMap.containsKey(cleanId)) return _uiAssetMap[cleanId];
    } else if (id.startsWith('badge_')) {
      final cleanId = id.substring(6);
      if (_uiAssetMap.containsKey(cleanId)) return _uiAssetMap[cleanId];
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
