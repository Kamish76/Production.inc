// Database Integrity Check Script
// This script checks for material leaks, money tracking issues, and transaction integrity

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

// ignore_for_file: avoid_print

Future<void> main() async {
  print('=== DATABASE INTEGRITY CHECK ===\n');
  
  // Initialize sqflite_ffi for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Try to find the database
  final dbPath = await _findDatabase();
  if (dbPath == null) {
    print('ERROR: Could not find production_inc_save.db');
    print('Please run the app first to generate the database.');
    return;
  }
  
  print('Database found: $dbPath\n');
  
  // Open database
  final db = await openDatabase(dbPath, readOnly: true);
  
  try {
    await _checkGameState(db);
    await _checkMaterials(db);
    await _checkProducts(db);
    await _checkActiveProductions(db);
    await _checkShippingOrders(db);
    await _analyzeTransactionFlow(db);
    await _checkForOrphanedData(db);
  } finally {
    await db.close();
  }
  
  print('\n=== CHECK COMPLETE ===');
}

Future<String?> _findDatabase() async {
  // Common database locations
  final possiblePaths = [
    // Windows AppData
    path.join(Platform.environment['APPDATA'] ?? '', 'game1', 'databases', 'production_inc_save.db'),
    path.join(Platform.environment['LOCALAPPDATA'] ?? '', 'game1', 'databases', 'production_inc_save.db'),
    // Current directory
    'production_inc_save.db',
    // Build directory
    'build/production_inc_save.db',
  ];
  
  for (final p in possiblePaths) {
    if (await File(p).exists()) {
      return p;
    }
  }
  
  return null;
}

Future<void> _checkGameState(Database db) async {
  print('--- GAME STATE ---');
  final result = await db.query('game_state');
  
  if (result.isEmpty) {
    print('⚠️  WARNING: No game state found!');
    return;
  }
  
  final state = result.first;
  final money = state['money'] as double;
  final lastSaved = state['last_saved'] as int?;
  
  print('💰 Money: \$${money.toStringAsFixed(2)}');
  
  if (money < 0) {
    print('❌ ERROR: Negative money balance detected!');
  } else if (money > 1000000000) {
    print('⚠️  WARNING: Suspiciously high money balance');
  } else {
    print('✅ Money balance looks normal');
  }
  
  if (lastSaved != null) {
    final lastSavedTime = DateTime.fromMillisecondsSinceEpoch(lastSaved);
    print('Last saved: $lastSavedTime');
  }
  
  print('');
}

Future<void> _checkMaterials(Database db) async {
  print('--- MATERIALS INVENTORY ---');
  final result = await db.query('materials');
  
  if (result.isEmpty) {
    print('No materials in inventory');
    print('');
    return;
  }
  
  var totalMaterials = 0;
  var negativeCount = 0;
  var suspiciousCount = 0;
  
  print('Material inventory:');
  for (final row in result) {
    final materialId = row['material_id'] as String;
    final quantity = row['quantity'] as int;
    totalMaterials += quantity;
    
    if (quantity < 0) {
      print('  ❌ $materialId: $quantity (NEGATIVE!)');
      negativeCount++;
    } else if (quantity > 100000) {
      print('  ⚠️  $materialId: $quantity (very high)');
      suspiciousCount++;
    } else {
      print('  ✓ $materialId: $quantity');
    }
  }
  
  print('\nTotal materials: $totalMaterials');
  
  if (negativeCount > 0) {
    print('❌ ERROR: $negativeCount materials with negative quantities!');
  }
  if (suspiciousCount > 0) {
    print('⚠️  WARNING: $suspiciousCount materials with very high quantities');
  }
  if (negativeCount == 0 && suspiciousCount == 0) {
    print('✅ Material inventory looks healthy');
  }
  
  print('');
}

Future<void> _checkProducts(Database db) async {
  print('--- PRODUCTS INVENTORY ---');
  final result = await db.query('products');
  
  if (result.isEmpty) {
    print('No products in inventory');
    print('');
    return;
  }
  
  var totalProducts = 0;
  var negativeCount = 0;
  var suspiciousCount = 0;
  
  print('Product inventory:');
  for (final row in result) {
    final productId = row['product_id'] as String;
    final quantity = row['quantity'] as int;
    totalProducts += quantity;
    
    if (quantity < 0) {
      print('  ❌ $productId: $quantity (NEGATIVE!)');
      negativeCount++;
    } else if (quantity > 100000) {
      print('  ⚠️  $productId: $quantity (very high)');
      suspiciousCount++;
    } else {
      print('  ✓ $productId: $quantity');
    }
  }
  
  print('\nTotal products: $totalProducts');
  
  if (negativeCount > 0) {
    print('❌ ERROR: $negativeCount products with negative quantities!');
  }
  if (suspiciousCount > 0) {
    print('⚠️  WARNING: $suspiciousCount products with very high quantities');
  }
  if (negativeCount == 0 && suspiciousCount == 0) {
    print('✅ Product inventory looks healthy');
  }
  
  print('');
}

