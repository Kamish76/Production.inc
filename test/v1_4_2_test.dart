import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';

void main() {
  group('V1.4.2 Implementation Tests', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService();
    });

    test('Camera Module (Complex tier) is available', () {
      final cameraModule = GameData.getProduct('camera_module');
      expect(cameraModule, isNotNull);
      expect(cameraModule!.name, equals('Camera Module'));
      expect(cameraModule.emoji, equals('📷'));
      expect(cameraModule.sellPrice, equals(150.0));
      expect(cameraModule.levelId, equals(ProductLevel.complex));
      expect(cameraModule.productionTimeSeconds, equals(50.0));
      expect(cameraModule.baseShippingTimeSeconds, equals(18.0));
    });

    test('Camera Module has correct required materials', () {
      final cameraModule = GameData.getProduct('camera_module');
      expect(cameraModule, isNotNull);

      final expectedMaterials = {
        'lens': 1,
        'image_sensor': 1,
        'processor': 1,
        'battery': 1,
        'metal_enclosure': 1,
        'wires': 2,
      };

      expect(cameraModule!.requiredMaterials, equals(expectedMaterials));
    });

    test('Digital Camera (Retail tier) is available', () {
      final camera = GameData.getProduct('camera');
      expect(camera, isNotNull);
      expect(camera!.name, equals('Digital Camera'));
      expect(camera.emoji, equals('📹'));
      expect(camera.sellPrice, equals(350.0));
      expect(camera.levelId, equals(ProductLevel.retail));
      expect(camera.productionTimeSeconds, equals(60.0));
      expect(camera.baseShippingTimeSeconds, equals(22.0));
    });

    test('Digital Camera has correct required materials', () {
      final camera = GameData.getProduct('camera');
      expect(camera, isNotNull);

      final expectedMaterials = {
        'circuits': 1,
        'processor': 1,
        'metal_enclosure': 1,
        'basic_metals': 1,
        'wires': 1,
        'battery': 1,
        'image_sensor': 1,
      };

      expect(camera!.requiredMaterials, equals(expectedMaterials));
    });

    test('Complex products are properly categorized', () {
      final complexProducts = gameService.complexProducts;
      expect(complexProducts.isNotEmpty, isTrue);

      final cameraModuleInComplex = complexProducts.any(
        (p) => p.id == 'camera_module',
      );
      expect(cameraModuleInComplex, isTrue);
    });

    test('New retail products are properly categorized', () {
      final retailProducts = gameService.retailProducts;
      expect(retailProducts.isNotEmpty, isTrue);

      final cameraInRetail = retailProducts.any((p) => p.id == 'camera');
      expect(cameraInRetail, isTrue);
    });

    test('V1.4.2 products have proper dependency chain', () {
      // Camera Module requires intermediate parts (image_sensor, processor)
      final cameraModule = GameData.getProduct('camera_module');
      expect(
        cameraModule!.requiredMaterials.containsKey('image_sensor'),
        isTrue,
      );
      expect(cameraModule.requiredMaterials.containsKey('processor'), isTrue);

      // Digital Camera requires intermediate part (image_sensor)
      final camera = GameData.getProduct('camera');
      expect(camera!.requiredMaterials.containsKey('image_sensor'), isTrue);
      expect(camera.requiredMaterials.containsKey('processor'), isTrue);
    });

    test('Economic balance is reasonable for V1.4.2 products', () {
      final cameraModule = GameData.getProduct('camera_module');
      final camera = GameData.getProduct('camera');

      // Camera Module should be profitable
      expect(cameraModule!.sellPrice, greaterThan(100.0));
      expect(cameraModule.sellPrice, lessThan(200.0));

      // Camera should be the most expensive retail product so far
      expect(camera!.sellPrice, greaterThan(300.0));
      expect(camera.sellPrice, lessThan(400.0));

      // Production times should scale with complexity
      expect(cameraModule.productionTimeSeconds, greaterThan(40.0));
      expect(camera.productionTimeSeconds, greaterThan(50.0));
    });

    test('All prerequisite products exist for V1.4.2 chain', () {
      // Check that all required materials for new products exist
      final requiredItems = {
        'lens',
        'image_sensor',
        'processor',
        'battery',
        'metal_enclosure',
        'wires',
        'circuits',
        'basic_metals',
      };

      for (final itemId in requiredItems) {
        final material = GameData.getMaterial(itemId);
        final product = GameData.getProduct(itemId);

        expect(
          material != null || product != null,
          isTrue,
          reason:
              'Required item $itemId must exist as either material or product',
        );
      }
    });
  });
}
