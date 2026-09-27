import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  debugPrint('Testing database factory initialization...');

  // Initialize database factory for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    debugPrint('Initializing FFI database factory for desktop...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('✅ Database factory initialized successfully');
  } else {
    debugPrint('Running on mobile platform, using default database factory');
  }

  try {
    // Test opening a database
    debugPrint('Testing database open...');
    final db = await openDatabase(
      ':memory:',
      version: 1,
      onCreate: (db, version) async {
        debugPrint('Creating test table...');
        await db.execute(
          'CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)',
        );
      },
    );

    debugPrint('✅ Database opened successfully');

    // Test basic database operations
    await db.insert('test', {'name': 'Hello World'});
    final result = await db.query('test');
    debugPrint('✅ Database operations successful: $result');

    await db.close();
    debugPrint('✅ Database closed successfully');

    debugPrint('\n🎉 All database operations completed successfully!');
  } catch (e) {
    debugPrint('❌ Database operation failed: $e');
  }
}
