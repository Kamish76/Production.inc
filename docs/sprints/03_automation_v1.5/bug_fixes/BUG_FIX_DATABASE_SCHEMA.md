# Database Schema Fix - Auto-Buy Column Missing Issue

**Date:** 2025-10-11  
**Issue:** SQLite error "no such column: auto_buy_machines_owned" on Android  
**Status:** ✅ FIXED

## Problem Description

When running the app on Android, users encountered a database error:
```
DatabaseException(no such column: auto_buy_machines_owned (code 1 SQLITE_ERROR))
```

This occurred because:
1. Existing databases on Android devices were at an older version (pre-v1.5.0)
2. The database migration to version 6 was not running properly
3. Auto-buy machines purchased were not being saved correctly

## Root Cause

The database migration system had the correct migration code, but:
- Migrations were running silently without proper verification
- No automatic schema verification on database open
- Missing columns were not being detected until save operations failed

## Solution Implemented

### 1. Enhanced Migration System

**File:** `lib/services/game_persistence_service.dart`

#### Improved `_migrateToVersion6` Method
- Added `PRAGMA table_info` check to detect existing columns
- Only adds columns if they don't already exist
- Enhanced logging to show migration progress
- Properly checks each column before attempting ALTER TABLE

```dart
// Check if columns already exist
final tableInfo = await db.rawQuery('PRAGMA table_info(game_state)');
final existingColumns = tableInfo.map((row) => row['name'] as String).toSet();

// Only add if missing
if (!existingColumns.contains('auto_buy_machines_owned')) {
  await db.execute('ALTER TABLE game_state ADD COLUMN auto_buy_machines_owned INTEGER DEFAULT 0');
}
```

### 2. Automatic Schema Verification

**File:** `lib/services/game_persistence_service.dart`

#### Enhanced `_verifyDatabaseIntegrity` Method
- Now automatically checks for required auto-buy columns on database open
- Runs migration fix if columns are missing
- Prevents "no such column" errors before they happen

```dart
// Verify game_state has required columns
final requiredAutoColumns = {
  'auto_buy_machines_owned',
  'auto_buy_enabled',
  'auto_buy_last_tick',
  'auto_buy_resource_capacity',
};

// Auto-fix if missing
if (missingColumns) {
  await _migrateToVersion6(db);
}
```

### 3. Manual Fix Tools

**File:** `lib/services/game_persistence_service.dart`

Added two new public methods:

#### `verifyAndFixSchema()`
- Manually checks database schema
- Fixes missing columns/tables
- Safe to run - preserves all data
- Useful for debugging schema issues

#### `resetDatabase()` 
- Complete database reset (DESTRUCTIVE)
- Deletes all data and recreates fresh database
- Last resort for corrupted databases
- Only use when database is broken beyond repair

### 4. Developer UI Controls

**File:** `lib/screens/control_screen.dart`

Added new developer controls in Control Center:

1. **"Verify Database Schema"** button
   - Checks and fixes missing columns/tables
   - Safe operation - preserves data
   - Shows success/error messages

2. **"Reset Database"** button
   - WARNING: Deletes all data
   - Requires confirmation dialog
   - Only for corrupted databases

### 5. Auto-Build Status Display Enhancement

**File:** `lib/screens/control_screen.dart`

Added tick tracker information to auto-build tiers:
```dart
'Building ${machineCount * 5} products every 5s${enabled ? " (active)" : " (paused)"}'
```

This matches the auto-buy status display format and provides users with:
- Number of products built per tick
- Tick interval (5 seconds)
- Active/paused status

## Testing the Fix

### For Existing Users (Android)

1. **Update the app** to the latest version
2. **Launch the app** - schema verification runs automatically
3. **Check console output** for migration messages:
   ```
   Existing game_state columns: id, money, last_saved...
   Added column: auto_buy_machines_owned
   Schema fix completed
   ```

### Manual Fix (if needed)

If automatic fix doesn't work:

1. Open **Control Center** (bottom navigation)
2. Scroll to **Developer Controls**
3. Tap **"Verify Database Schema"**
4. Wait for success message
5. Test auto-buy machine purchase/save

### Last Resort

If database is completely broken:

1. Open **Control Center**
2. Tap **"Reset Database"** (red warning button)
3. Confirm deletion (⚠️ ALL DATA LOST)
4. App creates fresh database
5. Start new game

## Verification Steps

After fix is applied, verify:

1. ✅ Auto-buy machines can be purchased
2. ✅ Auto-buy machine count persists after app restart
3. ✅ Auto-buy enabled/disabled state saves correctly
4. ✅ Auto-buy capacity settings are saved
5. ✅ Auto-build machines save properly
6. ✅ No "no such column" errors in logs

## Database Version History

- **v1**: Initial database
- **v2**: Added integrity tracking (v1.4.8)
- **v3**: Added queue system (v1.4.10)
- **v4**: Added buy/sell preferences (v1.4.11)
- **v5**: Added product unlock system (v1.4.18)
- **v6**: Added auto-buy and auto-build systems (v1.5.0) ⬅️ **Current**

## Files Modified

1. `lib/services/game_persistence_service.dart`
   - Enhanced migration system
   - Added auto-verification on database open
   - Added manual fix methods

2. `lib/services/production_game_service.dart`
   - Added `verifyAndFixDatabaseSchema()` method
   - Added `resetDatabase()` method
   - Updated `repairDatabase()` method

3. `lib/screens/control_screen.dart`
   - Added "Verify Database Schema" button
   - Added "Reset Database" button
   - Added tick tracker to auto-build status

## Prevention

To prevent similar issues in future:

1. ✅ All migrations now check existing columns first
2. ✅ Automatic schema verification on database open
3. ✅ Better logging for migration process
4. ✅ Manual fix tools available in dev controls
5. ✅ Migration creates tables with `IF NOT EXISTS`

## Console Log Examples

### Successful Migration
```
Migrating database from version 5 to 6
Starting migration to version 6 (auto-buy system)
Existing game_state columns: id, money, last_saved, data_checksum, last_backup
Added column: auto_buy_machines_owned
Added column: auto_buy_enabled
Added column: auto_buy_last_tick
Added column: auto_buy_resource_capacity
Created auto_build_machines table
Created auto_build_enabled table
Created auto_build_last_tick table
Created auto_build_capacity table
Database migration completed successfully
```

### Automatic Fix on Open
```
Database verification: Missing column auto_buy_machines_owned, will attempt fix
Applying schema fix for auto-buy columns...
Starting migration to version 6 (auto-buy system)
...
Schema fix completed
```

## Notes

- Migration is **idempotent** - safe to run multiple times
- All data is **preserved** during schema fixes
- Backup is automatically created before migrations
- Changes are **backward compatible** with older versions

## Support

If users still encounter issues after applying fixes:

1. Check console logs for error messages
2. Try "Verify Database Schema" button
3. Check if database file is corrupted
4. As last resort, use "Reset Database" (loses all progress)
5. Report issue with full error log

---

**Version:** v1.5.0 Phase 2  
**Feature Branch:** `feature/Automation/builder`
