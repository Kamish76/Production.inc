import 'package:flutter_test/flutter_test.dart';
import 'package:game1/constants/game_constants.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/machine_builder.dart';
import 'package:game1/services/production_game_service.dart';
import 'test_utils.dart';

void main() {
  group('Auto-Build Priority Queue - Order & Ranking Logic', () {
    late ProductionGameService service;

    setUp(() {
      service = createTestGameService();
    });

    test('Default product order when no products are pinned', () {
      final defaultOrder = AutoBuildConstants.productOrderByTier['basicParts']!;
      final effectiveOrder = service.getEffectiveProductOrder('basicParts');

      expect(effectiveOrder, equals(defaultOrder));
      expect(service.getPinnedProducts('basicParts'), isEmpty);
    });

    test('Pinning products promotes them to the top of the queue', () {
      // Pin 'wires' first, then 'battery'
      service.pinProduct('wires');
      service.pinProduct('battery');

      final effectiveOrder = service.getEffectiveProductOrder('basicParts');

      expect(effectiveOrder.first, equals('wires'));
      expect(effectiveOrder[1], equals('battery'));
      expect(service.isProductPinned('wires'), isTrue);
      expect(service.isProductPinned('battery'), isTrue);
      expect(service.isProductPinned('box'), isFalse);

      expect(service.getProductPriorityRank('wires'), equals(1));
      expect(service.getProductPriorityRank('battery'), equals(2));
      expect(service.getProductPriorityRank('box'), isNull);

      // Verify no duplicates in the effective order
      final defaultOrder = AutoBuildConstants.productOrderByTier['basicParts']!;
      expect(effectiveOrder.length, equals(defaultOrder.length));
      expect(effectiveOrder.toSet().length, equals(defaultOrder.length));
    });

    test('Toggle pin toggles between pinned and unpinned', () {
      expect(service.isProductPinned('gears'), isFalse);

      service.togglePinProduct('gears');
      expect(service.isProductPinned('gears'), isTrue);
      expect(service.getProductPriorityRank('gears'), equals(1));

      service.togglePinProduct('gears');
      expect(service.isProductPinned('gears'), isFalse);
      expect(service.getProductPriorityRank('gears'), isNull);
    });

    test('Unpinning restores standard order position', () {
      service.pinProduct('wires');
      service.pinProduct('battery');
      service.pinProduct('copper_coils');

      expect(service.getPinnedProducts('basicParts'), equals(['wires', 'battery', 'copper_coils']));

      service.unpinProduct('battery');

      expect(service.getPinnedProducts('basicParts'), equals(['wires', 'copper_coils']));
      expect(service.getProductPriorityRank('wires'), equals(1));
      expect(service.getProductPriorityRank('copper_coils'), equals(2));
      expect(service.getProductPriorityRank('battery'), isNull);
    });

    test('Reordering pinned items adjusts priority order', () {
      service.pinProduct('box');
      service.pinProduct('wires');
      service.pinProduct('battery');

      expect(service.getPinnedProducts('basicParts'), equals(['box', 'wires', 'battery']));

      // Move 'battery' from index 2 to index 0 (top priority)
      service.movePinnedProductPriority('basicParts', 2, true); // index 2 -> 1
      service.movePinnedProductPriority('basicParts', 1, true); // index 1 -> 0

      expect(service.getPinnedProducts('basicParts'), equals(['battery', 'box', 'wires']));
      expect(service.getProductPriorityRank('battery'), equals(1));
      expect(service.getProductPriorityRank('box'), equals(2));
      expect(service.getProductPriorityRank('wires'), equals(3));
    });

    test('Clearing pinned products empties the tier priority queue', () {
      service.pinProduct('wires');
      service.pinProduct('battery');
      expect(service.getPinnedProducts('basicParts').length, equals(2));

      service.clearPinnedProducts('basicParts');
      expect(service.getPinnedProducts('basicParts'), isEmpty);
      expect(service.getEffectiveProductOrder('basicParts'),
          equals(AutoBuildConstants.productOrderByTier['basicParts']!));
    });
  });

  group('Auto-Build Priority Queue - Machine Execution Engine', () {
    final productRecipes = {
      'box': {'cardboard': 2},
      'wires': {'plastic': 1},
      'battery': {'plastic': 2, 'basic_metals': 1},
    };

    test('Pinned product is built first until capacity before moving to rest', () {
      final productInventory = {
        'box': 0,
        'wires': 0,
        'battery': 0,
      };
      final materialInventory = {
        'cardboard': 100,
        'plastic': 100,
        'basic_metals': 100,
      };
      final unlockedProducts = {'box', 'wires', 'battery'};

      // Pinned order: wires (#1) -> box -> battery
      final prioritizedOrder = ['wires', 'box', 'battery'];

      // Tick 1: 2 machines * 2 builds = 4 pooled builds. Cap = 6.
      final result1 = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: prioritizedOrder,
        productCap: 6,
      );

      // All 4 builds should go to 'wires' because it is prioritized and deficit is 6
      expect(result1.itemsBuilt, equals(4));
      expect(productInventory['wires'], equals(4));
      expect(productInventory['box'], equals(0));
      expect(productInventory['battery'], equals(0));

      // Tick 2: 4 pooled builds. Wires only needs 2 more to hit cap of 6.
      // Remaining 2 builds should flow to next item: 'box'.
      final result2 = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: prioritizedOrder,
        productCap: 6,
      );

      expect(result2.itemsBuilt, equals(4));
      expect(productInventory['wires'], equals(6), reason: 'Wires reached capacity of 6');
      expect(productInventory['box'], equals(2), reason: 'Machine moved on to box after wires reached capacity');
      expect(productInventory['battery'], equals(0));
    });

    test('Option A: Non-blocking fall-through when pinned product lacks materials', () {
      final productInventory = {
        'box': 0,
        'wires': 0,
        'battery': 0,
      };
      // No plastic! So 'wires' (requires plastic: 1) cannot be built.
      // But we have cardboard: 100 for 'box'.
      final materialInventory = {
        'cardboard': 100,
        'plastic': 0,
        'basic_metals': 100,
      };
      final unlockedProducts = {'box', 'wires', 'battery'};

      // Pinned order: wires (#1) -> box -> battery
      final prioritizedOrder = ['wires', 'box', 'battery'];

      final result1 = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: prioritizedOrder,
        productCap: 10,
      );

      // Wires cannot be built (0 plastic), so machine falls through to box
      expect(result1.itemsBuilt, equals(4));
      expect(productInventory['wires'], equals(0));
      expect(productInventory['box'], equals(4));

      // Now replenish plastic: 50
      materialInventory['plastic'] = 50;

      // Tick 2: Wires now has materials, so all capacity immediately returns to wires
      final result2 = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: prioritizedOrder,
        productCap: 10,
      );

      expect(result2.itemsBuilt, equals(4));
      expect(productInventory['wires'], equals(4), reason: 'Reverts 100% priority to wires once materials arrive');
      expect(productInventory['box'], equals(4), reason: 'Box remains at 4 while wires is below cap');
    });

    test('Multiple pinned products are satisfied in rank order before unpinned items', () {
      final productInventory = {
        'battery': 0,
        'wires': 0,
        'box': 0,
      };
      final materialInventory = {
        'cardboard': 200,
        'plastic': 200,
        'basic_metals': 200,
      };
      final unlockedProducts = {'box', 'wires', 'battery'};

      // #1 Battery, #2 Wires, unpinned Box
      final prioritizedOrder = ['battery', 'wires', 'box'];

      // Tick with 5 builds, cap = 5
      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 5,
        buildsPerMachinePerTick: 1,
        productOrder: prioritizedOrder,
        productCap: 5,
      );

      expect(result.itemsBuilt, equals(5));
      expect(productInventory['battery'], equals(5), reason: '#1 priority item filled first');
      expect(productInventory['wires'], equals(0));
      expect(productInventory['box'], equals(0));

      // Next tick with 5 builds
      final result2 = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 5,
        buildsPerMachinePerTick: 1,
        productOrder: prioritizedOrder,
        productCap: 5,
      );

      expect(result2.itemsBuilt, equals(5));
      expect(productInventory['battery'], equals(5));
      expect(productInventory['wires'], equals(5), reason: '#2 priority item filled second');
      expect(productInventory['box'], equals(0));

      // Third tick with 5 builds
      final result3 = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 5,
        buildsPerMachinePerTick: 1,
        productOrder: prioritizedOrder,
        productCap: 5,
      );

      expect(result3.itemsBuilt, equals(5));
      expect(productInventory['battery'], equals(5));
      expect(productInventory['wires'], equals(5));
      expect(productInventory['box'], equals(5), reason: 'Unpinned item filled last');
    });
  });

  group('Auto-Build Priority Queue - GameState Serialization', () {
    test('Roundtrips autoBuildPriorityOrder in toJson and fromJson', () {
      final state = const GameState(
        autoBuildMachinesOwned: {'basicParts': 2},
        autoBuildEnabled: {'basicParts': true},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {'basicParts': 10},
        autoBuildPriorityOrder: {
          'basicParts': ['wires', 'battery'],
          'intermediate': ['servo_motor'],
        },
      );

      final json = state.toJson();
      expect(json['autoBuildPriorityOrder'], isNotNull);

      final restored = GameState.fromJson(json);
      expect(
        restored.autoBuildPriorityOrder['basicParts'],
        equals(['wires', 'battery']),
      );
      expect(
        restored.autoBuildPriorityOrder['intermediate'],
        equals(['servo_motor']),
      );
    });
  });
}
