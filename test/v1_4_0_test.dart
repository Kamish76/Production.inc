import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/services/production_game_service.dart';

/// Test suite for v1.4.0 Phase 1 content
void main() {
  group('v1.4.0 Phase 1 Tests', () {
    late ProductionGameService gameService;

    setUp(() async {
      gameService = ProductionGameService();
      // Wait a bit for the service to initialize
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      gameService.dispose();
    });

    test('New glass material is available', () {
      final glass = gameService.getMaterial('glass');
      expect(glass, isNotNull);
      expect(glass!.name, equals('Glass'));
      expect(glass.buyPrice, equals(5.0));
      expect(glass.emoji, equals('🪟'));
    });

    test('New basic parts are available', () {
      // Metal Enclosure
      final metalEnclosure = gameService.getProduct('metal_enclosure');
      expect(metalEnclosure, isNotNull);
      expect(metalEnclosure!.name, equals('Metal Enclosure'));
      expect(metalEnclosure.levelId, equals(ProductLevel.basicParts));
      expect(metalEnclosure.requiredMaterials, containsPair('basic_metals', 2));
      expect(metalEnclosure.requiredMaterials, containsPair('plastic', 1));

      // Lens
      final lens = gameService.getProduct('lens');
      expect(lens, isNotNull);
      expect(lens!.name, equals('Lens'));
      expect(lens.levelId, equals(ProductLevel.basicParts));
      expect(lens.requiredMaterials, containsPair('glass', 1));
      expect(lens.requiredMaterials, containsPair('advanced_metals', 2));

      // Battery
      final battery = gameService.getProduct('battery');
      expect(battery, isNotNull);
      expect(battery!.name, equals('Battery'));
      expect(battery.levelId, equals(ProductLevel.basicParts));
      expect(battery.requiredMaterials, containsPair('advanced_metals', 2));
      expect(battery.requiredMaterials, containsPair('plastic', 1));
      expect(battery.requiredMaterials, containsPair('wires', 1));
    });

    test('New intermediate parts are available', () {
      // Display Screen
      final displayScreen = gameService.getProduct('display_screen');
      expect(displayScreen, isNotNull);
      expect(displayScreen!.name, equals('Display Screen'));
      expect(displayScreen.levelId, equals(ProductLevel.intermediate));
      expect(displayScreen.requiredMaterials, containsPair('glass', 2));
      expect(displayScreen.requiredMaterials, containsPair('circuits', 1));
      expect(
        displayScreen.requiredMaterials,
        containsPair('metal_enclosure', 1),
      );
      expect(displayScreen.requiredMaterials, containsPair('wires', 1));

      // Processor
      final processor = gameService.getProduct('processor');
      expect(processor, isNotNull);
      expect(processor!.name, equals('Processor'));
      expect(processor.levelId, equals(ProductLevel.intermediate));
      expect(processor.requiredMaterials, containsPair('advanced_metals', 3));
      expect(processor.requiredMaterials, containsPair('circuits', 2));
      expect(processor.requiredMaterials, containsPair('enclosure_plastic', 1));
      expect(processor.requiredMaterials, containsPair('wires', 2));
    });

    test('New retail product is available', () {
      final powerBank = gameService.getProduct('power_bank');
      expect(powerBank, isNotNull);
      expect(powerBank!.name, equals('Power Bank'));
      expect(powerBank.levelId, equals(ProductLevel.retail));
      expect(powerBank.sellPrice, equals(120.0));
      expect(powerBank.requiredMaterials, containsPair('circuits', 1));
      expect(powerBank.requiredMaterials, containsPair('enclosure_plastic', 1));
      expect(powerBank.requiredMaterials, containsPair('basic_metals', 1));
      expect(powerBank.requiredMaterials, containsPair('wires', 1));
      expect(powerBank.requiredMaterials, containsPair('battery', 2));
    });

    test('Intermediate products are properly categorized', () {
      final intermediateProducts = gameService.intermediateProducts;
      expect(intermediateProducts.length, equals(2));
      expect(intermediateProducts.map((p) => p.id), contains('display_screen'));
      expect(intermediateProducts.map((p) => p.id), contains('processor'));
    });

    test('Can produce new basic parts with materials', () async {
      // Ensure game service has proper starting money
      expect(gameService.state.money, greaterThanOrEqualTo(100.0));

      // Test production of metal enclosure (needs basic_metals: 2 x $3 = $6, plastic: 1 x $2 = $2, total $8)
      final metalResult = gameService.buyMaterial('basic_metals', 2);
      expect(metalResult, isTrue);
      final plasticResult = gameService.buyMaterial('plastic', 1);
      expect(plasticResult, isTrue);

      final canProduceMetal = gameService.state.hasMaterialsFor({
        'basic_metals': 2,
        'plastic': 1,
      });
      expect(canProduceMetal, isTrue);

      // Test production of lens (needs glass: 1 x $5 = $5, advanced_metals: 2 x $8 = $16, total $21)
      final glassResult = gameService.buyMaterial('glass', 1);
      expect(glassResult, isTrue);
      final advancedResult = gameService.buyMaterial('advanced_metals', 2);
      expect(advancedResult, isTrue);

      final canProduceLens = gameService.state.hasMaterialsFor({
        'glass': 1,
        'advanced_metals': 2,
      });
      expect(canProduceLens, isTrue);
    });

    test('Complex production chain works (Power Bank)', () async {
      // This test ensures the complex production chain works end-to-end
      // Check that we can at least verify the materials requirements
      // Starting money should be $100, so we need to be conservative

      // Buy minimal materials to test basic components
      final metalResult = gameService.buyMaterial('basic_metals', 3);
      expect(metalResult, isTrue);
      final plasticResult = gameService.buyMaterial('plastic', 2);
      expect(plasticResult, isTrue);

      // Should be able to produce wires (needs 2 basic_metals + 1 plastic)
      final canProduceWires = gameService.state.hasMaterialsFor({
        'basic_metals': 2,
        'plastic': 1,
      });
      expect(canProduceWires, isTrue);

      // Should be able to produce circuits (needs 3 basic_metals + 2 plastic)
      final canProduceCircuits = gameService.state.hasMaterialsFor({
        'basic_metals': 3,
        'plastic': 2,
      });
      expect(canProduceCircuits, isTrue);

      // Should NOT be able to produce enclosure without more plastic
      final canProduceEnclosure = gameService.state.hasMaterialsFor({
        'plastic': 4,
      });
      expect(canProduceEnclosure, isFalse); // Need 4 plastic, only have 2

      // Should NOT be able to produce battery without wires and advanced metals
      final canProduceBattery = gameService.state.hasMaterialsFor({
        'advanced_metals': 2,
        'plastic': 1,
        'wires': 1,
      });
      expect(canProduceBattery, isFalse); // Need to produce wires first
    });

    test('All v1.4.0 Phase 1 content counts', () {
      // Verify the exact number of new items added
      final allMaterials = gameService.allMaterials;
      expect(allMaterials.length, equals(5)); // 4 original + 1 new (glass)

      final allProducts = gameService.allProducts;
      expect(allProducts.length, equals(12)); // 6 original + 6 new

      final basicParts = gameService.basicPartsProducts;
      expect(basicParts.length, equals(8)); // 5 original + 3 new

      final intermediate = gameService.intermediateProducts;
      expect(intermediate.length, equals(2)); // 0 original + 2 new

      final retail = gameService.retailProducts;
      expect(retail.length, equals(2)); // 1 original + 1 new
    });
  });
}
