import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game1/widgets/game_icon.dart';

void main() {
  group('GameIcon Asset Path Resolution', () {
    test('Resolves all Batch 1 materials correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('cardboard'),
        'assets/images/icons/materials/mat_cardboard.svg',
      );
      expect(
        GameIcon.resolveAssetPath('basic_metals'),
        'assets/images/icons/materials/mat_basic_metals.svg',
      );
      expect(
        GameIcon.resolveAssetPath('plastic'),
        'assets/images/icons/materials/mat_plastic.svg',
      );
      expect(
        GameIcon.resolveAssetPath('glass'),
        'assets/images/icons/materials/mat_glass.svg',
      );
      expect(
        GameIcon.resolveAssetPath('advanced_metals'),
        'assets/images/icons/materials/mat_advanced_metals.svg',
      );
    });

    test('Resolves all Batch 1 products correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('box'),
        'assets/images/icons/products/prod_box.svg',
      );
      expect(
        GameIcon.resolveAssetPath('wires'),
        'assets/images/icons/products/prod_wires.svg',
      );
      expect(
        GameIcon.resolveAssetPath('circuits'),
        'assets/images/icons/products/prod_circuits.svg',
      );
      expect(
        GameIcon.resolveAssetPath('enclosure_plastic'),
        'assets/images/icons/products/prod_enclosure_plastic.svg',
      );
      expect(
        GameIcon.resolveAssetPath('metal_enclosure'),
        'assets/images/icons/products/prod_metal_enclosure.svg',
      );
    });

    test('Resolves all Batch 3 products correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('sound_driver'),
        'assets/images/icons/products/prod_sound_driver.svg',
      );
      expect(
        GameIcon.resolveAssetPath('lens'),
        'assets/images/icons/products/prod_lens.svg',
      );
      expect(
        GameIcon.resolveAssetPath('battery'),
        'assets/images/icons/products/prod_battery.svg',
      );
      expect(
        GameIcon.resolveAssetPath('gears'),
        'assets/images/icons/products/prod_gears.svg',
      );
      expect(
        GameIcon.resolveAssetPath('solar_cells'),
        'assets/images/icons/products/prod_solar_cells.svg',
      );
      expect(
        GameIcon.resolveAssetPath('display_screen'),
        'assets/images/icons/products/prod_display_screen.svg',
      );
      expect(
        GameIcon.resolveAssetPath('processor'),
        'assets/images/icons/products/prod_processor.svg',
      );
      expect(
        GameIcon.resolveAssetPath('gear_mechanism'),
        'assets/images/icons/products/prod_gear_mechanism.svg',
      );
      expect(
        GameIcon.resolveAssetPath('speaker'),
        'assets/images/icons/products/prod_speaker.svg',
      );
      expect(
        GameIcon.resolveAssetPath('power_bank'),
        'assets/images/icons/products/prod_power_bank.svg',
      );
    });

    test('Resolves all Batch 4 products correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('camera'),
        'assets/images/icons/products/prod_camera.svg',
      );
      expect(
        GameIcon.resolveAssetPath('e_reader'),
        'assets/images/icons/products/prod_e_reader.svg',
      );
      expect(
        GameIcon.resolveAssetPath('electric_scooter'),
        'assets/images/icons/products/prod_electric_scooter.svg',
      );
      expect(
        GameIcon.resolveAssetPath('gaming_console'),
        'assets/images/icons/products/prod_gaming_console.svg',
      );
      expect(
        GameIcon.resolveAssetPath('laptop'),
        'assets/images/icons/products/prod_laptop.svg',
      );
      expect(
        GameIcon.resolveAssetPath('smartphone'),
        'assets/images/icons/products/prod_smartphone.svg',
      );
      expect(
        GameIcon.resolveAssetPath('smartwatch'),
        'assets/images/icons/products/prod_smartwatch.svg',
      );
      expect(
        GameIcon.resolveAssetPath('solar_panel'),
        'assets/images/icons/products/prod_solar_panel.svg',
      );
      expect(
        GameIcon.resolveAssetPath('telescope'),
        'assets/images/icons/products/prod_telescope.svg',
      );
      expect(
        GameIcon.resolveAssetPath('vr_headset'),
        'assets/images/icons/products/prod_vr_headset.svg',
      );
    });

    test('Resolves all Batch 5 products correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('drone'),
        'assets/images/icons/products/prod_drone.svg',
      );
      expect(
        GameIcon.resolveAssetPath('cleaning_drone'),
        'assets/images/icons/products/prod_drone.svg',
      );
      expect(
        GameIcon.resolveAssetPath('electric_car'),
        'assets/images/icons/products/prod_electric_car.svg',
      );
      expect(
        GameIcon.resolveAssetPath('fusion_reactor'),
        'assets/images/icons/products/prod_fusion_reactor.svg',
      );
      expect(
        GameIcon.resolveAssetPath('quantum_core'),
        'assets/images/icons/products/prod_fusion_reactor.svg',
      );
      expect(
        GameIcon.resolveAssetPath('high_speed_train'),
        'assets/images/icons/products/prod_high_speed_train.svg',
      );
      expect(
        GameIcon.resolveAssetPath('industrial_robot'),
        'assets/images/icons/products/prod_industrial_robot.svg',
      );
      expect(
        GameIcon.resolveAssetPath('robotic_arm'),
        'assets/images/icons/products/prod_industrial_robot.svg',
      );
      expect(
        GameIcon.resolveAssetPath('mining_drill'),
        'assets/images/icons/products/prod_mining_drill.svg',
      );
      expect(
        GameIcon.resolveAssetPath('robot_dog'),
        'assets/images/icons/products/prod_robot_dog.svg',
      );
      expect(
        GameIcon.resolveAssetPath('toy_robot'),
        'assets/images/icons/products/prod_robot_dog.svg',
      );
      expect(
        GameIcon.resolveAssetPath('space_satellite'),
        'assets/images/icons/products/prod_space_satellite.svg',
      );
      expect(
        GameIcon.resolveAssetPath('orbital_satellite'),
        'assets/images/icons/products/prod_space_satellite.svg',
      );
      expect(
        GameIcon.resolveAssetPath('supercomputer'),
        'assets/images/icons/products/prod_supercomputer.svg',
      );
      expect(
        GameIcon.resolveAssetPath('wind_turbine'),
        'assets/images/icons/products/prod_wind_turbine.svg',
      );
      expect(
        GameIcon.resolveAssetPath('wind_turbine_generator'),
        'assets/images/icons/products/prod_wind_turbine.svg',
      );
    });

    test('Resolves all Batch 6 products correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('ai_core'),
        'assets/images/icons/products/prod_ai_core.svg',
      );
      expect(
        GameIcon.resolveAssetPath('nova_robotics'),
        'assets/images/icons/products/prod_ai_core.svg',
      );
      expect(
        GameIcon.resolveAssetPath('client_nova_robotics'),
        'assets/images/icons/products/prod_ai_core.svg',
      );
      expect(
        GameIcon.resolveAssetPath('dyson_receiver'),
        'assets/images/icons/products/prod_dyson_receiver.svg',
      );
      expect(
        GameIcon.resolveAssetPath('solaria_energy'),
        'assets/images/icons/products/prod_dyson_receiver.svg',
      );
      expect(
        GameIcon.resolveAssetPath('client_solaria_energy'),
        'assets/images/icons/products/prod_dyson_receiver.svg',
      );
      expect(
        GameIcon.resolveAssetPath('orbital_station'),
        'assets/images/icons/products/prod_orbital_station.svg',
      );
      expect(
        GameIcon.resolveAssetPath('particle_accelerator'),
        'assets/images/icons/products/prod_particle_accelerator.svg',
      );
      expect(
        GameIcon.resolveAssetPath('material_science'),
        'assets/images/icons/products/prod_particle_accelerator.svg',
      );
      expect(
        GameIcon.resolveAssetPath('tech_material_science'),
        'assets/images/icons/products/prod_particle_accelerator.svg',
      );
      expect(
        GameIcon.resolveAssetPath('quantum_computer'),
        'assets/images/icons/products/prod_quantum_computer.svg',
      );
      expect(
        GameIcon.resolveAssetPath('quantum_processor'),
        'assets/images/icons/products/prod_quantum_processor.svg',
      );
      expect(
        GameIcon.resolveAssetPath('space_probe'),
        'assets/images/icons/products/prod_space_probe.svg',
      );
      expect(
        GameIcon.resolveAssetPath('logistics_optimization'),
        'assets/images/icons/products/prod_space_probe.svg',
      );
      expect(
        GameIcon.resolveAssetPath('tech_logistics_optimization'),
        'assets/images/icons/products/prod_space_probe.svg',
      );
      expect(
        GameIcon.resolveAssetPath('space_telescope'),
        'assets/images/icons/products/prod_space_telescope.svg',
      );
      expect(
        GameIcon.resolveAssetPath('telecom_tower'),
        'assets/images/icons/products/prod_telecom_tower.svg',
      );
      expect(
        GameIcon.resolveAssetPath('apex_telecom'),
        'assets/images/icons/products/prod_telecom_tower.svg',
      );
      expect(
        GameIcon.resolveAssetPath('client_apex_telecom'),
        'assets/images/icons/products/prod_telecom_tower.svg',
      );
    });

    test('Resolves all Batch 2 machines correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('buyer'),
        'assets/images/icons/machines/mach_auto_buy.svg',
      );
      expect(
        GameIcon.resolveAssetPath('mach_auto_buy'),
        'assets/images/icons/machines/mach_auto_buy.svg',
      );
      expect(
        GameIcon.resolveAssetPath('basic_assembler'),
        'assets/images/icons/machines/mach_build_basic.svg',
      );
      expect(
        GameIcon.resolveAssetPath('intermediate_assembler'),
        'assets/images/icons/machines/mach_build_intermediate.svg',
      );
      expect(
        GameIcon.resolveAssetPath('complex_assembler'),
        'assets/images/icons/machines/mach_build_complex.svg',
      );
      expect(
        GameIcon.resolveAssetPath('basic_seller'),
        'assets/images/icons/machines/mach_auto_sell.svg',
      );
      expect(
        GameIcon.resolveAssetPath('tool_maintenance'),
        'assets/images/icons/machines/tool_maintenance.svg',
      );
      expect(
        GameIcon.resolveAssetPath('tool_salvage'),
        'assets/images/icons/machines/tool_salvage.svg',
      );
    });

    test('Resolves all Batch 2 logistics fleet correctly as SVG', () {
      expect(
        GameIcon.resolveAssetPath('courier_bike'),
        'assets/images/icons/fleet/fleet_courier_bike.svg',
      );
      expect(
        GameIcon.resolveAssetPath('fleet_1'),
        'assets/images/icons/fleet/fleet_courier_bike.svg',
      );
      expect(
        GameIcon.resolveAssetPath('delivery_van'),
        'assets/images/icons/fleet/fleet_delivery_van.svg',
      );
      expect(
        GameIcon.resolveAssetPath('fleet_2'),
        'assets/images/icons/fleet/fleet_delivery_van.svg',
      );
      expect(
        GameIcon.resolveAssetPath('freight_truck'),
        'assets/images/icons/fleet/fleet_freight_truck.svg',
      );
      expect(
        GameIcon.resolveAssetPath('fleet_3'),
        'assets/images/icons/fleet/fleet_freight_truck.svg',
      );
      expect(
        GameIcon.resolveAssetPath('cargo_plane'),
        'assets/images/icons/fleet/fleet_cargo_plane.svg',
      );
      expect(
        GameIcon.resolveAssetPath('fleet_4'),
        'assets/images/icons/fleet/fleet_cargo_plane.svg',
      );
    });

    test('Handles prefixed IDs gracefully', () {
      expect(
        GameIcon.resolveAssetPath('mat_cardboard'),
        'assets/images/icons/materials/mat_cardboard.svg',
      );
      expect(
        GameIcon.resolveAssetPath('prod_box'),
        'assets/images/icons/products/prod_box.svg',
      );
      expect(
        GameIcon.resolveAssetPath('mach_buyer'),
        'assets/images/icons/machines/mach_auto_buy.svg',
      );
      expect(
        GameIcon.resolveAssetPath('fleet_courier_bike'),
        'assets/images/icons/fleet/fleet_courier_bike.svg',
      );
      expect(
        GameIcon.resolveAssetPath('prod_battery'),
        'assets/images/icons/products/prod_battery.svg',
      );
      expect(
        GameIcon.resolveAssetPath('prod_smartphone'),
        'assets/images/icons/products/prod_smartphone.svg',
      );
      expect(
        GameIcon.resolveAssetPath('prod_drone'),
        'assets/images/icons/products/prod_drone.svg',
      );
      expect(
        GameIcon.resolveAssetPath('prod_ai_core'),
        'assets/images/icons/products/prod_ai_core.svg',
      );
      expect(
        GameIcon.resolveAssetPath('prod_quantum_computer'),
        'assets/images/icons/products/prod_quantum_computer.svg',
      );
    });

    test('Returns null for uncreated / future assets', () {
      expect(GameIcon.resolveAssetPath('silicon_wafer'), isNull);
      expect(GameIcon.resolveAssetPath('microcontroller'), isNull);
      expect(GameIcon.resolveAssetPath('chassis_alloy'), isNull);
      expect(GameIcon.resolveAssetPath('unknown_item'), isNull);
      expect(GameIcon.hasAsset('silicon_wafer'), isFalse);
    });

    test('hasAsset correctly identifies registered icons', () {
      expect(GameIcon.hasAsset('cardboard'), isTrue);
      expect(GameIcon.hasAsset('box'), isTrue);
      expect(GameIcon.hasAsset('buyer'), isTrue);
      expect(GameIcon.hasAsset('fleet_1'), isTrue);
      expect(GameIcon.hasAsset('battery'), isTrue);
      expect(GameIcon.hasAsset('speaker'), isTrue);
      expect(GameIcon.hasAsset('smartphone'), isTrue);
      expect(GameIcon.hasAsset('camera'), isTrue);
      expect(GameIcon.hasAsset('solar_panel'), isTrue);
      expect(GameIcon.hasAsset('vr_headset'), isTrue);
      expect(GameIcon.hasAsset('drone'), isTrue);
      expect(GameIcon.hasAsset('robot_dog'), isTrue);
      expect(GameIcon.hasAsset('electric_car'), isTrue);
      expect(GameIcon.hasAsset('fusion_reactor'), isTrue);
      expect(GameIcon.hasAsset('wind_turbine'), isTrue);
      expect(GameIcon.hasAsset('ai_core'), isTrue);
      expect(GameIcon.hasAsset('quantum_computer'), isTrue);
      expect(GameIcon.hasAsset('telecom_tower'), isTrue);
      expect(GameIcon.hasAsset('space_probe'), isTrue);
      expect(GameIcon.hasAsset('chassis_alloy'), isFalse);
    });
  });

  group('GameIcon Widget Rendering', () {
    testWidgets('Renders SvgPicture when SVG asset exists for item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameIcon(
              itemId: 'cardboard',
              fallbackEmoji: '📄',
              size: 32,
            ),
          ),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);

      final svgWidget = tester.widget<SvgPicture>(svgFinder);
      expect(svgWidget.width, 32);
      expect(svgWidget.height, 32);
    });

    testWidgets('Renders fallback emoji Text when no asset exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameIcon(
              itemId: 'future_item',
              fallbackEmoji: '🛸',
              size: 24,
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.byType(Image), findsNothing);
      final textFinder = find.text('🛸');
      expect(textFinder, findsOneWidget);
    });

    testWidgets('Convenience factory constructors function correctly with SVG', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GameIcon.forMaterial(
                  id: 'plastic',
                  fallbackEmoji: '🧱',
                  size: 28,
                ),
                GameIcon.forProduct(
                  id: 'wires',
                  fallbackEmoji: '🔌',
                  size: 28,
                ),
                GameIcon.forMachine(
                  id: 'buyer',
                  fallbackEmoji: '🤖',
                  size: 28,
                ),
                GameIcon.forFleet(
                  id: 'fleet_1',
                  fallbackEmoji: '🚲',
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      );

      final svgs = tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
      expect(svgs.length, 4);
      expect(svgs[0].width, 28);
      expect(svgs[1].width, 28);
      expect(svgs[2].width, 28);
      expect(svgs[3].width, 28);
    });
  });
}
