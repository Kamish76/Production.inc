/// Unit tests for Auto-Buy Machine service (v1.5.0)
///
/// Tests the pooled-capacity buying algorithm with various scenarios:
/// - User's example scenario (2 machines, specific starting inventory)
/// - Money constraints (insufficient funds, running out mid-tick)
/// - Edge cases (all resources at cap, no machines, single machine)
/// - Wrapping behavior (pooled buys > single resource deficit)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/machine_buyer.dart';

void main() {
  // Test material prices (matching game data approximately)
  const materialPrices = {
    'metal': 3.0,
    'wood': 2.0,
    'plastic': 2.0,
    'glass': 5.0,
    'cardboard': 1.0,
  };

  group('Auto-Buy Machine - Pooled Capacity Model with Money', () {
    test('User example: 2 machines, metal=3, wood=10, plastic=5, cap=10, sufficient money', () {
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
      
      // Need money for: 7 metal (\\\$21) + 3 plastic (\\\$6) = \\\$27
      const startMoney = 100.0;

      // Tick 1: pooled buys = 2 * 5 = 10
      // In the full-batch model, metal is below cap (3 < 10), so machines buy full batch:
      // min(pooled 10, affordable 33) = 10 metal for $30 -> metal = 13, pooled = 0
      final result1 = performAutoBuyTick(
        inventory: inventory,
        currentMoney: startMoney,
        materialPrices: materialPrices,
        machinesEnabled: machinesEnabled,
        buysPerMachinePerTick: buysPerMachinePerTick,
        resourceOrder: resourceOrder,
        resourceCap: resourceCap,
      );

      expect(result1.itemsPurchased, equals(10), reason: 'Tick 1 should purchase 10 items');
      expect(result1.moneySpent, equals(30.0), reason: 'Tick 1 should spend \$30 for 10 metal');
      expect(inventory['metal'], equals(13), reason: 'Metal should be 13 (full batch)');
      expect(inventory['wood'], equals(10), reason: 'Wood should remain at cap');
      expect(inventory['plastic'], equals(5), reason: 'Plastic should remain 5');

      // Tick 2: pooled buys = 10, money = \$70
      // metal is 13 (>= cap 10), skip
      // wood is 10 (>= cap 10), skip
      // plastic is 5 (< cap 10), buy full batch 10 for \$20 -> plastic = 15, pooled = 0
      final result2 = performAutoBuyTick(
        inventory: inventory,
        currentMoney: startMoney - result1.moneySpent,
        materialPrices: materialPrices,
        machinesEnabled: machinesEnabled,
        buysPerMachinePerTick: buysPerMachinePerTick,
        resourceOrder: resourceOrder,
        resourceCap: resourceCap,
      );

      expect(result2.itemsPurchased, equals(10), reason: 'Tick 2 should purchase 10 items');
      expect(result2.moneySpent, equals(20.0), reason: 'Tick 2 should spend \$20');
      expect(inventory['metal'], equals(13), reason: 'Metal should remain at 13');
      expect(inventory['wood'], equals(10), reason: 'Wood should remain at cap');
      expect(inventory['plastic'], equals(15), reason: 'Plastic should be 15 (full batch)');
    });

    test('Insufficient money: stops buying when money runs out', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
      };

      // Only \\\$10, can buy 3 metal (\\\$9) but not a 4th (\\\$12 would exceed)
      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 10.0,
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(3), reason: 'Should buy 3 metal with \\\$10');
      expect(result.moneySpent, equals(9.0), reason: 'Should spend \\\$9');
      expect(inventory['metal'], equals(3), reason: 'Metal should have 3');
      expect(inventory['wood'], equals(0), reason: 'Wood should remain 0 (no money left)');
    });

    test('No money: no purchases', () {
      final inventory = {
        'metal': 0,
      };

      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 0.0,
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(0), reason: 'No money, no purchases');
      expect(result.moneySpent, equals(0.0), reason: 'No money spent');
      expect(inventory['metal'], equals(0));
    });

    test('All resources at cap: no purchases', () {
      final inventory = {
        'metal': 10,
        'wood': 10,
        'plastic': 10,
      };

      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood', 'plastic'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(0), reason: 'No purchases when all at cap');
      expect(result.moneySpent, equals(0.0));
      expect(inventory['metal'], equals(10));
      expect(inventory['wood'], equals(10));
      expect(inventory['plastic'], equals(10));
    });

    test('No machines enabled: no purchases', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
      };

      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 0,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(0), reason: 'No purchases with 0 machines');
      expect(result.moneySpent, equals(0.0));
      expect(inventory['metal'], equals(0));
      expect(inventory['wood'], equals(0));
    });

    test('Single machine: 5 buys/tick with money constraint', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
      };

      // 1 machine * 5 buys = 5 total
      // metal deficit = 10, money allows 5 metal (\\\$15)
      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 1,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(5), reason: '1 machine should buy 5 items');
      expect(result.moneySpent, equals(15.0), reason: '5 metal at \\\$3 each = \\\$15');
      expect(inventory['metal'], equals(5), reason: 'Metal should have 5');
      expect(inventory['wood'], equals(0), reason: 'Wood should remain 0 (no buys left)');
    });

    test('Multiple machines scale capacity: 3 machines = 15 buys with money', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
        'plastic': 0,
      };

      // 3 machines * 5 = 15 buys
      // 3 machines * 5 = 15 buys
      // In full-batch model: metal is 0 (< cap 10), so machines buy min(15, 33) = 15 metal for $45
      // metal = 15, pooled = 0
      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 3,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood', 'plastic'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(15), reason: '3 machines should buy 15 items');
      expect(result.moneySpent, equals(45.0), reason: '15 metal (\$45)');
      expect(inventory['metal'], equals(15), reason: 'Metal should be 15');
      expect(inventory['wood'], equals(0), reason: 'Wood should have 0');
      expect(inventory['plastic'], equals(0), reason: 'Plastic should remain 0');
    });

    test('Full batch behavior: buys full pooled capacity for first deficit resource', () {
      final inventory = {
        'metal': 8, // below cap 10
        'wood': 8,  // below cap 10
      };

      // 2 machines * 5 = 10 pooled buys
      // Metal is below cap (8 < 10), so full pooled batch of 10 is bought for metal:
      // metal = 8 + 10 = 18, cost = $30. pooled buys = 0.
      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(10), reason: 'Should buy full batch of 10 items');
      expect(result.moneySpent, equals(30.0), reason: '10 metal at \$3 = \$30');
      expect(inventory['metal'], equals(18), reason: 'Metal exceeds cap due to full batch');
      expect(inventory['wood'], equals(8), reason: 'Wood not reached in tick 1');
    });

    test('Resource not in inventory is initialized to 0', () {
      final inventory = <String, int>{};

      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 1,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(5), reason: 'Should buy 5 for new resource');
      expect(result.moneySpent, equals(15.0), reason: '5 metal at \\\$3 = \\\$15');
      expect(inventory['metal'], equals(5), reason: 'Metal initialized and filled to 5');
    });

    test('Negative money clamped to zero: no purchases', () {
      final inventory = {
        'metal': 0,
      };

      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: -100.0, // Invalid, should clamp to 0
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(0), reason: 'Negative money should result in no buys');
      expect(result.moneySpent, equals(0.0));
      expect(inventory['metal'], equals(0), reason: 'Inventory unchanged');
    });

    test('Empty resourceOrder: no purchases', () {
      final inventory = {
        'metal': 0,
      };

      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 100.0,
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: [], // Empty order
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(0), reason: 'Empty resourceOrder should buy nothing');
      expect(result.moneySpent, equals(0.0));
      expect(inventory['metal'], equals(0));
    });

    test('Mixed prices: expensive resource stops early when money low', () {
      final inventory = {
        'glass': 0,   // \\\$5 each
        'cardboard': 0, // \\\$1 each
      };

      // Only \\\$12: can buy 2 glass (\\\$10), leaving \\\$2 for 2 cardboard
      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 12.0,
        materialPrices: materialPrices,
        machinesEnabled: 2,
        buysPerMachinePerTick: 5,
        resourceOrder: ['glass', 'cardboard'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(4), reason: 'Should buy 2 glass + 2 cardboard = 4');
      expect(result.moneySpent, equals(12.0), reason: '2 glass (\\\$10) + 2 cardboard (\\\$2) = \\\$12');
      expect(inventory['glass'], equals(2));
      expect(inventory['cardboard'], equals(2));
    });

    test('Partial fill with money constraint: stops mid-order', () {
      final inventory = {
        'metal': 0,
        'wood': 0,
        'plastic': 0,
      };

      // Only \\\$20: enough for 6 metal (\\\$18), then \\\$2 left = 1 wood (\\\$2), no plastic
      final result = performAutoBuyTick(
        inventory: inventory,
        currentMoney: 20.0,
        materialPrices: materialPrices,
        machinesEnabled: 3,
        buysPerMachinePerTick: 5,
        resourceOrder: ['metal', 'wood', 'plastic'],
        resourceCap: 10,
      );

      expect(result.itemsPurchased, equals(7), reason: 'Should buy 6 metal + 1 wood = 7');
      expect(result.moneySpent, equals(20.0), reason: '6 metal (\\\$18) + 1 wood (\\\$2) = \\\$20');
      expect(inventory['metal'], equals(6));
      expect(inventory['wood'], equals(1));
      expect(inventory['plastic'], equals(0));
    });
  });
}

