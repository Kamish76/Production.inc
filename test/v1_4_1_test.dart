import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/services/production_game_service.dart';

void main() {
  group('v1.4.1 Phase 2 Tests - Advanced Components', () {
    late ProductionGameService gameService;

    setUp(() async {
      gameService = ProductionGameService();
      // Wait a bit for the service to initialize
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      gameService.dispose();
    });

    test('New solar_cells basic part is available', () {
      final solarCells = gameService.getProduct('solar_cells');
      expect(solarCells, isNotNull);
      expect(solarCells!.name, 'Solar Cells');
      expect(solarCells.description, 'Photovoltaic cells for renewable energy');
      expect(solarCells.sellPrice, 40.0);
      expect(solarCells.emoji, '☀️');
      expect(solarCells.levelId, ProductLevel.basicParts);
      expect(solarCells.productionTimeSeconds, 15.0);

      // Check recipe requirements
      expect(solarCells.requiredMaterials['advanced_metals'], 2);
      expect(solarCells.requiredMaterials['glass'], 2);
      expect(solarCells.requiredMaterials['wires'], 1);
    });

    test('New image_sensor intermediate part is available', () {
      final imageSensor = gameService.getProduct('image_sensor');
      expect(imageSensor, isNotNull);
      expect(imageSensor!.name, 'Image Sensor');
      expect(imageSensor.description, 'Digital camera sensor');
      expect(imageSensor.sellPrice, 80.0);
      expect(imageSensor.emoji, '📸');
      expect(imageSensor.levelId, ProductLevel.intermediate);
      expect(imageSensor.productionTimeSeconds, 30.0);

      // Check recipe requirements
      expect(imageSensor.requiredMaterials['advanced_metals'], 3);
      expect(imageSensor.requiredMaterials['circuits'], 2);
      expect(imageSensor.requiredMaterials['lens'], 1);
      expect(imageSensor.requiredMaterials['wires'], 2);
    });

    test('New solar_panel retail product is available', () {
      final solarPanel = gameService.getProduct('solar_panel');
      expect(solarPanel, isNotNull);
      expect(solarPanel!.name, 'Solar Panel');
      expect(solarPanel.description, 'Solar power generator');
      expect(solarPanel.sellPrice, 200.0);
      expect(solarPanel.emoji, '🌞');
      expect(solarPanel.levelId, ProductLevel.retail);
      expect(solarPanel.productionTimeSeconds, 45.0);

      // Check recipe requirements
      expect(solarPanel.requiredMaterials['circuits'], 2);
      expect(solarPanel.requiredMaterials['metal_enclosure'], 1);
      expect(solarPanel.requiredMaterials['basic_metals'], 1);
      expect(solarPanel.requiredMaterials['wires'], 2);
      expect(solarPanel.requiredMaterials['solar_cells'], 3);
    });

    test('Solar technology products are properly categorized', () {
      final basicParts = gameService.basicPartsProducts;
      final intermediateParts = gameService.intermediateProducts;
      final retailProducts = gameService.retailProducts;

      // Check solar_cells is in basic parts
      expect(basicParts.any((p) => p.id == 'solar_cells'), true);

      // Check image_sensor is in intermediate
      expect(intermediateParts.any((p) => p.id == 'image_sensor'), true);

      // Check solar_panel is in retail
      expect(retailProducts.any((p) => p.id == 'solar_panel'), true);
    });

    test('Can verify solar_cells material requirements', () {
      // Test that materials are properly defined
      final solarCells = gameService.getProduct('solar_cells')!;

      // Verify that the product exists and has correct materials
      expect(solarCells.requiredMaterials['advanced_metals'], 2);
      expect(solarCells.requiredMaterials['glass'], 2);
      expect(solarCells.requiredMaterials['wires'], 1);

      // Check that materials exist
      final hasMaterials = gameService.state.hasMaterialsFor({
        'advanced_metals': 2,
        'glass': 2,
      });
      expect(hasMaterials, false); // Should be false initially

      // Buy materials
      final advancedMetalsResult = gameService.buyMaterial(
        'advanced_metals',
        2,
      );
      final glassResult = gameService.buyMaterial('glass', 2);

      expect(advancedMetalsResult, true);
      expect(glassResult, true);
    });

    test('Can verify image_sensor component requirements', () {
      // Test production chain dependencies
      final imageSensor = gameService.getProduct('image_sensor')!;

      // Verify it requires lens (which is a v1.4.0 product)
      expect(imageSensor.requiredMaterials.containsKey('lens'), true);
      expect(imageSensor.requiredMaterials['lens'], 1);

      // Verify it requires circuits (existing product)
      expect(imageSensor.requiredMaterials.containsKey('circuits'), true);
      expect(imageSensor.requiredMaterials['circuits'], 2);
    });

    test('Solar panel requires solar_cells dependency', () {
      final solarPanel = gameService.getProduct('solar_panel')!;

      // Verify solar panel requires 3 solar_cells
      expect(solarPanel.requiredMaterials.containsKey('solar_cells'), true);
      expect(solarPanel.requiredMaterials['solar_cells'], 3);

      // Verify other components
      expect(solarPanel.requiredMaterials.containsKey('metal_enclosure'), true);
      expect(solarPanel.requiredMaterials['metal_enclosure'], 1);
    });

    test('All v1.4.1 Phase 2 content is available', () {
      final allProducts = gameService.allProducts;

      // Count new v1.4.1 items
      final solarCellsExists = allProducts.any((p) => p.id == 'solar_cells');
      final imageSensorExists = allProducts.any((p) => p.id == 'image_sensor');
      final solarPanelExists = allProducts.any((p) => p.id == 'solar_panel');

      expect(solarCellsExists, true, reason: 'solar_cells should exist');
      expect(imageSensorExists, true, reason: 'image_sensor should exist');
      expect(solarPanelExists, true, reason: 'solar_panel should exist');

      // Verify total count increase
      final v141Products =
          allProducts
              .where(
                (p) =>
                    p.id == 'solar_cells' ||
                    p.id == 'image_sensor' ||
                    p.id == 'solar_panel',
              )
              .length;

      expect(
        v141Products,
        3,
        reason: 'Should have exactly 3 new v1.4.1 products',
      );
    });

    test('Economic balance verification for v1.4.1 products', () {
      final solarCells = gameService.getProduct('solar_cells')!;
      final imageSensor = gameService.getProduct('image_sensor')!;
      final solarPanel = gameService.getProduct('solar_panel')!;

      // Verify pricing progression makes sense
      expect(solarCells.sellPrice, 40.0);
      expect(imageSensor.sellPrice, 80.0);
      expect(solarPanel.sellPrice, 200.0);

      // Verify production time progression
      expect(solarCells.productionTimeSeconds, 15.0);
      expect(imageSensor.productionTimeSeconds, 30.0);
      expect(solarPanel.productionTimeSeconds, 45.0);

      // Solar panel should be most valuable and complex
      expect(solarPanel.sellPrice > imageSensor.sellPrice, true);
      expect(solarPanel.sellPrice > solarCells.sellPrice, true);
      expect(
        solarPanel.productionTimeSeconds > imageSensor.productionTimeSeconds,
        true,
      );
      expect(
        solarPanel.productionTimeSeconds > solarCells.productionTimeSeconds,
        true,
      );
    });

    test('Renewable energy theme progression', () {
      // Test that solar technology creates a logical progression
      final solarCells = gameService.getProduct('solar_cells')!;
      final solarPanel = gameService.getProduct('solar_panel')!;
      final imageSensor = gameService.getProduct('image_sensor')!;

      // Solar panel should require solar cells
      expect(solarPanel.requiredMaterials.containsKey('solar_cells'), true);
      expect(solarPanel.requiredMaterials['solar_cells'], 3);

      // Solar cells should use renewable energy materials (glass)
      expect(solarCells.requiredMaterials.containsKey('glass'), true);
      expect(solarCells.requiredMaterials['glass'], 2);

      // Both should require advanced technology (advanced_metals)
      expect(solarCells.requiredMaterials.containsKey('advanced_metals'), true);
      expect(
        imageSensor.requiredMaterials.containsKey('advanced_metals'),
        true,
      );
    });

    test('Intermediate products count updated', () {
      final intermediateProducts = gameService.intermediateProducts;

      // Should have v1.4.0 intermediate products plus new v1.4.1
      expect(intermediateProducts.length, greaterThanOrEqualTo(3));

      // Should contain v1.4.0 products
      expect(intermediateProducts.any((p) => p.id == 'display_screen'), true);
      expect(intermediateProducts.any((p) => p.id == 'processor'), true);

      // Should contain new v1.4.1 product
      expect(intermediateProducts.any((p) => p.id == 'image_sensor'), true);
    });
  });
}
