# Production.INC Development & Invariants Rule

Whenever working on this project (Production.INC):

1. **Mandatory Context Consultation**:
   - Always consult [context.md](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/context.md) for architectural patterns, state management standards, and directory conventions before modifying code.
   - Align all new gameplay mechanics with the phases outlined in [FUTURE_PLANS.md](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/FUTURE_PLANS.md).

2. **Database Migration Invariant (CRITICAL)**:
   - NEVER alter, add, or rename SQLite database tables/columns without incrementing the database version in `lib/services/game_persistence_service.dart`.
   - Always provide an explicit, non-destructive `onUpgrade` migration step to prevent player save file corruption.

3. **Material & Inventory Consumption Invariant**:
   - Strictly maintain separation between raw materials (`materialsInventory`) and manufactured components (`productsInventory`) when items (like boxes or circuits) act as materials for higher-tier products. Never allow merged inventory logic to overwrite raw material counts.

4. **Unlock Synchronization Invariant**:
   - Any transaction that mutates inventory (manual purchases, crafting, auto-buy ticks, auto-build ticks) MUST trigger `_checkAndUpdateUnlocks()` followed by `notifyListeners()` to keep the UI in sync.

5. **Proactive Hot Reload**:
   - Utilize Dart MCP tools to trigger `hot_reload` after UI widget edits and `hot_restart` after service, state model, or initialization modifications.

6. **Icon Asset Pipeline & SVG Invariants**:
   - **SVG Exclusivity**: Standardize 100% on Scalable Vector Graphics (`.svg`) rendered via `flutter_svg`. Never convert vector SVGs to PNG.
   - **Centralized Consumption**: In-game icons must always route through `GameIcon` (or convenience constructors `GameIcon.forMaterial` / `GameIcon.forProduct`) with `placeholderBuilder` and `errorBuilder` falling back gracefully to Unicode emojis.
   - **Zero Solid Background Bleed**: All icons must have complete alpha transparency (`alpha = 0`) around artwork edges. No off-white or solid card background squares are permitted in production directories.
   - **Clean Staging & Zero Leftovers**: Temporary drop directories (e.g. `assets/images/Batch X - ...`), draft `*_v1.*` files, and unreferenced PNGs must be cleaned up before committing. Preserve empty category folders with `.gitkeep`.

