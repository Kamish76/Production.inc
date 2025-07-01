import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  print('Testing database factory initialization...');

  // Initialize database factory for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    print('Initializing FFI database factory for desktop...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('✅ Database factory initialized successfully');
  } else {
    print('Running on mobile platform, using default database factory');
  }

  try {
    // Test opening a database
    print('Testing database open...');
    final db = await openDatabase(
      ':memory:',
      version: 1,
      onCreate: (db, version) async {
        print('Creating test table...');
        await db.execute(
          'CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)',
        );
      },
    );

    print('✅ Database opened successfully');

    // Test basic database operations
    await db.insert('test', {'name': 'Hello World'});
    final result = await db.query('test');
    print('✅ Database operations successful: $result');

    await db.close();
    print('✅ Database closed successfully');

    print('\n🎉 All database operations completed successfully!');
  } catch (e) {
    print('❌ Database operation failed: $e');
  }
}
