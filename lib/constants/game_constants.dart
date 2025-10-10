/// Game Constants - Centralized configuration values
///
/// This file contains all magic numbers, thresholds, and configuration
/// values used throughout the Production.Inc game. Centralizing these
/// values makes the codebase more maintainable and allows for easy
/// balance adjustments.
///
/// Created as part of v1.4.19 code quality improvements.
library;

import 'package:flutter/material.dart';

// ==================================================
// PRODUCTION & TIMING CONSTANTS
// ==================================================

/// Timer update frequencies (in milliseconds)
class TimerConstants {
  /// Fast update interval when operations are finishing soon
  static const int fastUpdateMs = 500;

  /// Normal update interval for active operations
  static const int normalUpdateMs = 1000;

  /// Slow update interval when fewer operations are active
  static const int slowUpdateMs = 2000;

  /// Idle update interval when no operations are active
  static const int idleUpdateMs = 5000;
}

/// Save frequency constants (in seconds)
class SaveConstants {
  /// Save frequency when app is active and operations are running
  static const int activeSaveIntervalSeconds = 60;

  /// Save frequency when app is in background
  static const int backgroundSaveIntervalSeconds = 300; // 5 minutes

  /// Force save frequency (legacy - used in old save system)
  static const int legacyActiveSaveSeconds = 30;

  /// Force save frequency for background (legacy)
  static const int legacyBackgroundSaveSeconds = 120; // 2 minutes
}

// ==================================================
// GAME BALANCE CONSTANTS
// ==================================================

/// Inventory and money limits to prevent overflow
class LimitsConstants {
  /// Maximum quantity of any product/material a player can own
  static const int maxProducts = 1000000;

  /// Maximum money a player can have
  static const double maxMoney = 999999999.0;

  /// Maximum shipping history entries to keep (for performance)
  static const int maxShippingHistoryEntries = 100;
}

/// Economic balance constants
class EconomicConstants {
  /// Profit per second for retail products (total chain time calculation)
  static const double retailProfitPerSecond = 0.5;

  /// Minimum profit margin for basic parts
  static const double basicPartsMinProfitMargin = 0.05; // 5%

  /// Maximum profit margin for basic parts
  static const double basicPartsMaxProfitMargin = 0.15; // 15%

  /// Minimum profit for basic parts (overrides percentage when higher)
  static const double basicPartsMinProfit = 1.0;

  /// Target profit margin for intermediate parts
  static const double intermediatePartsTargetMargin = 0.20; // 20%

  /// Target profit margin for complex parts
  static const double complexPartsTargetMargin = 0.14; // 14%
}

// ==================================================
// UNLOCK SYSTEM CONSTANTS
// ==================================================

/// Material thresholds for unlocking basic parts
/// These values determine when basic parts become visible to players
class UnlockThresholds {
  // Basic parts material requirements
  static const int boxCardboardThreshold = 3;
  static const int wiresBasicMetalsThreshold = 2;
  static const int wiresPlasticThreshold = 1;
  static const int circuitsBasicMetalsThreshold = 3;
  static const int circuitsPlasticThreshold = 2;
  static const int plasticEnclosurePlasticThreshold = 4;
  static const int metalEnclosureBasicMetalsThreshold = 2;
  static const int metalEnclosurePlasticThreshold = 1;
  static const int lensGlassThreshold = 1;
  static const int lensAdvancedMetalsThreshold = 2;
  static const int batteryAdvancedMetalsThreshold = 2;
  static const int batteryPlasticThreshold = 1;
  static const int solarCellsAdvancedMetalsThreshold = 2;
  static const int solarCellsGlassThreshold = 2;
  static const int gearsBasicMetalsThreshold = 1;
  static const int soundDriverAdvancedMetalsThreshold = 2;
  static const int soundDriverBasicMetalsThreshold = 1;
}

// ==================================================
// UI CONSTANTS
// ==================================================

/// User interface spacing and sizing constants
class UIConstants {
  /// Standard padding for cards and containers
  static const double standardPadding = 8.0;

  /// Large padding for screen edges
  static const double largePadding = 16.0;

  /// Small padding for tight spaces
  static const double smallPadding = 4.0;

  /// Standard spacing between UI elements
  static const double standardSpacing = 12.0;

  /// Minimum touch target size (accessibility)
  static const double minTouchTarget = 48.0;

  /// Card elevation for material design
  static const double cardElevation = 2.0;

  /// Animation duration for smooth transitions (milliseconds)
  static const int standardAnimationMs = 300;

  /// Icon rotation animation duration (milliseconds)
  static const int iconAnimationMs = 200;
}

/// Typography constants
class TypographyConstants {
  /// Product name font size in cards
  static const double productNameSize = 14.0;

  /// Production time font size
  static const double productionTimeSize = 12.0;

  /// Status indicator font size
  static const double statusIndicatorSize = 12.0;

  /// Material label font size
  static const double materialLabelSize = 12.0;

  /// Material chip font size
  static const double materialChipSize = 10.0;

  /// Button text font size
  static const double buttonTextSize = 11.0;

  /// Small button text font size
  static const double smallButtonTextSize = 9.0;
}

/// Grid layout constants
class LayoutConstants {
  /// Number of columns for mobile 3-column layout
  static const int mobileColumns = 3;

