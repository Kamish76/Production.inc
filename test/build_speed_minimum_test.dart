import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() {
  group('Build Speed Multiplier - Minimum Time Tests (v2.0 Modernized)', () {
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

    test('Production time respects baseline when no speed boosts active', () {
      const baseTime = 5.0;
      final adjustedTime = gameService.getAdjustedProductionTime('wires', baseTime);
      expect(adjustedTime, equals(baseTime));
    });

    test('Production time scales with Prestige Golden Shares speed multiplier', () {
      // 10 Golden Shares = +100% speed -> 2.0x multiplier
      gameService.devAddGoldenShares(10);
      expect(gameService.state.prestigeSpeedMultiplier, 2.0);

      const baseTime = 5.0;
      final adjustedTime = gameService.getAdjustedProductionTime('wires', baseTime);
      expect(adjustedTime, equals(2.5),
          reason: '5.0s / 2.0x = 2.5s');
    });

    test('Extreme speed multiplier respects lower clamp bound (0.1s minimum)', () {
      // 1000 Golden Shares = extreme multiplier
      gameService.devAddGoldenShares(1000);
      expect(gameService.state.prestigeSpeedMultiplier, greaterThan(10.0));

      const baseTime = 3.0;
      final adjustedTime = gameService.getAdjustedProductionTime('box', baseTime);
      expect(adjustedTime, greaterThanOrEqualTo(0.1),
          reason: 'Production time should never drop below safe minimum 0.1s');
    });
  });
}
