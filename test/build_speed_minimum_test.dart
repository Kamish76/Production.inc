import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() {
  group('Build Speed Multiplier - Minimum Time Tests', () {
    late ProductionGameService gameService;
    late String testDbName;

    setUp(() {
      testDbName = 'test_db_minimum_${DateTime.now().microsecondsSinceEpoch}.db';
      GamePersistenceService.initializeDatabaseFactory(
        testDatabaseName: testDbName,
      );
      gameService = ProductionGameService(testMode: true);
    });

    tearDown(() async {
      await gameService.dispose();
      final dbPath = await sqflite.getDatabasesPath();
      final fullPath = [dbPath, testDbName].join(Platform.pathSeparator);
      await sqflite.databaseFactory.deleteDatabase(fullPath);
    });

    test('Production time enforces minimum of 1 second', () {
      gameService.state.autoBuildMachinesOwned['basicParts'] = 50;
      
      const baseTime = 5.0;
      final adjustedTime = gameService.getAdjustedProductionTime('wires', baseTime);
      
      expect(adjustedTime, greaterThanOrEqualTo(1.0),
          reason: 'Production time should never go below 1 second');
      expect(adjustedTime, equals(1.0),
          reason: 'With many machines, time should be clamped to 1 second minimum');
    });

    test('Short base times also respect 1 second minimum', () {
      gameService.state.autoBuildMachinesOwned['basicParts'] = 100;
      
      const baseTime = 3.0;
      final adjustedTime = gameService.getAdjustedProductionTime('box', baseTime);
      
      expect(adjustedTime, equals(1.0),
          reason: 'Even 3s base time with 100 machines should floor at 1s');
    });

    test('Normal machine counts do not hit minimum', () {
      gameService.state.autoBuildMachinesOwned['basicParts'] = 5;
      
      const baseTime = 5.0;
      final adjustedTime = gameService.getAdjustedProductionTime('wires', baseTime);
      
      expect(adjustedTime, greaterThan(1.0),
          reason: 'With reasonable machine counts, time should still be above 1s');
      expect(adjustedTime, lessThan(baseTime),
          reason: 'Time should still be reduced by machines');
    });
  });
}
