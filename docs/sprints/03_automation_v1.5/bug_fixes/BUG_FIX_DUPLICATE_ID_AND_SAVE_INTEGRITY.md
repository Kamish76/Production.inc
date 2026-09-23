# Bug Fix: Duplicate ID Error and Machine Purchase Save Integrity

**Date:** October 11, 2025  
**Version:** 1.5.0+  
**Status:** ✅ Fixed

## Problem

### 1. Database Constraint Error
```
DatabaseException(UNIQUE constraint failed: active_productions.id (code 1555 SQLITE_CONSTRAINT_PRIMARYKEY))
```

**Root Cause:**
- Production task IDs were generated using `DateTime.now().millisecondsSinceEpoch`
- When auto-build created multiple production tasks in the same loop, they all executed within the same millisecond
- This resulted in duplicate IDs like `1760115680867_autobuild_0`

**Impact:**
- Auto-build system would occasionally fail to save production tasks
- Game state could become inconsistent

### 2. Machine Purchase Save Issue
**Root Cause:**
- `buyAutoBuyMachine()` and `buyAutoBuildMachine()` called `_saveGameStateOptimized()` without awaiting
- The save operation ran asynchronously in the background
- If the app crashed or closed before the save completed, machine purchases could be lost

**Impact:**
- Players could lose purchased machines if the app closed before the save completed
- Money would be deducted but machine count might not be saved

## Solution

### 1. Fixed Duplicate ID Generation

**Changed ID generation from milliseconds to microseconds:**

**Before:**
```dart
id: '${DateTime.now().millisecondsSinceEpoch}_autobuild_$i'
id: '${DateTime.now().millisecondsSinceEpoch}_$i'
id: DateTime.now().millisecondsSinceEpoch.toString()
```

**After:**
```dart
id: '${DateTime.now().microsecondsSinceEpoch}_autobuild_${tier}_$i'
id: '${DateTime.now().microsecondsSinceEpoch}_manual_$i'
id: DateTime.now().microsecondsSinceEpoch.toString()
```

**Benefits:**
- Microseconds provide 1000x more precision than milliseconds
- Each ID is guaranteed to be unique even when multiple tasks are created in rapid succession
- Added tier information to auto-build IDs for better debugging

### 2. Made Machine Purchases Await Save Completion

**Changed method signatures:**
```dart
// Before
bool buyAutoBuyMachine() { ... }
bool buyAutoBuildMachine(String tier) { ... }

// After
Future<bool> buyAutoBuyMachine() async { ... }
Future<bool> buyAutoBuildMachine(String tier) async { ... }
```

**Changed save calls:**
```dart
// Before
_saveGameStateOptimized();

// After
await _saveGameStateOptimized(); // Await to ensure save completes
```

**Updated UI callers:**
```dart
// Before
onPressed: () {
  final success = gameService.buyAutoBuyMachine();
  if (!success) {
    // show error
  }
}

// After
onPressed: () async {
  final success = await gameService.buyAutoBuyMachine();
  if (!success && context.mounted) { // Added context.mounted check
    // show error
  }
}
```

## Files Modified

1. **lib/services/production_game_service.dart**
   - Fixed ID generation in 3 locations (auto-build, manual production, shipping)
   - Made `buyAutoBuyMachine()` async with awaited save
   - Made `buyAutoBuildMachine()` async with awaited save

2. **lib/screens/control_screen.dart**
   - Updated auto-buy machine purchase button to await the async method
   - Updated auto-build machine purchase button to await the async method
   - Added `context.mounted` check for async scaffold messenger usage

## Testing

### Test Results
- ✅ No more duplicate ID database errors
- ✅ Machine purchases are logged successfully
- ✅ App runs smoothly with auto-build enabled
- ✅ Multiple items can be built in the same tick without conflicts

### Observed Logs
```
I/flutter: │ 💡 Auto-build machine for intermediate purchased! Count: 2, Money remaining: $11858.00
I/flutter: │ 💡 Auto-build machine for complex purchased! Count: 2, Money remaining: $10858.00
```

## Prevention

To prevent similar issues in the future:

1. **Always use microseconds for time-based IDs** when multiple items might be created rapidly
2. **Always await async save operations** when state changes are critical (like purchases)
3. **Add context.mounted checks** when showing UI feedback after async operations
4. **Include identifying information in IDs** (like tier) for better debugging

## Related Issues

- Auto-build system improvements (v1.5.0)
- Builder stats tick rate display enhancement
- Game persistence reliability

## Impact

- **High Priority:** Prevents data loss and database corruption
- **User Experience:** Ensures purchased machines are reliably saved
- **System Stability:** Eliminates intermittent database constraint errors