  /// Number of columns for tablet layout
  static const int tabletColumns = 4;

  /// Number of columns for desktop layout
  static const int desktopColumns = 5;

  /// Breakpoint for narrow screens (switches to 2 columns)
  static const double narrowScreenBreakpoint = 400.0;

  /// Breakpoint for tablet layout
  static const double tabletBreakpoint = 768.0;

  /// Breakpoint for desktop layout
  static const double desktopBreakpoint = 1024.0;
}

// ==================================================
// DEBUG & LOGGING CONSTANTS
// ==================================================

/// Debug output configuration
class DebugConstants {
  /// Whether to show verbose production logging
  static const bool verboseProductionLogging = false;

  /// Whether to show unlock system debug logs
  static const bool unlockSystemLogging = false;

  /// Whether to show performance timing logs
  static const bool performanceLogging = false;

  /// Whether to show save/load operation logs
  static const bool persistenceLogging = true;
}

// ==================================================
// VALIDATION CONSTANTS
// ==================================================

/// Input validation limits
class ValidationConstants {
  /// Minimum reasonable production time (seconds)
  static const double minProductionTime = 0.1;

  /// Maximum reasonable production time (seconds)
  static const double maxProductionTime = 3600.0; // 1 hour

  /// Minimum reasonable sell price
  static const double minSellPrice = 0.01;

  /// Maximum reasonable sell price
  static const double maxSellPrice = 999999.0;

  /// Minimum quantity for purchases/sales
  static const int minQuantity = 1;

  /// Maximum quantity for single operation
  static const int maxSingleOperationQuantity = 1000;
}

// ==================================================
// AUTO-BUY MACHINE CONSTANTS (v1.5.0 - in development)
// ==================================================

/// Auto-Buy Machine configuration and behavior constants
class AutoBuyConstants {
  /// Number of items one machine buys per tick
  static const int buysPerMachinePerTick = 5;
  
  /// Default resource capacity (player-configurable in increments of 10)
  static const int defaultResourceCapacity = 10;
  
  /// Capacity increment step (capacity can only be changed in multiples of this)
  static const int capacityIncrement = 10;
  
  /// Interval between auto-buy ticks (seconds) - DEV MODE: reduced to 5s for testing
  static const int tickIntervalSeconds = 5;
  
  /// Resource order for auto-buy processing (priority order)
  /// Earlier resources in the list are filled first
  static const List<String> resourceOrder = [
    'cardboard', // Cardboard ($1) - cheapest first
    'plastic', // Plastic ($2)
    'basic_metals', // Basic Metals ($3)
    'glass', // Glass ($5)
    'advanced_metals', // Advanced Metals ($8) - most expensive last
  ];
}

// ==================================================
// AUTO-BUILD MACHINE CONSTANTS (v1.5.0 Phase 2 - in development)
// ==================================================

/// Auto-Build Machine configuration and behavior constants
class AutoBuildConstants {
  /// Number of products one machine builds per tick
  static const int buildsPerMachinePerTick = 2;
  
  /// Default product capacity (player-configurable in increments of 10)
  static const int defaultProductCapacity = 10;
  
  /// Capacity increment step (capacity can only be changed in multiples of this)
  static const int capacityIncrement = 10;
  
  /// Interval between auto-build ticks (seconds) - DEV MODE: 5s for testing
  static const int tickIntervalSeconds = 5;
  
  /// Product order for auto-build processing per tier (ordered by production time, simplest first)
  /// Earlier products in each tier list are built first
  static const Map<String, List<String>> productOrderByTier = {
    'basicParts': [
      'box', // Box - 3 seconds (simplest)
      'wires', // Wires - 5 seconds
      'enclosure_plastic', // Plastic Enclosure - 6 seconds
      'metal_enclosure', // Metal Enclosure - 7 seconds
      'circuits', // Circuits - 8 seconds
      'lens', // Lens - 10 seconds
      'battery', // Battery - 12 seconds
      'sound_driver', // Sound Driver - 15 seconds
      'solar_cells', // Solar Cells - 15 seconds
      'gears', // Gears - 2 seconds
    ],
    'intermediate': [
      'display_screen', // 20 seconds
      'processor', // 25 seconds
      'image_sensor', // 30 seconds
      'gear_mechanism', // 15 seconds
    ],
    'complex': [
      'camera_module', // 50 seconds
    ],
  };
}

// ==================================================
// COLOR CONSTANTS
// ==================================================

/// Application color scheme constants
class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFF1A1A2E);
  static const Color gradientEnd = Color(0xFF16213E);

  // Accent colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryBlueLight = Color(0xFF64B5F6);
  static const Color primaryBlueDark = Color(0xFF1976D2);

  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textHint = Color(0xFF78909C);

  // Background colors
  static const Color cardBackground = Color(0xFF263238);
  static const Color surfaceBackground = Color(0xFF37474F);

  // Border colors
  static const Color borderLight = Color(0xFF546E7A);
  static const Color borderAccent = Color(0xFF42A5F5);

  // Production status colors
  static const Color productionActive = Color(0xFFFF9800);
  static const Color productionComplete = Color(0xFF4CAF50);
  static const Color productionQueued = Color(0xFF9E9E9E);
}

// ==================================================
