import 'dart:io';import 'package:flutter_test/flutter_test.dart';

import 'package:game1/services/production_game_service.dart';

import 'package:flutter_test/flutter_test.dart';import 'package:game1/services/game_persistence_service.dart';

import 'package:game1/services/production_game_service.dart';import 'package:game1/models/game_state.dart';

import 'package:game1/services/game_persistence_service.dart';import 'package:game1/models/game_data.dart';

import 'package:game1/models/game_data.dart';import 'package:game1/constants/game_constants.dart';

import 'package:game1/constants/game_constants.dart';import 'dart:math' as math;

import 'package:sqflite/sqflite.dart' as sqflite;

import 'dart:math' as math;void main() {

  group('Build Speed Multiplier Tests (v1.5.0)', () {

void main() {    late ProductionGameService gameService;

  group('Build Speed Multiplier Tests (v1.5.0)', () {    late GamePersistenceService persistenceService;

    late ProductionGameService gameService;

    late String testDbName;    setUp(() async {

      persistenceService = GamePersistenceService();

    setUp(() {      await persistenceService.initDatabase();

      testDbName = 'test_db_build_speed_${DateTime.now().microsecondsSinceEpoch}.db';      gameService = ProductionGameService(persistenceService);

      GamePersistenceService.initializeDatabaseFactory(      await gameService.initGameState();

        testDatabaseName: testDbName,    });

      );

      gameService = ProductionGameService();    tearDown(() async {

    });      await persistenceService.close();

    });

    tearDown() async {

      await gameService.dispose();    test('getAdjustedProductionTime - no machines returns base time', () {

      final dbPath = await sqflite.getDatabasesPath();      // Setup: basicParts product with 0 machines

      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);      const productId = 'basic_circuit';

      await sqflite.databaseFactory.deleteDatabase(fullPath);      final product = GameData.products.firstWhere((p) => p.id == productId);

    });      final baseTime = product.productionTimeSeconds;



    test('getAdjustedProductionTime - no machines returns base time', () {      // Execute

      // Setup: basicParts product with 0 machines      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      const productId = 'basic_circuit';

      final product = GameData.products.firstWhere((p) => p.id == productId);      // Verify

      final baseTime = product.productionTimeSeconds;      expect(adjustedTime, equals(baseTime),

          reason: 'With 0 machines, time should be unchanged');

      // Execute    });

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

    test('getAdjustedProductionTime - 1 machine gives 1.2x speed', () {

      // Verify      // Setup: 1 basicParts machine

      expect(adjustedTime, equals(baseTime),      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;

          reason: 'With 0 machines, time should be unchanged');      

    });      const productId = 'basic_circuit';

      final product = GameData.products.firstWhere((p) => p.id == productId);

    test('getAdjustedProductionTime - 1 machine gives 1.1x speed', () {      final baseTime = product.productionTimeSeconds;

      // Setup: 1 basicParts machine

      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;      // Execute

            final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      const productId = 'basic_circuit';      

      final product = GameData.products.firstWhere((p) => p.id == productId);      // Verify: time should be baseTime / 1.2

      final baseTime = product.productionTimeSeconds;      final expectedTime = baseTime / 1.2;

      expect(adjustedTime, closeTo(expectedTime, 0.01),

      // Execute          reason: '1 machine should give 1.2x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);    });

      

      // Verify: time should be baseTime / 1.1    test('getAdjustedProductionTime - 2 machines give 1.44x speed', () {

      final expectedTime = baseTime / 1.1;      // Setup: 2 basicParts machines

      expect(adjustedTime, closeTo(expectedTime, 0.01),      gameService.state.autoBuildMachinesOwned['basicParts'] = 2;

          reason: '1 machine should give 1.1x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');      

    });      const productId = 'basic_circuit';

      final product = GameData.products.firstWhere((p) => p.id == productId);

    test('getAdjustedProductionTime - 2 machines give 1.21x speed', () {      final baseTime = product.productionTimeSeconds;

      // Setup: 2 basicParts machines

      gameService.state.autoBuildMachinesOwned['basicParts'] = 2;      // Execute

            final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      const productId = 'basic_circuit';      

      final product = GameData.products.firstWhere((p) => p.id == productId);      // Verify: time should be baseTime / (1.2^2) = baseTime / 1.44

      final baseTime = product.productionTimeSeconds;      final expectedMultiplier = math.pow(1.2, 2);

      final expectedTime = baseTime / expectedMultiplier;

      // Execute      expect(adjustedTime, closeTo(expectedTime, 0.01),

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);          reason: '2 machines should give 1.44x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');

          });

      // Verify: time should be baseTime / (1.1^2) = baseTime / 1.21

      final expectedMultiplier = math.pow(1.1, 2);    test('getAdjustedProductionTime - 3 machines give 1.728x speed', () {

      final expectedTime = baseTime / expectedMultiplier;      // Setup: 3 intermediate machines

      expect(adjustedTime, closeTo(expectedTime, 0.01),      gameService.state.autoBuildMachinesOwned['intermediate'] = 3;

          reason: '2 machines should give 1.21x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');      

    });      const productId = 'smartphones';

      final product = GameData.products.firstWhere((p) => p.id == productId);

    test('getAdjustedProductionTime - 3 machines give 1.331x speed', () {      final baseTime = product.productionTimeSeconds;

      // Setup: 3 intermediate machines

      gameService.state.autoBuildMachinesOwned['intermediate'] = 3;      // Execute

            final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      const productId = 'smartphones';      

      final product = GameData.products.firstWhere((p) => p.id == productId);      // Verify: time should be baseTime / (1.2^3) = baseTime / 1.728

      final baseTime = product.productionTimeSeconds;      final expectedMultiplier = math.pow(1.2, 3);

      final expectedTime = baseTime / expectedMultiplier;

      // Execute      expect(adjustedTime, closeTo(expectedTime, 0.01),

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);          reason: '3 machines should give 1.728x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');

          });

      // Verify: time should be baseTime / (1.1^3) = baseTime / 1.331

      final expectedMultiplier = math.pow(1.1, 3);    test('getAdjustedProductionTime - different tiers use correct machines', () {

      final expectedTime = baseTime / expectedMultiplier;      // Setup: Different machine counts per tier

      expect(adjustedTime, closeTo(expectedTime, 0.01),      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;

          reason: '3 machines should give 1.331x speed (${baseTime}s → ${expectedTime.toStringAsFixed(1)}s)');      gameService.state.autoBuildMachinesOwned['intermediate'] = 2;

    });      gameService.state.autoBuildMachinesOwned['complex'] = 3;



    test('getAdjustedProductionTime - different tiers use correct machines', () {      // Test basicParts product

      // Setup: Different machine counts per tier      final circuitProduct = GameData.products.firstWhere((p) => p.id == 'basic_circuit');

      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;      final circuitTime = gameService.getAdjustedProductionTime('basic_circuit', circuitProduct.productionTimeSeconds);

      gameService.state.autoBuildMachinesOwned['intermediate'] = 2;      final expectedCircuitTime = circuitProduct.productionTimeSeconds / 1.2;

      gameService.state.autoBuildMachinesOwned['complex'] = 3;      expect(circuitTime, closeTo(expectedCircuitTime, 0.01),

          reason: 'basicParts product should use basicParts machine count');

      // Test basicParts product

      final circuitProduct = GameData.products.firstWhere((p) => p.id == 'basic_circuit');      // Test intermediate product

      final circuitTime = gameService.getAdjustedProductionTime('basic_circuit', circuitProduct.productionTimeSeconds);      final smartphoneProduct = GameData.products.firstWhere((p) => p.id == 'smartphones');

      final expectedCircuitTime = circuitProduct.productionTimeSeconds / 1.1;      final smartphoneTime = gameService.getAdjustedProductionTime('smartphones', smartphoneProduct.productionTimeSeconds);

      expect(circuitTime, closeTo(expectedCircuitTime, 0.01),      final expectedSmartphoneTime = smartphoneProduct.productionTimeSeconds / math.pow(1.2, 2);

          reason: 'basicParts product should use basicParts machine count');      expect(smartphoneTime, closeTo(expectedSmartphoneTime, 0.01),

          reason: 'intermediate product should use intermediate machine count');

      // Test intermediate product

      final smartphoneProduct = GameData.products.firstWhere((p) => p.id == 'smartphones');      // Test complex product

      final smartphoneTime = gameService.getAdjustedProductionTime('smartphones', smartphoneProduct.productionTimeSeconds);      final solarProduct = GameData.products.firstWhere((p) => p.id == 'solar_cells');

      final expectedSmartphoneTime = smartphoneProduct.productionTimeSeconds / math.pow(1.1, 2);      final solarTime = gameService.getAdjustedProductionTime('solar_cells', solarProduct.productionTimeSeconds);

      expect(smartphoneTime, closeTo(expectedSmartphoneTime, 0.01),      final expectedSolarTime = solarProduct.productionTimeSeconds / math.pow(1.2, 3);

          reason: 'intermediate product should use intermediate machine count');      expect(solarTime, closeTo(expectedSolarTime, 0.01),

          reason: 'complex product should use complex machine count');

      // Test complex product    });

      final solarProduct = GameData.products.firstWhere((p) => p.id == 'solar_cells');

      final solarTime = gameService.getAdjustedProductionTime('solar_cells', solarProduct.productionTimeSeconds);    test('getAdjustedProductionTime - material products not affected', () {

      final expectedSolarTime = solarProduct.productionTimeSeconds / math.pow(1.1, 3);      // Setup: Machines present

      expect(solarTime, closeTo(expectedSolarTime, 0.01),      gameService.state.autoBuildMachinesOwned['basicParts'] = 2;

          reason: 'complex product should use complex machine count');

    });      // Test material (not a product level)

      const materialId = 'copper_ore';

    test('getAdjustedProductionTime - material products not affected', () {      final material = GameData.materials.firstWhere((m) => m.id == materialId);

      // Setup: Machines present      

      gameService.state.autoBuildMachinesOwned['basicParts'] = 2;      // Materials don't have production time, but test the logic

      const baseTime = 10.0;

      // Test material (not a product level)      final adjustedTime = gameService.getAdjustedProductionTime(materialId, baseTime);

      const materialId = 'copper_ore';

      final material = GameData.materials.firstWhere((m) => m.id == materialId);      expect(adjustedTime, equals(baseTime),

                reason: 'Materials should not get speed bonus');

      // Materials don't have production time, but test the logic    });

      const baseTime = 10.0;

      final adjustedTime = gameService.getAdjustedProductionTime(materialId, baseTime);    test('Manual build uses adjusted time', () async {

      // Setup: 1 basicParts machine, sufficient materials

      expect(adjustedTime, equals(baseTime),      gameService.state.autoBuildMachinesOwned['basicParts'] = 1;

          reason: 'Materials should not get speed bonus');      gameService.state.materials['copper_wire'] = 100;

    });      gameService.state.materials['plastic'] = 100;



    test('Build speed scales correctly with multiple machines', () {      // Execute: Build a basic circuit

      const baseTime = 100.0;      final success = await gameService.buildProduct('basic_circuit', 1, false);

      

      // Test different machine counts      // Verify: Production task should have adjusted time

      final testCases = [      expect(success, isTrue);

        {'machines': 0, 'expectedMultiplier': 1.0},      expect(gameService.state.activeProductions.length, equals(1));

        {'machines': 1, 'expectedMultiplier': 1.1},      

        {'machines': 2, 'expectedMultiplier': 1.21},      final task = gameService.state.activeProductions.first;

        {'machines': 3, 'expectedMultiplier': 1.331},      final product = GameData.products.firstWhere((p) => p.id == 'basic_circuit');

        {'machines': 5, 'expectedMultiplier': math.pow(1.1, 5)},      final expectedTime = product.productionTimeSeconds / 1.2;

        {'machines': 10, 'expectedMultiplier': math.pow(1.1, 10)},      

      ];      expect(task.durationSeconds, closeTo(expectedTime, 0.01),

          reason: 'Manual build should use adjusted production time');

      for (final testCase in testCases) {    });

        final machineCount = testCase['machines'] as int;

        final expectedMultiplier = testCase['expectedMultiplier'] as double;    test('Build speed scales correctly with multiple machines', () {

              const baseTime = 100.0;

        gameService.state.autoBuildMachinesOwned['basicParts'] = machineCount;      

              // Test different machine counts

        final adjustedTime = gameService.getAdjustedProductionTime('basic_circuit', baseTime);      final testCases = [

        final expectedTime = baseTime / expectedMultiplier;        {'machines': 0, 'expectedMultiplier': 1.0},

                {'machines': 1, 'expectedMultiplier': 1.2},

        expect(adjustedTime, closeTo(expectedTime, 0.01),        {'machines': 2, 'expectedMultiplier': 1.44},

            reason: '$machineCount machines should give ${expectedMultiplier.toStringAsFixed(2)}x speed');        {'machines': 3, 'expectedMultiplier': 1.728},

      }        {'machines': 5, 'expectedMultiplier': math.pow(1.2, 5)},

    });        {'machines': 10, 'expectedMultiplier': math.pow(1.2, 10)},

      ];

    test('Production time enforces minimum of 1 second', () {

      // Setup: Create a scenario where multiplier would reduce time below 1 second      for (final testCase in testCases) {

      // With 1.1x per machine, after ~44 machines, a 5s base time would drop below 1s        final machineCount = testCase['machines'] as int;

      // (5 / 1.1^44 ≈ 0.67s)        final expectedMultiplier = testCase['expectedMultiplier'] as double;

      gameService.state.autoBuildMachinesOwned['basicParts'] = 50;        

              gameService.state.autoBuildMachinesOwned['basicParts'] = machineCount;

      const baseTime = 5.0; // Wires base time        

      final adjustedTime = gameService.getAdjustedProductionTime('wires', baseTime);        final adjustedTime = gameService.getAdjustedProductionTime('basic_circuit', baseTime);

              final expectedTime = baseTime / expectedMultiplier;

      expect(adjustedTime, greaterThanOrEqualTo(1.0),        

          reason: 'Production time should never go below 1 second');        expect(adjustedTime, closeTo(expectedTime, 0.01),

      expect(adjustedTime, equals(1.0),            reason: '$machineCount machines should give ${expectedMultiplier.toStringAsFixed(2)}x speed');

          reason: 'With many machines, time should be clamped to 1 second minimum');      }

    });    });



    test('Short base times also respect 1 second minimum', () {    test('Production time enforces minimum of 1 second', () {

      // Test with box (3s base time) and extreme machine count      // Setup: Create a scenario where multiplier would reduce time below 1 second

      gameService.state.autoBuildMachinesOwned['basicParts'] = 100;      // With 1.1x per machine, after ~44 machines, a 5s base time would drop below 1s

            // (5 / 1.1^44 ≈ 0.67s)

      const baseTime = 3.0; // Box base time      gameService.state.autoBuildMachinesOwned['basicParts'] = 50;

      final adjustedTime = gameService.getAdjustedProductionTime('box', baseTime);      

            const baseTime = 5.0; // Wires base time

      expect(adjustedTime, equals(1.0),      final adjustedTime = gameService.getAdjustedProductionTime('wires', baseTime);

          reason: 'Even 3s base time with 100 machines should floor at 1s');      

    });      expect(adjustedTime, greaterThanOrEqualTo(1.0),

  });          reason: 'Production time should never go below 1 second');

}      expect(adjustedTime, equals(1.0),

          reason: 'With many machines, time should be clamped to 1 second minimum');
    });

    test('Short base times also respect 1 second minimum', () {
      // Test with box (3s base time) and extreme machine count
      gameService.state.autoBuildMachinesOwned['basicParts'] = 100;
      
      const baseTime = 3.0; // Box base time
      final adjustedTime = gameService.getAdjustedProductionTime('box', baseTime);
      
      expect(adjustedTime, equals(1.0),
          reason: 'Even 3s base time with 100 machines should floor at 1s');
    });
  });
}