Future<void> _checkActiveProductions(Database db) async {
  print('--- ACTIVE PRODUCTIONS ---');
  final result = await db.query('active_productions');
  
  if (result.isEmpty) {
    print('No active productions');
    print('');
    return;
  }
  
  print('Active production tasks: ${result.length}');
  
  var queuedCount = 0;
  var activeCount = 0;
  final productionsByProduct = <String, int>{};
  
  for (final row in result) {
    final productId = row['product_id'] as String;
    final quantity = row['quantity'] as int;
    final isQueued = row['is_queued'] as int;
    
    productionsByProduct[productId] = (productionsByProduct[productId] ?? 0) + quantity;
    
    if (isQueued == 1) {
      queuedCount++;
    } else {
      activeCount++;
    }
    
    if (quantity <= 0) {
      print('  ❌ WARNING: Production with quantity $quantity for $productId');
    }
  }
  
  print('Active: $activeCount, Queued: $queuedCount');
  print('\nProducts in production:');
  productionsByProduct.forEach((productId, qty) {
    print('  $productId: $qty units');
  });
  
  print('');
}

Future<void> _checkShippingOrders(Database db) async {
  print('--- SHIPPING ORDERS ---');
  final result = await db.query('active_shipping_orders');
  
  if (result.isEmpty) {
    print('No active shipping orders');
    print('');
    return;
  }
  
  print('Active shipping orders: ${result.length}');
  
  var totalRevenue = 0.0;
  
  for (final row in result) {
    final id = row['id'] as String;
    final completionTime = row['completion_time'] as int;
    
    // Check shipping_order_items
    final items = await db.query(
      'shipping_order_items',
      where: 'order_id = ?',
      whereArgs: [id],
    );
    
    if (items.isEmpty) {
      print('  ⚠️  Shipping order $id has no items!');
    }
    
    for (final item in items) {
      final revenue = item['revenue'] as double;
      totalRevenue += revenue;
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (completionTime < now) {
      print('  ⚠️  Shipping order should have completed: $id');
    }
  }
  
  print('Total revenue pending: \$${totalRevenue.toStringAsFixed(2)}');
  print('');
}

Future<void> _analyzeTransactionFlow(Database db) async {
  print('--- TRANSACTION FLOW ANALYSIS ---');
  
  // Check shipping history to see revenue flow
  final history = await db.query('shipping_history', orderBy: 'completed_time DESC', limit: 10);
  
  if (history.isEmpty) {
    print('No shipping history found');
    print('This could indicate money isn\'t being generated from sales.');
    print('');
    return;
  }
  
  print('Recent shipping history (last 10):');
  var totalHistoricalRevenue = 0.0;
  
  for (final record in history) {
    final id = record['id'] as String;
    final completedTime = record['completed_time'] as int;
    
    // Get items for this history entry
    final items = await db.query(
      'shipping_history_items',
      where: 'history_id = ?',
      whereArgs: [id],
    );
    
    var orderRevenue = 0.0;
    for (final item in items) {
      final revenue = item['revenue'] as double;
      orderRevenue += revenue;
    }
    
    totalHistoricalRevenue += orderRevenue;
    
    final completedDateTime = DateTime.fromMillisecondsSinceEpoch(completedTime);
    print('  Order $id: \$${orderRevenue.toStringAsFixed(2)} at $completedDateTime');
  }
  
  print('\nTotal revenue from last 10 orders: \$${totalHistoricalRevenue.toStringAsFixed(2)}');
  
  if (totalHistoricalRevenue == 0) {
    print('⚠️  WARNING: No revenue recorded in recent history');
  } else {
    print('✅ Revenue is being recorded');
  }
  
  print('');
}

Future<void> _checkForOrphanedData(Database db) async {
  print('--- ORPHANED DATA CHECK ---');
  
  // Check for shipping order items without parent orders
  final allOrderItems = await db.query('shipping_order_items');
  final activeOrders = await db.query('active_shipping_orders');
  final activeOrderIds = activeOrders.map((row) => row['id'] as String).toSet();
  
  var orphanedActiveItems = 0;
  for (final item in allOrderItems) {
    final orderId = item['order_id'] as String;
    if (!activeOrderIds.contains(orderId)) {
      orphanedActiveItems++;
    }
  }
  
  if (orphanedActiveItems > 0) {
    print('⚠️  WARNING: $orphanedActiveItems orphaned shipping order items');
  } else {
    print('✅ No orphaned active shipping items');
  }
  
  // Check for shipping history items without parent history
  final allHistoryItems = await db.query('shipping_history_items');
  final historyRecords = await db.query('shipping_history');
  final historyIds = historyRecords.map((row) => row['id'] as String).toSet();
  
  var orphanedHistoryItems = 0;
  for (final item in allHistoryItems) {
    final historyId = item['history_id'] as String;
    if (!historyIds.contains(historyId)) {
      orphanedHistoryItems++;
    }
  }
  
  if (orphanedHistoryItems > 0) {
    print('⚠️  WARNING: $orphanedHistoryItems orphaned shipping history items');
  } else {
    print('✅ No orphaned history items');
  }
  
  print('');
}
