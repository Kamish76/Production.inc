import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/models/game_state.dart';
import 'package:game1/models/game_data.dart';
import 'package:game1/constants/game_constants.dart';
import 'dart:math' as math;

void main() {
  group('Build Speed Multiplier Tests (v1.5.0)', () {
    late ProductionGameService gameService;
    late GamePersistenceService persistenceService;

    setUp(() async {
      persistenceService = GamePersistenceService();
      await persistenceService.initDatabase();
      gameService = ProductionGameService(persistenceService);
      await gameService.initGameState();
    });

    tearDown(() async {
      await persistenceService.close();
    });

    test('getAdjustedProductionTime - no machines returns base time', () {
      // Setup: basicParts product with 0 machines
      const productId = 'basic_circuit';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      // Execute
      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      // Verify
      expect(adjustedTime, equals(baseTime),
          reason: 'With 0 machines, time should be unchanged');
    });

    test('getAdjustedProductionTime - 1 machine gives 1.2x speed', () {
      // Setup: 1 basicParts machine
      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;
      
      const productId = 'basic_circuit';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      // Execute
      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);
      
      // Verify: time should be baseTime / 1.2
      final expectedTime = baseTime / 1.2;
      expect(adjustedTime, closeTo(expectedTime, 0.01),
          reason: '1 machine should give 1.2x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');
    });

    test('getAdjustedProductionTime - 2 machines give 1.44x speed', () {
      // Setup: 2 basicParts machines
      gameService.state.autoBuildMachinesOwned['basicParts'] = 2;
      
      const productId = 'basic_circuit';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      // Execute
      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);
      
      // Verify: time should be baseTime / (1.2^2) = baseTime / 1.44
      final expectedMultiplier = math.pow(1.2, 2);
      final expectedTime = baseTime / expectedMultiplier;
      expect(adjustedTime, closeTo(expectedTime, 0.01),
          reason: '2 machines should give 1.44x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');
    });

    test('getAdjustedProductionTime - 3 machines give 1.728x speed', () {
      // Setup: 3 intermediate machines
      gameService.state.autoBuildMachinesOwned['intermediate'] = 3;
      
      const productId = 'smartphones';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      // Execute
      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);
      
      // Verify: time should be baseTime / (1.2^3) = baseTime / 1.728
      final expectedMultiplier = math.pow(1.2, 3);
      final expectedTime = baseTime / expectedMultiplier;
      expect(adjustedTime, closeTo(expectedTime, 0.01),
          reason: '3 machines should give 1.728x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');
    });

    test('getAdjustedProductionTime - different tiers use correct machines', () {
      // Setup: Different machine counts per tier
      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;
      gameService.state.autoBuildMachinesOwned['intermediate'] = 2;
      gameService.state.autoBuildMachinesOwned['complex'] = 3;

      // Test basicParts product
      final circuitProduct = GameData.products.firstWhere((p) => p.id == 'basic_circuit');
      final circuitTime = gameService.getAdjustedProductionTime('basic_circuit', circuitProduct.productionTimeSeconds);
      final expectedCircuitTime = circuitProduct.productionTimeSeconds / 1.2;
      expect(circuitTime, closeTo(expectedCircuitTime, 0.01),
          reason: 'basicParts product should use basicParts machine count');

      // Test intermediate product
      final smartphoneProduct = GameData.products.firstWhere((p) => p.id == 'smartphones');
      final smartphoneTime = gameService.getAdjustedProductionTime('smartphones', smartphoneProduct.productionTimeSeconds);
      final expectedSmartphoneTime = smartphoneProduct.productionTimeSeconds / math.pow(1.2, 2);
      expect(smartphoneTime, closeTo(expectedSmartphoneTime, 0.01),
          reason: 'intermediate product should use intermediate machine count');

      // Test complex product
      final solarProduct = GameData.products.firstWhere((p) => p.id == 'solar_cells');
      final solarTime = gameService.getAdjustedProductionTime('solar_cells', solarProduct.productionTimeSeconds);
      final expectedSolarTime = solarProduct.productionTimeSeconds / math.pow(1.2, 3);
      expect(solarTime, closeTo(expectedSolarTime, 0.01),
          reason: 'complex product should use complex machine count');
    });

    test('getAdjustedProductionTime - material products not affected', () {
      // Setup: Machines present
      gameService.state.autoBuildMachinesOwned['basicParts'] = 2;

      // Test material (not a product level)
      const materialId = 'copper_ore';
      final material = GameData.materials.firstWhere((m) => m.id == materialId);
      
      // Materials don't have production time, but test the logic
      const baseTime = 10.0;
      final adjustedTime = gameService.getAdjustedProductionTime(materialId, baseTime);

      expect(adjustedTime, equals(baseTime),
          reason: 'Materials should not get speed bonus');
    });

    test('Manual build uses adjusted time', () async {
      // Setup: 1 basicParts machine, sufficient materials
      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;
      gameService.state.materials['copper_wire'] = 100;
      gameService.state.materials['plastic'] = 100;

      // Execute: Build a basic circuit
      final success = await gameService.buildProduct('basic_circuit', 1, false);

      // Verify: Production task should have adjusted time
      expect(success, isTrue);
      expect(gameService.state.activeProductions.length, equals(1));
      
      final task = gameService.state.activeProductions.first;
      final product = GameData.products.firstWhere((p) => p.id == 'basic_circuit');
      final expectedTime = product.productionTimeSeconds / 1.2;
      
      expect(task.durationSeconds, closeTo(expectedTime, 0.01),
          reason: 'Manual build should use adjusted production time');
    });

    test('Build speed scales correctly with multiple machines', () {
      const baseTime = 100.0;
      
      // Test different machine counts
      final testCases = [
        {'machines': 0, 'expectedMultiplier': 1.0},
        {'machines': 1, 'expectedMultiplier': 1.2},
        {'machines': 2, 'expectedMultiplier': 1.44},
        {'machines': 3, 'expectedMultiplier': 1.728},
        {'machines': 5, 'expectedMultiplier': math.pow(1.2, 5)},
        {'machines': 10, 'expectedMultiplier': math.pow(1.2, 10)},
      ];

      for (final testCase in testCases) {
        final machineCount = testCase['machines'] as int;
        final expectedMultiplier = testCase['expectedMultiplier'] as double;
        
        gameService.state.autoBuildMachinesOwned['basicParts'] = machineCount;
        
        final adjustedTime = gameService.getAdjustedProductionTime('basic_circuit', baseTime);
        final expectedTime = baseTime / expectedMultiplier;
        
        expect(adjustedTime, closeTo(expectedTime, 0.01),
            reason: '$machineCount machines should give ${expectedMultiplier.toStringAsFixed(2)}x speed');
      }
    });
  });
}
