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
    });

    test('Returns null for uncreated / future assets', () {
      expect(GameIcon.resolveAssetPath('sound_driver'), isNull);
      expect(GameIcon.resolveAssetPath('toy_robot'), isNull);
      expect(GameIcon.resolveAssetPath('unknown_item'), isNull);
      expect(GameIcon.hasAsset('sound_driver'), isFalse);
    });

    test('hasAsset correctly identifies registered icons', () {
      expect(GameIcon.hasAsset('cardboard'), isTrue);
      expect(GameIcon.hasAsset('box'), isTrue);
      expect(GameIcon.hasAsset('buyer'), isTrue);
      expect(GameIcon.hasAsset('fleet_1'), isTrue);
      expect(GameIcon.hasAsset('quantum_core'), isFalse);
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
