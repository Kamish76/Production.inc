import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';

void main() {
  group('V1.4.3 Implementation Tests', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService();
    });

    test('Smartphone (Premium retail) is available', () {
      final smartphone = GameData.getProduct('smartphone');
      expect(smartphone, isNotNull);
      expect(smartphone!.name, equals('Smartphone'));
      expect(smartphone.emoji, equals('📱'));
      expect(smartphone.sellPrice, equals(800.0));
      expect(smartphone.levelId, equals(ProductLevel.retail));
      expect(smartphone.productionTimeSeconds, equals(90.0));
      expect(smartphone.baseShippingTimeSeconds, equals(35.0));
    });

    test('Smartphone has correct required materials', () {
      final smartphone = GameData.getProduct('smartphone');
      expect(smartphone, isNotNull);

      final expectedMaterials = {
        'circuits': 2,
        'processor': 1,
        'metal_enclosure': 1,
        'basic_metals': 2,
        'wires': 3,
        'battery': 1,
        'sound_driver': 1,
        'display_screen': 1,
        'enclosure_plastic': 1,
      };

      expect(smartphone!.requiredMaterials, equals(expectedMaterials));
    });

    test('Smartphone is properly categorized in retail tier', () {
      final retailProducts = gameService.retailProducts;
      expect(retailProducts.isNotEmpty, isTrue);

      final smartphoneInRetail = retailProducts.any(
        (p) => p.id == 'smartphone',
      );
      expect(smartphoneInRetail, isTrue);
    });

    test('Smartphone is the most expensive product', () {
      final allProducts = GameData.products;
      final smartphone = GameData.getProduct('smartphone');

      // Smartphone should be the most expensive product
      final maxPrice = allProducts
          .map((p) => p.sellPrice)
          .reduce((a, b) => a > b ? a : b);
      expect(smartphone!.sellPrice, equals(maxPrice));
      expect(smartphone.sellPrice, equals(800.0));
    });

    test('Smartphone has the longest production time', () {
      final allProducts = GameData.products;
      final smartphone = GameData.getProduct('smartphone');

      // Smartphone should have the longest production time
      final maxProductionTime = allProducts
          .map((p) => p.productionTimeSeconds)
          .reduce((a, b) => a > b ? a : b);
      expect(smartphone!.productionTimeSeconds, equals(maxProductionTime));
      expect(smartphone.productionTimeSeconds, equals(90.0));
    });

    test('Smartphone requires the most materials', () {
      final smartphone = GameData.getProduct('smartphone');
      expect(smartphone, isNotNull);

      // Count total materials required
      final totalMaterials = smartphone!.requiredMaterials.values.reduce(
        (a, b) => a + b,
      );
      expect(totalMaterials, equals(13)); // 2+1+1+2+3+1+1+1+1 = 13 materials

      // Should be one of the most complex recipes
      expect(totalMaterials, greaterThan(10));
    });

    test('Economic balance is appropriate for premium product', () {
      final smartphone = GameData.getProduct('smartphone');
      expect(smartphone, isNotNull);

      // Smartphone should have significant profit potential
      expect(smartphone!.sellPrice, greaterThan(600.0));
      expect(smartphone.sellPrice, lessThan(1000.0));

      // Production time should reflect complexity
      expect(smartphone.productionTimeSeconds, greaterThan(80.0));
      expect(smartphone.productionTimeSeconds, lessThan(120.0));

      // Shipping time should be premium
      expect(smartphone.baseShippingTimeSeconds, greaterThan(30.0));
    });

    test('All prerequisite materials/products exist for smartphone', () {
      final smartphone = GameData.getProduct('smartphone');
      expect(smartphone, isNotNull);

      // Check that all required materials for smartphone exist
      for (final materialId in smartphone!.requiredMaterials.keys) {
        final material = GameData.getMaterial(materialId);
        final product = GameData.getProduct(materialId);

        expect(
          material != null || product != null,
          isTrue,
          reason:
              'Required item $materialId must exist as either material or product',
        );
      }
    });

    test('V1.4 series completion - all phases implemented', () {
      // Verify all V1.4 products exist
      final v14Products = [
        // V1.4.0
        'metal_enclosure',
        'lens',
        'battery',
        'display_screen',
        'processor',
        'power_bank',
        // V1.4.1
        'solar_cells', 'image_sensor', 'solar_panel',
        // V1.4.2
        'camera_module', 'camera',
        // V1.4.3
        'smartphone',
      ];

      for (final productId in v14Products) {
        final product = GameData.getProduct(productId);
        expect(
          product,
          isNotNull,
          reason: 'V1.4 product $productId should exist',
        );
      }
    });

    test('Complete production chain from materials to smartphone', () {
      // Test that we can trace full production chain
      final smartphone = GameData.getProduct('smartphone');
      expect(smartphone, isNotNull);

      // Check intermediate dependencies exist
      expect(GameData.getProduct('display_screen'), isNotNull);
      expect(GameData.getProduct('processor'), isNotNull);
      expect(GameData.getProduct('sound_driver'), isNotNull);
      expect(GameData.getProduct('battery'), isNotNull);

      // Check basic materials exist
      expect(GameData.getMaterial('basic_metals'), isNotNull);
      expect(GameData.getMaterial('advanced_metals'), isNotNull);
      expect(GameData.getMaterial('plastic'), isNotNull);
      expect(GameData.getMaterial('glass'), isNotNull);
    });

    test('Game progression path validates correctly', () {
      // Test the complete progression path:
      // Materials → Basic Parts → Intermediate → Complex → Premium Retail

      final basicParts = gameService.basicPartsProducts;
      final intermediateParts = gameService.intermediateProducts;
      final complexParts = gameService.complexProducts;
      final retailProducts = gameService.retailProducts;

      expect(basicParts.length, greaterThan(5));
      expect(intermediateParts.length, greaterThan(2));
      expect(complexParts.length, greaterThan(0));
      expect(retailProducts.length, greaterThan(3));

      // Smartphone should be in retail
      expect(retailProducts.any((p) => p.id == 'smartphone'), isTrue);
    });
  });
}
