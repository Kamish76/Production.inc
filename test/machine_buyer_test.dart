/// Unit tests for Auto-Buy Machine service (v1.5.0)
///
/// Tests the pooled-capacity buying algorithm with various scenarios:
/// - User's example scenario (2 machines, specific starting inventory)
/// - Edge cases (all resources at cap, no machines, single machine)
/// - Wrapping behavior (pooled buys > single resource deficit)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/machine_buyer.dart';

void main() {
  group('Auto-Buy Machine - Pooled Capacity Model', () {
    test('User example: 2 machines, metal=3, wood=10, plastic=5, cap=10', () {
      // Setup matching user's example
      final inventory = {
        'metal': 3,
        'wood': 10,
        'plastic': 5,
      };
      const machinesEnabled = 2;
      const buysPerMachinePerTick = 5;
      const resourceCap = 10;
      const resourceOrder = ['metal', 'wood', 'plastic'];

      // Tick 1: pooled buys = 2 * 5 = 10
      // metal deficit = 7, buy 7 -> metal = 10, pooled = 3
      // wood deficit = 0, skip
      // plastic deficit = 5, buy 3 -> plastic = 8, pooled = 0
      final purchased1 = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: machinesEnabled,
        buysPerMachinePerTick: buysPerMachinePerTick,
        resourceOrder: resourceOrder,
        resourceCap: resourceCap,
      );

      expect(purchased1, equals(10), reason: 'Tick 1 should purchase 10 items');
      expect(inventory['metal'], equals(10), reason: 'Metal should be at cap');
      expect(inventory['wood'], equals(10), reason: 'Wood should remain at cap');
      expect(inventory['plastic'], equals(8), reason: 'Plastic should be 8');

      // Tick 2: pooled buys = 10
      // metal deficit = 0, skip
      // wood deficit = 0, skip
      // plastic deficit = 2, buy 2 -> plastic = 10, pooled = 8
      // All resources at cap, remaining 8 unused
      final purchased2 = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: machinesEnabled,
        buysPerMachinePerTick: buysPerMachinePerTick,
        resourceOrder: resourceOrder,
        resourceCap: resourceCap,
      );

      expect(purchased2, equals(2), reason: 'Tick 2 should purchase 2 items');
      expect(inventory['metal'], equals(10), reason: 'Metal should remain at cap');
      expect(inventory['wood'], equals(10), reason: 'Wood should remain at cap');
      expect(inventory['plastic'], equals(10), reason: 'Plastic should be at cap');
    });

    test('All resources at cap: no purchases', () {
      final inventory = {
        'metal': 10,
        'wood': 10,
        'plastic': 10,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood', 'plastic'],
        resourceCap: 10,
      );

      expect(purchased, equals(0), reason: 'No purchases when all at cap');
      expect(inventory['metal'], equals(10));
      expect(inventory['wood'], equals(10));
      expect(inventory['plastic'], equals(10));
    });

    test('No machines enabled: no purchases', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 0,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      expect(purchased, equals(0), reason: 'No purchases with 0 machines');
      expect(inventory['metal'], equals(0));
      expect(inventory['wood'], equals(0));
    });

    test('Single machine: 5 buys/tick', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 1,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      // 1 machine * 5 buys = 5 total
      // metal deficit = 10, buy 5 -> metal = 5, pooled = 0
      expect(purchased, equals(5), reason: '1 machine should buy 5 items');
      expect(inventory['metal'], equals(5), reason: 'Metal should have 5');
      expect(inventory['wood'], equals(0), reason: 'Wood should remain 0 (no buys left)');
    });

    test('Multiple machines scale capacity: 3 machines = 15 buys', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
        'plastic': 0,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 3,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood', 'plastic'],
        resourceCap: 10,
      );

      // 3 machines * 5 = 15 buys
      // metal deficit = 10, buy 10 -> metal = 10, pooled = 5
      // wood deficit = 10, buy 5 -> wood = 5, pooled = 0
      expect(purchased, equals(15), reason: '3 machines should buy 15 items');
      expect(inventory['metal'], equals(10), reason: 'Metal should be at cap');
      expect(inventory['wood'], equals(5), reason: 'Wood should have 5');
      expect(inventory['plastic'], equals(0), reason: 'Plastic should remain 0');
    });

    test('Wrapping behavior: pooled buys wrap back to top of resourceOrder', () {
      final inventory = {
        'metal': 8, // deficit = 2
        'wood': 8, // deficit = 2
      };

      // 2 machines * 5 = 10 pooled buys
      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      // Pass 1: metal buy 2 -> metal=10, pooled=8; wood buy 2 -> wood=10, pooled=6
      // Pass 2: metal at cap, skip; wood at cap, skip
      // Remaining 6 buys unused (all at cap)
      expect(purchased, equals(4), reason: 'Should buy 4 items (2+2) then stop');
      expect(inventory['metal'], equals(10), reason: 'Metal at cap');
      expect(inventory['wood'], equals(10), reason: 'Wood at cap');
    });

    test('Resource not in inventory is initialized to 0', () {
      final inventory = <String, int>{};

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 1,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal'],
        resourceCap: 10,
      );

      expect(purchased, equals(5), reason: 'Should buy 5 for new resource');
      expect(inventory['metal'], equals(5), reason: 'Metal initialized and filled to 5');
    });

    test('Negative inputs clamped to zero', () {
      final inventory = {
        'metal': 0,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: -5, // Invalid, should clamp to 0
        buysPerMachinePerTick: -3, // Invalid, should clamp to 0
        resourceOrder: ['metal'],
        resourceCap: -10, // Invalid, should clamp to 0
      );

      expect(purchased, equals(0), reason: 'Negative inputs should result in no buys');
      expect(inventory['metal'], equals(0), reason: 'Inventory unchanged');
    });

    test('Empty resourceOrder: no purchases', () {
      final inventory = {
        'metal': 0,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: [], // Empty order
        resourceCap: 10,
      );

      expect(purchased, equals(0), reason: 'Empty resourceOrder should buy nothing');
      expect(inventory['metal'], equals(0));
    });

    test('Large machine count: 10 machines = 50 buys/tick', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
      };

      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 10,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      // 10 machines * 5 = 50 buys
      // metal deficit = 10, buy 10 -> metal = 10, pooled = 40
      // wood deficit = 10, buy 10 -> wood = 10, pooled = 30
      // Pass 2: both at cap, remaining 30 unused
      expect(purchased, equals(20), reason: '10 machines should fill both resources');
      expect(inventory['metal'], equals(10));
      expect(inventory['wood'], equals(10));
    });

    test('Partial fill scenario: uneven deficits', () {
      final inventory = {
        'metal': 7, // deficit = 3
        'wood': 2, // deficit = 8
        'plastic': 9, // deficit = 1
      };

      // 2 machines * 5 = 10 pooled buys
      final purchased = performAutoBuyTick(
        inventory: inventory,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood', 'plastic'],
        resourceCap: 10,
      );

      // metal deficit=3, buy 3 -> metal=10, pooled=7
      // wood deficit=8, buy 7 -> wood=9, pooled=0
      expect(purchased, equals(10), reason: 'Should use all 10 pooled buys');
      expect(inventory['metal'], equals(10), reason: 'Metal at cap');
      expect(inventory['wood'], equals(9), reason: 'Wood partially filled');
      expect(inventory['plastic'], equals(9), reason: 'Plastic unchanged');
    });
  });
}
