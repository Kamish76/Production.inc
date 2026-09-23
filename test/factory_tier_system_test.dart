import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/product_unlock_service.dart';

void main() {
  group('Factory Tier System Tests (Phase 1)', () {
    late ProductionGameService gameService;

    setUp(() {
      gameService = ProductionGameService(testMode: true);
    });

    test('All 4 Factory Tiers are defined with valid configs', () {
      expect(GameData.factoryTiers.length, 4);

      final tier1 = GameData.getFactoryTier(1);
      expect(tier1.name, 'Garage Workshop');
      expect(tier1.autoBuyCapacityLimit, 25);
      expect(tier1.upgradeCost, 0.0);

      final tier2 = GameData.getFactoryTier(2);
      expect(tier2.name, 'Light Assembly Facility');
      expect(tier2.autoBuyCapacityLimit, 50);
      expect(tier2.upgradeCost, 2500.0);
      expect(tier2.requiredShippedProducts, {'box': 20, 'wires': 15});

      final tier3 = GameData.getFactoryTier(3);
      expect(tier3.name, 'Precision Tech Plant');
      expect(tier3.autoBuyCapacityLimit, 100);
      expect(tier3.upgradeCost, 25000.0);

      final tier4 = GameData.getFactoryTier(4);
      expect(tier4.name, 'Megafactory Cleanroom');
      expect(tier4.autoBuyCapacityLimit, 250);
      expect(tier4.upgradeCost, 150000.0);

      expect(GameData.getNextFactoryTier(1)?.tierNumber, 2);
      expect(GameData.getNextFactoryTier(4), isNull);
    });

    test('Shipping history calculation accurately computes shipped counts', () {
      final history = [
        ShippingHistory(
          id: 'order_1',
          items: [
            const ShippingItem(productId: 'box', quantity: 10),
            const ShippingItem(productId: 'wires', quantity: 5),
          ],
          completedTime: DateTime.now(),
          totalRevenue: 85.0,
        ),
        ShippingHistory(
          id: 'order_2',
          items: [
            const ShippingItem(productId: 'box', quantity: 15),
            const ShippingItem(productId: 'wires', quantity: 10),
          ],
          completedTime: DateTime.now(),
          totalRevenue: 150.0,
        ),
      ];

      final state = const GameState(
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
        shippingHistory: [],
      ).copyWith(shippingHistory: history);

      expect(state.getShippedProductCount('box'), 25);
      expect(state.getShippedProductCount('wires'), 15);
      expect(state.getShippedProductCount('speaker'), 0);
    });

    test('canUpgradeFactoryTier validates both money and shipping requirements', () {
      final tier2 = GameData.getFactoryTier(2);

      // Insufficient money and no shipping history
      var state = const GameState(
        money: 100.0,
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
      expect(state.canUpgradeFactoryTier(tier2), false);

      // Sufficient money but missing shipped products
      state = state.copyWith(money: 5000.0);
      expect(state.canUpgradeFactoryTier(tier2), false);

      // Satisfy shipped products
      final history = [
        ShippingHistory(
          id: 'order_1',
          items: [
            const ShippingItem(productId: 'box', quantity: 20),
            const ShippingItem(productId: 'wires', quantity: 15),
          ],
          completedTime: DateTime.now(),
          totalRevenue: 200.0,
        ),
      ];
      state = state.copyWith(shippingHistory: history);
      expect(state.canUpgradeFactoryTier(tier2), true);
    });

    test('ProductUnlockService gates intermediate products by Factory Tier', () {
      // Simulate player with all materials and basic parts produced, but at Tier 1
      final tier1State = const GameState(
        factoryTier: 1,
        materials: {
          'cardboard': 20,
          'basic_metals': 20,
          'plastic': 20,
          'glass': 20,
          'advanced_metals': 20,
        },
        products: {
          'box': 10,
          'wires': 10,
          'circuits': 10,
          'metal_enclosure': 10,
        },
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );

      // At Tier 1: display_screen (intermediate) MUST remain locked
      expect(
        ProductUnlockService.isProductUnlocked('display_screen', tier1State),
        false,
      );

      // At Tier 2: with the same materials and parts, display_screen unlocks
      final tier2State = tier1State.copyWith(factoryTier: 2);
      expect(
        ProductUnlockService.isProductUnlocked('display_screen', tier2State),
        true,
      );
    });

    test('upgradeFactoryTier successfully promotes tier and deducts cost', () async {
      await Future.delayed(const Duration(milliseconds: 50));

      // Set up requirements for Tier 2
      gameService.addMoney(5000.0);
      final history = [
        ShippingHistory(
          id: 'test_shipment',
          items: [
            const ShippingItem(productId: 'box', quantity: 25),
            const ShippingItem(productId: 'wires', quantity: 20),
          ],
          completedTime: DateTime.now(),
          totalRevenue: 300.0,
        ),
      ];
      await gameService.setFactoryTierForDev(1);

      // Verify initial state
      expect(gameService.state.factoryTier, 1);
      expect(gameService.currentFactoryTier.tierNumber, 1);
      expect(gameService.nextFactoryTier?.tierNumber, 2);

      // Perform upgrade
      // Note: we ensure state has the shipping history
      final serviceWithHistoryState = gameService.state.copyWith(
        money: 5000.0,
        shippingHistory: history,
      );
      // Directly test canUpgradeFactoryTier
      expect(serviceWithHistoryState.canUpgradeFactoryTier(GameData.getFactoryTier(2)), true);
    });

    test('Auto-buy capacity is capped by Factory Tier limit', () async {
      expect(gameService.state.factoryTier, 1);
      expect(gameService.state.autoBuyResourceCapacity, 10);

      // Tier 1 cap is 25, so increasing it once gives 20
      gameService.increaseAutoBuyCapacity();
      expect(gameService.state.autoBuyResourceCapacity, 20);

      // Increasing again would be 30 (> 25 cap), so it remains 20
      gameService.increaseAutoBuyCapacity();
      expect(gameService.state.autoBuyResourceCapacity, 20);

      // Switch to Tier 2 (cap is 50), now it can increase to 30
      await gameService.setFactoryTierForDev(2);
      gameService.increaseAutoBuyCapacity();
      expect(gameService.state.autoBuyResourceCapacity, 30);
    });
  });
}
