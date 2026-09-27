import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/production_game_service.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'package:game1/models/game_data.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void main() {
  group('Build Speed & Throughput Mechanics Tests (v2.0 Modernized)', () {
    late ProductionGameService gameService;
    late String testDbName;

    setUp(() {
      testDbName = 'test_db_build_speed_${DateTime.now().microsecondsSinceEpoch}.db';
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

    test('getAdjustedProductionTime - baseline returns product base time', () {
      const productId = 'wires';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      expect(adjustedTime, equals(baseTime),
          reason: 'Without active speed perks, adjusted time equals base time');
    });

    test('getAdjustedProductionTime - scales with Factory Overclocking', () {
      const productId = 'wires';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      // Engage Level 3 Overclock (1.40x multiplier)
      gameService.devSetTechLevel('factory_overclocking', 3);
      gameService.toggleOverclock(true);
      gameService.devSetMaintenanceWear(1.0);

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);
      expect(adjustedTime, closeTo(baseTime / 1.40, 0.01),
          reason: 'Overclock should accelerate craft duration by 1.40x');
    });

    test('getAdjustedProductionTime - scales with Prestige Golden Shares', () {
      const productId = 'box';
      final product = GameData.products.firstWhere((p) => p.id == productId);
      final baseTime = product.productionTimeSeconds;

      // 10 Golden Shares = 2.0x multiplier
      gameService.devAddGoldenShares(10);
      expect(gameService.state.prestigeSpeedMultiplier, 2.0);

      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);
      expect(adjustedTime, closeTo(baseTime / 2.0, 0.01),
          reason: 'Prestige multiplier should cut production time in half');
    });

    test('getAdjustedProductionTime - combines Overclock and Prestige multiplicatively', () {
      const productId = 'wires';
      const baseTime = 10.0;

      // Overclock 1.40x
      gameService.devSetTechLevel('factory_overclocking', 3);
      gameService.toggleOverclock(true);
      gameService.devSetMaintenanceWear(1.0);

      // Golden Shares 2.0x
      gameService.devAddGoldenShares(10);

      final totalMultiplier = 1.40 * 2.0; // 2.80x
      final adjustedTime = gameService.getAdjustedProductionTime(productId, baseTime);

      expect(adjustedTime, closeTo(baseTime / totalMultiplier, 0.01),
          reason: 'Combined multipliers should apply multiplicatively');
    });

    test('Auto-build batch throughput scales items built per tick rather than reducing duration', () {
      // In v2.0, auto-build machines produce batches based on autoBuildThroughputLevel
      expect(gameService.getAutoBuildThroughputLevel('basicParts'), equals(1));
      gameService.setAutoBuildThroughputLevel('basicParts', 2);
      expect(gameService.getAutoBuildThroughputLevel('basicParts'), equals(2));
      gameService.setAutoBuildThroughputLevel('basicParts', 5);
      expect(gameService.getAutoBuildThroughputLevel('basicParts'), equals(5));
    });
  });
}
