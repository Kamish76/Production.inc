import 'package:flutter_test/flutter_test.dart';
import 'package:game1/models/game_models.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/constants/game_constants.dart';
import 'package:game1/services/product_unlock_service.dart';

void main() {
  setUp(() {
    ProductUnlockService.clearCache();
  });

  group('Phase 3: New Industry Branches Catalog Integrity', () {
    test('All 11 Phase 3 products exist in GameData.products', () {
      final expectedProducts = [
        // Robotics Branch
        'silicon_wafer',
        'copper_coils',
        'servo_motor',
        'microcontroller',
        'chassis_alloy',
        'cleaning_drone',
        'robotic_arm',
        // Clean Energy Branch
        'inverter_unit',
        'storage_cell',
        'home_powerwall',
        'wind_turbine_generator',
      ];

      for (final id in expectedProducts) {
        final product = GameData.getProduct(id);
        expect(product, isNotNull, reason: 'Product $id should exist in GameData');
      }
    });

    test('Phase 3 retail products match roadmap specifications and prices', () {
      final drone = GameData.getProduct('cleaning_drone')!;
      expect(drone.sellPrice, equals(480.0));
      expect(drone.levelId, equals(ProductLevel.retail));
      expect(drone.industryBranch, equals(IndustryBranch.robotics));

      final arm = GameData.getProduct('robotic_arm')!;
      expect(arm.sellPrice, equals(1250.0));
      expect(arm.levelId, equals(ProductLevel.retail));
      expect(arm.industryBranch, equals(IndustryBranch.robotics));

      final powerwall = GameData.getProduct('home_powerwall')!;
      expect(powerwall.sellPrice, equals(850.0));
      expect(powerwall.levelId, equals(ProductLevel.retail));
      expect(powerwall.industryBranch, equals(IndustryBranch.cleanEnergy));

      final turbine = GameData.getProduct('wind_turbine_generator')!;
      expect(turbine.sellPrice, equals(2100.0));
      expect(turbine.levelId, equals(ProductLevel.retail));
      expect(turbine.industryBranch, equals(IndustryBranch.cleanEnergy));
    });

    test('All Phase 3 product recipes use valid materials or products', () {
      final allValidIds = {
        ...GameData.materials.map((m) => m.id),
        ...GameData.products.map((p) => p.id),
      };

      final phase3ProductIds = [
        'silicon_wafer',
        'copper_coils',
        'servo_motor',
        'microcontroller',
        'chassis_alloy',
        'cleaning_drone',
        'robotic_arm',
        'inverter_unit',
        'storage_cell',
        'home_powerwall',
        'wind_turbine_generator',
      ];

      for (final id in phase3ProductIds) {
        final product = GameData.getProduct(id)!;
        expect(product.requiredMaterials, isNotEmpty,
            reason: '$id recipe must not be empty');

        for (final materialId in product.requiredMaterials.keys) {
          expect(allValidIds.contains(materialId), isTrue,
              reason:
                  'Ingredient $materialId in $id recipe must exist in materials or products');
        }
      }
    });

    test('IndustryBranch filtering helper returns matching products', () {
      final roboticsProducts =
          GameData.getProductsByBranch(IndustryBranch.robotics);
      final cleanEnergyProducts =
          GameData.getProductsByBranch(IndustryBranch.cleanEnergy);
      final consumerTechProducts =
          GameData.getProductsByBranch(IndustryBranch.consumerTech);

      expect(roboticsProducts.any((p) => p.id == 'cleaning_drone'), isTrue);
      expect(roboticsProducts.any((p) => p.id == 'robotic_arm'), isTrue);
      expect(roboticsProducts.any((p) => p.id == 'servo_motor'), isTrue);

      expect(cleanEnergyProducts.any((p) => p.id == 'home_powerwall'), isTrue);
      expect(cleanEnergyProducts.any((p) => p.id == 'wind_turbine_generator'),
          isTrue);
      expect(cleanEnergyProducts.any((p) => p.id == 'solar_panel'), isTrue);

      expect(consumerTechProducts.any((p) => p.id == 'smartphone'), isTrue);
      expect(consumerTechProducts.any((p) => p.id == 'camera'), isTrue);
    });
  });

  group('Phase 3: Progressive Unlock Logic & Tier Gating', () {
    test('Basic parts: silicon_wafer and copper_coils unlock on material thresholds', () {
      // Starting state: no materials
      final emptyState = const GameState(
        factoryTier: 1,
        materials: {},
        products: {},
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
      expect(ProductUnlockService.isProductUnlocked('silicon_wafer', emptyState),
          isFalse);
      expect(ProductUnlockService.isProductUnlocked('copper_coils', emptyState),
          isFalse);

      // Sufficient materials for silicon_wafer: glass >= 2, advanced_metals >= 1
      final waferState = emptyState.copyWith(
        materials: {'glass': 2, 'advanced_metals': 1},
      );
      expect(ProductUnlockService.isProductUnlocked('silicon_wafer', waferState),
          isTrue);

      // copper_coils requires basic_metals >= 2 and wires produced
      final partialCopperState = emptyState.copyWith(
        materials: {'basic_metals': 2},
      );
      expect(ProductUnlockService.isProductUnlocked('copper_coils', partialCopperState),
          isFalse);

      final fullCopperState = emptyState.copyWith(
        materials: {'basic_metals': 2},
        products: {'wires': 1},
      );
      expect(ProductUnlockService.isProductUnlocked('copper_coils', fullCopperState),
          isTrue);
    });

    test('Intermediate parts: servo_motor and microcontroller require component production', () {
      // In Tier 1: intermediate parts are not allowed
      final tier1State = const GameState(
        factoryTier: 1,
        materials: {},
        products: {
          'copper_coils': 5,
          'gears': 5,
          'circuits': 5,
        },
        autoBuildMachinesOwned: {},
        autoBuildEnabled: {},
        lastAutoBuildTick: {},
        autoBuildProductCapacity: {},
      );
      expect(ProductUnlockService.isProductUnlocked('servo_motor', tier1State),
          isFalse,
          reason: 'Tier 1 should not unlock intermediate parts');

      // In Tier 2: intermediate parts unlock once required basic parts have been produced
      final tier2StateIncomplete = tier1State.copyWith(
        factoryTier: 2,
        products: {
          'copper_coils': 5,
          // missing gears and circuits
        },
      );
      expect(ProductUnlockService.isProductUnlocked('servo_motor', tier2StateIncomplete),
          isFalse);

      final tier2StateComplete = tier1State.copyWith(
        factoryTier: 2,
        products: {
          'copper_coils': 2,
          'gears': 2,
          'circuits': 1,
        },
      );
      expect(ProductUnlockService.isProductUnlocked('servo_motor', tier2StateComplete),
          isTrue);

      // Microcontroller requires silicon_wafer, circuits, and wires
      final microcontrollerState = tier1State.copyWith(
        factoryTier: 2,
        products: {
          'silicon_wafer': 1,
          'circuits': 2,
          'wires': 2,
        },
      );
      expect(ProductUnlockService.isProductUnlocked('microcontroller', microcontrollerState),
          isTrue);
    });

    test('Retail products: Flagship tier gating is strictly enforced', () {
      final allComponentsProduced = {
        'copper_coils': 10,
        'inverter_unit': 10,
        'gear_mechanism': 10,
        'chassis_alloy': 10,
        'box': 10,
        'storage_cell': 10,
        'metal_enclosure': 10,
        'servo_motor': 10,
        'microcontroller': 10,
      };

      // wind_turbine_generator requires Tier 4 Megafactory Cleanroom
      final tier3State = GameState(
        factoryTier: 3,
        products: allComponentsProduced,
        autoBuildMachinesOwned: const {},
        autoBuildEnabled: const {},
        lastAutoBuildTick: const {},
        autoBuildProductCapacity: const {},
      );
      expect(
          ProductUnlockService.isProductUnlocked(
              'wind_turbine_generator', tier3State),
          isFalse,
          reason: 'Wind turbine requires Megafactory Cleanroom Tier 4');

      final tier4State = tier3State.copyWith(factoryTier: 4);
      expect(
          ProductUnlockService.isProductUnlocked(
              'wind_turbine_generator', tier4State),
          isTrue,
          reason: 'Wind turbine unlocks in Tier 4 once components produced');

      // robotic_arm and home_powerwall require Tier 3+
      final tier2State = tier3State.copyWith(factoryTier: 2);
      expect(
          ProductUnlockService.isProductUnlocked('robotic_arm', tier2State),
          isFalse,
          reason: 'Robotic Arm requires Precision Tech Plant Tier 3+');
      expect(
          ProductUnlockService.isProductUnlocked('home_powerwall', tier2State),
          isFalse,
          reason: 'Home Powerwall requires Precision Tech Plant Tier 3+');

      expect(
          ProductUnlockService.isProductUnlocked('robotic_arm', tier3State),
          isTrue);
      expect(
          ProductUnlockService.isProductUnlocked('home_powerwall', tier3State),
          isTrue);
    });
  });

  group('Phase 3: Automation & B2B Contracts Integration', () {
    test('AutoBuildConstants includes new basic and intermediate parts', () {
      final basicPartsOrder =
          AutoBuildConstants.productOrderByTier['basicParts']!;
      expect(basicPartsOrder.contains('copper_coils'), isTrue);
      expect(basicPartsOrder.contains('silicon_wafer'), isTrue);

      final intermediateOrder =
          AutoBuildConstants.productOrderByTier['intermediate']!;
      expect(intermediateOrder.contains('servo_motor'), isTrue);
      expect(intermediateOrder.contains('microcontroller'), isTrue);
      expect(intermediateOrder.contains('chassis_alloy'), isTrue);
      expect(intermediateOrder.contains('inverter_unit'), isTrue);
      expect(intermediateOrder.contains('storage_cell'), isTrue);
    });

    test('Corporate clients demand Phase 3 branch products', () {
      final solaria = GameData.getCorporateClient('solaria_energy')!;
      expect(solaria.demandedProductIds.contains('inverter_unit'), isTrue);
      expect(solaria.demandedProductIds.contains('storage_cell'), isTrue);
      expect(solaria.demandedProductIds.contains('home_powerwall'), isTrue);
      expect(solaria.demandedProductIds.contains('wind_turbine_generator'), isTrue);
      expect(solaria.demandedProductIds.contains('solar_cells'), isTrue);

      final nova = GameData.getCorporateClient('nova_robotics')!;
      expect(nova.demandedProductIds.contains('copper_coils'), isTrue);
      expect(nova.demandedProductIds.contains('servo_motor'), isTrue);
      expect(nova.demandedProductIds.contains('microcontroller'), isTrue);
      expect(nova.demandedProductIds.contains('chassis_alloy'), isTrue);
      expect(nova.demandedProductIds.contains('cleaning_drone'), isTrue);
      expect(nova.demandedProductIds.contains('robotic_arm'), isTrue);

      final apex = GameData.getCorporateClient('apex_telecom')!;
      expect(apex.demandedProductIds.contains('silicon_wafer'), isTrue);
      expect(apex.demandedProductIds.contains('microcontroller'), isTrue);
      expect(apex.demandedProductIds.contains('processor'), isTrue);
    });
  });
}
