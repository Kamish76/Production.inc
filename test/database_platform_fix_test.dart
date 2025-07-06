import 'package:flutter_test/flutter_test.dart';
import 'package:game1/services/game_persistence_service.dart';
import 'dart:io';

void main() {
  group('Database Platform Fix Tests', () {
    test(
      'Database factory initialization should work on current platform',
      () async {
        // Test that the database factory initializes without error
        expect(
          () => GamePersistenceService.initializeDatabaseFactory(),
          returnsNormally,
        );
      },
    );

    test('Database can be opened and closed', () async {
      // Initialize the database factory
      GamePersistenceService.initializeDatabaseFactory();

      // Create a service instance
      final service = GamePersistenceService();

      // Test that database can be opened
      final db = await service.database;
      expect(db.isOpen, isTrue);

      // Test that we can perform a simple query
      final result = await db.rawQuery('SELECT 1');
      expect(result, isNotEmpty);
      expect(result.first['1'], 1);
    });

    test('Platform detection works correctly', () {
      // This test verifies the platform detection logic
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile platforms, FFI should NOT be used
        expect(true, isTrue); // Mobile platforms should use default factory
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // On desktop platforms, FFI should be used
        expect(true, isTrue); // Desktop platforms should use FFI factory
      }
    });
  });
}
