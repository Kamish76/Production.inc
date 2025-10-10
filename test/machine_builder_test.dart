/// Test suite for Auto-Build Machine system (v1.5.0 Phase 2)/// Test suite for Auto-Build Machine system (v1.5.0 Phase 2)

/// /// 

/// Comprehensive tests for the pooled-capacity building logic/// Comprehensive tests for the pooled-capacity building logic

/// with queued product count tracking./// following the same pattern as auto-buy machine tests.



import 'package:flutter_test/flutter_test.dart';import 'package:flutter_test/flutter_test.dart';

import 'package:game1/services/machine_builder.dart';import 'package:game1/services/machine_builder.dart';



void main() {void main() {

  group('Auto-Build Machine - Basic Functionality', () {  group('Auto-Build Machine - Basic Functionality', () {

    final productRecipes = {    final productRecipes = {

      'box': {'cardboard': 2},      'box': {'cardboard': 2},

      'wires': {'plastic': 1},      'wires': {'plastic': 1},

      'circuit': {'plastic': 2, 'basic_metals': 1},      'circuit': {'plastic': 2, 'basic_metals': 1},

    };    };



    test('Basic building: 2 machines × 2 builds = 4 builds per tick', () {    test('Basic building: 2 machines × 2 builds = 4 builds per tick', () {

      final productInventory = {'box': 0};      final productInventory = {'box': 0};

      final materialInventory = {'cardboard': 100};      final materialInventory = {'cardboard': 100};

      final unlockedProducts = {'box'};      final unlockedProducts = {'box'};



      final result = performAutoBuildTick(      final result = performAutoBuildTick(

        productInventory: productInventory,        productInventory: productInventory,

        materialInventory: materialInventory,        materialInventory: materialInventory,

        productRecipes: productRecipes,        productRecipes: productRecipes,

        unlockedProducts: unlockedProducts,        unlockedProducts: unlockedProducts,

        queuedProductCounts: {},        queuedProductCounts: {},

        machinesEnabled: 2,        machinesEnabled: 2,

        buildsPerMachinePerTick: 2,        buildsPerMachinePerTick: 2,

        productOrder: ['box'],        productOrder: ['box'],

        productCap: 10,        productCap: 10,

      );      );



      expect(result.itemsBuilt, equals(4), reason: '2 machines × 2 builds = 4 items');      expect(result.itemsBuilt, equals(4), reason: '2 machines × 2 builds = 4 items');

      expect(productInventory['box'], equals(4), reason: 'Should build 4 boxes');      expect(productInventory['box'], equals(4), reason: 'Should build 4 boxes');

      expect(materialInventory['cardboard'], equals(92), reason: 'Should consume 8 cardboard (4 × 2)');      expect(materialInventory['cardboard'], equals(92), reason: 'Should consume 8 cardboard (4 × 2)');

      expect(result.materialsConsumed['cardboard'], equals(8));      expect(result.materialsConsumed['cardboard'], equals(8));

    });    });



    test('Respect queued items: inventory + queued against cap', () {    test('Material constraint: stop when materials run out', () {

      final productInventory = {'box': 3};      final productInventory = {'box': 0};

      final materialInventory = {'cardboard': 100};      final materialInventory = {'cardboard': 5}; // Only enough for 2 boxes

      final unlockedProducts = {'box'};      final unlockedProducts = {'box'};

      final queuedProductCounts = {'box': 5}; // 5 boxes in queue

      final result = performAutoBuildTick(

      // Total = 3 (inventory) + 5 (queued) = 8        productInventory: productInventory,

      // Cap = 10, so deficit = 2, should only build 2        materialInventory: materialInventory,

      final result = performAutoBuildTick(        productRecipes: productRecipes,

        productInventory: productInventory,        unlockedProducts: unlockedProducts,

        materialInventory: materialInventory,        queuedProductCounts: {},

        productRecipes: productRecipes,        machinesEnabled: 2,

        unlockedProducts: unlockedProducts,        buildsPerMachinePerTick: 2,

        queuedProductCounts: queuedProductCounts,        productOrder: ['box'],

        machinesEnabled: 2,        productCap: 10,

        buildsPerMachinePerTick: 2,      );

        productOrder: ['box'],

        productCap: 10,      expect(result.itemsBuilt, equals(2), reason: 'Can only build 2 boxes with 5 cardboard');

      );      expect(productInventory['box'], equals(2));

      expect(materialInventory['cardboard'], equals(1), reason: 'Should have 1 cardboard left');

      expect(result.itemsBuilt, equals(2), reason: 'Should only build 2 (inventory 3 + queued 5 + build 2 = 10 cap)');    });

      expect(productInventory['box'], equals(5), reason: 'Inventory updated');

    });    test('Capacity constraint: stop at product cap', () {

      final productInventory = {'box': 8};

    test('At cap with queued items: no builds', () {      final materialInventory = {'cardboard': 100};

      final productInventory = {'box': 5};      final unlockedProducts = {'box'};

      final materialInventory = {'cardboard': 100};

      final unlockedProducts = {'box'};      final result = performAutoBuildTick(

      final queuedProductCounts = {'box': 5}; // Total = 10, at cap        productInventory: productInventory,

        materialInventory: materialInventory,

      final result = performAutoBuildTick(        productRecipes: productRecipes,

        productInventory: productInventory,        unlockedProducts: unlockedProducts,

        materialInventory: materialInventory,        queuedProductCounts: {},

        productRecipes: productRecipes,        machinesEnabled: 2,

        unlockedProducts: unlockedProducts,        buildsPerMachinePerTick: 2,

        queuedProductCounts: queuedProductCounts,        productOrder: ['box'],

        machinesEnabled: 2,        productCap: 10,

        buildsPerMachinePerTick: 2,      );

        productOrder: ['box'],

        productCap: 10,      expect(result.itemsBuilt, equals(2), reason: 'Should only build to cap (10)');

      );      expect(productInventory['box'], equals(10), reason: 'Should stop at cap');

      expect(materialInventory['cardboard'], equals(96), reason: 'Should consume 4 cardboard (2 × 2)');

      expect(result.itemsBuilt, equals(0), reason: 'At cap (5 + 5 = 10), no builds');    });

      expect(productInventory['box'], equals(5), reason: 'Inventory unchanged');

    });    test('Already at cap: no builds', () {

      final productInventory = {'box': 10};

    test('Material constraint: stop when materials run out', () {      final materialInventory = {'cardboard': 100};

      final productInventory = {'box': 0};      final unlockedProducts = {'box'};

      final materialInventory = {'cardboard': 5}; // Only enough for 2 boxes

      final unlockedProducts = {'box'};      final result = performAutoBuildTick(

        productInventory: productInventory,

      final result = performAutoBuildTick(        materialInventory: materialInventory,

        productInventory: productInventory,        productRecipes: productRecipes,

        materialInventory: materialInventory,        unlockedProducts: unlockedProducts,

        productRecipes: productRecipes,        queuedProductCounts: {},

        unlockedProducts: unlockedProducts,        machinesEnabled: 2,

        queuedProductCounts: {},        buildsPerMachinePerTick: 2,

        machinesEnabled: 2,        productOrder: ['box'],

        buildsPerMachinePerTick: 2,        productCap: 10,

        productOrder: ['box'],      );

        productCap: 10,

      );      expect(result.itemsBuilt, equals(0), reason: 'Already at cap, no builds');

      expect(productInventory['box'], equals(10));

      expect(result.itemsBuilt, equals(2), reason: 'Can only build 2 boxes with 5 cardboard');      expect(materialInventory['cardboard'], equals(100), reason: 'No materials consumed');

      expect(productInventory['box'], equals(2));    });

      expect(materialInventory['cardboard'], equals(1), reason: 'Should have 1 cardboard left');  });

    });

  });  group('Auto-Build Machine - Multiple Products', () {

    final productRecipes = {

  group('Auto-Build Machine - Multiple Products', () {      'box': {'cardboard': 2},

    final productRecipes = {      'wires': {'plastic': 1},

      'box': {'cardboard': 2},    };

      'wires': {'plastic': 1},

    };    test('Build multiple products in order', () {

      final productInventory = {'box': 0, 'wires': 0};

    test('Wrap around to next product when first is at cap (considering queue)', () {      final materialInventory = {'cardboard': 100, 'plastic': 100};

      final productInventory = {'box': 5, 'wires': 0};      final unlockedProducts = {'box', 'wires'};

      final materialInventory = {'cardboard': 100, 'plastic': 100};

      final unlockedProducts = {'box', 'wires'};      // 4 pooled builds: fill box first (0 -> 4), then no capacity left

      final queuedProductCounts = {'box': 3}; // Total box = 5 + 3 = 8      final result = performAutoBuildTick(

        productInventory: productInventory,

      // 4 pooled builds: box needs 2 to cap (8 -> 10), then 2 left for wires        materialInventory: materialInventory,

      final result = performAutoBuildTick(        productRecipes: productRecipes,

        productInventory: productInventory,        unlockedProducts: unlockedProducts,

        materialInventory: materialInventory,        queuedProductCounts: {},

        productRecipes: productRecipes,        machinesEnabled: 2,

        unlockedProducts: unlockedProducts,        buildsPerMachinePerTick: 2,

        queuedProductCounts: queuedProductCounts,        productOrder: ['box', 'wires'],

        machinesEnabled: 2,        productCap: 10,

        buildsPerMachinePerTick: 2,      );

        productOrder: ['box', 'wires'],

        productCap: 10,      expect(result.itemsBuilt, equals(4), reason: 'Should build 4 boxes');

      );      expect(productInventory['box'], equals(4));

      expect(productInventory['wires'], equals(0), reason: 'All pooled capacity used on boxes');

      expect(result.itemsBuilt, equals(4), reason: 'Should build 2 boxes + 2 wires');    });

      expect(productInventory['box'], equals(7));

      expect(productInventory['wires'], equals(2));    test('Wrap around to next product when first is at cap', () {

    });      final productInventory = {'box': 8, 'wires': 0};

  });      final materialInventory = {'cardboard': 100, 'plastic': 100};

      final unlockedProducts = {'box', 'wires'};

  group('Auto-Build Machine - Edge Cases', () {

    final productRecipes = {      // 4 pooled builds: box needs 2 to cap (8 -> 10), then 2 left for wires

      'box': {'cardboard': 2},      final result = performAutoBuildTick(

    };        productInventory: productInventory,

        materialInventory: materialInventory,

    test('Zero machines: no builds', () {        productRecipes: productRecipes,

      final productInventory = {'box': 0};        unlockedProducts: unlockedProducts,

      final materialInventory = {'cardboard': 100};        queuedProductCounts: {},

      final unlockedProducts = {'box'};        machinesEnabled: 2,

        buildsPerMachinePerTick: 2,

      final result = performAutoBuildTick(        productOrder: ['box', 'wires'],

        productInventory: productInventory,        productCap: 10,

        materialInventory: materialInventory,      );

        productRecipes: productRecipes,

        unlockedProducts: unlockedProducts,      expect(result.itemsBuilt, equals(4), reason: 'Should build 2 boxes + 2 wires');

        queuedProductCounts: {},      expect(productInventory['box'], equals(10));

        machinesEnabled: 0,      expect(productInventory['wires'], equals(2));

        buildsPerMachinePerTick: 2,      expect(materialInventory['cardboard'], equals(96), reason: '2 boxes consume 4 cardboard');

        productOrder: ['box'],      expect(materialInventory['plastic'], equals(98), reason: '2 wires consume 2 plastic');

        productCap: 10,    });

      );

    test('All products at cap: remaining builds unused', () {

      expect(result.itemsBuilt, equals(0), reason: 'No machines, no builds');      final productInventory = {'box': 10, 'wires': 10};

    });      final materialInventory = {'cardboard': 100, 'plastic': 100};

      final unlockedProducts = {'box', 'wires'};

    test('No materials available: no builds', () {

      final productInventory = {'box': 0};      final result = performAutoBuildTick(

      final materialInventory = {'cardboard': 0};        productInventory: productInventory,

      final unlockedProducts = {'box'};        materialInventory: materialInventory,

        productRecipes: productRecipes,

      final result = performAutoBuildTick(        unlockedProducts: unlockedProducts,

        productInventory: productInventory,        queuedProductCounts: {},

        materialInventory: materialInventory,        machinesEnabled: 2,

        productRecipes: productRecipes,        buildsPerMachinePerTick: 2,

        unlockedProducts: unlockedProducts,        productOrder: ['box', 'wires'],

        queuedProductCounts: {},        productCap: 10,

        machinesEnabled: 2,      );

        buildsPerMachinePerTick: 2,

        productOrder: ['box'],      expect(result.itemsBuilt, equals(0), reason: 'All at cap, no builds');

        productCap: 10,      expect(productInventory['box'], equals(10));

      );      expect(productInventory['wires'], equals(10));

    });

      expect(result.itemsBuilt, equals(0), reason: 'No materials, no builds');  });

    });

  });  group('Auto-Build Machine - Unlock Constraints', () {

}    final productRecipes = {

      'box': {'cardboard': 2},
      'wires': {'plastic': 1},
    };

    test('Skip locked products', () {
      final productInventory = {'box': 0, 'wires': 0};
      final materialInventory = {'cardboard': 100, 'plastic': 100};
      final unlockedProducts = {'wires'}; // Only wires unlocked

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['box', 'wires'], // Box comes first but is locked
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(4), reason: 'Should skip box, build 4 wires');
      expect(productInventory['box'], equals(0), reason: 'Box is locked, not built');
      expect(productInventory['wires'], equals(4), reason: 'Wires unlocked, built');
    });

    test('No unlocked products: no builds', () {
      final productInventory = {'box': 0};
      final materialInventory = {'cardboard': 100};
      final unlockedProducts = <String>{}; // Nothing unlocked

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['box'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(0), reason: 'Nothing unlocked, no builds');
    });
  });

  group('Auto-Build Machine - Complex Recipes', () {
    final productRecipes = {
      'circuit': {'plastic': 2, 'basic_metals': 1},
    };

    test('Multiple materials per product', () {
      final productInventory = {'circuit': 0};
      final materialInventory = {'plastic': 100, 'basic_metals': 100};
      final unlockedProducts = {'circuit'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['circuit'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(4), reason: 'Should build 4 circuits');
      expect(productInventory['circuit'], equals(4));
      expect(materialInventory['plastic'], equals(92), reason: '4 circuits × 2 plastic = 8');
      expect(materialInventory['basic_metals'], equals(96), reason: '4 circuits × 1 metal = 4');
      expect(result.materialsConsumed['plastic'], equals(8));
      expect(result.materialsConsumed['basic_metals'], equals(4));
    });

    test('Limited by scarcest material', () {
      final productInventory = {'circuit': 0};
      final materialInventory = {'plastic': 100, 'basic_metals': 2}; // Only 2 circuits possible
      final unlockedProducts = {'circuit'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['circuit'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(2), reason: 'Limited by basic_metals');
      expect(productInventory['circuit'], equals(2));
      expect(materialInventory['plastic'], equals(96), reason: '2 circuits × 2 plastic = 4');
      expect(materialInventory['basic_metals'], equals(0), reason: 'All consumed');
    });
  });

  group('Auto-Build Machine - Edge Cases', () {
    final productRecipes = {
      'box': {'cardboard': 2},
    };

    test('Zero machines: no builds', () {
      final productInventory = {'box': 0};
      final materialInventory = {'cardboard': 100};
      final unlockedProducts = {'box'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 0,
        buildsPerMachinePerTick: 2,
        productOrder: ['box'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(0), reason: 'No machines, no builds');
    });

    test('Negative machines clamped to zero', () {
      final productInventory = {'box': 0};
      final materialInventory = {'cardboard': 100};
      final unlockedProducts = {'box'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: -5,
        buildsPerMachinePerTick: 2,
        productOrder: ['box'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(0), reason: 'Negative clamped to 0');
    });

    test('Empty product order: no builds', () {
      final productInventory = {'box': 0};
      final materialInventory = {'cardboard': 100};
      final unlockedProducts = {'box'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: [],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(0), reason: 'Empty order, no builds');
    });

    test('Product with no recipe: skip it', () {
      final productInventory = {'box': 0, 'unknown': 0};
      final materialInventory = {'cardboard': 100};
      final unlockedProducts = {'box', 'unknown'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes, // No recipe for 'unknown'
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['unknown', 'box'], // Unknown first
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(4), reason: 'Skip unknown, build boxes');
      expect(productInventory['box'], equals(4));
      expect(productInventory['unknown'], equals(0));
    });

    test('No materials available: no builds', () {
      final productInventory = {'box': 0};
      final materialInventory = {'cardboard': 0};
      final unlockedProducts = {'box'};

      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['box'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(0), reason: 'No materials, no builds');
    });
  });

  group('Auto-Build Machine - Wrapping Behavior', () {
    final productRecipes = {
      'box': {'cardboard': 2},
      'wires': {'plastic': 1},
    };

    test('Wrap back to first product after processing all', () {
      final productInventory = {'box': 9, 'wires': 9};
      final materialInventory = {'cardboard': 100, 'plastic': 100};
      final unlockedProducts = {'box', 'wires'};

      // 4 pooled builds: box 9 -> 10 (1 build), wires 9 -> 10 (1 build), wrap: box at cap, wires at cap, 2 remaining unused
      final result = performAutoBuildTick(
        productInventory: productInventory,
        materialInventory: materialInventory,
        productRecipes: productRecipes,
        unlockedProducts: unlockedProducts,
        queuedProductCounts: {},
        machinesEnabled: 2,
        buildsPerMachinePerTick: 2,
        productOrder: ['box', 'wires'],
        productCap: 10,
      );

      expect(result.itemsBuilt, equals(2), reason: 'Build 1 box + 1 wire, then both at cap');
      expect(productInventory['box'], equals(10));
      expect(productInventory['wires'], equals(10));
    });
  });
}

