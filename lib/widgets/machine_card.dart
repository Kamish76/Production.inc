import 'package:flutter/material.dart';
import '../services/production_game_service.dart';
import '../constants/game_constants.dart';

/// Unified Machine Controls Card Widget
///
/// A generic, reusable card for displaying and controlling automated machinery
/// (e.g., Auto-Buy Procurement Fleet and Auto-Build Assembly Tiers).
///
/// Features:
/// - Header: Machine Icon, Title, Subtitle, Active/Paused status badge, Master Toggle switch
/// - Fleet Count: Unit counter badge and standardized 'Buy Machine' action button
/// - Capacity Stepper: Decrement / Increment buttons with prominent capacity pill and unit label
/// - Telemetry Strip: Real-time throughput status strip with dynamic indicators
class MachineCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final bool isEnabled;
  final int machineCount;
  final double machineCost;
  final bool canBuy;
  final VoidCallback? onBuy;
  final ValueChanged<bool>? onToggle;
  final int capacity;
  final String capacityUnit;
  final VoidCallback? onIncreaseCapacity;
  final VoidCallback? onDecreaseCapacity;
  final bool canDecreaseCapacity;
  final bool canIncreaseCapacity;
  final String telemetryText;
  final IconData? telemetryIcon;
  final int machineLimit;
  final double salvageValue;
  final VoidCallback? onSalvage;
  final bool canSalvage;
  final int throughputLevel;
  final double throughputUpgradeCost;
  final VoidCallback? onUpgradeThroughput;
  final String throughputLabel;
  final bool canUpgradeThroughput;
  final bool isMaxThroughput;
  final bool showCapacity;

  const MachineCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accentColor,
    required this.isEnabled,
    required this.machineCount,
    required this.machineCost,
    required this.canBuy,
    this.onBuy,
    this.onToggle,
    required this.capacity,
    required this.capacityUnit,
    this.onIncreaseCapacity,
    this.onDecreaseCapacity,
    this.canDecreaseCapacity = true,
    this.canIncreaseCapacity = true,
    required this.telemetryText,
    this.telemetryIcon,
    this.machineLimit = 10,
    this.salvageValue = 0.0,
    this.onSalvage,
    this.canSalvage = false,
    this.throughputLevel = 1,
    this.throughputUpgradeCost = 0.0,
    this.onUpgradeThroughput,
    this.throughputLabel = '',
    this.canUpgradeThroughput = false,
    this.isMaxThroughput = false,
    this.showCapacity = true,
  });

  /// Factory constructor for Auto-Buy Machinery
  factory MachineCard.autoBuy({
    Key? key,
    required BuildContext context,
    required ProductionGameService gameService,
  }) {
    final state = gameService.state;
    final machineCount = state.autoBuyMachinesOwned;
    final isEnabled = state.autoBuyEnabled;
    final capacity = state.autoBuyResourceCapacity;
    final machineLimit = gameService.getMachineTierLimit('autoBuy');
    final cost = gameService.getMachinePrice('autoBuy', machineCount);
    final salvageValue = gameService.getMachineSalvageValue('autoBuy', machineCount);
    final canSalvage = machineCount > 0;
    final canBuy = state.money >= cost && machineCount < machineLimit;
    final throughputLevel = gameService.getAutoBuyIntakeLevel();
    final throughputCost = gameService.getAutoBuyIntakeUpgradeCost();
    final canUpgradeThroughput = state.money >= throughputCost;
    final throughputLabel =
        '${gameService.getAutoBuyIntakeMultiplier(throughputLevel)}x Intake';

    String telemetry;
    if (machineCount > 0) {
      if (isEnabled) {
        final throughput = machineCount * AutoBuyConstants.buysPerMachinePerTick;
        telemetry = 'Buying $throughput materials every ${AutoBuyConstants.tickIntervalSeconds}s (active)';
      } else {
        telemetry = 'Offline - Auto-buy is paused';
      }
    } else {
      telemetry = 'No machines deployed. Purchase a unit to start auto-procuring.';
    }

    return MachineCard(
      key: key,
      icon: Icons.shopping_cart,
      title: 'Auto-Buy Machines',
      subtitle: 'Procures raw materials automatically',
      accentColor: const Color(0xFF00E676), // Emerald / Green Accent
      isEnabled: isEnabled,
      machineCount: machineCount,
      machineCost: cost,
      canBuy: canBuy,
      machineLimit: machineLimit,
      salvageValue: salvageValue,
      canSalvage: canSalvage,
      throughputLevel: throughputLevel,
      throughputUpgradeCost: throughputCost,
      canUpgradeThroughput: canUpgradeThroughput && throughputLevel < 5,
      isMaxThroughput: throughputLevel >= 5,
      throughputLabel: throughputLabel,
      onUpgradeThroughput: () async {
        final success = await gameService.upgradeAutoBuyIntake();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough money to upgrade intake!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onSalvage: () async {
        await gameService.salvageMachine('autoBuy');
      },
      onBuy: () async {
        final success = await gameService.buyAutoBuyMachine();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough money to buy machine!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onToggle: machineCount > 0 ? (_) => gameService.toggleAutoBuy() : null,
      capacity: capacity,
      capacityUnit: 'per resource',
      onDecreaseCapacity: gameService.decreaseAutoBuyCapacity,
      onIncreaseCapacity: gameService.increaseAutoBuyCapacity,
      canDecreaseCapacity: capacity > AutoBuyConstants.defaultResourceCapacity,
      canIncreaseCapacity: true, // Phase 6: Uncapped
      telemetryText: telemetry,
      telemetryIcon: Icons.shopping_bag_outlined,
    );
  }

  /// Factory constructor for Auto-Build Machinery by tier
  factory MachineCard.autoBuild({
    Key? key,
    required BuildContext context,
    required ProductionGameService gameService,
    required String tier,
    required String tierName,
    Color? accentColor,
    IconData? icon,
    String? subtitle,
  }) {
    final state = gameService.state;
    final machineCount = state.autoBuildMachinesOwned[tier] ?? 0;
    final isEnabled = state.autoBuildEnabled[tier] ?? false;
    final capacity = state.autoBuildProductCapacity[tier] ?? AutoBuildConstants.defaultProductCapacity;
    final machineLimit = gameService.getMachineTierLimit(tier);
    final cost = gameService.getMachinePrice(tier, machineCount);
    final salvageValue = gameService.getMachineSalvageValue(tier, machineCount);
    final canSalvage = machineCount > 0;
    final canBuy = state.money >= cost && machineCount < machineLimit;
    final throughputLevel = gameService.getAutoBuildThroughputLevel(tier);
    final throughputCost = gameService.getAutoBuildThroughputUpgradeCost(tier);
    final canUpgradeThroughput = state.money >= throughputCost;
    final throughputLabel = '$throughputLevel Items/Tick';

    final effectiveColor = accentColor ?? _defaultColorForTier(tier);
    final effectiveIcon = icon ?? _defaultIconForTier(tier);
    final effectiveSubtitle = subtitle ?? _defaultSubtitleForTier(tier);

    String telemetry;
    if (machineCount > 0) {
      if (isEnabled) {
        final throughput = machineCount * AutoBuildConstants.buildsPerMachinePerTick;
        telemetry = 'Building $throughput products every ${AutoBuildConstants.tickIntervalSeconds}s (active)';
      } else {
        telemetry = 'Offline - Auto-build is paused';
      }
    } else {
      telemetry = 'No machines deployed. Purchase a unit to start auto-building.';
    }

    return MachineCard(
      key: key,
      icon: effectiveIcon,
      title: 'Auto-Build: $tierName',
      subtitle: effectiveSubtitle,
      accentColor: effectiveColor,
      isEnabled: isEnabled,
      machineCount: machineCount,
      machineCost: cost,
      canBuy: canBuy,
      machineLimit: machineLimit,
      salvageValue: salvageValue,
      canSalvage: canSalvage,
      throughputLevel: throughputLevel,
      throughputUpgradeCost: throughputCost,
      canUpgradeThroughput: canUpgradeThroughput && throughputLevel < 5,
      isMaxThroughput: throughputLevel >= 5,
      throughputLabel: throughputLabel,
      onUpgradeThroughput: () async {
        final success = await gameService.upgradeAutoBuildThroughput(tier);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough money to upgrade throughput!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onSalvage: () async {
        await gameService.salvageMachine(tier);
      },
      onBuy: () async {
        final success = await gameService.buyAutoBuildMachine(tier);
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough money to buy machine!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onToggle: machineCount > 0 ? (_) => gameService.toggleAutoBuild(tier) : null,
      capacity: capacity,
      capacityUnit: 'per product',
      onDecreaseCapacity: () => gameService.decreaseAutoBuildCapacity(tier),
      onIncreaseCapacity: () => gameService.increaseAutoBuildCapacity(tier),
      canDecreaseCapacity: capacity > AutoBuildConstants.defaultProductCapacity,
      canIncreaseCapacity: true,
      telemetryText: telemetry,
      telemetryIcon: Icons.precision_manufacturing,
    );
  }

  /// Factory constructor for Auto-Sell Machinery (Phase 9B: Auto-Sell Dispatchers)
  factory MachineCard.autoSell({
    Key? key,
    required BuildContext context,
    required ProductionGameService gameService,
  }) {
    final state = gameService.state;
    final machineCount = state.autoSellMachinesOwned;
    final isEnabled = state.autoSellEnabled;
    final machineLimit = gameService.getMachineTierLimit('autoSell');
    final cost = gameService.getMachinePrice('autoSell', machineCount);
    final salvageValue =
        gameService.getMachineSalvageValue('autoSell', machineCount);
    final canSalvage = machineCount > 0;
    final canBuy = state.money >= cost && machineCount < machineLimit;
    final throughputLevel = gameService.getAutoSellThroughputLevel();
    final throughputCost = gameService.getAutoSellThroughputUpgradeCost();
    final canUpgradeThroughput = state.money >= throughputCost;
    final throughputLabel = '$throughputLevel Units/Tick';

    String telemetry;
    if (machineCount > 0) {
      if (isEnabled) {
        final totalCapacity = machineCount * throughputLevel;
        telemetry = 'Selling up to $totalCapacity items every 5s (walk-in)';
      } else {
        telemetry = 'Offline - Auto-sell is paused';
      }
    } else {
      telemetry =
          'No dispatchers deployed. Purchase a unit to start auto-selling.';
    }

    return MachineCard(
      key: key,
      icon: Icons.storefront,
      title: 'Auto-Sell Dispatchers',
      subtitle: 'Automates finished goods walk-in sales (0 fleet slots)',
      accentColor: const Color(0xFFAB47BC), // Purple accent
      isEnabled: isEnabled,
      machineCount: machineCount,
      machineCost: cost,
      canBuy: canBuy,
      machineLimit: machineLimit,
      salvageValue: salvageValue,
      canSalvage: canSalvage,
      throughputLevel: throughputLevel,
      throughputUpgradeCost: throughputCost,
      canUpgradeThroughput: canUpgradeThroughput && throughputLevel < 5,
      isMaxThroughput: throughputLevel >= 5,
      throughputLabel: throughputLabel,
      showCapacity: false,
      capacity: 0,
      capacityUnit: '',
      onUpgradeThroughput: () async {
        final success = await gameService.upgradeAutoSellThroughput();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough money to upgrade throughput!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onSalvage: () async {
        await gameService.salvageMachine('autoSell');
      },
      onBuy: () async {
        final success = await gameService.buyAutoSellMachine();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough money to buy machine!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onToggle: machineCount > 0 ? (_) => gameService.toggleAutoSell() : null,
      telemetryText: telemetry,
      telemetryIcon: Icons.point_of_sale,
    );
  }

  static Color _defaultColorForTier(String tier) {
    switch (tier) {
      case 'basicParts':
        return Colors.cyanAccent;
      case 'intermediate':
        return Colors.amberAccent;
      case 'complex':
        return Colors.purpleAccent;
      default:
        return Colors.blueAccent;
    }
  }

  static IconData _defaultIconForTier(String tier) {
    switch (tier) {
      case 'basicParts':
        return Icons.build;
      case 'intermediate':
        return Icons.handyman;
      case 'complex':
        return Icons.memory;
      default:
        return Icons.precision_manufacturing;
    }
  }

  static String _defaultSubtitleForTier(String tier) {
    switch (tier) {
      case 'basicParts':
        return 'Automates basic parts fabrication';
      case 'intermediate':
        return 'Automates sub-assembly production';
      case 'complex':
        return 'Automates advanced manufacturing';
      default:
        return 'Automated assembly unit';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = isEnabled && machineCount > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E2842).withValues(alpha: 0.95),
            const Color(0xFF151C30).withValues(alpha: 0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? accentColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Icon + Title + Active Badge + Master Toggle
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Active/Paused Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withValues(alpha: 0.15)
                          : machineCount > 0
                              ? Colors.amber.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isActive
                            ? Colors.greenAccent.withValues(alpha: 0.5)
                            : machineCount > 0
                                ? Colors.amberAccent.withValues(alpha: 0.5)
                                : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? Colors.greenAccent
                                : machineCount > 0
                                    ? Colors.amberAccent
                                    : Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActive
                              ? 'ACTIVE'
                              : machineCount > 0
                                  ? 'PAUSED'
                                  : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isActive
                                ? Colors.greenAccent
                                : machineCount > 0
                                    ? Colors.amberAccent
                                    : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Master Toggle Switch
                  Switch(
                    value: isActive,
                    onChanged: machineCount > 0 ? onToggle : null,
                    activeThumbColor: accentColor,
                    activeTrackColor: accentColor.withValues(alpha: 0.4),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Fleet Count Row: Machines badge + Buy Machine action button + Salvage button
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Fleet Count:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131726),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$machineCount ${machineCount == 1 ? "Unit" : "Units"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  machineCount >= machineLimit
                      ? Tooltip(
                          message:
                              'Tier Limit Reached ($machineLimit/$machineLimit). Upgrade Factory to expand.',
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.lock, size: 16),
                            label: Text(
                              'Buy Machine (\$${machineCost.toInt()})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[850],
                              disabledForegroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: canBuy ? onBuy : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: Text(
                            'Buy Machine (\$${machineCost.toInt()})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[850],
                            disabledForegroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                  IconButton(
                    icon: const Icon(Icons.recycling),
                    tooltip: 'Salvage Machine',
                    color: Colors.orangeAccent,
                    disabledColor: Colors.grey[700],
                    onPressed: canSalvage
                        ? () {
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Salvage Machine'),
                                content: Text(
                                  'Salvage 1 Machine for +\$${salvageValue.toStringAsFixed(2)}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      onSalvage?.call();
                                    },
                                    child: const Text('Salvage'),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),

              if (showCapacity) ...[
                const SizedBox(height: 12),

                // 3. Capacity Stepper Row: [-] [Value] [+] + Unit label
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    const Text(
                      'Capacity:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: canDecreaseCapacity ? onDecreaseCapacity : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.redAccent,
                          disabledColor: Colors.grey[700],
                          iconSize: 22,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131726),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            '$capacity',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: canIncreaseCapacity ? onIncreaseCapacity : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.greenAccent,
                          disabledColor: Colors.grey[700],
                          iconSize: 22,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Text(
                      capacityUnit,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // 4. Throughput Upgrade Row: Throughput Badge + Upgrade Button
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    'Throughput:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (throughputLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131726),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        throughputLabel,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: canUpgradeThroughput ? onUpgradeThroughput : null,
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: Text(
                      isMaxThroughput 
                          ? 'Max Level' 
                          : 'Upgrade (\$${throughputUpgradeCost.toStringAsFixed(2)})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[850],
                      disabledForegroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 5. Telemetry / Status Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF111422),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? accentColor.withValues(alpha: 0.25)
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      telemetryIcon ??
                          (isActive ? Icons.bolt : Icons.pause_circle_outline),
                      size: 16,
                      color: isActive ? accentColor : Colors.white38,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        telemetryText,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.white54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience wrapper for AutoBuyMachineCard using unified MachineCard
class AutoBuyMachineCard extends StatelessWidget {
  final ProductionGameService gameService;

  const AutoBuyMachineCard({super.key, required this.gameService});

  @override
  Widget build(BuildContext context) {
    return MachineCard.autoBuy(context: context, gameService: gameService);
  }
}

/// Convenience wrapper for AutoBuildMachineCard using unified MachineCard
class AutoBuildMachineCard extends StatelessWidget {
  final ProductionGameService gameService;
  final String tier;
  final String tierName;
  final Color? accentColor;
  final IconData? icon;
  final String? subtitle;

  const AutoBuildMachineCard({
    super.key,
    required this.gameService,
    required this.tier,
    required this.tierName,
    this.accentColor,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return MachineCard.autoBuild(
      context: context,
      gameService: gameService,
      tier: tier,
      tierName: tierName,
      accentColor: accentColor,
      icon: icon,
      subtitle: subtitle,
    );
  }
}

/// Convenience wrapper for AutoSellMachineCard using unified MachineCard (Phase 9B)
class AutoSellMachineCard extends StatelessWidget {
  final ProductionGameService gameService;

  const AutoSellMachineCard({super.key, required this.gameService});

  @override
  Widget build(BuildContext context) {
    return MachineCard.autoSell(context: context, gameService: gameService);
  }
}
