# Build Speed Multiplier - Minimum Time Floor

## Summary
Implemented a minimum production time floor of 1 second for all products when applying auto-build machine speed multipliers.

## Problem
The build speed multiplier system (1.1x per machine, stacking multiplicatively) could theoretically reduce production times below 1 second with many machines. Since the tick mechanism operates by seconds (not milliseconds), allowing production times below 1 second would be:
- Inconsistent with the game's timing mechanism
- Potentially problematic for game balance
- Not meaningful given the 1-second tick granularity

## Solution
Modified `getAdjustedProductionTime()` in `production_game_service.dart` to enforce a minimum of 1 second:

```dart
// Apply speed bonus: time / multiplier
final adjustedTime = baseTime / speedMultiplier;

// Enforce minimum of 1 second (tick mechanism operates by seconds, not milliseconds)
return math.max(1.0, adjustedTime);
```

## Examples

### Without Floor (Previous Behavior)
- Wires (5s base) with 50 machines: ~0.42s (problematic)
- Box (3s base) with 100 machines: ~0.02s (problematic)

### With Floor (Current Behavior)
- Wires (5s base) with 50 machines: 1.0s (clamped)
- Box (3s base) with 100 machines: 1.0s (clamped)
- Wires (5s base) with 5 machines: ~3.1s (not clamped, normal reduction)

## Files Modified
1. **lib/services/production_game_service.dart**
   - Updated `getAdjustedProductionTime()` to use `math.max(1.0, adjustedTime)`
   - Updated documentation to mention minimum time

2. **lib/constants/game_constants.dart**
   - Updated documentation for `buildSpeedMultiplierPerMachine` to mention 1 second cap

## Testing
Created `test/build_speed_minimum_test.dart` with tests for:
- Extreme machine counts (50, 100) properly floor at 1 second
- Normal machine counts (5) don't hit the floor
- Short base times (3s) also respect the minimum

## Impact
- **Positive**: Prevents absurdly fast production times that don't align with game mechanics
- **No Breaking Changes**: Normal gameplay won't hit this limit
- **Future-Proof**: Protects against balance issues if players acquire many machines
